import 'package:uuid/uuid.dart';

import '../../data/dto/dog_dto.dart';
import '../../data/hive_boxes.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../domain/repositories/dog_repository.dart';
import '../../models/dog.dart';
import '../../models/sync_task.dart';
import 'local_sync_queue_repository.dart';

class LocalDogRepository implements DogRepository {
  LocalDogRepository({SyncQueueRepository? syncQueueRepository})
      : _syncQueueRepository =
            syncQueueRepository ?? LocalSyncQueueRepository();

  final SyncQueueRepository _syncQueueRepository;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Dog>> getMyDogs() async {
    return dogsBox().values.toList();
  }

  @override
  Future<Dog?> getDog(String dogKey) async {
    for (final entry in dogsBox().toMap().entries) {
      if (entry.value.dogKey == dogKey) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<void> upsertDog(Dog dog) async {
    final box = dogsBox();
    for (final entry in box.toMap().entries) {
      if (entry.value.dogKey == dog.dogKey) {
        await box.put(entry.key, dog);
        await _enqueueSyncTask(dog);
        return;
      }
    }
    await box.add(dog);
    await _enqueueSyncTask(dog);
  }

  @override
  Future<void> deleteDog(String dogKey) async {
    final box = dogsBox();
    for (final entry in box.toMap().entries) {
      if (entry.value.dogKey == dogKey) {
        await box.delete(entry.key);
        return;
      }
    }
  }

  Future<void> _enqueueSyncTask(Dog dog) async {
    final task = SyncTask(
      taskId: _uuid.v4(),
      entityType: 'dog',
      entityId: dog.dogKey,
      payload: dogToJson(dog),
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );
    await _syncQueueRepository.addTask(task);
  }
}
