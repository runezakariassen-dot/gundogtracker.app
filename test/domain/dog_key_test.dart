import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/repositories/dog_repository.dart';
import 'package:jakthund_app/domain/repositories/membership_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/services/dog_service.dart';
import 'package:jakthund_app/utils/reg_nr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_dogkey_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DogAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(RoleAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(StatusAdapter());
    }
    if (!Hive.isAdapterRegistered(222)) {
      Hive.registerAdapter(DogSexAdapter());
    }
    await Hive.openBox<dynamic>(appSettingsBoxName);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('createDog normalizes dogKey from regNrDisplay', () async {
    final service = DogService(
      dogRepository: _InMemoryDogRepository(),
      membershipRepository: _InMemoryMembershipRepository(),
    );

    final dog = await service.createDog(
      regNrInput: 'no123/45',
      name: 'Birk',
    );

    expect(dog.regNrDisplay, 'NO123/45');
    expect(dog.dogKey, 'NO123-45');
  });

  test('createDog rejects duplicate dogKey', () async {
    final repo = _InMemoryDogRepository();
    final service = DogService(
      dogRepository: repo,
      membershipRepository: _InMemoryMembershipRepository(),
    );

    await service.createDog(
      regNrInput: 'NO123/45',
      name: 'Birk',
    );

    await expectLater(
      service.createDog(
        regNrInput: 'no123-45',
        name: 'Luna',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('updateDog persists profile metadata without changing identity',
      () async {
    final repo = _InMemoryDogRepository();
    final service = DogService(
      dogRepository: repo,
      membershipRepository: _InMemoryMembershipRepository(),
    );

    final created = await service.createDog(
      regNrInput: 'NO124/45',
      name: 'Birk',
    );

    final updated = await service.updateDog(
      created.copyWith(
        imagePath: 'dogs/photos/dog-1.jpg',
        pedigreeUrl: 'https://example.com/pedigree',
        breed: 'Engelsk setter',
        sex: DogSex.female,
      ),
    );

    final stored = await repo.getDog(updated.dogKey);
    expect(stored, isNotNull);
    expect(updated.id, created.id);
    expect(updated.dogKey, created.dogKey);
    expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
    expect(stored!.imagePath, 'dogs/photos/dog-1.jpg');
    expect(stored.pedigreeUrl, 'https://example.com/pedigree');
    expect(stored.breed, 'Engelsk setter');
    expect(stored.sex, DogSex.female);
  });

  test('initDomainLayer backfills missing dogKey', () async {
    final dogs = await Hive.openBox<Dog>(dogsBoxName);
    await dogs.put(
      'dog-1',
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: '',
        regNrDisplay: 'NO123/45',
        updatedAt: DateTime(2024, 1, 1),
      ),
    );

    await _backfillDogKeys(dogs);

    final updated = dogs.get('dog-1');
    expect(updated, isNotNull);
    expect(updated!.dogKey, 'NO123-45');
  });
}

Future<void> _backfillDogKeys(Box<Dog> box) async {
  for (final entry in box.toMap().entries) {
    final dog = entry.value;
    final display = dog.regNrDisplay.trim();
    if (display.isEmpty) continue;
    final normalized = normalizeRegNr(display);
    if (normalized.isEmpty || dog.dogKey == normalized) continue;
    final updated = dog.copyWith(dogKey: normalized);
    await box.put(entry.key, updated);
  }
}

class _InMemoryDogRepository implements DogRepository {
  final Map<String, Dog> _storage = {};

  @override
  Future<void> deleteDog(String dogKey) async {
    _storage.remove(dogKey);
  }

  @override
  Future<List<Dog>> getMyDogs() async => _storage.values.toList();

  @override
  Future<Dog?> getDog(String dogKey) async => _storage[dogKey];

  @override
  Future<void> upsertDog(Dog dog) async {
    _storage[dog.dogKey] = dog;
  }
}

class _InMemoryMembershipRepository implements DogMembershipRepository {
  final Map<String, DogMembership> _storage = {};

  @override
  Future<DogMembership?> getMembership(String dogKey, String userId) async {
    return _storage['$dogKey::$userId'];
  }

  @override
  Future<List<DogMembership>> getMembershipsForDog(String dogKey) async {
    return _storage.values.where((m) => m.dogKey == dogKey).toList();
  }

  @override
  Future<void> upsertMembership(DogMembership membership) async {
    _storage['${membership.dogKey}::${membership.userId}'] = membership;
  }
}
