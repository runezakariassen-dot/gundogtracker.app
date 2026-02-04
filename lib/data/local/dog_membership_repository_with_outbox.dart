import 'package:uuid/uuid.dart';

import '../../data/dto/membership_dto.dart';
import '../../data/remote/sync_contracts.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../models/dog_membership.dart';
import 'outbox_service.dart';

class DogMembershipRepositoryWithOutbox implements DogMembershipRepository {
  DogMembershipRepositoryWithOutbox({
    required DogMembershipRepository local,
    required OutboxService outbox,
  })  : _local = local,
        _outbox = outbox;

  final DogMembershipRepository _local;
  final OutboxService _outbox;
  final Uuid _uuid = const Uuid();

  @override
  Future<DogMembership?> getMembership(String dogKey, String userId) {
    return _local.getMembership(dogKey, userId);
  }

  @override
  Future<List<DogMembership>> getMembershipsForDog(String dogKey) {
    return _local.getMembershipsForDog(dogKey);
  }

  @override
  Future<void> upsertMembership(DogMembership membership) async {
    await _local.upsertMembership(membership);
    final change = RemoteChange(
      table: 'dog_memberships',
      op: 'upsert',
      clientOpId: _uuid.v4(),
      row: membershipToJson(membership),
    );
    await _outbox.enqueue(dogId: membership.dogKey, change: change);
  }
}
