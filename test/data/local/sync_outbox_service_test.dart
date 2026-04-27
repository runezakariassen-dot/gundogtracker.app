import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type.dart';
import 'package:jakthund_app/models/sync_state.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/services/cloud/auto_sync_coordinator.dart';

void main() {
  late Directory tempDir;
  late Box<SyncTask> box;
  late Box<SyncState> syncState;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_sync_outbox_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(221)) {
      Hive.registerAdapter(SyncStateAdapter());
    }
    box = await Hive.openBox<SyncTask>('sync_outbox_test');
    syncState = await Hive.openBox<SyncState>(syncStateBoxName);
  });

  tearDown(() async {
    await box.close();
    await syncState.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('enqueueUpsertDog triggers auto sync after enqueue', () async {
    var runAfterEnqueueCount = 0;
    final coordinator = AutoSyncCoordinator(
      resetFailedTasks: () async {
        runAfterEnqueueCount++;
        return 0;
      },
      pullData: () async {},
      processOutbox: () async {},
    );
    final service = SyncOutboxService(
      box: box,
      autoSyncCoordinator: coordinator,
    );
    final dog = Dog(
      id: 'dog-1',
      name: 'Birk',
      dogKey: 'NO12345',
      regNrDisplay: 'NO123/45',
      cloudId: 'cloud-dog-1',
      cloudOwnerUid: 'owner-1',
    );

    await service.enqueueUpsertDog(dog);
    await Future<void>.delayed(Duration.zero);

    expect(runAfterEnqueueCount, 1);
    expect(box.values.length, 1);
    expect(box.values.single.entityType, 'dog_upsert');
    expect(box.values.single.payload['cloudId'], 'cloud-dog-1');
    expect(box.values.single.payload['cloudOwnerUid'], 'owner-1');
  });

  test('enqueueUpsertSession triggers auto sync after enqueue', () async {
    var runAfterEnqueueCount = 0;
    final coordinator = AutoSyncCoordinator(
      resetFailedTasks: () async {
        runAfterEnqueueCount++;
        return 0;
      },
      pullData: () async {},
      processOutbox: () async {},
    );
    final service = SyncOutboxService(
      box: box,
      autoSyncCoordinator: coordinator,
    );
    final session = HuntSession(
      dogId: 'dog-1',
      dateTime: DateTime(2024, 1, 1, 8, 0),
      location: 'Skog',
      durationMinutes: 30,
      birdsSeen: 1,
      points: 1,
      flushes: 0,
      notes: 'Test',
      sessionType: SessionType.training,
    );

    await service.enqueueUpsertSession('session-1', session);
    await Future<void>.delayed(Duration.zero);

    expect(runAfterEnqueueCount, 1);
    expect(box.values.length, 1);
    expect(box.values.single.entityType, 'session_upsert');
  });

  test('local session delete enqueues tombstone task', () async {
    final service = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final deletedAt = DateTime.utc(2026, 3, 22, 12, 0, 0);
    final session = HuntSession(
      dogId: 'dog-1',
      dateTime: DateTime(2024, 1, 1, 8, 0),
      location: 'Skog',
      durationMinutes: 30,
      birdsSeen: 1,
      points: 1,
      flushes: 0,
      notes: 'Delete me',
      sessionType: SessionType.training,
      updatedAt: deletedAt,
      deletedAt: deletedAt,
    );

    await service.enqueueDeleteSession(
      'session-1',
      session,
      deletedAt: deletedAt,
    );

    final task = box.values.single;
    expect(task.entityType, 'session_delete');
    expect(task.entityId, 'session-1');
    expect(task.payload['operation'], 'delete');
    expect(task.payload['deletedAt'], deletedAt.toIso8601String());
    expect(task.status, SyncStatus.pending);
  });

  test('local dog delete enqueues tombstone task', () async {
    final service = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final deletedAt = DateTime.utc(2026, 3, 22, 12, 0, 0);

    await service.enqueueDeleteDog(
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'NO12345',
        regNrDisplay: 'NO123/45',
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      ),
      deletedAt: deletedAt,
    );

    final task = box.values.single;
    expect(task.entityType, 'dog_delete');
    expect(task.entityId, 'dog-1');
    expect(task.payload['operation'], 'delete');
    expect(task.payload['deletedAt'], deletedAt.toIso8601String());
    expect(task.status, SyncStatus.pending);
  });

  test('cooldown prevents immediate retry', () async {
    final baseTime = DateTime(2026, 3, 22, 10, 0, 0);
    var now = baseTime;
    final service = SyncOutboxService(
      box: box,
      now: () => now,
      enableAutoSync: false,
    );

    await box.put(
      'task-1',
      SyncTask(
        taskId: 'task-1',
        entityType: 'session_upsert',
        entityId: 'session-1',
        payload: const {},
        status: SyncStatus.failed,
        createdAt: baseTime.subtract(const Duration(minutes: 1)),
        retryCount: 1,
        lastAttemptAt: baseTime,
        nextAttemptAt: baseTime.add(const Duration(seconds: 15)),
      ),
    );

    final resetCount = await service.resetFailedTasksForAutomaticRetry();

    expect(resetCount, 0);
    expect(box.get('task-1')!.status, SyncStatus.failed);
    expect(box.get('task-1')!.nextAttemptAt, isNotNull);
  });

  test('eligible task is picked after cooldown', () async {
    final baseTime = DateTime(2026, 3, 22, 10, 0, 0);
    var now = baseTime;
    final service = SyncOutboxService(
      box: box,
      now: () => now,
      enableAutoSync: false,
    );

    await box.put(
      'task-1',
      SyncTask(
        taskId: 'task-1',
        entityType: 'dog_upsert',
        entityId: 'dog-1',
        payload: const {},
        status: SyncStatus.failed,
        createdAt: baseTime.subtract(const Duration(minutes: 1)),
        retryCount: 1,
        lastAttemptAt: baseTime,
        nextAttemptAt: baseTime.add(const Duration(seconds: 15)),
      ),
    );

    expect(await service.resetFailedTasksForAutomaticRetry(), 0);

    now = baseTime.add(const Duration(seconds: 16));

    expect(await service.resetFailedTasksForAutomaticRetry(), 1);

    final pendingTasks = await service.fetchPendingTasks();
    expect(pendingTasks, hasLength(1));
    expect(pendingTasks.single.taskId, 'task-1');
  });

  test('max retries stops further automatic processing', () async {
    final baseTime = DateTime(2026, 3, 22, 10, 0, 0);
    var now = baseTime;
    final service = SyncOutboxService(
      box: box,
      now: () => now,
      enableAutoSync: false,
    );

    await box.put(
      'task-1',
      SyncTask(
        taskId: 'task-1',
        entityType: 'session_upsert',
        entityId: 'session-1',
        payload: const {},
        status: SyncStatus.inProgress,
        createdAt: baseTime.subtract(const Duration(minutes: 5)),
        retryCount: SyncOutboxService.maxRetryCount - 1,
        lastAttemptAt: baseTime.subtract(const Duration(minutes: 1)),
      ),
    );

    await service.markTaskFailed('task-1', StateError('boom'));

    final failedTask = box.get('task-1')!;
    expect(failedTask.status, SyncStatus.failed);
    expect(failedTask.retryCount, SyncOutboxService.maxRetryCount);
    expect(failedTask.nextAttemptAt, isNull);
    expect(service.isRetryEligible(failedTask, now: now), isFalse);
    expect(await service.resetFailedTasksForAutomaticRetry(), 0);
    expect(box.get('task-1')!.status, SyncStatus.failed);
  });

  test('manual retry reset makes failed tasks processable again', () async {
    final baseTime = DateTime(2026, 3, 22, 10, 0, 0);
    final service = SyncOutboxService(
      box: box,
      now: () => baseTime,
      enableAutoSync: false,
    );

    await box.put(
      'task-1',
      SyncTask(
        taskId: 'task-1',
        entityType: 'dog_upsert',
        entityId: 'dog-1',
        payload: const {},
        status: SyncStatus.failed,
        createdAt: baseTime.subtract(const Duration(minutes: 5)),
        retryCount: SyncOutboxService.maxRetryCount,
        lastAttemptAt: baseTime.subtract(const Duration(minutes: 1)),
        lastError: 'boom',
      ),
    );

    final resetCount = await service.resetFailedTasksForRetry();
    final resetTask = box.get('task-1')!;

    expect(resetCount, 1);
    expect(resetTask.status, SyncStatus.pending);
    expect(resetTask.retryCount, 0);
    expect(resetTask.nextAttemptAt, isNull);
    expect((await service.fetchPendingTasks()).single.taskId, 'task-1');
  });

  test('manual retry reset also restores failed session_delete tasks',
      () async {
    final baseTime = DateTime(2026, 3, 22, 10, 0, 0);
    final service = SyncOutboxService(
      box: box,
      now: () => baseTime,
      enableAutoSync: false,
    );

    await box.put(
      'task-delete-1',
      SyncTask(
        taskId: 'task-delete-1',
        entityType: 'session_delete',
        entityId: 'session-1',
        payload: const {'deletedAt': '2026-03-22T10:00:00.000Z'},
        status: SyncStatus.failed,
        createdAt: baseTime.subtract(const Duration(minutes: 5)),
        retryCount: SyncOutboxService.maxRetryCount,
        lastAttemptAt: baseTime.subtract(const Duration(minutes: 1)),
        lastError: 'boom',
      ),
    );

    final resetCount = await service.resetFailedTasksForRetry();

    expect(resetCount, 1);
    expect(box.get('task-delete-1')!.status, SyncStatus.pending);
    expect(box.get('task-delete-1')!.retryCount, 0);
  });

  test('manual retry reset also restores failed dog_delete tasks', () async {
    final baseTime = DateTime(2026, 3, 22, 10, 0, 0);
    final service = SyncOutboxService(
      box: box,
      now: () => baseTime,
      enableAutoSync: false,
    );

    await box.put(
      'task-delete-dog-1',
      SyncTask(
        taskId: 'task-delete-dog-1',
        entityType: 'dog_delete',
        entityId: 'dog-1',
        payload: const {'deletedAt': '2026-03-22T10:00:00.000Z'},
        status: SyncStatus.failed,
        createdAt: baseTime.subtract(const Duration(minutes: 5)),
        retryCount: SyncOutboxService.maxRetryCount,
        lastAttemptAt: baseTime.subtract(const Duration(minutes: 1)),
        lastError: 'boom',
      ),
    );

    final resetCount = await service.resetFailedTasksForRetry();

    expect(resetCount, 1);
    expect(box.get('task-delete-dog-1')!.status, SyncStatus.pending);
    expect(box.get('task-delete-dog-1')!.retryCount, 0);
  });

  test('successful transition pending -> in_progress -> sent', () async {
    final service = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final task = SyncTask(
      taskId: 'task-1',
      entityType: 'session_upsert',
      entityId: 'session-1',
      payload: const {},
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    await box.put(task.taskId, task);

    await service.markTaskInProgress(task.taskId);
    expect(box.get(task.taskId)!.status, SyncStatus.inProgress);
    expect(box.get(task.taskId)!.lastAttemptAt, isNotNull);
    expect(box.get(task.taskId)!.nextAttemptAt, isNull);

    await service.markTaskDone(task.taskId);
    expect(box.get(task.taskId)!.status, SyncStatus.sent);
  });

  test('taskCounts returns counts for all sync task states', () async {
    final service = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );

    await box.put(
      'pending-1',
      SyncTask(
        taskId: 'pending-1',
        entityType: 'session_upsert',
        entityId: 'session-1',
        payload: const {},
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await box.put(
      'pending-2',
      SyncTask(
        taskId: 'pending-2',
        entityType: 'dog_upsert',
        entityId: 'dog-1',
        payload: const {},
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await box.put(
      'in-progress-1',
      SyncTask(
        taskId: 'in-progress-1',
        entityType: 'session_upsert',
        entityId: 'session-2',
        payload: const {},
        status: SyncStatus.inProgress,
        createdAt: DateTime.now(),
      ),
    );
    await box.put(
      'failed-1',
      SyncTask(
        taskId: 'failed-1',
        entityType: 'dog_upsert',
        entityId: 'dog-2',
        payload: const {},
        status: SyncStatus.failed,
        createdAt: DateTime.now(),
        retryCount: SyncOutboxService.maxRetryCount,
      ),
    );
    await box.put(
      'sent-1',
      SyncTask(
        taskId: 'sent-1',
        entityType: 'session_upsert',
        entityId: 'session-3',
        payload: const {},
        status: SyncStatus.sent,
        createdAt: DateTime.now(),
      ),
    );

    final counts = service.taskCounts();

    expect(counts.pending, 2);
    expect(counts.inProgress, 1);
    expect(counts.failed, 1);
    expect(counts.sent, 1);
  });
}
