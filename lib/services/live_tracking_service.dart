import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'carpool_service.dart';

/// Service gérant l'envoi de la position GPS du conducteur en temps réel
/// vers le serveur Render toutes les 30 secondes.
class LiveTrackingService {
  LiveTrackingService._internal();
  static final LiveTrackingService _instance = LiveTrackingService._internal();
  factory LiveTrackingService() => _instance;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('active_trajet_tracking_id');
    if (savedId != null && _activeTrajetId == null) {
      await startTracking(savedId);
    }
  }

  Timer? _timer;
  String? _activeTrajetId;
  final CarpoolService _api = CarpoolService();

  String? get activeTrajetId => _activeTrajetId;

  /// Démarre le suivi GPS pour un trajet spécifique
  Future<void> startTracking(String trajetId) async {
    if (_timer != null) await stopTracking();

    _activeTrajetId = trajetId;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_trajet_tracking_id', trajetId);

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
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_trajet_tracking_id');
  }

  bool get isTracking => _timer != null;
}
