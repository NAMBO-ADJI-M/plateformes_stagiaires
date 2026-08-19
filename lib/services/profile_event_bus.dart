import 'dart:async';

/// Notifie l'app que le profil utilisateur (avatar, nom, établissement)
/// a été mis à jour, afin que tous les écrans affichant ces infos
/// (Dashboard, Profil, etc.) se rafraîchissent automatiquement.
class ProfileEventBus {
  ProfileEventBus._internal();
  static final ProfileEventBus _instance = ProfileEventBus._internal();
  factory ProfileEventBus() => _instance;

  final _controller = StreamController<void>.broadcast();

  Stream<void> get onProfileUpdate => _controller.stream;

  void notifyProfileUpdate() => _controller.add(null);
}
