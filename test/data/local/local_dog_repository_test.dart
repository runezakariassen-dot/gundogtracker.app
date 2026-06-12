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

  Future<void> restartRepositoryStorage() async {
    await dogBox.close();
    await outboxBox.close();
    dogBox = await Hive.openBox<Dog>(dogsBoxName);
    outboxBox = await Hive.openBox<SyncTask>(syncTasksBoxName);
  }

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

  test('male sex persists after restart and keeps profile metadata', () async {
    final repository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    final dog = Dog(
      id: 'dog-male',
      name: 'Birk',
      dogKey: 'DOG-MALE',
      regNrDisplay: 'NO100/01',
      imagePath: '/tmp/birk.jpg',
      pedigreeUrl: 'https://example.com/pedigree/birk',
      sex: DogSex.male,
      updatedAt: DateTime.utc(2024, 1, 1, 12),
    );

    await repository.upsertDog(dog);
    await restartRepositoryStorage();

    final reloadedRepository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    final restored = await reloadedRepository.getDog('DOG-MALE');

    expect(restored, isNotNull);
    expect(restored!.sex, DogSex.male);
    expect(restored.name, 'Birk');
    expect(restored.pedigreeUrl, 'https://example.com/pedigree/birk');
    expect(restored.imagePath, '/tmp/birk.jpg');
  });

  test('female sex persists after restart and keeps profile metadata',
      () async {
    final repository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    final dog = Dog(
      id: 'dog-female',
      name: 'Luna',
      dogKey: 'DOG-FEMALE',
      regNrDisplay: 'NO100/02',
      imagePath: '/tmp/luna.jpg',
      pedigreeUrl: 'https://example.com/pedigree/luna',
      sex: DogSex.female,
      updatedAt: DateTime.utc(2024, 1, 1, 12),
    );

    await repository.upsertDog(dog);
    await restartRepositoryStorage();

    final reloadedRepository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    final restored = await reloadedRepository.getDog('DOG-FEMALE');

    expect(restored, isNotNull);
    expect(restored!.sex, DogSex.female);
    expect(restored.name, 'Luna');
    expect(restored.pedigreeUrl, 'https://example.com/pedigree/luna');
    expect(restored.imagePath, '/tmp/luna.jpg');
  });

  test('editing sex is persisted across restart in both directions', () async {
    final repository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    final baseDog = Dog(
      id: 'dog-edit',
      name: 'Rapp',
      dogKey: 'DOG-EDIT',
      regNrDisplay: 'NO100/03',
      sex: DogSex.male,
      updatedAt: DateTime.utc(2024, 1, 1, 12),
    );
    await repository.upsertDog(baseDog);

    await repository.upsertDog(
      baseDog.copyWith(
        sex: DogSex.female,
        updatedAt: DateTime.utc(2024, 1, 2, 12),
      ),
    );
    await restartRepositoryStorage();

    var reloadedRepository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    var restored = await reloadedRepository.getDog('DOG-EDIT');
    expect(restored, isNotNull);
    expect(restored!.sex, DogSex.female);

    await reloadedRepository.upsertDog(
      restored.copyWith(
        sex: DogSex.male,
        updatedAt: DateTime.utc(2024, 1, 3, 12),
      ),
    );
    await restartRepositoryStorage();

    reloadedRepository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );
    restored = await reloadedRepository.getDog('DOG-EDIT');
    expect(restored, isNotNull);
    expect(restored!.sex, DogSex.male);
  });

  test('multiple dogs remain persisted after repository restart', () async {
    final repository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );

    await repository.upsertDog(
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'DOG-1',
        regNrDisplay: 'NO100/10',
        updatedAt: DateTime.utc(2024, 1, 1, 12),
      ),
    );
    await repository.upsertDog(
      Dog(
        id: 'dog-2',
        name: 'Luna',
        dogKey: 'DOG-2',
        regNrDisplay: 'NO100/11',
        updatedAt: DateTime.utc(2024, 1, 1, 12),
      ),
    );

    await restartRepositoryStorage();

    final reloadedRepository = LocalDogRepository(
      syncOutboxService: SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      ),
    );

    final dogs = await reloadedRepository.getMyDogs();
    expect(dogs.map((dog) => dog.id).toSet(), {'dog-1', 'dog-2'});
  });
}
