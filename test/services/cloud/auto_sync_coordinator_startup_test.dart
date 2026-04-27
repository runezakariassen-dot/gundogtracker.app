import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/services/cloud/auto_sync_coordinator.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  late String tempDirPath;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('jakthund_autosync_');
    tempDirPath = tempDir.path;
    HivePathService.setOverridePathForTesting(tempDirPath);
    HiveLifecycleService.resetForTesting();
    await HivePathService.init();
    registerDomainAdapters();
    await HiveLifecycleService.init();
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    final tempDir = Directory(tempDirPath);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('runOnStartup resets and processes', () async {
    final events = <String>[];

    final coordinator = AutoSyncCoordinator(
      resetFailedTasks: () async {
        events.add('[SYNC][AUTO] retry reset count');
        return 0;
      },
      pullData: () async {},
      processOutbox: () async {
        events.add('[SYNC][PROCESSOR] start');
      },
      cleanupData: () async {
        events.add('[SYNC][CLEANUP] start');
      },
    );

    await coordinator.runOnStartup();

    expect(
      events,
      [
        '[SYNC][AUTO] retry reset count',
        '[SYNC][PROCESSOR] start',
        '[SYNC][CLEANUP] start',
      ],
    );
  });
}
