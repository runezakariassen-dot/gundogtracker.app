import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/domain/dogs/dog_heat_cycle_repository.dart';
import 'package:jakthund_app/models/dog_heat_cycle_log.dart';
import 'package:jakthund_app/models/sync_task.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late Box<SyncTask> outboxBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dog_heat_cycle_sync_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }
    settingsBox = await Hive.openBox<dynamic>(appSettingsBoxName);
    outboxBox = await Hive.openBox<SyncTask>(syncTasksBoxName);
  });

  tearDown(() async {
    await settingsBox.close();
    await outboxBox.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('new heat cycle gets stable id and creator', () async {
    final repository = DogHeatCycleRepository(
      box: settingsBox,
      createdByUserIdProvider: () => 'user-a',
    );
    final createdAt = DateTime.utc(2026, 10, 1, 8);

    await repository.saveForDog(
      DogHeatCycleLog(
        dogId: 'dog-1',
        startDate: DateTime(2026, 10, 1),
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    final stored = await repository.listForDog('dog-1');
    expect(stored, hasLength(1));
    expect(stored.single.id, isNotNull);
    expect(stored.single.id!.trim().isNotEmpty, isTrue);
    expect(stored.single.createdByUserId, 'user-a');
  });

  test('legacy entry without id is preserved and migrated idempotently',
      () async {
    final legacy = <String, dynamic>{
      'dogId': 'dog-legacy',
      'startDate': '2026-01-10T00:00:00.000Z',
      'endDate': null,
      'note': 'Legacy',
      'createdAt': '2026-01-10T08:00:00.000Z',
      'updatedAt': '2026-01-10T08:00:00.000Z',
    };
    await settingsBox.put(
      DogHeatCycleRepository.storageKeyForDog('dog-legacy'),
      <Map<String, dynamic>>[legacy],
    );

    final repository = DogHeatCycleRepository(box: settingsBox);
    final firstRead = await repository.listForDog('dog-legacy');
    final migratedId = firstRead.single.id;

    expect(firstRead, hasLength(1));
    expect(firstRead.single.note, 'Legacy');
    expect(migratedId, isNotNull);

    final secondRead = await repository.listForDog('dog-legacy');
    expect(secondRead, hasLength(1));
    expect(secondRead.single.id, migratedId);

    final raw =
        settingsBox.get(DogHeatCycleRepository.storageKeyForDog('dog-legacy'))
            as List<dynamic>;
    expect(raw, hasLength(1));
    expect((raw.single as Map<dynamic, dynamic>)['id'], migratedId);
  });

  test('upsert keeps id and creator stable', () async {
    final repository = DogHeatCycleRepository(
      box: settingsBox,
      createdByUserIdProvider: () => 'creator-a',
    );
    final createdAt = DateTime.utc(2026, 2, 2, 8);

    await repository.saveForDog(
      DogHeatCycleLog(
        dogId: 'dog-2',
        startDate: DateTime(2026, 2, 2),
        note: 'First',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    final initial = (await repository.listForDog('dog-2')).single;

    await repository.saveForDog(
      initial.copyWith(
        note: 'Edited',
        createdByUserId: null,
        updatedAt: DateTime.utc(2026, 2, 3, 10),
      ),
    );

    final edited = (await repository.listForDog('dog-2')).single;
    expect(edited.id, initial.id);
    expect(edited.createdByUserId, 'creator-a');
    expect(edited.note, 'Edited');
  });

  test('delete creates tombstone and delete outbox task', () async {
    final outboxService = SyncOutboxService(
      box: outboxBox,
      enableAutoSync: false,
    );
    final repository = DogHeatCycleRepository(
      box: settingsBox,
      syncOutboxService: outboxService,
      now: () => DateTime.utc(2026, 3, 5, 12),
      createdByUserIdProvider: () => 'creator-b',
    );
    final createdAt = DateTime.utc(2026, 3, 1, 9);

    await repository.saveForDog(
      DogHeatCycleLog(
        dogId: 'dog-3',
        startDate: DateTime(2026, 3, 1),
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    final created = (await repository.listForDog('dog-3')).single;

    await repository.deleteForDog(
      dogId: 'dog-3',
      createdAt: createdAt,
    );

    final visible = await repository.listForDog('dog-3');
    final all = await repository.listForDog('dog-3', includeDeleted: true);

    expect(visible, isEmpty);
    expect(all, hasLength(1));
    expect(all.single.isDeleted, isTrue);
    expect(all.single.deletedAt, DateTime.utc(2026, 3, 5, 12));

    final deleteTask = outboxBox.values
        .where((task) => task.entityType == 'heat_cycle_delete')
        .toList();
    expect(deleteTask, hasLength(1));
    expect(deleteTask.single.entityId, created.id);
    expect(deleteTask.single.payload['dogId'], 'dog-3');
  });
}
