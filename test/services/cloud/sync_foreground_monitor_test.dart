import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/services/cloud/auto_sync_coordinator.dart';
import 'package:jakthund_app/services/cloud/network_awareness_service.dart';
import 'package:jakthund_app/services/cloud/sync_foreground_monitor.dart';

class FakeNetworkMonitorService implements NetworkAwarenessService {
  FakeNetworkMonitorService() : controller = StreamController<bool>.broadcast();

  final StreamController<bool> controller;

  @override
  Future<bool> shouldProcessOutbox() async => true;

  @override
  Stream<bool> watchOnlineStatus({
    Duration pollInterval = const Duration(seconds: 20),
  }) {
    return controller.stream;
  }

  Future<void> dispose() async {
    await controller.close();
  }
}

void main() {
  test('network restored trigger runs when offline becomes online', () async {
    final networkService = FakeNetworkMonitorService();
    var networkTriggerCount = 0;
    final coordinator = AutoSyncCoordinator(
      resetFailedTasks: () async {
        networkTriggerCount++;
        return 0;
      },
      pullData: () async {},
      processOutbox: () async {},
      cleanupData: () async {},
      networkAwarenessService: networkService,
    );
    final monitor = SyncForegroundMonitor(
      coordinator: coordinator,
      networkAwarenessService: networkService,
    );

    monitor.start();
    networkService.controller.add(false);
    await Future<void>.delayed(Duration.zero);
    networkService.controller.add(true);
    await Future<void>.delayed(Duration.zero);

    expect(networkTriggerCount, 1);

    await monitor.stop();
    await networkService.dispose();
  });

  test('initial online state does not trigger network recovery run', () async {
    final networkService = FakeNetworkMonitorService();
    var triggerCount = 0;
    final coordinator = AutoSyncCoordinator(
      resetFailedTasks: () async {
        triggerCount++;
        return 0;
      },
      pullData: () async {},
      processOutbox: () async {},
      cleanupData: () async {},
      networkAwarenessService: networkService,
    );
    final monitor = SyncForegroundMonitor(
      coordinator: coordinator,
      networkAwarenessService: networkService,
    );

    monitor.start();
    networkService.controller.add(true);
    await Future<void>.delayed(Duration.zero);

    expect(triggerCount, 0);

    await monitor.stop();
    await networkService.dispose();
  });
}
