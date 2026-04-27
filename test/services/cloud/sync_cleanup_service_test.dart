import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type.dart';
import 'package:jakthund_app/models/session_type_adapter.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/services/cloud/sync_cleanup_service.dart';

void main() {
  late Directory tempDir;
  late Box<SyncTask> outboxBox;
  late Box<Dog> dogBox;
  late Box<HuntSession> sessionBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_cleanup_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DogAdapter());
    }
    if (!Hive.isAdapterRegistered(222)) {
      Hive.registerAdapter(DogSexAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HuntSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }

    outboxBox = await Hive.openBox<SyncTask>('sync_cleanup_outbox');
    dogBox = await Hive.openBox<Dog>('sync_cleanup_dogs');
    sessionBox = await Hive.openBox<HuntSession>('sync_cleanup_sessions');
  });

  tearDown(() async {
    await outboxBox.close();
    await dogBox.close();
    await sessionBox.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('sent outbox task older than retention is deleted', () async {
    final now = DateTime.utc(2026, 3, 22, 12);
    final service = _service(
      now: () => now,
      outboxBox: outboxBox,
      dogBox: dogBox,
      sessionBox: sessionBox,
    );
    await outboxBox.put(
      'sent-old',
      _task(
        taskId: 'sent-old',
        entityType: 'dog_upsert',
        entityId: 'dog-1',
        status: SyncStatus.sent,
        createdAt: now.subtract(const Duration(days: 10)),
        lastAttemptAt: now.subtract(const Duration(days: 8)),
      ),
    );

    final result = await service.runCleanup();

    expect(result.removedTasks, 1);
    expect(outboxBox.containsKey('sent-old'), isFalse);
  });

  test('sent outbox task newer than retention is kept', () async {
    final now = DateTime.utc(2026, 3, 22, 12);
    final service = _service(
      now: () => now,
      outboxBox: outboxBox,
      dogBox: dogBox,
      sessionBox: sessionBox,
    );
    await outboxBox.put(
      'sent-new',
      _task(
        taskId: 'sent-new',
        entityType: 'dog_upsert',
        entityId: 'dog-1',
        status: SyncStatus.sent,
        createdAt: now.subtract(const Duration(days: 2)),
        lastAttemptAt: now.subtract(const Duration(days: 2)),
      ),
    );

    final result = await service.runCleanup();

    expect(result.removedTasks, 0);
    expect(outboxBox.containsKey('sent-new'), isTrue);
  });

  test('pending task is not deleted', () async {
    final now = DateTime.utc(2026, 3, 22, 12);
    final service = _service(
      now: () => now,
      outboxBox: outboxBox,
      dogBox: dogBox,
      sessionBox: sessionBox,
    );
    await outboxBox.put(
      'pending-1',
      _task(
        taskId: 'pending-1',
        entityType: 'dog_upsert',
        entityId: 'dog-1',
        status: SyncStatus.pending,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    );

    await service.runCleanup();

    expect(outboxBox.containsKey('pending-1'), isTrue);
  });

  test('inProgress task is not deleted', () async {
    final now = DateTime.utc(2026, 3, 22, 12);
    final service = _service(
      now: () => now,
      outboxBox: outboxBox,
      dogBox: dogBox,
      sessionBox: sessionBox,
    );
    await outboxBox.put(
      'in-progress-1',
      _task(
        taskId: 'in-progress-1',
        entityType: 'session_upsert',
        entityId: 'session-1',
        status: SyncStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    );

    await service.runCleanup();

    expect(outboxBox.containsKey('in-progress-1'), isTrue);
  });

  test('tombstone older than retention is removed when safe', () async {
    final now = DateTime.utc(2026, 3, 22, 12);
    final service = _service(
      now: () => now,
      outboxBox: outboxBox,
      dogBox: dogBox,
      sessionBox: sessionBox,
    );
    await dogBox.put(
      'dog-1',
      _dog(
        id: 'dog-1',
        deletedAt: now.subtract(const Duration(days: 35)),
      ),
    );

    final result = await service.runCleanup();

    expect(result.removedRecords, 1);
    expect(dogBox.containsKey('dog-1'), isFalse);
  });

  test('newer tombstone is kept', () async {
    final now = DateTime.utc(2026, 3, 22, 12);
    final service = _service(
      now: () => now,
      outboxBox: outboxBox,
      dogBox: dogBox,
      sessionBox: sessionBox,
    );
    await sessionBox.put(
      'session-1',
      _session(
        dogId: 'dog-1',
        deletedAt: now.subtract(const Duration(days: 10)),
      ),
    );

    final result = await service.runCleanup();

    expect(result.removedRecords, 0);
    expect(sessionBox.containsKey('session-1'), isTrue);
  });

  test('unsafe tombstone candidate is skipped', () async {
    final now = DateTime.utc(2026, 3, 22, 12);
    final service = _service(
      now: () => now,
      outboxBox: outboxBox,
      dogBox: dogBox,
      sessionBox: sessionBox,
    );
    await dogBox.put(
      'dog-1',
      _dog(
        id: 'dog-1',
        deletedAt: now.subtract(const Duration(days: 35)),
      ),
    );
    await outboxBox.put(
      'dog-delete-failed',
      _task(
        taskId: 'dog-delete-failed',
        entityType: 'dog_delete',
        entityId: 'dog-1',
        status: SyncStatus.failed,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    );

    final result = await service.runCleanup();

    expect(result.removedRecords, 0);
    expect(result.skippedCandidates, 1);
    expect(dogBox.containsKey('dog-1'), isTrue);
  });

  test('cleanup run does not overlap with itself', () async {
    final completer = Completer<void>();
    var startCount = 0;
    final service = _service(
      now: () => DateTime.utc(2026, 3, 22, 12),
      outboxBox: outboxBox,
      dogBox: dogBox,
      sessionBox: sessionBox,
      onStart: () async {
        startCount++;
        await completer.future;
      },
    );

    final firstRun = service.runCleanup();
    await Future<void>.delayed(Duration.zero);
    final secondRun = service.runCleanup();

    completer.complete();
    final results = await Future.wait([firstRun, secondRun]);

    expect(startCount, 1);
    expect(results.first.removedTasks, 0);
    expect(results[1].removedTasks, 0);
  });
}

SyncCleanupService _service({
  required DateTime Function() now,
  required Box<SyncTask> outboxBox,
  required Box<Dog> dogBox,
  required Box<HuntSession> sessionBox,
  Future<void> Function()? onStart,
}) {
  return SyncCleanupService(
    now: now,
    outboxBox: outboxBox,
    dogBox: dogBox,
    sessionBox: sessionBox,
    onStart: onStart,
  );
}

SyncTask _task({
  required String taskId,
  required String entityType,
  required String entityId,
  required SyncStatus status,
  required DateTime createdAt,
  DateTime? lastAttemptAt,
}) {
  return SyncTask(
    taskId: taskId,
    entityType: entityType,
    entityId: entityId,
    payload: const <String, dynamic>{},
    status: status,
    createdAt: createdAt,
    lastAttemptAt: lastAttemptAt,
  );
}

Dog _dog({
  required String id,
  DateTime? deletedAt,
}) {
  return Dog(
    id: id,
    name: 'Birk',
    dogKey: 'DOG-$id',
    regNrDisplay: 'NO123/45',
    updatedAt: deletedAt ?? DateTime.utc(2026, 1, 1),
    deletedAt: deletedAt,
    sex: DogSex.male,
  );
}

HuntSession _session({
  required String dogId,
  DateTime? deletedAt,
}) {
  return HuntSession(
    dogId: dogId,
    dogKey: 'DOG-$dogId',
    dateTime: DateTime.utc(2026, 1, 1, 10),
    location: 'Skog',
    durationMinutes: 30,
    birdsSeen: 1,
    points: 1,
    flushes: 0,
    notes: 'cleanup',
    sessionType: SessionType.training,
    updatedAt: deletedAt ?? DateTime.utc(2026, 1, 1),
    deletedAt: deletedAt,
  );
}
