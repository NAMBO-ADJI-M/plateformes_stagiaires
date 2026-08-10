// lib/services/auth_service.dart
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService([ApiService? apiService])
      : _apiService = apiService ?? ApiService();

  // ============================================
  // LOGIN
  // ============================================

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    UserType userType,
  ) async {
    try {
      final role = userType == UserType.stagiaire ? 'stagiaire' : 'entreprise';
      final result = await _apiService.loginWithEmail(email, password, role);

      if (result.containsKey('token') && result['token'] != null) {
        await saveToken(result['token']);
      }

      return result;
    } on ApiException {
      // ✅ On garde le message ET les erreurs de validation d'origine
      rethrow;
    } catch (error) {
      throw ApiException('Impossible de se connecter. Vérifiez vos informations.');
    }
  }

  // ============================================
  // VÉRIFIER LE CODE
  // ============================================

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final result = await _apiService.verifyLoginCode(email, code);

      if (result.containsKey('token') && result['token'] != null) {
        await saveToken(result['token']);
      }

      return result;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Code invalide ou expiré. Veuillez réessayer.');
    }
  }

  // ============================================
  // RENVOYER LE CODE
  // ============================================

  Future<void> resendCode(String email) async {
    try {
      await _apiService.resendCode(email);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Impossible d\'envoyer le code. Veuillez réessayer.');
    }
  }

  // ============================================
  // INSCRIPTION
  // ============================================

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    UserType userType,
  ) async {
    try {
      final role = userType == UserType.stagiaire ? 'stagiaire' : 'entreprise';

      // Utilise loginWithEmail() pour créer le compte auto
      final result = await _apiService.loginWithEmail(email, password, role);

      return result;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Impossible de créer le compte. Vérifiez vos informations.');
    }
  }

  // ============================================
  // DÉCONNEXION
  // ============================================

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (error) {
      // Ignorer les erreurs de déconnexion
    }
    await clearToken();
  }

  // ============================================
  // SAUVEGARDE DU TOKEN
  // ============================================

  Future<void> saveToken(String token) async {
    _apiService.setToken(token);
    await _apiService.saveToken(token);
  }

  Future<void> loadToken() async {
    await _apiService.loadToken();
  }

  Future<void> clearToken() async {
    _apiService.clear();
    await _apiService.clearToken();
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
    try {
      return await _apiService.getProfile();
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Impossible de charger le profil.');
    }
  }

  // ============================================
  // ÉTAT DE L'AUTHENTIFICATION
  // ============================================

  bool get isAuthenticated => _apiService.isAuthenticated;
  bool get isStagiaire => _apiService.isStagiaire;
  bool get isEntreprise => _apiService.isEntreprise;
  String? get token => _apiService.token;
  String? get userRole => _apiService.userRole;

  // ============================================
  // GESTION DU TOKEN
  // ============================================

  void setToken(String token) {
    _apiService.setToken(token);
  }

  void setUserRole(String role) {
    _apiService.setUserRole(role);
  }

  void clear() {
    _apiService.clear();
  }
}