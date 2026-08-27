import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'api_exception.dart';
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // ============================================
  // AUTHENTIFICATION
  // ============================================

  Future<Map<String, dynamic>> loginWithEmail(String email, UserType userType) async {
    final role = userType == UserType.stagiaire ? 'stagiaire' : 'entreprise';
    final response = await postRequest('/auth/login', {'email': email, 'role': role}, useAuth: false);
    return response['data'] ?? response;
  }

  Future<Map<String, dynamic>> verifyLoginCode(String email, String code) async {
    final response = await postRequest('/auth/verify', {'email': email, 'code': code}, useAuth: false);
    final result = response['data'] ?? response;
    
    final String? tokenValue = result['token'];
    final String? roleValue = result['user']?['role'];
    
    if (tokenValue != null) {
      await saveToken(tokenValue, role: roleValue);
    }
    return result;
  }

  Future<void> resendCode(String email) async {
    await postRequest('/auth/resend-code', {'email': email}, useAuth: false);
  }

  Future<void> logout() async {
    try {
      await postRequest('/auth/logout', {});
    } catch (_) {}
    await clearToken();
  }

  Future<bool> validateToken() async {
    if (!isAuthenticated) return false;
    try {
      await getProfile();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  // ============================================
  // PROFIL
  // ============================================

  Future<Map<String, dynamic>> getProfile() async {
    return readCachedOrRefresh<Map<String, dynamic>>(
      'profile',
      () async => await getRequest('/auth/profile'),
      ttl: const Duration(minutes: 10),
    );
  }

  Future<String> updatePhotoProfil(File fichier) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${BaseApiService.baseUrl}/user/photo'));
      request.headers.addAll(authHeadersMultipart);
      request.files.add(await http.MultipartFile.fromPath('photo', fichier.path));

      // Note: we use a temporary client for multipart as BaseApiService generic post doesn't support it yet
      final httpClient = http.Client();
      final streamedResponse = await httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(body['message'] ?? 'Erreur envoi photo', statusCode: response.statusCode);
      }

      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final url = data['photo_profil_url'] ?? data['photo_url'] ?? data['photo_profil'];
      
      await cache.delete('profile');
      return url;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError('/user/photo');
    }
  }

  Future<Map<String, dynamic>> completeStagiaireProfile(Map<String, dynamic> data) async {
    final body = await postRequest('/stagiaire/profil', data);
    await cache.delete('profile');
    return body;
  }

  Future<Map<String, dynamic>> completeEntrepriseProfile(Map<String, dynamic> data) async {
    final body = await postRequest('/entreprise/profil', data);
    await cache.delete('profile');
    return body;
  }

  Future<void> supprimerPhotoProfil() async {
    try {
      await deleteRequest('/user/photo');
      await cache.delete('profile');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError('/user/photo');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await postRequest('/auth/delete-account', {});
    } catch (_) {}
    await clearToken();
  }
}
