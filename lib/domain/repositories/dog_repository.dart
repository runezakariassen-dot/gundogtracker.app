import '../../models/dog.dart';

abstract class DogRepository {
  Future<List<Dog>> getMyDogs();
  Future<Dog?> getDog(String dogKey);
  Future<void> upsertDog(Dog dog);
  Future<void> deleteDog(String dogKey);
}
