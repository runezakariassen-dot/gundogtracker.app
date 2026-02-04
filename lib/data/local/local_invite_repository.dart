import 'package:uuid/uuid.dart';

import '../../data/dto/share_invitation_dto.dart';
import '../../data/hive_boxes.dart';
import '../../domain/repositories/invite_repository.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../models/dog_membership.dart';
import '../../models/share_invitation.dart';
import '../../models/sync_task.dart';
import 'local_sync_queue_repository.dart';

class LocalShareInvitationRepository implements ShareInvitationRepository {
  LocalShareInvitationRepository({SyncQueueRepository? syncQueueRepository})
      : _syncQueueRepository =
            syncQueueRepository ?? LocalSyncQueueRepository();

  final SyncQueueRepository _syncQueueRepository;
  final Uuid _uuid = const Uuid();

  @override
  Future<ShareInvitation?> getByToken(String tokenUpper) async {
    for (final invite in shareInvitesBox().values) {
      if (invite.token.toUpperCase() == tokenUpper) {
        return invite;
      }
    }
    return null;
  }

  @override
  Future<void> upsertInvite(ShareInvitation invite) async {
    await shareInvitesBox().put(invite.inviteId, invite);
    await _enqueueSyncTask(invite);
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    final box = shareInvitesBox();
    final existing = box.get(inviteId);
    if (existing == null) {
      return;
    }
    final revoked = existing.copyWith(status: Status.revoked);
    await box.put(inviteId, revoked);
    await _enqueueSyncTask(revoked);
  }

  @override
  Future<List<ShareInvitation>> getInvitesForDog(String dogKey) async {
    return shareInvitesBox().values.where((i) => i.dogKey == dogKey).toList();
  }

  Future<void> _enqueueSyncTask(ShareInvitation invite) async {
    final task = SyncTask(
      taskId: _uuid.v4(),
      entityType: 'share_invitation',
      entityId: invite.inviteId,
      payload: shareInvitationToJson(invite),
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );
    await _syncQueueRepository.addTask(task);
  }
}
