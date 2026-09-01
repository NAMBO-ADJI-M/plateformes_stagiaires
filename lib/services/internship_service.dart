import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'base_api_service.dart';
import 'api_exception.dart';

class InternshipService extends BaseApiService {
  InternshipService._internal();
  static final InternshipService _instance = InternshipService._internal();
  factory InternshipService() => _instance;

  // ============================================
  // CARNET DE STAGE & POINTAGE
  // ============================================

  Future<List<dynamic>> getCarnets() async {
    return readCachedOrRefresh<List<dynamic>>(
      'carnets',
      () async {
        final response = await getRequest('/carnets');
        return decodeListResponse(response);
      },
      ttl: const Duration(minutes: 10),
    );
  }

  Future<Map<String, dynamic>> getCarnetStats(String carnetId) async {
    final cacheKey = 'carnet_stats_$carnetId';
    final cached = await cache.getJson<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final response = await getRequest('/carnets/$carnetId/stats');
    final data = response['data'] ?? {};
    await cache.setJson(cacheKey, data, ttl: const Duration(minutes: 5));
    return data;
  }

  Future<Map<String, dynamic>> createCarnet(Map<String, dynamic> data) async {
    final body = await postRequest('/carnets', data);
    await cache.delete('carnets');
    return body;
  }

  Future<Map<String, dynamic>> pointageArrivee({double? latitude, double? longitude, String? carnetId, String? autorisationId}) async {
    final body = await postRequest('/pointage/arrivee', {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (carnetId != null) 'carnet_id': carnetId,
      if (autorisationId != null) 'autorisation_pointage_id': autorisationId,
    });
    if (carnetId != null) {
      await cache.delete('carnet_stats_$carnetId');
      await cache.delete('pointage_historique_$carnetId');
    }
    if (autorisationId != null) {
      await cache.delete('pointage_historique_auth_$autorisationId');
    }
    return body;
  }

  Future<Map<String, dynamic>> pointageDepart({double? latitude, double? longitude, String? carnetId, String? autorisationId}) async {
    final body = await postRequest('/pointage/depart', {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (carnetId != null) 'carnet_id': carnetId,
      if (autorisationId != null) 'autorisation_pointage_id': autorisationId,
    });
    if (carnetId != null) {
      await cache.delete('carnet_stats_$carnetId');
      await cache.delete('pointage_historique_$carnetId');
    }
    if (autorisationId != null) {
      await cache.delete('pointage_historique_auth_$autorisationId');
    }
    return body;
  }

  Future<List<dynamic>> getHistoriquePointage(String? carnetId, {String? autorisationId}) async {
    if (carnetId == null && autorisationId == null) return [];
    
    final cacheKey = autorisationId != null 
        ? 'pointage_historique_auth_$autorisationId' 
        : 'pointage_historique_$carnetId';
        
    final cached = await cache.getJson<List<dynamic>>(cacheKey);
    if (cached != null) return cached;

    final endpoint = autorisationId != null
        ? '/pointage/historique/autorisation/$autorisationId'
        : '/pointage/historique/carnet/$carnetId';
        
    final response = await getRequest(endpoint);
    final decoded = decodeListResponse(response);
    await cache.setJson(cacheKey, decoded, ttl: const Duration(minutes: 5));
    return decoded;
  }

  // ============================================
  // ENTREPRISE / TUTEUR
  // ============================================

  Future<Map<String, dynamic>> getEntrepriseStagiaires() async {
    return readCachedOrRefresh<Map<String, dynamic>>(
      'entreprise_stagiaires_v2',
      () async {
        final response = await getRequest('/stagiaires');
        if (response is Map<String, dynamic>) return response;
        return {'rattaches': response, 'disponibles': []};
      },
      ttl: const Duration(minutes: 5),
    );
  }

  Future<Map<String, dynamic>> getEntrepriseDashboardStats() async {
    return readCachedOrRefresh<Map<String, dynamic>>(
      'entreprise_dashboard_stats_v2',
      () async {
        final response = await getRequest('/dashboard-stats');
        return (response['data'] as Map<String, dynamic>?) ?? {};
      },
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<dynamic>> getDemandesRattachement() async {
    return readCachedOrRefresh<List<dynamic>>(
      'entreprise_demandes_rattachement',
      () async {
        final response = await getRequest('/entreprise/demandes-rattachement');
        return decodeListResponse(response);
      },
      ttl: const Duration(minutes: 2),
    );
  }

  Future<Map<String, dynamic>> createFicheInvitation(Map<String, dynamic> data) async {
    return await postRequest('/fiches-invitation', data);
  }

  Future<List<dynamic>> getEvaluations(String carnetId) async {
    return readCachedOrRefresh<List<dynamic>>(
      'evaluations_$carnetId',
      () async {
        final response = await getRequest('/carnets/$carnetId/evaluations');
        return decodeListResponse(response);
      },
      ttl: const Duration(minutes: 10),
    );
  }

  Future<Map<String, dynamic>> evaluerCompetence(Map<String, dynamic> data) async {
    return await postRequest('/evaluations', data);
  }

  Future<Map<String, dynamic>> envoyerEncouragement(String carnetId, String type, String contenu) async {
    final body = await postRequest('/carnets/$carnetId/encourager', {'type': type, 'contenu': contenu});
    await cache.delete('encouragements_$carnetId');
    await cache.delete('carnet_stats_$carnetId');
    return body;
  }

  Future<List<dynamic>> getEncouragements(String carnetId) async {
    final cacheKey = 'encouragements_$carnetId';
    final cached = await cache.getJson<List<dynamic>>(cacheKey);
    if (cached != null) return cached;

    final response = await getRequest('/carnets/$carnetId/encouragements');
    final decoded = decodeListResponse(response);
    await cache.setJson(cacheKey, decoded, ttl: const Duration(minutes: 5));
    return decoded;
  }

  // ============================================
  // RÉFÉRENTIEL
  // ============================================

  Future<List<dynamic>> getDomaines() async {
    return readCachedOrRefresh<List<dynamic>>(
      'referentiel_domaines',
      () async => decodeListResponse(await getRequest('/referentiel/domaines')),
      ttl: const Duration(days: 30),
    );
  }

  Future<List<dynamic>> getNiveauxFormation() async {
    return readCachedOrRefresh<List<dynamic>>(
      'referentiel_niveaux_formation',
      () async => decodeListResponse(await getRequest('/referentiel/niveaux-formation')),
      ttl: const Duration(days: 30),
    );
  }

  Future<List<dynamic>> getMetiers({String? domaineId}) async {
    final cacheKey = domaineId == null ? 'referentiel_metiers_all' : 'referentiel_metiers_$domaineId';
    return readCachedOrRefresh<List<dynamic>>(
      cacheKey,
      () async {
        final endpoint = domaineId != null ? '/referentiel/metiers?domaineId=$domaineId' : '/referentiel/metiers';
        return decodeListResponse(await getRequest(endpoint));
      },
      ttl: const Duration(days: 30),
    );
  }

  Future<List<dynamic>> getMesAttestations() async {
    return readCachedOrRefresh<List<dynamic>>(
      'mes_attestations',
      () async => decodeListResponse(await getRequest('/mes-attestations')),
      ttl: const Duration(minutes: 30),
    );
  }

  Future<List<dynamic>> getEntreesJournal(String carnetId) async {
    final cacheKey = 'journal_entrees_$carnetId';
    final cached = await cache.getJson<List<dynamic>>(cacheKey);
    if (cached != null) return cached;

    final response = await getRequest('/carnets/$carnetId/entrees');
    final decoded = decodeListResponse(response);
    await cache.setJson(cacheKey, decoded, ttl: const Duration(minutes: 5));
    return decoded;
  }

  Future<Map<String, dynamic>> createEntreeJournal(String carnetId, Map<String, dynamic> data) async {
    final body = await postRequest('/carnets/$carnetId/entrees', data);
    await cache.delete('journal_entrees_$carnetId');
    await cache.delete('carnet_stats_$carnetId');
    return body;
  }

  String urlTelechargementAttestation(String attestationId) {
    return '${BaseApiService.baseUrl}/attestations/$attestationId/telecharger';
  }

  Future<Map<String, dynamic>> genererCarteAppui(String evaluationId, Map<String, dynamic> data) async {
    return await postRequest('/documents/evaluations/$evaluationId/carte-appui', data);
  }

  Future<Map<String, dynamic>> genererAttestation(String evaluationId) async {
    return await postRequest('/documents/evaluations/$evaluationId/attestation', {});
  }

  Future<List<dynamic>> rechercherEntreprises(String query) async {
    final response = await getRequest('/entreprises/recherche?q=$query');
    return decodeListResponse(response);
  }

  Future<Map<String, dynamic>> checkRattachementStatus() async {
    return readCachedOrRefresh<Map<String, dynamic>>(
      'rattachement_statut',
      () async => await getRequest('/rattachement/statut'),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<Map<String, dynamic>> demanderRattachement(String entrepriseId) async {
    final res = await postRequest('/rattachement/demander', {'entreprise_id': entrepriseId});
    await cache.delete('rattachement_statut');
    return res;
  }

  Future<Map<String, dynamic>> confirmerPause({String? carnetId, String? autorisationId}) async {
    final body = await postRequest('/pointage/confirmer-pause', {
      if (carnetId != null) 'carnet_id': carnetId,
      if (autorisationId != null) 'autorisation_pointage_id': autorisationId,
    });
    if (carnetId != null) {
      await cache.delete('carnet_stats_$carnetId');
      await cache.delete('pointage_historique_$carnetId');
    }
    if (autorisationId != null) {
      await cache.delete('pointage_historique_auth_$autorisationId');
    }
    return body;
  }

  Future<Map<String, dynamic>> confirmerDepart({String? carnetId, String? autorisationId}) async {
    final body = await postRequest('/pointage/confirmer-depart', {
      if (carnetId != null) 'carnet_id': carnetId,
      if (autorisationId != null) 'autorisation_pointage_id': autorisationId,
    });
    if (carnetId != null) {
      await cache.delete('carnet_stats_$carnetId');
      await cache.delete('pointage_historique_$carnetId');
    }
    if (autorisationId != null) {
      await cache.delete('pointage_historique_auth_$autorisationId');
    }
    return body;
  }

  String urlTelechargementConvention(String autorisationId) {
    return '${BaseApiService.baseUrl}/documents/liaison/$autorisationId/convention-pdf';
  }

  Future<List<dynamic>> getCompetences() async {
    return readCachedOrRefresh<List<dynamic>>(
      'referentiel_competences',
      () async => decodeListResponse(await getRequest('/referentiel/competences')),
      ttl: const Duration(days: 30),
    );
  }

  Future<Map<String, dynamic>> verifierCodeSuivi(String code, {String? carnetId}) async {
    return await postRequest('/pointage/verifier-code', {
      'code': code,
      if (carnetId != null) 'carnet_id': carnetId,
    });
  }

  Future<Map<String, dynamic>> sauvegarderBrouillonLiaison(Map<String, dynamic> data) async {
    return await postRequest('/pointage/brouillon-liaison', data);
  }

  Future<Map<String, dynamic>> validerLiaisonDefinitive(String code, Map<String, dynamic> data, {String? carnetId}) async {
    final body = await postRequest('/pointage/valider-liaison', {
      'code': code,
      if (carnetId != null) 'carnet_id': carnetId,
      ...data
    });
    await cache.delete('profile');
    await cache.delete('carnets');
    if (carnetId != null) {
      await cache.delete('carnet_stats_$carnetId');
    }
    return body;
  }

  Future<void> declinerLiaison(String code, String entrepriseId) async {
    await postRequest('/pointage/decliner-liaison', {
      'code': code,
      'entreprise_id': entrepriseId
    });
    await cache.delete('profile');
  }

  Future<List<dynamic>> getNotifications() async {
    return readCachedOrRefresh<List<dynamic>>(
      'notifications',
      () async => decodeListResponse(await getRequest('/notifications')),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<void> markNotificationAsRead(String id) async {
    await postRequest('/notifications/$id/read', {});
    await cache.delete('notifications');
    await cache.delete('profile');
  }

  Future<void> markAllNotificationsAsRead() async {
    await postRequest('/notifications/read-all', {});
    await cache.delete('notifications');
    await cache.delete('profile');
  }

  Future<Map<String, dynamic>> repondreDemandeSuivi(String autorisationId, bool accepter) async {
    final body = await postRequest('/pointage/repondre', {
      'autorisation_id': autorisationId,
      'accepter': accepter
    });
    await cache.delete('profile');
    await cache.delete('notifications');
    return body;
  }

  Future<Map<String, dynamic>> demanderSuiviPointage({
    required String stagiaireId,
    required String poste,
    required String dateDebut,
    required String dateFin,
    String? conditions,
    String? etablissementNom,
    required String tuteurDesigne,
    String? tuteurNom,
    String? tuteurPrenom,
    String? tuteurFonction,
    String? tuteurEmail,
    String? tuteurTelephone,
    
    String? raisonSociale,
    String? adresse,
    String? secteurActivite,
    String? entrepriseEmail,
    String? entrepriseTelephone,
    
    String? repLegalNom,
    String? repLegalFonction,
    String? repLegalContact,
    
    String? objetStage,
    String? objetStageAutre,
    String? cursusRattachement,
    String? anneeAcademique,
    
    String? lieuExecution,
    int? nombreMoisStage,
    String? dureeHebdomadaire,
    dynamic joursPresence,
    String? teletravailModalites,
    String? referentPedagogiqueNom,
    String? referentPedagogiqueContact,
    
    bool? gratificationPrevue,
    double? gratificationMontant,
    String? gratificationPeriodicite,
    String? congesAbsences,
    
    double? lieuExecutionLat,
    double? lieuExecutionLng,
  }) async {
    final body = await postRequest('/entreprise/demander-suivi', {
      'stagiaire_id': stagiaireId,
      'poste': poste,
      'date_debut': dateDebut,
      'date_fin': dateFin,
      'conditions_stage': conditions,
      'etablissement_nom': etablissementNom,
      'tuteur_designe': tuteurDesigne,
      'tuteur_nom': tuteurNom,
      'tuteur_prenom': tuteurPrenom,
      'tuteur_fonction': tuteurFonction,
      'tuteur_email': tuteurEmail,
      'tuteur_telephone': tuteurTelephone,
      
      'raison_sociale_custom': raisonSociale,
      'adresse_custom': adresse,
      'secteur_activite_custom': secteurActivite,
      'entreprise_email_document': entrepriseEmail,
      'entreprise_telephone_document': entrepriseTelephone,
      
      'representant_legal_nom': repLegalNom,
      'representant_legal_fonction': repLegalFonction,
      'representant_legal_contact': repLegalContact,
      
      'objet_stage': objetStage,
      'objet_stage_autre': objetStageAutre,
      'cursus_rattachement': cursusRattachement,
      'stagiaire_annee_academique': anneeAcademique,
      
      'lieu_execution': lieuExecution,
      'lieu_execution_lat': lieuExecutionLat,
      'lieu_execution_lng': lieuExecutionLng,
      'nombre_mois_stage': nombreMoisStage,
      'duree_hebdomadaire': dureeHebdomadaire,
      'jours_presence': joursPresence,
      'teletravail_modalites': teletravailModalites,
      'referent_pedagogique_nom': referentPedagogiqueNom,
      'referent_pedagogique_contact': referentPedagogiqueContact,
      
      'gratification_prevue': gratificationPrevue,
      'gratification_montant': gratificationMontant,
      'gratification_periodicite': gratificationPeriodicite,
      'conges_absences': congesAbsences,
    });
    await cache.delete('entreprise_stagiaires_v2');
    return body;
  }

  Future<File> telechargerEtSauvegarderConvention(String autorisationId) async {
    final url = Uri.parse('${BaseApiService.baseUrl}/documents/liaison/$autorisationId/convention-pdf');
    final httpClient = http.Client();
    final response = await httpClient.get(url, headers: authHeaders);

    if (response.statusCode != 200) {
      throw ApiException('Erreur téléchargement convention PDF', statusCode: response.statusCode);
    }

    final bytes = response.bodyBytes;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/convention_$autorisationId.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
