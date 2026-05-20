import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local/local_dog_repository.dart';
import '../data/local/local_invite_repository.dart';
import '../data/local/local_membership_repository.dart';
import '../domain/domain_errors.dart';
import '../domain/repositories/dog_repository.dart';
import '../domain/repositories/invite_repository.dart';
import '../domain/repositories/membership_repository.dart';
import '../models/dog_membership.dart';
import '../models/share_invitation.dart';
import 'user_identity_service.dart';

class SharingService {
  SharingService({
    UserIdentityService? identityService,
    ShareInvitationRepository? inviteRepository,
    DogMembershipRepository? membershipRepository,
    DogRepository? dogRepository,
    Random? random,
  })  : _identityService = identityService ?? UserIdentityService(),
        _inviteRepository =
            inviteRepository ?? LocalShareInvitationRepository(),
        _membershipRepository =
            membershipRepository ?? LocalDogMembershipRepository(),
        _dogRepository = dogRepository ?? LocalDogRepository(),
        _random = random ?? Random();

  final UserIdentityService _identityService;
  final ShareInvitationRepository _inviteRepository;
  final DogMembershipRepository _membershipRepository;
  final DogRepository _dogRepository;
  final Random _random;
  final Uuid _uuid = const Uuid();

  Future<ShareInvitation> createShareInvite({
    required String dogKey,
    required String recipientEmail,
    Duration ttl = const Duration(days: 7),
  }) async {
    final currentUserId = _currentUserId();
    if (!await _hasSharingPrivilege(currentUserId, dogKey)) {
      throw ShareException(ShareError.notOwner);
    }

    final normalizedEmail = _normalizeEmail(recipientEmail);
    if (!normalizedEmail.contains('@')) {
      throw ShareException(ShareError.invalidEmail);
    }

    // Check for existing active invitations to the same email for this dog
    final existingInvites = await _inviteRepository.getInvitesForDog(dogKey);
    final hasActiveInvite = existingInvites.any((invite) =>
        invite.recipientEmail == normalizedEmail &&
        invite.status == Status.pending);
    if (hasActiveInvite) {
      throw ShareException(ShareError.alreadyInvited);
    }

    final token = await _generateUniqueToken();
    final now = _now();
    final invite = ShareInvitation(
      inviteId: _uuid.v4(),
      dogKey: dogKey,
      role: Role.editor,
      token: token,
      createdAt: now,
      expiresAt: now.add(ttl),
      status: Status.pending,
      recipientEmail: normalizedEmail,
      recipientUserId: null,
      createdByUserId: currentUserId,
    );
    await _inviteRepository.upsertInvite(invite);
    return invite;
  }

  Future<DogMembership> acceptShareInvite({
    required String token,
  }) async {
    final tokenUpper = token.trim().toUpperCase();
    final invite = await _inviteRepository.getByToken(tokenUpper);
    if (invite == null) {
      throw ShareException(ShareError.inviteNotFound);
    }
    if (invite.status == Status.revoked) {
      throw ShareException(ShareError.inviteRevoked);
    }
    if (invite.status == Status.expired) {
      throw ShareException(ShareError.inviteExpired);
    }

    final currentUserId = _currentUserId();
    if (invite.expiresAt.isBefore(_now())) {
      final expired = invite.copyWith(status: Status.expired);
      await _inviteRepository.upsertInvite(expired);
      throw ShareException(ShareError.inviteExpired);
    }

    final existingMembership = await _membershipRepository.getMembership(
      invite.dogKey,
      currentUserId,
    );
    if (existingMembership != null) {
      if (invite.status != Status.accepted) {
        final accepted = invite.copyWith(status: Status.accepted);
        await _inviteRepository.upsertInvite(accepted);
      }
      return existingMembership;
    }
    if (invite.status != Status.pending) {
      throw ShareException(ShareError.inviteInactive);
    }

    final dog = await _dogRepository.getDog(invite.dogKey);
    final addedBy = dog?.ownerUserId ?? '';

    final membership = DogMembership(
      dogKey: invite.dogKey,
      userId: currentUserId,
      role: Role.editor,
      status: Status.active,
      addedAt: _now(),
      addedByUserId: addedBy,
    );
    await _membershipRepository.upsertMembership(membership);

    final accepted = invite.copyWith(status: Status.accepted);
    await _inviteRepository.upsertInvite(accepted);

    return membership;
  }

  Future<void> revokeShareInvite({
    required String inviteId,
  }) async {
    final currentUserId = _identityService.getCurrentUserId();
    final invite = await _findInviteById(inviteId);
    if (invite == null) {
      throw ShareException(ShareError.inviteNotFound);
    }
    if (!await _hasSharingPrivilege(currentUserId, invite.dogKey)) {
      throw ShareException(ShareError.notOwner);
    }

    final revoked = invite.copyWith(status: Status.revoked);
    await _inviteRepository.upsertInvite(revoked);
  }

  Future<void> declineShareInvite({
    required String inviteId,
  }) async {
    final invite = await _findInviteById(inviteId);
    if (invite == null) {
      throw ShareException(ShareError.inviteNotFound);
    }
    final declined = invite.copyWith(status: Status.revoked);
    await _inviteRepository.upsertInvite(declined);
  }

  Future<void> revokeInvite(String inviteId) async {
    await revokeShareInvite(inviteId: inviteId);
  }

  Future<int> expirePendingInvites() async {
    final now = _now();
    var updated = 0;
    final dogs = await _dogRepository.getMyDogs();
    for (final dog in dogs) {
      final invites = await _inviteRepository.getInvitesForDog(dog.dogKey);
      for (final invite in invites) {
        if (invite.status != Status.pending) {
          continue;
        }
        if (invite.expiresAt.isAfter(now)) {
          continue;
        }
        final expired = invite.copyWith(status: Status.expired);
        await _inviteRepository.upsertInvite(expired);
        updated += 1;
      }
    }
    return updated;
  }

  Future<ShareInvitation?> _findInviteById(String inviteId) async {
    final dogs = await _dogRepository.getMyDogs();
    for (final dog in dogs) {
      final invites = await _inviteRepository.getInvitesForDog(dog.dogKey);
      for (final invite in invites) {
        if (invite.inviteId == inviteId) {
          return invite;
        }
      }
    }
    return null;
  }

  String _currentUserId() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid.trim();
      if (uid != null && uid.isNotEmpty) {
        return uid;
      }
    } catch (_) {
      // Fall back to local identity for offline mode and domain tests.
    }
    return _identityService.getCurrentUserId();
  }

  Future<bool> _hasSharingPrivilege(String userId, String dogKey) async {
    final membership =
        await _membershipRepository.getMembership(dogKey, userId);
    final hasAdminMembership = membership != null &&
        membership.status == Status.active &&
        membership.role.isCanonicalAdmin;
    final dog = await _dogRepository.getDog(dogKey);
    final isOwner = dog != null &&
        (dog.ownerUserId == userId || dog.cloudOwnerUid == userId);
    final canShare = isOwner || hasAdminMembership;
    if (kDebugMode) {
      final resolvedRole = membership?.role.name ?? 'none';
      debugPrint(
        '[SHARE][PERMISSION] activeUid=$userId dogId=${dog?.id ?? dogKey} '
        'cloudId=${dog?.cloudId ?? ''} ownerUserId=${dog?.ownerUserId ?? ''} '
        'cloudOwnerUid=${dog?.cloudOwnerUid ?? ''} role=$resolvedRole '
        'canShare=$canShare',
      );
    }
    return canShare;
  }

  Future<String> _generateUniqueToken() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    for (var attempt = 0; attempt < 10; attempt++) {
      final token = List.generate(
        10,
        (_) => chars[_random.nextInt(chars.length)],
      ).join();
      final existing = await _inviteRepository.getByToken(token);
      if (existing == null) {
        return token;
      }
    }
    return _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();
  }

  DateTime _now() => DateTime.now();

  String _normalizeEmail(String email) => email.trim().toLowerCase();
}
