import '../../models/dog_membership.dart';

abstract class DogMembershipRepository {
  Future<DogMembership?> getMembership(String dogKey, String userId);
  Future<List<DogMembership>> getMembershipsForDog(String dogKey);
  Future<void> upsertMembership(DogMembership membership);
}
