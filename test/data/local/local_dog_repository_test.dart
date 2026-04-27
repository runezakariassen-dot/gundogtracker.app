import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/local_dog_repository.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/models/sync_task.dart';

void main() {
  late Directory tempDir;
  late Box<Dog> dogBox;
  late Box<SyncTask> outboxBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('local_dog_repo_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DogAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(222)) {
      Hive.registerAdapter(DogSexAdapter());
    }

    dogBox = await Hive.openBox<Dog>(dogsBoxName);
    outboxBox = await Hive.openBox<SyncTask>(syncTasksBoxName);
  });

  tearDown(() async {
    await dogBox.close();
    await outboxBox.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('deleteDog marks local dog deleted and enqueues dog_delete task',
      () async {
    final repository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    final dog = Dog(
      id: 'dog-1',
      name: 'Birk',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO123/45',
      updatedAt: DateTime.utc(2024, 1, 1, 12),
    );
    await dogBox.add(dog);

    await repository.deleteDog('DOG-1');

    final storedDog = dogBox.values.single;
    final task = outboxBox.values.single;

    expect(storedDog.deletedAt, isNotNull);
    expect(task.entityType, 'dog_delete');
    expect(task.entityId, 'dog-1');
    expect(task.payload['deletedAt'], isNotNull);
  });

  test('upsertDog updates an existing dog by id before dogKey lookup',
      () async {
    final repository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    final original = Dog(
      id: 'dog-1',
      name: 'Birk',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO123/45',
      updatedAt: DateTime.utc(2024, 1, 1, 12),
    );
    await dogBox.add(original);

    await repository.upsertDog(
      original.copyWith(
        dogKey: 'DOG-2',
        regNrDisplay: 'NO123/46',
        updatedAt: DateTime.utc(2024, 1, 2, 12),
      ),
    );

    expect(dogBox.values, hasLength(1));
    final storedDog = dogBox.values.single;
    expect(storedDog.id, 'dog-1');
    expect(storedDog.dogKey, 'DOG-2');
    expect(storedDog.regNrDisplay, 'NO123/46');
    expect(outboxBox.values, hasLength(1));
    expect(outboxBox.values.single.entityId, 'dog-1');
  });
}
