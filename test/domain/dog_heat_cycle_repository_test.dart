import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/dogs/dog_heat_cycle_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_heat_cycle_log.dart';
import 'package:jakthund_app/models/dog_sex.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late Box<Dog> dogsBox;

  Future<void> restartStorage() async {
    await settingsBox.close();
    await dogsBox.close();
    settingsBox = await Hive.openBox<dynamic>(appSettingsBoxName);
    dogsBox = await Hive.openBox<Dog>(dogsBoxName);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dog_heat_cycle_repo_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DogAdapter());
    }
    if (!Hive.isAdapterRegistered(222)) {
      Hive.registerAdapter(DogSexAdapter());
    }

    settingsBox = await Hive.openBox<dynamic>(appSettingsBoxName);
    dogsBox = await Hive.openBox<Dog>(dogsBoxName);
  });

  tearDown(() async {
    await settingsBox.close();
    await dogsBox.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('heat cycle can be saved for female dog', () async {
    final repository = DogHeatCycleRepository(box: settingsBox);
    final dog = Dog(
      id: 'female-dog-1',
      name: 'Luna',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO100/11',
      sex: DogSex.female,
    );
    await dogsBox.put('dog-1', dog);

    final entry = DogHeatCycleLog(
      dogId: dog.id,
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 1, 25),
      note: 'Roligere på trening',
      createdAt: DateTime.utc(2026, 1, 10, 8),
      updatedAt: DateTime.utc(2026, 1, 10, 8),
    );

    await repository.saveForDog(entry);

    final stored = await repository.listForDog(dog.id);
    expect(stored, hasLength(1));
    expect(stored.first.startDate, DateTime(2026, 1, 10));
    expect(stored.first.endDate, DateTime(2026, 1, 25));
    expect(stored.first.note, 'Roligere på trening');
  });

  test('heat cycle is restored after repository reload/restart', () async {
    var repository = DogHeatCycleRepository(box: settingsBox);
    final entry = DogHeatCycleLog(
      dogId: 'female-dog-2',
      startDate: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 2, 17),
      note: 'Normal',
      createdAt: DateTime.utc(2026, 2, 1, 7),
      updatedAt: DateTime.utc(2026, 2, 1, 7),
    );
    await repository.saveForDog(entry);

    await restartStorage();

    repository = DogHeatCycleRepository(box: settingsBox);
    final restored = await repository.listForDog('female-dog-2');

    expect(restored, hasLength(1));
    expect(restored.first.startDate, DateTime(2026, 2, 1));
    expect(restored.first.endDate, DateTime(2026, 2, 17));
    expect(restored.first.note, 'Normal');
  });

  test('end date can be empty', () async {
    final repository = DogHeatCycleRepository(box: settingsBox);
    final entry = DogHeatCycleLog(
      dogId: 'female-dog-3',
      startDate: DateTime(2026, 3, 1),
      endDate: null,
      note: 'Pågår',
      createdAt: DateTime.utc(2026, 3, 1, 8),
      updatedAt: DateTime.utc(2026, 3, 1, 8),
    );

    await repository.saveForDog(entry);

    final stored = await repository.listForDog('female-dog-3');
    expect(stored, hasLength(1));
    expect(stored.first.endDate, isNull);
  });

  test('note can be empty', () async {
    final repository = DogHeatCycleRepository(box: settingsBox);
    final entry = DogHeatCycleLog(
      dogId: 'female-dog-4',
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 4, 16),
      note: null,
      createdAt: DateTime.utc(2026, 4, 1, 6),
      updatedAt: DateTime.utc(2026, 4, 1, 6),
    );

    await repository.saveForDog(entry);

    final stored = await repository.listForDog('female-dog-4');
    expect(stored, hasLength(1));
    expect(stored.first.note, isNull);
  });

  test('editing and deleting heat cycle entries are persisted', () async {
    final repository = DogHeatCycleRepository(box: settingsBox);
    final createdAt = DateTime.utc(2026, 5, 2, 9);
    final initial = DogHeatCycleLog(
      dogId: 'female-dog-5',
      startDate: DateTime(2026, 5, 2),
      endDate: null,
      note: null,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    await repository.saveForDog(initial);

    await repository.saveForDog(
      initial.copyWith(
        endDate: DateTime(2026, 5, 18),
        note: 'Ferdig',
        updatedAt: DateTime.utc(2026, 5, 18, 12),
      ),
    );

    var stored = await repository.listForDog('female-dog-5');
    expect(stored, hasLength(1));
    expect(stored.first.endDate, DateTime(2026, 5, 18));
    expect(stored.first.note, 'Ferdig');

    await repository.deleteForDog(
      dogId: 'female-dog-5',
      createdAt: createdAt,
    );

    stored = await repository.listForDog('female-dog-5');
    expect(stored, isEmpty);
  });

  test('existing dog fields are unaffected by heat cycle saves', () async {
    final repository = DogHeatCycleRepository(box: settingsBox);
    final dog = Dog(
      id: 'female-dog-6',
      name: 'Mira',
      dogKey: 'DOG-6',
      regNrDisplay: 'NO100/16',
      imagePath: '/tmp/mira.jpg',
      pedigreeUrl: 'https://example.com/mira',
      sex: DogSex.female,
    );
    await dogsBox.put('dog-6', dog);

    await repository.saveForDog(
      DogHeatCycleLog(
        dogId: dog.id,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 19),
        note: 'Test',
        createdAt: DateTime.utc(2026, 6, 1, 9),
        updatedAt: DateTime.utc(2026, 6, 1, 9),
      ),
    );

    final storedDog = dogsBox.get('dog-6');
    expect(storedDog, isNotNull);
    expect(storedDog!.name, 'Mira');
    expect(storedDog.pedigreeUrl, 'https://example.com/mira');
    expect(storedDog.imagePath, '/tmp/mira.jpg');
    expect(storedDog.sex, DogSex.female);
  });
}
