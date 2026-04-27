import 'package:flutter/foundation.dart';

import '../../data/hive_boxes.dart';
import '../../domain/repositories/dog_repository.dart';
import '../../models/dog.dart';
import 'sync_outbox_service.dart';

class LocalDogRepository implements DogRepository {
  LocalDogRepository({SyncOutboxService? syncOutboxService})
      : _syncOutboxService = syncOutboxService ?? SyncOutboxService();

  final SyncOutboxService _syncOutboxService;

  @override
  Future<List<Dog>> getMyDogs() async {
    return dogsBox()
        .values
        .where((dog) => !dog.isDeleted)
        .toList(growable: false);
  }

  @override
  Future<Dog?> getDog(String dogKey) async {
    for (final entry in dogsBox().toMap().entries) {
      if (entry.value.dogKey == dogKey) {
        if (entry.value.isDeleted) {
          return null;
        }
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<void> upsertDog(Dog dog) async {
    debugPrint('[LOCAL][DOG] upsertDog called for ${dog.name} (${dog.id})');
    final box = dogsBox();
    for (final entry in box.toMap().entries) {
      if (entry.value.id == dog.id) {
        await box.put(entry.key, dog);
        await _syncOutboxService.enqueueUpsertDog(dog);
        return;
      }
    }
    for (final entry in box.toMap().entries) {
      if (entry.value.dogKey == dog.dogKey) {
        await box.put(entry.key, dog);
        await _syncOutboxService.enqueueUpsertDog(dog);
        return;
      }
    }
    await box.add(dog);
    await _syncOutboxService.enqueueUpsertDog(dog);
  }

  @override
  Future<void> deleteDog(String dogKey) async {
    final box = dogsBox();
    for (final entry in box.toMap().entries) {
      if (entry.value.dogKey == dogKey) {
        if (entry.value.isDeleted) {
          return;
        }
        final deletedAt = DateTime.now().toUtc();
        final deletedDog = entry.value.copyWith(
          updatedAt: deletedAt,
          deletedAt: deletedAt,
        );
        await box.put(entry.key, deletedDog);
        debugPrint('[SYNC][DELETE] enqueue dog delete: ${deletedDog.id}');
        await _syncOutboxService.enqueueDeleteDog(
          deletedDog,
          deletedAt: deletedAt,
        );
        return;
      }
    }
  }
}
