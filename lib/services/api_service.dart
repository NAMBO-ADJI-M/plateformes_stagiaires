// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_exception.dart';
import 'sqlite_cache_service.dart';
import 'offline_queue_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // IP hôte recommandée pour l'émulateur Android (10.0.2.2) ou localhost pour le web/desktop
  static const String baseUrl = "https://backend-stagiaires-laravel-1.onrender.com/api";

  String? _token;
  String? _userRole;
  final SqliteCacheService _cache = SqliteCacheService();
  final OfflineQueueService _queue = OfflineQueueService();
  final Connectivity _connectivity = Connectivity();

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
    await _cache.clearAll();
  }

  // ============================================
  // OFFLINE MODE & QUEUE SYNC
  // ============================================

  /// Vérifie si le réseau est disponible
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  /// Synchronise la queue d'attente quand le réseau revient
  Future<void> syncOfflineQueue() async {
    final online = await isOnline();
    if (!online) return;

    final pending = await _queue.getPending();
    if (pending.isEmpty) return;

    for (final op in pending) {
      try {
        await _retryQueuedOperation(op);
        await _queue.remove(op.id);
      } catch (e) {
        await _queue.incrementRetry(op.id);
        // Continue avec la prochaine opération, ne pas bloquer
      }
    }
  }

  /// Réessaye une opération de la queue
  Future<void> _retryQueuedOperation(QueuedOperation op) async {
    final url = Uri.parse('$baseUrl${op.endpoint}');

    late http.Response response;

    if (op.method == 'POST') {
      response = await http.post(
        url,
        headers: op.headers ?? _authHeaders,
        body: op.body,
      );
    } else if (op.method == 'DELETE') {
      response = await http.delete(
        url,
        headers: op.headers ?? _authHeaders,
      );
    } else {
      throw Exception('Unsupported method: ${op.method}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'La synchronisation a échoué pour ${op.method} ${op.endpoint}',
        statusCode: response.statusCode,
      );
    }
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

  /// En-têtes pour un envoi multipart (upload de fichier) : pas de
  /// Content-Type ici, http.MultipartRequest le fixe lui-même (avec la
  /// boundary), le forcer manuellement casserait l'envoi.
  Map<String, String> get _authHeadersMultipart => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  // ============================================
  // HELPER DE PARSING DÉFENSIF
  // ============================================

  Future<T> _readCachedOrRefresh<T>(
    String key,
    Future<T> Function() loader, {
    Duration ttl = const Duration(minutes: 10),
    bool forceRefresh = false,
  }) async {
    final cached = await _cache.getJson<T>(key);

    if (cached != null && !forceRefresh) {
      () async {
        try {
          final fresh = await loader();
          await _cache.setJson(key, fresh, ttl: ttl);
        } catch (_) {
          // on garde la donnée mise en cache en cas d'échec réseau ;
          // l'écran reste fluide pendant le rechargement en arrière-plan.
        }
      }();
      return cached;
    }

    final fresh = await loader();
    await _cache.setJson(key, fresh, ttl: ttl);
    return fresh;
  }

  /// Décode une réponse JSON qui doit représenter une liste, en gérant
  /// les deux formats possibles renvoyés par le backend :
  /// - un tableau JSON brut : [ {...}, {...} ]
  /// - un objet enveloppé : { "data": [ {...}, {...} ] }
  List<dynamic> _decodeList(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data;
    }
    return [];
  }

  // ============================================
  // WRAPPERS POUR LES MUTATIONS AVEC SUPPORT OFFLINE
  // ============================================

  /// Wrapper pour POST avec support offline automatique
  Future<dynamic> _post(
    String endpoint,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    final online = await isOnline();

    if (!online) {
      // Mode offline : enqueue l'opération
      await _queue.enqueue(
        'POST',
        endpoint,
        headers: headers ?? _authHeaders,
        body: body,
      );
      throw ApiException(
        'Vous êtes hors ligne. L\'opération sera envoyée une fois la connexion rétablie.',
        statusCode: 0,
      );
    }

    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: headers ?? _authHeaders,
      body: body is String ? body : jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Erreur lors de l\'envoi des données',
        statusCode: response.statusCode,
      );
    }

    return jsonDecode(response.body);
  }

  /// Wrapper pour DELETE avec support offline automatique
  Future<dynamic> _delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final online = await isOnline();

    if (!online) {
      await _queue.enqueue(
        'DELETE',
        endpoint,
        headers: headers ?? _authHeaders,
      );
      throw ApiException(
        'Vous êtes hors ligne. L\'opération sera envoyée une fois la connexion rétablie.',
        statusCode: 0,
      );
    }

    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(
      url,
      headers: headers ?? _authHeaders,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Erreur lors de la suppression',
        statusCode: response.statusCode,
      );
    }

    return jsonDecode(response.body);
  }

  // ============================================
  // AUTHENTIFICATION (passwordless : email + code)
  // ============================================

  Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
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

      final token = result is Map<String, dynamic> ? result['token'] : null;
      if (token == null || token is! String || token.isEmpty) {
        throw ApiException(
          data['message'] ?? 'Code invalide ou expiré',
          statusCode: response.statusCode,
          errors: data['errors'] as Map<String, dynamic>?,
        );
      }

      _token = token;
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

  Future<void> deleteAccount() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/delete-account'),
        headers: _authHeaders,
      );
    } catch (_) {}
    await clearToken();
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _readCachedOrRefresh<Map<String, dynamic>>(
      'profile',
      () async {
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
      },
      ttl: const Duration(minutes: 10),
    );
  }

  Future<Map<String, dynamic>> completeStagiaireProfile(
      Map<String, dynamic> data) async {
    final body = await _post('/stagiaire/profil', jsonEncode(data));
    return body;
  }

  Future<Map<String, dynamic>> completeEntrepriseProfile(
      Map<String, dynamic> data) async {
    final body = await _post('/entreprise/profil', jsonEncode(data));
    return body;
  }

  // ============================================
  // PHOTO DE PROFIL
  // ============================================
  // NOTE : suppose deux routes côté Laravel à créer si elles n'existent
  // pas encore :
  //   POST   /api/stagiaire/photo   (multipart, champ "photo")
  //          -> renvoie { "data": { "photo_profil": "https://.../xxx.jpg" } }
  //   DELETE /api/stagiaire/photo
  // À adapter aux noms réels de tes routes/contrôleur si différents.

  /// Envoie une nouvelle photo de profil et renvoie son URL publique.
  Future<String> updatePhotoProfil(File fichier) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/photo'),
      );
      request.headers.addAll(_authHeadersMultipart);
      request.files
          .add(await http.MultipartFile.fromPath('photo', fichier.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          body['message'] ?? 'Erreur lors de l\'envoi de la photo',
          statusCode: response.statusCode,
          errors: body['errors'] as Map<String, dynamic>?,
        );
      }

      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final url =
          data['photo_profil'] as String? ?? data['photo_url'] as String?;
      if (url == null || url.isEmpty) {
        throw ApiException(
            'Réponse inattendue du serveur après l\'envoi de la photo.');
      }

      // ✅ TRÈS IMPORTANT : Invalider le cache du profil pour forcer la mise à jour
      await _cache.delete('profile');

      return url;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError('/user/photo');
    }
  }

  /// Supprime la photo de profil actuelle.
  Future<void> supprimerPhotoProfil() async {
    try {
      await _delete('/user/photo');
      // ✅ Invalider le cache du profil
      await _cache.delete('profile');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError('/user/photo');
    }
  }

  // ============================================
  // RÉFÉRENTIEL
  // ============================================

  Future<List<dynamic>> getDomaines() async {
    return _readCachedOrRefresh<List<dynamic>>(
      'referentiel_domaines',
      () async {
        final response = await http.get(
          Uri.parse('$baseUrl/referentiel/domaines'),
          headers: _authHeaders,
        );
        return _decodeList(response);
      },
      ttl: const Duration(days: 30),
    );
  }

  Future<List<dynamic>> getMetiers({String? domaineId}) async {
    final cacheKey = domaineId == null
        ? 'referentiel_metiers_all'
        : 'referentiel_metiers_$domaineId';

    return _readCachedOrRefresh<List<dynamic>>(
      cacheKey,
      () async {
        final uri = Uri.parse('$baseUrl/referentiel/metiers').replace(
          queryParameters: domaineId != null ? {'domaineId': domaineId} : null,
        );

        final response = await http.get(uri, headers: _authHeaders);

        if (response.statusCode != 200) {
          throw ApiException(
            'Erreur de chargement des métiers',
            statusCode: response.statusCode,
          );
        }

        return _decodeList(response);
      },
      ttl: const Duration(days: 30),
    );
  }

  Future<List<dynamic>> getNiveauxFormation() async {
    return _readCachedOrRefresh<List<dynamic>>(
      'referentiel_niveaux_formation',
      () async {
        final response = await http.get(
          Uri.parse('$baseUrl/referentiel/niveaux-formation'),
          headers: _authHeaders,
        );
        return _decodeList(response);
      },
      ttl: const Duration(days: 30),
    );
  }

  Future<List<dynamic>> getCompetences() async {
    return _readCachedOrRefresh<List<dynamic>>(
      'referentiel_competences',
      () async {
        final response = await http.get(
          Uri.parse('$baseUrl/referentiel/competences'),
          headers: _authHeaders,
        );
        return _decodeList(response);
      },
      ttl: const Duration(days: 30),
    );
  }

  Future<List<dynamic>> getCriteresSavoirEtre() async {
    return _readCachedOrRefresh<List<dynamic>>(
      'referentiel_criteres_savoir_etre',
      () async {
        final response = await http.get(
          Uri.parse('$baseUrl/criteres-savoir-etre'),
          headers: _authHeaders,
        );
        return _decodeList(response);
      },
      ttl: const Duration(days: 30),
    );
  }

  // ============================================
  // CARNET DE STAGE & POINTAGE
  // ============================================

  Future<List<dynamic>> getCarnets() async {
    return _readCachedOrRefresh<List<dynamic>>(
      'carnets',
      () async {
        final response = await http.get(
          Uri.parse('$baseUrl/carnets'),
          headers: _authHeaders,
        );
        if (response.statusCode != 200) {
          final body = jsonDecode(response.body);
          throw ApiException(
            body['message'] ?? 'Erreur de chargement des carnets',
            statusCode: response.statusCode,
          );
        }
        return _decodeList(response);
      },
      ttl: const Duration(minutes: 10),
    );
  }

  Future<Map<String, dynamic>> getCarnetStats(String carnetId) async {
    final cacheKey = 'carnet_stats_$carnetId';
    final cached = await _cache.getJson<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/carnets/$carnetId/stats'),
      headers: _authHeaders,
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Erreur de chargement des statistiques',
        statusCode: response.statusCode,
      );
    }
    final data = body['data'] ?? {};
    await _cache.setJson(cacheKey, data, ttl: const Duration(minutes: 5));
    return data;
  }

  Future<Map<String, dynamic>> createCarnet(Map<String, dynamic> data) async {
    final body = await _post('/carnets', jsonEncode(data));
    await _cache.delete('carnets');
    return body;
  }

  /// Rattache un carnet existant à une entreprise/tuteur via un code
  /// d'invitation. [carnetId] est optionnel : à fournir lorsque
  /// l'utilisateur (stagiaire) possède plusieurs carnets et qu'il faut
  /// préciser lequel doit être rattaché.
  Future<Map<String, dynamic>> rattacherCarnet(
    String codeInvitation, {
    String? carnetId,
  }) async {
    final body = await _post(
        '/rattacher-carnet',
        jsonEncode({
          'code_invitation': codeInvitation,
          if (carnetId != null) 'carnet_id': carnetId,
        }));
    return body;
  }

  Future<Map<String, dynamic>> pointageArrivee(
      {double? latitude, double? longitude, String? carnetId}) async {
    final body = await _post(
        '/pointage/arrivee',
        jsonEncode({
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (carnetId != null) 'carnet_id': carnetId,
        }));
    if (carnetId != null) {
      await _cache.delete('carnet_stats_$carnetId');
      await _cache.delete('pointage_historique_$carnetId');
    }
    return body;
  }

  Future<Map<String, dynamic>> pointageDepart(
      {double? latitude, double? longitude, String? carnetId}) async {
    final body = await _post(
        '/pointage/depart',
        jsonEncode({
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (carnetId != null) 'carnet_id': carnetId,
        }));
    if (carnetId != null) {
      await _cache.delete('carnet_stats_$carnetId');
      await _cache.delete('pointage_historique_$carnetId');
    }
    return body;
  }

  Future<List<dynamic>> getHistoriquePointage(String carnetId) async {
    final cacheKey = 'pointage_historique_$carnetId';
    final cached = await _cache.getJson<List<dynamic>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/pointage/$carnetId/historique'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw ApiException('Erreur de chargement de l\'historique',
          statusCode: response.statusCode);
    }
    final decoded = _decodeList(response);
    await _cache.setJson(cacheKey, decoded, ttl: const Duration(minutes: 5));
    return decoded;
  }

  Future<List<dynamic>> getMesAttestations() async {
    return _readCachedOrRefresh<List<dynamic>>(
      'mes_attestations',
      () async {
        final response = await http.get(Uri.parse('$baseUrl/mes-attestations'),
            headers: _authHeaders);
        return _decodeList(response);
      },
      ttl: const Duration(minutes: 30),
    );
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  Future<List<dynamic>> getNotifications() async {
    return _readCachedOrRefresh<List<dynamic>>(
      'notifications',
      () async {
        final response = await http.get(Uri.parse('$baseUrl/notifications'),
            headers: _authHeaders);
        return _decodeList(response);
      },
      ttl: const Duration(minutes: 5),
    );
  }

  Future<void> markNotificationAsRead(String id) async {
    await _post('/notifications/$id/read', '{}');
    await _cache.delete('notifications');
    await _cache.delete('profile');
  }

  Future<void> markAllNotificationsAsRead() async {
    await _post('/notifications/read-all', '{}');
    await _cache.delete('notifications');
    await _cache.delete('profile');
  }

  /// Journal complet d'un carnet (missions + difficultés), sans limite,
  /// pour l'onglet "Journal" — distinct des stats qui n'en montrent
  /// que les 5 dernières activités mélangées.
  Future<List<dynamic>> getEntreesJournal(String carnetId) async {
    final cacheKey = 'journal_entrees_$carnetId';
    final cached = await _cache.getJson<List<dynamic>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/carnets/$carnetId/entrees'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw ApiException('Erreur de chargement du journal',
          statusCode: response.statusCode);
    }
    final decoded = _decodeList(response);
    await _cache.setJson(cacheKey, decoded, ttl: const Duration(minutes: 5));
    return decoded;
  }

  /// Historique complet des encouragements du tuteur pour un carnet,
  /// pour l'onglet "Encouragements".
  Future<List<dynamic>> getEncouragements(String carnetId) async {
    final cacheKey = 'encouragements_$carnetId';
    final cached = await _cache.getJson<List<dynamic>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/carnets/$carnetId/encouragements'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw ApiException('Erreur de chargement des encouragements',
          statusCode: response.statusCode);
    }
    final decoded = _decodeList(response);
    await _cache.setJson(cacheKey, decoded, ttl: const Duration(minutes: 5));
    return decoded;
  }

  Future<Map<String, dynamic>> createEntreeJournal(
      String carnetId, Map<String, dynamic> data) async {
    final body = await _post('/carnets/$carnetId/entrees', jsonEncode(data));
    await _cache.delete('journal_entrees_$carnetId');
    await _cache.delete('carnet_stats_$carnetId');
    return body;
  }

  /// URL directe du PDF d'une attestation (à ouvrir dans un navigateur/lecteur
  /// externe via url_launcher, par ex.).
  String urlTelechargementAttestation(String attestationId) {
    return '$baseUrl/attestations/$attestationId/telecharger';
  }

  Future<Map<String, dynamic>> createBilanReflexif(
      Map<String, dynamic> data) async {
    final body = await _post('/bilans-reflexifs', jsonEncode(data));
    if (data.containsKey('carnet_id')) {
      await _cache.delete('bilans_reflexifs_${data['carnet_id']}');
    }
    return body;
  }

  Future<List<dynamic>> getBilansReflexifs(String carnetId) async {
    final cacheKey = 'bilans_reflexifs_$carnetId';
    final cached = await _cache.getJson<List<dynamic>>(cacheKey);
    if (cached != null) return cached;

    final response = await http.get(
      Uri.parse('$baseUrl/bilans-reflexifs/carnets/$carnetId/bilans-reflexifs'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw ApiException('Erreur de chargement des bilans',
          statusCode: response.statusCode);
    }
    final decoded = _decodeList(response);
    await _cache.setJson(cacheKey, decoded, ttl: const Duration(minutes: 5));
    return decoded;
  }

  // ============================================
  // COVOITURAGE
  // ============================================

  Future<List<dynamic>> getTrajets() async {
    final response =
        await http.get(Uri.parse('$baseUrl/trajets'), headers: _authHeaders);
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> createTrajet(Map<String, dynamic> data) async {
    final body = await _post('/trajets', jsonEncode(data));
    return body;
  }

  Future<List<dynamic>> getMesTrajets() async {
    final response = await http.get(Uri.parse('$baseUrl/trajets/mes-trajets'),
        headers: _authHeaders);
    return _decodeList(response);
  }

  // Les identifiants du backend sont des UUID (String), pas des int.
  Future<Map<String, dynamic>> reserverTrajet(String trajetId,
      {int nombrePlaces = 1}) async {
    final body = await _post('/reservations/$trajetId/reserver',
        jsonEncode({'nombre_places': nombrePlaces}));
    return body;
  }

  Future<void> annulerReservation(String reservationId) async {
    await _post('/reservations/$reservationId/annuler', '{}');
  }

  Future<List<dynamic>> getMesReservations() async {
    final response = await http.get(
        Uri.parse('$baseUrl/reservations/mes-reservations'),
        headers: _authHeaders);
    return _decodeList(response);
  }

  Future<List<dynamic>> getTrajetMessages(String trajetId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trajets/$trajetId/messages'),
      headers: _authHeaders,
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> sendTrajetMessage(
      String trajetId, String message) async {
    return await _post(
        '/trajets/$trajetId/messages', jsonEncode({'contenu': message}));
  }

  Future<void> signalerTrajet(String trajetId, String motif) async {
    await _post('/trajets/$trajetId/signaler', jsonEncode({'motif': motif}));
  }

  // ============================================
  // ENTREPRISE / TUTEUR
  // ============================================

  Future<List<dynamic>> getEntrepriseStagiaires() async {
    return _readCachedOrRefresh<List<dynamic>>(
      'entreprise_stagiaires',
      () async {
        final response = await http.get(
          Uri.parse('$baseUrl/stagiaires'),
          headers: _authHeaders,
        );
        return _decodeList(response);
      },
      ttl: const Duration(minutes: 5),
    );
  }

  Future<Map<String, dynamic>> getEntrepriseDashboardStats() async {
    return _readCachedOrRefresh<Map<String, dynamic>>(
      'entreprise_dashboard_stats',
      () async {
        final response = await http.get(
          Uri.parse('$baseUrl/dashboard-stats'),
          headers: _authHeaders,
        );
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      },
      ttl: const Duration(minutes: 5),
    );
  }

  Future<Map<String, dynamic>> createFicheInvitation(
      Map<String, dynamic> data) async {
    return await _post('/fiches-invitation', jsonEncode(data));
  }

  Future<List<dynamic>> getFichesInvitation() async {
    final response = await http.get(Uri.parse('$baseUrl/fiches-invitation'),
        headers: _authHeaders);
    return _decodeList(response);
  }

  Future<List<dynamic>> getEvaluations(String carnetId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/carnets/$carnetId/evaluations'),
        headers: _authHeaders);
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> evaluerCompetence(
      Map<String, dynamic> data) async {
    return await _post('/evaluations', jsonEncode(data));
  }

  Future<Map<String, dynamic>> genererAttestation(String evaluationId) async {
    return await _post(
        '/documents/evaluations/$evaluationId/attestation', '{}');
  }

  Future<Map<String, dynamic>> genererCarteAppui(
      String evaluationId, Map<String, dynamic> data) async {
    return await _post(
        '/documents/evaluations/$evaluationId/carte-appui', jsonEncode(data));
  }

  Future<Map<String, dynamic>> evaluerSavoirEtre(
      Map<String, dynamic> data) async {
    return await _post('/evaluations-savoir-etre', jsonEncode(data));
  }

  Future<Map<String, dynamic>> envoyerEncouragement(
      String carnetId, String type, String contenu) async {
    final body = await _post(
      '/carnets/$carnetId/encourager',
      jsonEncode({'type': type, 'contenu': contenu}),
    );
    await _cache.delete('encouragements_$carnetId');
    await _cache.delete('carnet_stats_$carnetId');
    return body;
  }

  Future<void> commenterEntree(String entreeId, String commentaire) async {
    await _post(
      '/entrees-carnet/$entreeId/commentaire',
      jsonEncode({'commentaire_tuteur': commentaire}),
    );
    // Invalider le cache du journal car une entrée a été modifiée
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