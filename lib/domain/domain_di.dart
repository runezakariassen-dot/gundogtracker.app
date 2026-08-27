import '../core/feature_flags.dart';
import '../data/local/local_dog_repository.dart';
import '../data/local/local_invite_repository.dart';
import '../data/local/local_membership_repository.dart';
import '../data/local/local_sync_queue_repository.dart';
import '../data/local/local_transfer_repository.dart';
import '../data/remote/remote_dog_repository.dart';
import '../data/remote/remote_invite_repository.dart';
import '../data/remote/remote_membership_repository.dart';
import '../data/remote/remote_transfer_repository.dart';
import '../domain/repositories/dog_repository.dart';
import '../domain/repositories/invite_repository.dart';
import '../domain/repositories/membership_repository.dart';
import '../domain/repositories/sync_queue_repository.dart';
import '../domain/repositories/transfer_repository.dart';
import '../services/dog_service.dart';
import '../services/ownership_service.dart';
import '../services/sharing_service.dart';
import '../services/user_identity_service.dart';

class DomainDi {
  static DogRepository dogRepository() {
    if (FeatureFlags.enableRemoteSync) {
      return RemoteDogRepository();
    }
    return LocalDogRepository();
  }

  static DogMembershipRepository membershipRepository() {
    if (FeatureFlags.enableRemoteSync) {
      return RemoteDogMembershipRepository();
    }
    return LocalDogMembershipRepository();
  }

  static ShareInvitationRepository inviteRepository() {
    if (FeatureFlags.enableRemoteSync) {
      return RemoteShareInvitationRepository();
    }
    return LocalShareInvitationRepository();
  }

  static OwnershipTransferRepository transferRepository() {
    if (FeatureFlags.enableRemoteSync) {
      return RemoteOwnershipTransferRepository();
    }
    return LocalOwnershipTransferRepository();
  }

  static SyncQueueRepository syncQueueRepository() {
    return LocalSyncQueueRepository();
  }

  static DogService dogService({UserIdentityService? identityService}) {
    return DogService(
      identityService: identityService,
      dogRepository: dogRepository(),
      membershipRepository: membershipRepository(),
    );
  }

  static SharingService sharingService({
    UserIdentityService? identityService,
    CloudShareInviteWriter? cloudShareInviteWriter,
  }) {
    return SharingService(
      identityService: identityService,
      inviteRepository: inviteRepository(),
      membershipRepository: membershipRepository(),
      dogRepository: dogRepository(),
      cloudShareInviteWriter: cloudShareInviteWriter,
    );
  }

  static OwnershipService ownershipService({
    UserIdentityService? identityService,
  }) {
    return OwnershipService(
      identityService: identityService,
      transferRepository: transferRepository(),
      membershipRepository: membershipRepository(),
      dogRepository: dogRepository(),
    );
  }
}
