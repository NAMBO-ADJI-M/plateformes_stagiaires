import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

/// Gère la synchronisation automatique de la queue offline
/// quand la connexion réseau revient
class OfflineSyncManager {
  OfflineSyncManager._internal();
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();
  factory OfflineSyncManager() => _instance;

  final Connectivity _connectivity = Connectivity();
  final ApiService _api = ApiService();

  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isOnline = false;

  /// Initialise le monitoring de la connexion
  Future<void> initialize() async {
    // Vérifier l'état initial
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Si on est en ligne, syncer immédiatement
    if (_isOnline) {
      await _api.syncOfflineQueue();
    }

    // Écouter les changements
    _subscription = _connectivity.onConnectivityChanged.listen(
      (result) async {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;

        // Transition hors-ligne → en ligne : syncer
        if (!wasOnline && _isOnline) {
          await _api.syncOfflineQueue();
        }
      },
    );
  }

  /// Arrête le monitoring
  void dispose() {
    _subscription?.cancel();
  }
}
