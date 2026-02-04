import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/dog_repository_with_outbox.dart';
import 'package:jakthund_app/data/local/outbox_service.dart';
import 'package:jakthund_app/domain/repositories/dog_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/outbox_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<OutboxEntry> outboxBox;
  bool _outboxAdapterRegistered = false;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_dog_outbox_');
    Hive.init(tempDir.path);
    if (!_outboxAdapterRegistered) {
      Hive.registerAdapter(OutboxEntryAdapter());
      _outboxAdapterRegistered = true;
    }
    outboxBox = await Hive.openBox<OutboxEntry>(syncOutboxBoxName);
    await outboxBox.clear();
  });

  tearDown(() async {
    await outboxBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('upsertDog enqueues outbox entry', () async {
    final repo = DogRepositoryWithOutbox(
      local: _InMemoryDogRepository(),
      outbox: OutboxService(box: outboxBox),
    );

    final dog = Dog(
      id: 'dog-1',
      name: 'Birk',
      dogKey: 'NO123-45',
      regNrDisplay: 'NO123/45',
      ownerUserId: 'owner',
      updatedAt: DateTime(2024, 1, 1),
    );

    await repo.upsertDog(dog);

    final entries = outboxBox.values.toList();
    expect(entries, hasLength(1));
    expect(entries.first.op, 'upsert');
    expect(entries.first.dogId, 'dog-1');
  });
}

class _InMemoryDogRepository implements DogRepository {
  Dog? _stored;

  @override
  Future<List<Dog>> getMyDogs() async {
    final dog = _stored;
    if (dog == null) return [];
    return [dog];
  }

  @override
  Future<Dog?> getDog(String dogKey) async {
    final dog = _stored;
    if (dog == null || dog.dogKey != dogKey) return null;
    return dog;
  }

  @override
  Future<void> upsertDog(Dog dog) async {
    _stored = dog;
  }

  @override
  Future<void> deleteDog(String dogKey) async {
    if (_stored?.dogKey == dogKey) {
      _stored = null;
    }
  }
}
