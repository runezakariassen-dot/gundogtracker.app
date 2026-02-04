import '../../domain/repositories/dog_repository.dart';
import '../../models/dog.dart';

class RemoteDogRepository implements DogRepository {
  @override
  Future<List<Dog>> getMyDogs() {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<Dog?> getDog(String dogKey) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<void> upsertDog(Dog dog) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<void> deleteDog(String dogKey) {
    throw UnimplementedError('Remote sync disabled');
  }
}
