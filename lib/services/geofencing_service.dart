import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geofence_service/geofence_service.dart' as gs;
import 'package:shared_preferences/shared_preferences.dart';
import 'internship_service.dart';
import 'pointage_event_bus.dart';
import 'notification_service.dart';

class GeofencingService {
  GeofencingService._internal();
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;

  final InternshipService _api = InternshipService();
  late final gs.GeofenceService _service;
  String? _autorisationId;
  String? _carnetId;
  bool _started = false;

  bool get isStarted => _started;

  static const String _keyEnabled = 'geofencing_enabled';
  static const String _keyLat = 'geofencing_lat';
  static const String _keyLng = 'geofencing_lng';
  static const String _keyAuthId = 'geofencing_auth_id';
  static const String _keyCarnetId = 'geofencing_carnet_id';
  static const String _keyRayon = 'geofencing_rayon';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool(_keyEnabled) ?? false;

    if (isEnabled) {
      final double? lat = prefs.getDouble(_keyLat);
      final double? lng = prefs.getDouble(_keyLng);
      final String? authId = prefs.getString(_keyAuthId);
      final String? carnetId = prefs.getString(_keyCarnetId);
      final int? rayon = prefs.getInt(_keyRayon);

      if (lat != null && lng != null && authId != null) {
        await start(
          autorisationId: authId,
          carnetId: carnetId,
          lat: lat,
          lng: lng,
          rayonMetres: rayon ?? 100,
          saveToPrefs: false,
        );
      }
    }
  }

  Future<void> start({
    String? carnetId,
    required String autorisationId,
    required double lat,
    required double lng,
    required int rayonMetres,
    bool saveToPrefs = true,
  }) async {
    if (_started) return;
    _autorisationId = autorisationId;
    _carnetId = carnetId;

    _service = gs.GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 10000, // Réduit à 10 secondes pour plus de réactivité
      statusChangeDelayMs: 5000,
      useActivityRecognition: false,
      allowMockLocations: false,
      printDevLog: false,
    );

    // Ajout d'une notification pour que le service soit considéré comme prioritaire par Android
    _service.addLocationChangeListener((location) {
       // Utile pour le débug si besoin
    });

    final geofence = gs.Geofence(
      id: 'lieu_stage_$autorisationId',
      latitude: lat,
      longitude: lng,
      radius: [
        gs.GeofenceRadius(id: 'r_$rayonMetres', length: rayonMetres.toDouble()),
      ],
    );

    _service.addGeofenceStatusChangeListener(_onStatusChanged);
    await _service.start([geofence]);
    _started = true;

    // ✅ Vérification manuelle de la position initiale
    _checkInitialPosition(lat, lng, rayonMetres);

    if (saveToPrefs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnabled, true);
      await prefs.setDouble(_keyLat, lat);
      await prefs.setDouble(_keyLng, lng);
      await prefs.setString(_keyAuthId, autorisationId);
      if (carnetId != null) {
        await prefs.setString(_keyCarnetId, carnetId);
      } else {
        await prefs.remove(_keyCarnetId);
      }
      await prefs.setInt(_keyRayon, rayonMetres);
    }
  }

  Future<void> _onStatusChanged(
    gs.Geofence geofence,
    gs.GeofenceRadius radius,
    gs.GeofenceStatus status,
    gs.Location location,
  ) async {
    if (_autorisationId == null) return;
    try {
      if (status == gs.GeofenceStatus.ENTER) {
        await _api.pointageArrivee(
          latitude: location.latitude,
          longitude: location.longitude,
          carnetId: _carnetId,
          autorisationId: _autorisationId,
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
          autorisationId: _autorisationId,
        );
        PointageEventBus().notifyPointageUpdate();
        
        // La sortie est désormais silencieuse, le cron ou le retour tranchera.
      }
    } catch (_) {
      // Erreur réseau ponctuelle : le prochain changement de statut retentera.
    }
  }

  Future<void> _checkInitialPosition(double targetLat, double targetLng, int rayon) async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, targetLat, targetLng);
      
      if (distance <= rayon) {
        // On est déjà dans la zone au démarrage
        await _api.pointageArrivee(
          latitude: pos.latitude,
          longitude: pos.longitude,
          carnetId: _carnetId,
          autorisationId: _autorisationId,
        );
        PointageEventBus().notifyPointageUpdate();
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    if (!_started) return;
    await _service.stop();
    _started = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
  }
}