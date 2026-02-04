import '../../domain/repositories/invite_repository.dart';
import '../../models/share_invitation.dart';

class RemoteShareInvitationRepository implements ShareInvitationRepository {
  @override
  Future<ShareInvitation?> getByToken(String tokenUpper) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<void> upsertInvite(ShareInvitation invite) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<void> revokeInvite(String inviteId) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<List<ShareInvitation>> getInvitesForDog(String dogKey) {
    throw UnimplementedError('Remote sync disabled');
  }
}
