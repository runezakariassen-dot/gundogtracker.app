import 'package:uuid/uuid.dart';

import '../data/local/local_dog_repository.dart';
import '../data/local/local_membership_repository.dart';
import '../data/local/local_transfer_repository.dart';
import '../domain/domain_errors.dart';
import '../domain/repositories/dog_repository.dart';
import '../domain/repositories/membership_repository.dart';
import '../domain/repositories/transfer_repository.dart';
import '../models/dog_membership.dart';
import '../models/ownership_transfer.dart';
import 'user_identity_service.dart';

class OwnershipService {
  OwnershipService({
    UserIdentityService? identityService,
    OwnershipTransferRepository? transferRepository,
    DogMembershipRepository? membershipRepository,
    DogRepository? dogRepository,
  })  : _identityService = identityService ?? UserIdentityService(),
        _transferRepository =
            transferRepository ?? LocalOwnershipTransferRepository(),
        _membershipRepository =
            membershipRepository ?? LocalDogMembershipRepository(),
        _dogRepository = dogRepository ?? LocalDogRepository();

  final UserIdentityService _identityService;
  final OwnershipTransferRepository _transferRepository;
  final DogMembershipRepository _membershipRepository;
  final DogRepository _dogRepository;
  final Uuid _uuid = const Uuid();

  Future<OwnershipTransfer> initiateTransfer(
    String dogKey,
    String toUserId, {
    int expiresInDays = 7,
  }) async {
    final currentUserId = _identityService.getCurrentUserId();
    final membership =
        await _membershipRepository.getMembership(dogKey, currentUserId);
    if (membership == null ||
        membership.status != Status.active ||
        !membership.role.isCanonicalAdmin) {
      throw TransferException(TransferError.notOwner);
    }
    if (toUserId.isEmpty || toUserId == currentUserId) {
      throw TransferException(TransferError.cannotTransferToSelf);
    }

    final transfer = OwnershipTransfer(
      transferId: _uuid.v4(),
      dogKey: dogKey,
      fromUserId: currentUserId,
      toUserId: toUserId,
      status: Status.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: expiresInDays)),
    );

    await _transferRepository.upsertTransfer(transfer);
    return transfer;
  }

  Future<void> acceptTransfer(String transferId) async {
    final transfer = await _transferRepository.getById(transferId);
    if (transfer == null) {
      throw TransferException(TransferError.transferNotFound);
    }
    if (transfer.status == Status.cancelled) {
      throw TransferException(TransferError.cancelled);
    }
    if (transfer.status != Status.pending) {
      throw TransferException(TransferError.transferNotPending);
    }
    if (transfer.expiresAt.isBefore(DateTime.now())) {
      final expired = transfer.copyWith(status: Status.expired);
      await _transferRepository.upsertTransfer(expired);
      throw TransferException(TransferError.transferExpired);
    }

    final currentUserId = _identityService.getCurrentUserId();
    if (currentUserId != transfer.toUserId) {
      throw TransferException(TransferError.notRecipient);
    }

    final dog = await _dogRepository.getDog(transfer.dogKey);
    if (dog == null) {
      throw TransferException(TransferError.transferNotFound);
    }

    final updatedDog = dog.copyWith(
      ownerUserId: transfer.toUserId,
      updatedAt: DateTime.now(),
    );
    await _dogRepository.upsertDog(updatedDog);

    await _upsertMembership(
      transfer.dogKey,
      transfer.toUserId,
      Role.owner,
      transfer.fromUserId,
    );
    await _upsertMembership(
      transfer.dogKey,
      transfer.fromUserId,
      Role.editor,
      transfer.fromUserId,
    );

    final accepted = transfer.copyWith(status: Status.accepted);
    await _transferRepository.upsertTransfer(accepted);
  }

  Future<void> cancelTransfer(String transferId) async {
    final transfer = await _transferRepository.getById(transferId);
    if (transfer == null) {
      throw TransferException(TransferError.transferNotFound);
    }
    if (transfer.status == Status.cancelled) {
      throw TransferException(TransferError.cancelled);
    }
    if (transfer.status != Status.pending) {
      throw TransferException(TransferError.transferNotPending);
    }
    final currentUserId = _identityService.getCurrentUserId();
    if (currentUserId != transfer.fromUserId) {
      throw TransferException(TransferError.notOwner);
    }
    final cancelled = transfer.copyWith(status: Status.cancelled);
    await _transferRepository.upsertTransfer(cancelled);
  }

  Future<void> declineTransfer(String transferId) async {
    final transfer = await _transferRepository.getById(transferId);
    if (transfer == null) {
      throw TransferException(TransferError.transferNotFound);
    }
    if (transfer.status == Status.cancelled) {
      throw TransferException(TransferError.cancelled);
    }
    if (transfer.status != Status.pending) {
      throw TransferException(TransferError.transferNotPending);
    }
    final currentUserId = _identityService.getCurrentUserId();
    if (currentUserId != transfer.toUserId) {
      throw TransferException(TransferError.notRecipient);
    }
    final declined = transfer.copyWith(status: Status.cancelled);
    await _transferRepository.upsertTransfer(declined);
  }

  Future<DogMembership> updateMembershipRole({
    required String dogKey,
    required String targetUserId,
    required Role role,
  }) async {
    final currentUserId = _identityService.getCurrentUserId();
    final actorMembership =
        await _membershipRepository.getMembership(dogKey, currentUserId);
    if (actorMembership == null || actorMembership.status != Status.active) {
      throw MembershipRoleException(MembershipRoleError.notAuthorized);
    }
    if (currentUserId == targetUserId) {
      throw MembershipRoleException(MembershipRoleError.cannotEditSelf);
    }

    final targetMembership =
        await _membershipRepository.getMembership(dogKey, targetUserId);
    if (targetMembership == null || targetMembership.status != Status.active) {
      throw MembershipRoleException(MembershipRoleError.membershipNotFound);
    }
    final actorRole = actorMembership.role;
    final targetRole = targetMembership.role;
    final actorIsOwner = actorRole == Role.owner;
    final actorIsAdmin = actorRole == Role.admin;

    if (targetMembership.role == Role.owner) {
      throw MembershipRoleException(MembershipRoleError.ownerRoleLocked);
    }

    if (role == Role.owner && !actorIsOwner) {
      throw MembershipRoleException(MembershipRoleError.ownerRoleLocked);
    }

    if (!actorIsOwner && !actorIsAdmin) {
      throw MembershipRoleException(MembershipRoleError.notAuthorized);
    }

    if (actorIsAdmin &&
        (targetRole.isCanonicalAdmin || role.isCanonicalAdmin)) {
      throw MembershipRoleException(MembershipRoleError.cannotPromoteToAdmin);
    }

    final updatedMembership = targetMembership.copyWith(role: role);
    await _membershipRepository.upsertMembership(updatedMembership);
    return updatedMembership;
  }

  Future<void> _upsertMembership(
    String dogKey,
    String userId,
    Role role,
    String addedByUserId,
  ) async {
    final existing = await _membershipRepository.getMembership(dogKey, userId);
    if (existing != null) {
      await _membershipRepository.upsertMembership(
        existing.copyWith(role: role, status: Status.active),
      );
      return;
    }
    final membership = DogMembership(
      dogKey: dogKey,
      userId: userId,
      role: role,
      status: Status.active,
      addedAt: DateTime.now(),
      addedByUserId: addedByUserId,
    );
    await _membershipRepository.upsertMembership(membership);
  }
}
