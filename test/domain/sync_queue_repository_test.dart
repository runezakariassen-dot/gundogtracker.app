import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/domain_di.dart';
import 'package:jakthund_app/models/sync_task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_syncrepo_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(SyncTaskAdapter().typeId)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(SyncStatusAdapter().typeId)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }

    await Hive.openBox<SyncTask>(syncTasksBoxName);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('enqueue then getPending returns task', () async {
    final repo = DomainDi.syncQueueRepository();

    final task = SyncTask(
      taskId: 'task-1',
      entityType: 'dog',
      entityId: 'NO123-45',
      payload: {'dogKey': 'NO123-45'},
      status: SyncStatus.pending,
      createdAt: DateTime(2024, 1, 1),
    );

    await repo.addTask(task);
    final pending = await repo.getPending();

    expect(pending, hasLength(1));
    expect(pending.first.taskId, task.taskId);
    expect(pending.first.status, SyncStatus.pending);
  });

  test('markSent updates status and removes from pending', () async {
    final repo = DomainDi.syncQueueRepository();

    final task = SyncTask(
      taskId: 'task-2',
      entityType: 'dog',
      entityId: 'NO124-45',
      payload: {'dogKey': 'NO124-45'},
      status: SyncStatus.pending,
      createdAt: DateTime(2024, 1, 1),
    );

    await repo.addTask(task);
    await repo.markSent(task.taskId);

    final pending = await repo.getPending();
    expect(pending, isEmpty);
  });

  test('clearAll empties queue', () async {
    final repo = DomainDi.syncQueueRepository();

    final task = SyncTask(
      taskId: 'task-3',
      entityType: 'dog',
      entityId: 'NO125-45',
      payload: {'dogKey': 'NO125-45'},
      status: SyncStatus.pending,
      createdAt: DateTime(2024, 1, 1),
    );

    await repo.addTask(task);
    await repo.clearAll();

    final pending = await repo.getPending();
    expect(pending, isEmpty);
  });
}
