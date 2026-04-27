import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/services/cloud/auto_sync_coordinator.dart';
import 'package:jakthund_app/services/cloud/network_awareness_service.dart';

class FakeNetworkAwarenessService implements NetworkAwarenessService {
  FakeNetworkAwarenessService({
    this.online = true,
    this.delay = Duration.zero,
    Stream<bool>? statusStream,
  }) : _statusStream = statusStream ?? const Stream<bool>.empty();

  final bool online;
  final Duration delay;
  final Stream<bool> _statusStream;

  @override
  Future<bool> shouldProcessOutbox() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return online;
  }

  @override
  Stream<bool> watchOnlineStatus({
    Duration pollInterval = const Duration(seconds: 20),
  }) {
    return _statusStream;
  }
}

void main() {
  test('lifecycle resume triggers processor once', () async {
    final calls = <String>[];
    final coordinator = AutoSyncCoordinator(
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      resetFailedTasks: () async {
        calls.add('reset');
        return 0;
      },
      pullData: () async {
        calls.add('pull');
      },
      processOutbox: () async {
        calls.add('process');
      },
      cleanupData: () async {
        calls.add('cleanup');
      },
    );

    await coordinator.runOnResumed();

    expect(calls, ['reset', 'pull', 'process', 'cleanup']);
  });

  test('repeated resume events do not overlap runs', () async {
    final completer = Completer<void>();
    var processCount = 0;
    var maxConcurrentRuns = 0;
    var activeRuns = 0;
    final coordinator = AutoSyncCoordinator(
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      resetFailedTasks: () async => 0,
      pullData: () async {},
      processOutbox: () async {
        processCount++;
        activeRuns++;
        if (activeRuns > maxConcurrentRuns) {
          maxConcurrentRuns = activeRuns;
        }
        await completer.future;
        activeRuns--;
      },
      cleanupData: () async {},
    );

    final firstRun = coordinator.runOnResumed();
    await Future<void>.delayed(Duration.zero);
    final secondRun = coordinator.runOnResumed();

    completer.complete();
    await Future.wait([firstRun, secondRun]);

    expect(processCount, 1);
    expect(maxConcurrentRuns, 1);
  });

  test('network online trigger runs processor once', () async {
    final calls = <String>[];
    final coordinator = AutoSyncCoordinator(
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      resetFailedTasks: () async {
        calls.add('reset');
        return 1;
      },
      pullData: () async {
        calls.add('pull');
      },
      processOutbox: () async {
        calls.add('process');
      },
      cleanupData: () async {
        calls.add('cleanup');
      },
    );

    await coordinator.runOnNetworkOnline();

    expect(calls, ['reset', 'pull', 'process', 'cleanup']);
  });

  test('resume trigger picks up retry-eligible failed work automatically',
      () async {
    var resetCount = 0;
    var processCount = 0;
    final coordinator = AutoSyncCoordinator(
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      resetFailedTasks: () async {
        resetCount++;
        return 1;
      },
      pullData: () async {},
      processOutbox: () async {
        processCount++;
      },
      cleanupData: () async {},
    );

    await coordinator.runOnResumed();

    expect(resetCount, 1);
    expect(processCount, 1);
  });

  test('offline resume skips processing', () async {
    var resetCount = 0;
    var processCount = 0;
    final coordinator = AutoSyncCoordinator(
      networkAwarenessService: FakeNetworkAwarenessService(online: false),
      resetFailedTasks: () async {
        resetCount++;
        return 0;
      },
      pullData: () async {},
      processOutbox: () async {
        processCount++;
      },
      cleanupData: () async {},
    );

    await coordinator.runOnResumed();

    expect(resetCount, 0);
    expect(processCount, 0);
  });

  test('in-progress guard prevents duplicate runs', () async {
    final completer = Completer<void>();
    var processCount = 0;
    final coordinator = AutoSyncCoordinator(
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      resetFailedTasks: () async => 0,
      pullData: () async {},
      processOutbox: () async {
        processCount++;
        await completer.future;
      },
      cleanupData: () async {},
    );

    final firstRun = coordinator.runOnResumed();
    await Future<void>.delayed(Duration.zero);
    await coordinator.runOnResumed();

    completer.complete();
    await firstRun;

    expect(processCount, 1);
  });

  test('enqueue overlap still queues one rerun without parallel processing',
      () async {
    final completer = Completer<void>();
    var activeRuns = 0;
    var maxConcurrentRuns = 0;
    var resetCount = 0;
    var processCount = 0;
    final coordinator = AutoSyncCoordinator(
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      resetFailedTasks: () async {
        resetCount++;
        return 0;
      },
      pullData: () async {},
      processOutbox: () async {
        processCount++;
        activeRuns++;
        if (activeRuns > maxConcurrentRuns) {
          maxConcurrentRuns = activeRuns;
        }
        if (processCount == 1) {
          await completer.future;
        }
        activeRuns--;
      },
      cleanupData: () async {},
    );

    final firstRun = coordinator.runAfterEnqueue();
    await Future<void>.delayed(Duration.zero);

    final secondRun = coordinator.runAfterEnqueue();

    completer.complete();
    await Future.wait([firstRun, secondRun]);

    expect(resetCount, 2);
    expect(processCount, 2);
    expect(maxConcurrentRuns, 1);
  });
}
