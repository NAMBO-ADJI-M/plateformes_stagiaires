// lib/services/auth_service.dart
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService([ApiService? apiService])
      : _apiService = apiService ?? ApiService();

  // ============================================
  // DEMANDE DE CODE (inscription ou connexion, sans mot de passe)
  // ============================================

  Future<Map<String, dynamic>> requestCode(
    String email,
    UserType userType,
  ) async {
    try {
      final role = userType == UserType.stagiaire ? 'stagiaire' : 'entreprise';
      // Le backend crée le compte automatiquement s'il n'existe pas
      // et envoie systématiquement un code de vérification par email.
      return await _apiService.loginWithEmail(email, role);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Impossible d\'envoyer le code. Vérifiez votre email.');
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

  /// Vérifie que le token stocké est toujours valide auprès du backend.
  /// À utiliser au démarrage de l'app pour décider si l'utilisateur
  /// reste connecté (accès direct au dashboard) ou doit se réauthentifier.
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