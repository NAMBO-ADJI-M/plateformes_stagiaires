import 'base_api_service.dart';

class CarpoolService extends BaseApiService {
  CarpoolService._internal();
  static final CarpoolService _instance = CarpoolService._internal();
  factory CarpoolService() => _instance;

  Future<List<dynamic>> getTrajets() async {
    return readCachedOrRefresh<List<dynamic>>(
      'trajets_list',
      () async => decodeListResponse(await getRequest('/trajets')),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<Map<String, dynamic>> createTrajet(Map<String, dynamic> data) async {
    final body = await postRequest('/trajets', data);
    await cache.delete('trajets_list');
    await cache.delete('mes_trajets');
    return body;
  }

  Future<List<dynamic>> getMesTrajets() async {
    return readCachedOrRefresh<List<dynamic>>(
      'mes_trajets',
      () async => decodeListResponse(await getRequest('/trajets/mes-trajets')),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<Map<String, dynamic>> reserverTrajet(String trajetId, {int nombrePlaces = 1}) async {
    final body = await postRequest('/reservations/$trajetId/reserver', {'nombre_places': nombrePlaces});
    await cache.delete('mes_reservations');
    return body;
  }

  Future<void> annulerReservation(String reservationId) async {
    await postRequest('/reservations/$reservationId/annuler', {});
    await cache.delete('mes_reservations');
  }

  Future<List<dynamic>> getMesReservations() async {
    return readCachedOrRefresh<List<dynamic>>(
      'mes_reservations',
      () async => decodeListResponse(await getRequest('/reservations/mes-reservations')),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<dynamic>> getConversations() async {
    return readCachedOrRefresh<List<dynamic>>(
      'conversations_list',
      () async => decodeListResponse(await getRequest('/messages')),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<dynamic>> getTrajetMessages(String trajetId) async {
    return readCachedOrRefresh<List<dynamic>>(
      'messages_$trajetId',
      () async => decodeListResponse(await getRequest('/trajets/$trajetId/messages')),
      ttl: const Duration(minutes: 2),
    );
  }

  Future<Map<String, dynamic>> sendTrajetMessage(String trajetId, String message) async {
    final body = await postRequest('/trajets/$trajetId/messages', {'contenu': message});
    await cache.delete('messages_$trajetId');
    return body;
  }

  Future<void> signalerTrajet(String trajetId, String motif) async {
    await postRequest('/trajets/$trajetId/signaler', {'motif': motif});
  }

  Future<void> updateTrajetPosition(String trajetId, double lat, double lng) async {
    await postRequest('/trajets/$trajetId/position', {
      'lat': lat,
      'lng': lng,
    });
  }
}
