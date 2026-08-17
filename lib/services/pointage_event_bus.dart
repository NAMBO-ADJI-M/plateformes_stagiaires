import 'dart:async';

/// Notifie l'app (ex: le dashboard) qu'un pointage vient d'être
/// enregistré automatiquement par le geofencing, pour rafraîchir
/// l'affichage sans action de l'utilisateur.
class PointageEventBus {
  PointageEventBus._internal();
  static final PointageEventBus _instance = PointageEventBus._internal();
  factory PointageEventBus() => _instance;

  final _controller = StreamController<void>.broadcast();

  Stream<void> get onPointageUpdate => _controller.stream;

  void notifyPointageUpdate() => _controller.add(null);
}