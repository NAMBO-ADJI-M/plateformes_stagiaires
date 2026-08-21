import 'dart:async';

class StagiaireEventBus {
  StagiaireEventBus._internal();
  static final StagiaireEventBus _instance = StagiaireEventBus._internal();
  factory StagiaireEventBus() => _instance;

  final _availableCountController = StreamController<int>.broadcast();
  Stream<int> get onAvailableCountChanged => _availableCountController.stream;

  void updateAvailableCount(int count) {
    _availableCountController.add(count);
  }
}
