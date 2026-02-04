import 'package:uuid/uuid.dart';

import '../../data/dto/dog_dto.dart';
import '../../data/remote/sync_contracts.dart';
import '../../domain/repositories/dog_repository.dart';
import '../../models/dog.dart';
import 'outbox_service.dart';

class DogRepositoryWithOutbox implements DogRepository {
  DogRepositoryWithOutbox({
    required DogRepository local,
    required OutboxService outbox,
  })  : _local = local,
        _outbox = outbox;

  final DogRepository _local;
  final OutboxService _outbox;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Dog>> getMyDogs() {
    return _local.getMyDogs();
  }

  @override
  Future<Dog?> getDog(String dogKey) {
    return _local.getDog(dogKey);
  }

  @override
  Future<void> upsertDog(Dog dog) async {
    await _local.upsertDog(dog);
    final change = RemoteChange(
      table: 'dogs',
      op: 'upsert',
      clientOpId: _uuid.v4(),
      row: dogToJson(dog),
    );
    await _outbox.enqueue(dogId: dog.id, change: change);
  }

  @override
  Future<void> deleteDog(String dogKey) async {
    final existing = await _local.getDog(dogKey);
    await _local.deleteDog(dogKey);
    if (existing == null) {
      return;
    }
    final change = RemoteChange(
      table: 'dogs',
      op: 'delete',
      clientOpId: _uuid.v4(),
      pk: {'id': existing.id},
    );
    await _outbox.enqueue(dogId: existing.id, change: change);
  }
}
