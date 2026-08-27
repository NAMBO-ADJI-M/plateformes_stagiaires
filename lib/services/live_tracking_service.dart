import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'carpool_service.dart';

/// Service gérant l'envoi de la position GPS du conducteur en temps réel
/// vers le serveur Render toutes les 30 secondes.
class LiveTrackingService {
  LiveTrackingService._internal();
  static final LiveTrackingService _instance = LiveTrackingService._internal();
  factory LiveTrackingService() => _instance;

  Timer? _timer;
  String? _activeTrajetId;
  final CarpoolService _api = CarpoolService();

  String? get activeTrajetId => _activeTrajetId;

  /// Démarre le suivi GPS pour un trajet spécifique
  Future<void> startTracking(String trajetId) async {
    if (_timer != null) await stopTracking();

    _activeTrajetId = trajetId;

    // Premier envoi immédiat
    _sendCurrentPosition();

    // Envoi toutes les 30 secondes
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendCurrentPosition();
    });
  }

  Future<void> _sendCurrentPosition() async {
    if (_activeTrajetId == null) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await _api.updateTrajetPosition(_activeTrajetId!, pos.latitude, pos.longitude);
    } catch (e) {
      // Erreur silencieuse (tunnel, réseau), on réessaiera au prochain tick
    }
  }

  /// Arrête le suivi GPS
  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _activeTrajetId = null;
  }

  bool get isTracking => _timer != null;
}
