// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_exception.dart';

class ApiService {
  // IP hôte recommandée pour l'émulateur Android (10.0.2.2) ou localhost pour le web/desktop
  static const String baseUrl = "http://127.0.0.1:8000/api";

  String? _token;
  String? _userRole;

  String? get token => _token;
  String? get userRole => _userRole;

  // ============================================
  // GESTION DU TOKEN ET DU RÔLE
  // ============================================

  Future<void> saveToken(String token, {String? role}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (role != null) {
      _userRole = role;
      await prefs.setString('user_role', role);
    }
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('user_role');
    if (token != null) {
      _token = token;
    }
    if (role != null) {
      _userRole = role;
    }
  }

  Future<void> clearToken() async {
    _token = null;
    _userRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
  }

  // ============================================
  // HEADERS
  // ============================================

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  // ============================================
  // AUTHENTIFICATION
  // ============================================

  /// Connexion ou demande de code par e-mail
  Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userData = data['data'];
        _token = userData['token'];
        _userRole = userData['user']?['role'] ?? role;
        await saveToken(_token!, role: _userRole);
        return userData;
      }

      if (response.statusCode == 201 || response.statusCode == 403) {
        return data['data'] ?? data;
      }

      throw ApiException(
        data['message'] ?? 'Erreur de connexion',
        statusCode: response.statusCode,
        errors: data['errors'] as Map<String, dynamic>?,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError('/auth/login');
    }
  }

  /// Vérification du code OTP
  Future<Map<String, dynamic>> verifyLoginCode(
    String email,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw ApiException(
          data['message'] ?? 'Code invalide',
          statusCode: response.statusCode,
          errors: data['errors'] as Map<String, dynamic>?,
        );
      }

      final result = data['data'];
      _token = result['token'];
      _userRole = result['user']?['role'];
      await saveToken(_token!, role: _userRole);

      return result;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError('/auth/verify');
    }
  }

  Future<void> resendCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-code'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw ApiException(
          data['message'] ?? 'Erreur d\'envoi',
          statusCode: response.statusCode,
          errors: data['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError('/auth/resend-code');
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _authHeaders,
        );
      } catch (_) {}
    }
    await clearToken();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _authHeaders,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message'] ?? 'Erreur de chargement du profil',
        statusCode: response.statusCode,
        errors: data['errors'] as Map<String, dynamic>?,
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> completeStagiaireProfile(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stagiaire/profil'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        body['message'] ?? 'Erreur de mise à jour du profil',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> completeEntrepriseProfile(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/entreprise/profil'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        body['message'] ?? 'Erreur de mise à jour de l\'entreprise',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  @Deprecated('Utilisez loginWithEmail() à la place')
  Future<void> register(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 201) {
        throw ApiException(
          data['message'] ?? 'Erreur d\'inscription',
          statusCode: response.statusCode,
          errors: data['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError('/auth/register');
    }
  }

  // ============================================
  // RÉFÉRENTIEL
  // ============================================

  Future<List<dynamic>> getDomaines() async {
    final response = await http.get(Uri.parse('$baseUrl/referentiel/domaines'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<List<dynamic>> getMetiers() async {
    final response = await http.get(Uri.parse('$baseUrl/referentiel/metiers'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<List<dynamic>> getNiveauxFormation() async {
    final response = await http.get(Uri.parse('$baseUrl/referentiel/niveaux-formation'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<List<dynamic>> getCompetences() async {
    final response = await http.get(Uri.parse('$baseUrl/referentiel/competences'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<List<dynamic>> getCriteresSavoirEtre() async {
    final response = await http.get(Uri.parse('$baseUrl/criteres-savoir-etre'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  // ============================================
  // CARNET DE STAGE & POINTAGE
  // ============================================

  Future<List<dynamic>> getCarnets() async {
    final response = await http.get(Uri.parse('$baseUrl/carnets'), headers: _authHeaders);
    if (response.statusCode != 200) {
      throw ApiException('Impossible de récupérer les carnets', statusCode: response.statusCode);
    }
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<Map<String, dynamic>> createCarnet(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/carnets'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Erreur lors de la création du carnet',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> rattacherCarnet(String codeInvitation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rattacher-carnet'),
      headers: _authHeaders,
      body: jsonEncode({'code_invitation': codeInvitation}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Code d\'invitation invalide',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> pointageArrivee({double? latitude, double? longitude, int? carnetId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pointage/arrivee'),
      headers: _authHeaders,
      body: jsonEncode({
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (carnetId != null) 'carnet_id': carnetId,
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        body['message'] ?? 'Erreur de pointage arrivée',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> pointageDepart({double? latitude, double? longitude, int? carnetId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pointage/depart'),
      headers: _authHeaders,
      body: jsonEncode({
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (carnetId != null) 'carnet_id': carnetId,
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        body['message'] ?? 'Erreur de pointage départ',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  Future<List<dynamic>> getHistoriquePointage(int carnetId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pointage/$carnetId/historique'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw ApiException('Erreur de chargement de l\'historique', statusCode: response.statusCode);
    }
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<List<dynamic>> getMesAttestations() async {
    final response = await http.get(Uri.parse('$baseUrl/mes-attestations'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<Map<String, dynamic>> createBilanReflexif(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bilans-reflexifs'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ============================================
  // COVOITURAGE
  // ============================================

  Future<List<dynamic>> getTrajets() async {
    final response = await http.get(Uri.parse('$baseUrl/trajets'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<Map<String, dynamic>> createTrajet(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trajets'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Erreur de création de trajet',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  Future<List<dynamic>> getMesTrajets() async {
    final response = await http.get(Uri.parse('$baseUrl/trajets/mes-trajets'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<Map<String, dynamic>> reserverTrajet(int trajetId, {int nombrePlaces = 1}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/$trajetId/reserver'),
      headers: _authHeaders,
      body: jsonEncode({'nombre_places': nombrePlaces}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        body['message'] ?? 'Erreur de réservation',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  Future<void> annulerReservation(int reservationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/$reservationId/annuler'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
        body['message'] ?? 'Erreur d\'annulation',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
  }

  Future<List<dynamic>> getMesReservations() async {
    final response = await http.get(Uri.parse('$baseUrl/reservations/mes-reservations'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<List<dynamic>> getTrajetMessages(int trajetId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trajets/$trajetId/messages'),
      headers: _authHeaders,
    );
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<Map<String, dynamic>> sendTrajetMessage(int trajetId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trajets/$trajetId/messages'),
      headers: _authHeaders,
      body: jsonEncode({'contenu': message}),
    );
    return jsonDecode(response.body);
  }

  Future<void> signalerTrajet(int trajetId, String motif) async {
    await http.post(
      Uri.parse('$baseUrl/trajets/$trajetId/signaler'),
      headers: _authHeaders,
      body: jsonEncode({'motif': motif}),
    );
  }

  // ============================================
  // ENTREPRISE / TUTEUR
  // ============================================

  Future<Map<String, dynamic>> createFicheInvitation(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fiches-invitation'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Erreur d\'invitation',
        statusCode: response.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return body;
  }

  Future<List<dynamic>> getFichesInvitation() async {
    final response = await http.get(Uri.parse('$baseUrl/fiches-invitation'), headers: _authHeaders);
    return jsonDecode(response.body)['data'] ?? [];
  }

  Future<Map<String, dynamic>> evaluerCompetence(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/evaluations'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> genererAttestation(int evaluationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/documents/evaluations/$evaluationId/attestation'),
      headers: _authHeaders,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> genererCarteAppui(int evaluationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/documents/evaluations/$evaluationId/carte-appui'),
      headers: _authHeaders,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> evaluerSavoirEtre(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/evaluations-savoir-etre'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ============================================
  // UTILS
  // ============================================

  bool get isAuthenticated => _token != null;
  bool get isStagiaire => _userRole == 'stagiaire';
  bool get isEntreprise => _userRole == 'entreprise';

  void setToken(String token) => _token = token;
  void setUserRole(String role) => _userRole = role;
  void clear() {
    _token = null;
    _userRole = null;
  }
}