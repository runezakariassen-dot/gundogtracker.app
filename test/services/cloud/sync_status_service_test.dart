import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/models/sync_task.dart' as outbox;
import 'package:jakthund_app/services/cloud/sync_status_service.dart';

void main() {
  late Directory tempDir;
  late Box<outbox.SyncTask> box;
  late SyncStatusService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_sync_status_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(outbox.SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(outbox.SyncTaskAdapter());
    }
    box = await Hive.openBox<outbox.SyncTask>('sync_status_test');
    service = SyncStatusService(
      outboxService: SyncOutboxService(
        box: box,
        enableAutoSync: false,
      ),
    );
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('maps outbox task statuses to UI sync status', () {
    expect(service.mapTaskStatus(null), SyncStatus.synced);
    expect(
      service.mapTaskStatus(outbox.SyncStatus.sent),
      SyncStatus.synced,
    );
    expect(
      service.mapTaskStatus(outbox.SyncStatus.pending),
      SyncStatus.pending,
    );
    expect(
      service.mapTaskStatus(outbox.SyncStatus.inProgress),
      SyncStatus.inProgress,
    );
    expect(
      service.mapTaskStatus(outbox.SyncStatus.failed),
      SyncStatus.failed,
    );
  });

  test('reads latest task for session_upsert entity', () async {
    final baseTime = DateTime(2026, 3, 22, 12, 0);
    await box.put(
      'older',
      outbox.SyncTask(
        taskId: 'older',
        entityType: 'session_upsert',
        entityId: 'session-1',
        payload: const {},
        status: outbox.SyncStatus.failed,
        createdAt: baseTime,
      ),
    );
    await box.put(
      'newer',
      outbox.SyncTask(
        taskId: 'newer',
        entityType: 'session_upsert',
        entityId: 'session-1',
        payload: const {},
        status: outbox.SyncStatus.inProgress,
        createdAt: baseTime.add(const Duration(minutes: 1)),
      ),
    );
    await box.put(
      'other',
      outbox.SyncTask(
        taskId: 'other',
        entityType: 'dog_upsert',
        entityId: 'dog-1',
        payload: const {},
        status: outbox.SyncStatus.failed,
        createdAt: baseTime.add(const Duration(minutes: 2)),
      ),
    );

    expect(
      service.statusForSession('session-1'),
      SyncStatus.inProgress,
    );
    expect(
      service.statusForSession('missing-session'),
      SyncStatus.synced,
    );
  });
}
