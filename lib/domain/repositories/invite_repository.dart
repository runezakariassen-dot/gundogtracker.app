import '../../models/share_invitation.dart';

abstract class ShareInvitationRepository {
  Future<ShareInvitation?> getByToken(String tokenUpper);
  Future<void> upsertInvite(ShareInvitation invite);
  Future<void> revokeInvite(String inviteId);
  Future<List<ShareInvitation>> getInvitesForDog(String dogKey);
}
