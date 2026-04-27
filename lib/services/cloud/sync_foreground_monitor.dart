import 'dart:async';

import 'auto_sync_coordinator.dart';
import 'network_awareness_service.dart';

class SyncForegroundMonitor {
  SyncForegroundMonitor({
    AutoSyncCoordinator? coordinator,
    NetworkAwarenessService? networkAwarenessService,
    this.pollInterval = const Duration(seconds: 20),
  })  : _coordinator = coordinator ?? AutoSyncCoordinator.instance,
        _networkAwarenessService =
            networkAwarenessService ?? NetworkAwarenessServiceImpl();

  final AutoSyncCoordinator _coordinator;
  final NetworkAwarenessService _networkAwarenessService;
  final Duration pollInterval;

  StreamSubscription<bool>? _subscription;
  bool? _lastOnline;

  bool get isStarted => _subscription != null;

  void start() {
    if (_subscription != null) {
      return;
    }

    _subscription = _networkAwarenessService
        .watchOnlineStatus(pollInterval: pollInterval)
        .listen((online) {
      final previous = _lastOnline;
      _lastOnline = online;

      if (online && previous == false) {
        unawaited(_coordinator.runOnNetworkOnline());
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
