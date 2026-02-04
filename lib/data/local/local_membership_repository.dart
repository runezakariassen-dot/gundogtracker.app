import '../../data/hive_boxes.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../models/dog_membership.dart';

class LocalDogMembershipRepository implements DogMembershipRepository {
  @override
  Future<DogMembership?> getMembership(String dogKey, String userId) async {
    return dogMembershipsBox().get(_membershipKey(dogKey, userId));
  }

  @override
  Future<List<DogMembership>> getMembershipsForDog(String dogKey) async {
    return dogMembershipsBox().values.where((m) => m.dogKey == dogKey).toList();
  }

  @override
  Future<void> upsertMembership(DogMembership membership) async {
    await dogMembershipsBox()
        .put(_membershipKey(membership.dogKey, membership.userId), membership);
  }

  String _membershipKey(String dogKey, String userId) {
    return '$dogKey::$userId';
  }
}
