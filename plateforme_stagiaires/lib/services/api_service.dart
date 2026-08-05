import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:plateforme_stagiaires/modeles/user_type.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}

class AuthService {
  AuthService({http.Client? httpClient, FlutterSecureStorage? storage})
      : _client = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const _storageTokenKey = 'auth_access_token';

  /// Remplacez par l'URL de votre backend Laravel.
  static const String baseUrl = String.fromEnvironment(
    'http://10.0.2.2:8000/api',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _token;

  Future<void> init() async {
    _token = await _storage.read(key: _storageTokenKey);
  }

  Future<void> requestCode(UserType type, String email) async {
    final endpoint = type == UserType.stagiaire
        ? 'auth/stagiaire/demander-code'
        : 'auth/entreprise/demander-code';

    final response = await _post(endpoint, {'email': email});
    if (response.statusCode != 200) {
      throw ApiException(_decodeMessage(response) ?? 'Erreur lors de l’envoi du code.');
    }
  }

  Future<void> verifyCode(UserType type, String email, String code) async {
    final endpoint = type == UserType.stagiaire
        ? 'auth/stagiaire/verifier-code'
        : 'auth/entreprise/verifier-code';

    final response = await _post(endpoint, {'email': email, 'code': code});
    if (response.statusCode != 200) {
      throw ApiException(_decodeMessage(response) ?? 'Code invalide ou expiré.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = body['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('Le token d’authentification est manquant.');
    }

    _token = accessToken;
    await _storage.write(key: _storageTokenKey, value: accessToken);
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    if (_token == null) {
      throw ApiException('Utilisateur non authentifié.');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/profil/moi'),
      headers: _defaultHeaders,
    );

    if (response.statusCode != 200) {
      throw ApiException(_decodeMessage(response) ?? 'Impossible de récupérer le profil.');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Map<String, String> get _defaultHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> _post(String path, Map<String, Object> body) {
    final uri = Uri.parse('$baseUrl/$path');
    return _client.post(
      uri,
      headers: _defaultHeaders,
      body: jsonEncode(body),
    );
  }

  String? _decodeMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['message']?.toString();
    } catch (_) {
      return null;
    }
  }
}
