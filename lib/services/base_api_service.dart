import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_exception.dart';
import 'sqlite_cache_service.dart';
import 'offline_queue_service.dart';

http.Client _buildHttpClient() {
  final httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  return IOClient(httpClient);
}

abstract class BaseApiService {
  static const String baseUrl = "https://backend-stagiaires-laravel-1.onrender.com/api";
  
  final http.Client _httpClient = _buildHttpClient();
  final SqliteCacheService cache = SqliteCacheService();
  final OfflineQueueService queue = OfflineQueueService();
  final Connectivity _connectivity = Connectivity();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  static String? _token;
  static String? _userRole;

  String? get token => _token;
  String? get userRole => _userRole;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Map<String, String> get authHeadersMultipart => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<void> saveToken(String token, {String? role}) async {
    _token = token;
    await secureStorage.write(key: 'auth_token', value: token);

    if (role != null) {
      _userRole = role;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
    }
  }

  Future<void> loadToken() async {
    _token = await secureStorage.read(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('user_role');
  }

  Future<void> clearToken() async {
    _token = null;
    _userRole = null;
    await secureStorage.delete(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await cache.clearAll();
  }

  void setToken(String token) => _token = token;
  void setUserRole(String role) => _userRole = role;
  
  bool get isAuthenticated => _token != null;
  bool get isStagiaire => _userRole == 'stagiaire';
  bool get isEntreprise => _userRole == 'entreprise';

  Future<bool> isOnline() async {
    try {
      final dynamic result = await _connectivity.checkConnectivity();
      if (result is List) {
        return result.isNotEmpty && result.any((res) => res != ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _withRetry(Future<http.Response> Function() action, {int attempts = 3}) async {
    int count = 0;
    while (count < attempts) {
      try {
        final response = await action();
        if (response.statusCode != 502 && response.statusCode != 503 && response.statusCode != 504) {
          return response;
        }
      } catch (e) {
        if (count == attempts - 1) rethrow;
      }
      count++;
      await Future.delayed(Duration(seconds: 1 * count));
    }
    throw Exception("Le serveur Render met trop de temps à répondre (Cold Start).");
  }

  Future<dynamic> getRequest(String endpoint) async {
    try {
      final response = await _withRetry(() => _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: authHeaders,
      ));
      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw ApiException(
          decoded['message'] ?? 'Erreur serveur',
          statusCode: response.statusCode,
          errors: decoded['errors'] as Map<String, dynamic>?,
        );
      }
      return decoded;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(endpoint);
    }
  }

  Future<dynamic> postRequest(String endpoint, dynamic body, {bool useAuth = true}) async {
    final online = await isOnline();
    if (!online) {
      await queue.enqueue('POST', endpoint, headers: useAuth ? authHeaders : headers, body: body);
      throw ApiException('Vous êtes hors ligne. L\'opération sera envoyée plus tard.', statusCode: 0);
    }

    try {
      final response = await _withRetry(() => _httpClient.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: useAuth ? authHeaders : headers,
        body: body is String ? body : jsonEncode(body),
      ));

      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(decoded['message'] ?? 'Erreur lors de l\'envoi', statusCode: response.statusCode);
      }
      return decoded;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(endpoint);
    }
  }

  Future<dynamic> deleteRequest(String endpoint) async {
    final online = await isOnline();
    if (!online) {
      await queue.enqueue('DELETE', endpoint, headers: authHeaders);
      throw ApiException('Vous êtes hors ligne. L\'opération sera envoyée plus tard.', statusCode: 0);
    }

    final response = await _httpClient.delete(Uri.parse('$baseUrl$endpoint'), headers: authHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Erreur lors de la suppression', statusCode: response.statusCode);
    }
    return jsonDecode(response.body);
  }

  Future<T> readCachedOrRefresh<T>(String key, Future<T> Function() loader, {Duration ttl = const Duration(minutes: 10), bool forceRefresh = false}) async {
    final cached = await cache.getJson<T>(key);
    final cachedIsEmptyList = cached is List && cached.isEmpty;

    if (cached != null && !forceRefresh && !cachedIsEmptyList) {
      (() async {
        try {
          final fresh = await loader();
          if (fresh is! List || fresh.isNotEmpty) {
            await cache.setJson(key, fresh, ttl: ttl);
          }
        } catch (_) {}
      })();
      return cached;
    }

    final fresh = await loader();
    if (fresh is! List || fresh.isNotEmpty) {
      await cache.setJson(key, fresh, ttl: ttl);
    } else {
      await cache.delete(key);
    }
    return fresh;
  }

  List<dynamic> decodeListResponse(dynamic response) {
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) return response['data'];
    return [];
  }

  Future<void> syncOfflineQueue() async {
    final online = await isOnline();
    if (!online) return;

    final pending = await queue.getPending();
    if (pending.isEmpty) return;

    for (final op in pending) {
      try {
        await _retryQueuedOperation(op);
        await queue.remove(op.id);
      } catch (e) {
        await queue.incrementRetry(op.id);
      }
    }
  }

  Future<void> _retryQueuedOperation(QueuedOperation op) async {
    final url = Uri.parse('$baseUrl${op.endpoint}');
    late http.Response response;

    if (op.method == 'POST') {
      response = await _httpClient.post(url, headers: op.headers ?? authHeaders, body: op.body);
    } else if (op.method == 'DELETE') {
      response = await _httpClient.delete(url, headers: op.headers ?? authHeaders);
    } else {
      throw Exception('Unsupported method: ${op.method}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Échec synchro ${op.method} ${op.endpoint}', statusCode: response.statusCode);
    }
  }
}
