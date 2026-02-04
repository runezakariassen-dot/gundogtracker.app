import '../../domain/repositories/membership_repository.dart';
import '../../models/dog_membership.dart';

class RemoteDogMembershipRepository implements DogMembershipRepository {
  @override
  Future<DogMembership?> getMembership(String dogKey, String userId) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<List<DogMembership>> getMembershipsForDog(String dogKey) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<void> upsertMembership(DogMembership membership) {
    throw UnimplementedError('Remote sync disabled');
  }
}
