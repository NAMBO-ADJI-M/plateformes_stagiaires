import 'dart:async';
import 'package:geofence_service/geofence_service.dart' as gs;
import 'api_service.dart';
import 'pointage_event_bus.dart';
import 'notification_service.dart';

class GeofencingService {
  GeofencingService._internal();
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;

  final ApiService _api = ApiService();
  late final gs.GeofenceService _service;
  String? _carnetId;
  bool _started = false;

  Future<void> start({
    required String carnetId,
    required double lat,
    required double lng,
    required int rayonMetres,
  }) async {
    if (_started) return;
    _carnetId = carnetId;

    _service = gs.GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 10000, // Réduit à 10 secondes pour plus de réactivité
      statusChangeDelayMs: 5000,
      useActivityRecognition: false,
      allowMockLocations: false,
      printDevLog: false, // Désactivé pour la production
    );

    // Ajout d'une notification pour que le service soit considéré comme prioritaire par Android
    _service.addLocationChangeListener((location) {
       // Utile pour le débug si besoin
    });

    final geofence = gs.Geofence(
      id: 'lieu_stage_$carnetId',
      latitude: lat,
      longitude: lng,
      radius: [
        gs.GeofenceRadius(id: 'r_$rayonMetres', length: rayonMetres.toDouble()),
      ],
    );

    _service.addGeofenceStatusChangeListener(_onStatusChanged);
    await _service.start([geofence]);
    _started = true;
  }

  Future<void> _onStatusChanged(
    gs.Geofence geofence,
    gs.GeofenceRadius radius,
    gs.GeofenceStatus status,
    gs.Location location,
  ) async {
    if (_carnetId == null) return;
    try {
      if (status == gs.GeofenceStatus.ENTER) {
        await _api.pointageArrivee(
          latitude: location.latitude,
          longitude: location.longitude,
          carnetId: _carnetId,
        );
        PointageEventBus().notifyPointageUpdate();

        // ✅ Notification de succès
        await NotificationService().showNotification(
          id: 1,
          title: '📍 Arrivée validée',
          body: 'Votre présence en stage a été enregistrée automatiquement.',
        );
      } else if (status == gs.GeofenceStatus.EXIT) {
        await _api.pointageDepart(
          latitude: location.latitude,
          longitude: location.longitude,
          carnetId: _carnetId,
        );
        PointageEventBus().notifyPointageUpdate();

        // ✅ Notification de succès
        await NotificationService().showNotification(
          id: 2,
          title: '👋 Départ validé',
          body: 'Votre fin de session a été enregistrée. Bonne fin de journée !',
        );
      }
    } catch (_) {
      // Erreur réseau ponctuelle : le prochain changement de statut retentera.
    }
  }

  Future<void> stop() async {
    if (!_started) return;
    await _service.stop();
    _started = false;
  }
}