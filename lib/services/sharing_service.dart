import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import '../data/local/local_dog_repository.dart';
import '../data/local/local_invite_repository.dart';
import '../data/local/local_membership_repository.dart';
import '../domain/dogs/dog_visibility.dart';
import '../domain/domain_errors.dart';
import '../domain/repositories/dog_repository.dart';
import '../domain/repositories/invite_repository.dart';
import '../domain/repositories/membership_repository.dart';
import '../models/dog_membership.dart';
import '../models/dog.dart';
import '../models/share_invitation.dart';
import 'cloud/firestore_dog_sync_service.dart';
import 'cloud/firestore_share_invitation_sync_service.dart';
import 'cloud/pull_sync_service.dart';
import 'user_identity_service.dart';

typedef AuthUserIdProvider = String? Function();
typedef AuthUserEmailProvider = String? Function();
typedef AuthUserDisplayNameProvider = String? Function();
typedef CloudShareMembershipWriter = Future<bool> Function({
  required ShareInvitation invite,
  required DogMembership membership,
});
typedef CloudShareInviteWriter = Future<void> Function(ShareInvitation invite);
typedef RestoreAccessibleDogs = Future<int> Function();
typedef PullAllVisibleData = Future<void> Function();

class SharingService {
  SharingService({
    UserIdentityService? identityService,
    ShareInvitationRepository? inviteRepository,
    DogMembershipRepository? membershipRepository,
    DogRepository? dogRepository,
    Random? random,
    AuthUserIdProvider? currentAuthUserIdProvider,
    AuthUserEmailProvider? currentAuthUserEmailProvider,
    AuthUserDisplayNameProvider? currentAuthUserDisplayNameProvider,
    FirestoreShareInvitationSyncService? cloudInviteSyncService,
    CloudShareInviteWriter? cloudShareInviteWriter,
    CloudShareMembershipWriter? cloudShareMembershipWriter,
    RestoreAccessibleDogs? restoreAccessibleDogs,
    PullAllVisibleData? pullAllVisibleData,
  })  : _identityService = identityService ?? UserIdentityService(),
        _inviteRepository =
            inviteRepository ?? LocalShareInvitationRepository(),
        _membershipRepository =
            membershipRepository ?? LocalDogMembershipRepository(),
        _dogRepository = dogRepository ?? LocalDogRepository(),
        _random = random ?? Random(),
        _currentAuthUserIdProvider =
            currentAuthUserIdProvider ?? _defaultCurrentAuthUserIdProvider,
        _currentAuthUserEmailProvider = currentAuthUserEmailProvider ??
            _defaultCurrentAuthUserEmailProvider,
        _currentAuthUserDisplayNameProvider =
            currentAuthUserDisplayNameProvider ??
                _defaultCurrentAuthUserDisplayNameProvider,
        _cloudInviteSyncService = cloudInviteSyncService ??
            FirestoreShareInvitationSyncService.instance,
        _cloudShareInviteWriter = cloudShareInviteWriter,
        _cloudShareMembershipWriter = cloudShareMembershipWriter ??
            FirestoreDogSyncService
                .instance.upsertShareInviteMembershipBestEffort,
        _restoreAccessibleDogs = restoreAccessibleDogs ??
            FirestoreDogSyncService.instance.restoreAccessibleDogsToHive,
        _pullAllVisibleData =
            pullAllVisibleData ?? PullSyncService().pullAllVisibleData;

  final UserIdentityService _identityService;
  final ShareInvitationRepository _inviteRepository;
  final DogMembershipRepository _membershipRepository;
  final DogRepository _dogRepository;
  final Random _random;
  final AuthUserIdProvider _currentAuthUserIdProvider;
  final AuthUserEmailProvider _currentAuthUserEmailProvider;
  final AuthUserDisplayNameProvider _currentAuthUserDisplayNameProvider;
  final FirestoreShareInvitationSyncService _cloudInviteSyncService;
  final CloudShareInviteWriter? _cloudShareInviteWriter;
  final CloudShareMembershipWriter _cloudShareMembershipWriter;
  final RestoreAccessibleDogs _restoreAccessibleDogs;
  final PullAllVisibleData _pullAllVisibleData;
  final Uuid _uuid = const Uuid();

  Future<ShareInvitation> createShareInvite({
    required String dogKey,
    required String recipientEmail,
    Duration ttl = const Duration(days: 7),
  }) async {
    final currentUserId = _currentUserId();
    final dog = await _dogRepository.getDog(dogKey);
    if (!await _hasSharingPrivilege(
      dog: dog,
      candidateUserIds: _candidateActorUserIds(),
      candidateEmail: _currentAuthUserEmail(),
      dogKey: dogKey,
    )) {
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
      cloudDogId: _resolveCloudDogId(dog),
      senderDisplayName: _resolveSenderDisplayName(),
      senderEmail: _currentAuthUserEmail()?.trim().toLowerCase(),
      dogName: _resolveDogName(dog),
    );
    await _upsertInviteEverywhere(invite);
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

    final authUid = (_currentAuthUserIdProvider() ?? '').trim();
    final currentUserId =
        authUid.isNotEmpty ? authUid : _identityService.getCurrentUserId();
    _logAcceptState(
      'start',
      invite: invite,
      currentUserId: currentUserId,
      authUid: authUid,
    );
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
      final acceptedMembership = existingMembership.copyWith(
        role: _acceptedRole(existingMembership, invite),
        status: Status.active,
      );
      await _membershipRepository.upsertMembership(acceptedMembership);
      _logAcceptMembershipResult(acceptedMembership);

      final accepted = invite.copyWith(
        status: Status.accepted,
        recipientUserId: currentUserId,
      );
      if (invite.status != Status.accepted ||
          invite.recipientUserId?.trim() != currentUserId) {
        await _upsertInviteEverywhere(accepted);
      }
      await _rehydrateAcceptedInvite(
        invite: accepted,
        membership: acceptedMembership,
        authUid: authUid,
      );
      return acceptedMembership;
    }
    if (invite.status != Status.pending) {
      throw ShareException(ShareError.inviteInactive);
    }

    final dog = await _dogRepository.getDog(invite.dogKey);
    final addedBy = dog?.ownerUserId ?? '';

    final membership = DogMembership(
      dogKey: invite.dogKey,
      userId: currentUserId,
      role: invite.role,
      status: Status.active,
      addedAt: _now(),
      addedByUserId: addedBy,
    );
    await _membershipRepository.upsertMembership(membership);
    _logAcceptMembershipResult(membership);

    final accepted = invite.copyWith(
      status: Status.accepted,
      recipientUserId: currentUserId,
    );
    await _upsertInviteEverywhere(accepted);
    await _rehydrateAcceptedInvite(
      invite: accepted,
      membership: membership,
      authUid: authUid,
    );

    return membership;
  }

  Future<void> revokeShareInvite({
    required String inviteId,
  }) async {
    final invite = await _findInviteById(inviteId);
    if (invite == null) {
      throw ShareException(ShareError.inviteNotFound);
    }
    final dog = await _dogRepository.getDog(invite.dogKey);
    if (!await _hasSharingPrivilege(
      dog: dog,
      candidateUserIds: _candidateActorUserIds(),
      candidateEmail: _currentAuthUserEmail(),
      dogKey: invite.dogKey,
    )) {
      throw ShareException(ShareError.notOwner);
    }

    final revoked = invite.copyWith(status: Status.revoked);
    await _upsertInviteEverywhere(revoked);
  }

  Future<void> declineShareInvite({
    required String inviteId,
  }) async {
    final invite = await _findInviteById(inviteId);
    if (invite == null) {
      throw ShareException(ShareError.inviteNotFound);
    }
    final declined = invite.copyWith(status: Status.revoked);
    await _upsertInviteEverywhere(declined);
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
        await _upsertInviteEverywhere(expired);
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

  Future<bool> _hasSharingPrivilege({
    required Dog? dog,
    required Iterable<String> candidateUserIds,
    required String? candidateEmail,
    required String dogKey,
  }) async {
    final normalizedIds = candidateUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (dog != null) {
      final ownerUserId = dog.ownerUserId?.trim() ?? '';
      if (ownerUserId.isNotEmpty && normalizedIds.contains(ownerUserId)) {
        return true;
      }
      final cloudOwnerUid = dog.cloudOwnerUid?.trim() ?? '';
      if (cloudOwnerUid.isNotEmpty && normalizedIds.contains(cloudOwnerUid)) {
        return true;
      }

      final ownerEmail = dog.ownerEmail?.trim().toLowerCase();
      final currentEmail = candidateEmail?.trim().toLowerCase();
      if (ownerEmail != null &&
          ownerEmail.isNotEmpty &&
          currentEmail != null &&
          currentEmail.isNotEmpty &&
          ownerEmail == currentEmail) {
        return true;
      }
    }

    if (normalizedIds.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[Sharing] Access denied (dog=$dogKey): no actor IDs and no owner/email match',
        );
      }
      return false;
    }

    for (final userId in normalizedIds) {
      final membership =
          await _membershipRepository.getMembership(dogKey, userId);
      final hasActiveMembership = membership != null &&
          membership.status == Status.active &&
          membership.role.isCanonicalAdmin;
      if (hasActiveMembership) {
        return true;
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[Sharing] Access denied (dog=$dogKey users=${normalizedIds.join(',')} ownerUserId=${dog?.ownerUserId ?? ''} cloudOwnerUid=${dog?.cloudOwnerUid ?? ''} ownerEmail=${dog?.ownerEmail ?? ''} currentEmail=${candidateEmail ?? ''})',
      );
    }
    return false;
  }

  Set<String> _candidateActorUserIds() {
    final ids = <String>{};
    final localUserId = _identityService.getCurrentUserId().trim();
    if (localUserId.isNotEmpty) {
      ids.add(localUserId);
    }
    final authUserId = (_currentAuthUserIdProvider() ?? '').trim();
    if (authUserId.isNotEmpty) {
      ids.add(authUserId);
    }
    return ids;
  }

  String? _currentAuthUserEmail() {
    return _currentAuthUserEmailProvider();
  }

  String? _resolveSenderDisplayName() {
    final authDisplayName = _currentAuthUserDisplayNameProvider()?.trim();
    if (authDisplayName != null && authDisplayName.isNotEmpty) {
      return authDisplayName;
    }
    final localDisplayName = _identityService.getDisplayName()?.trim();
    if (localDisplayName != null && localDisplayName.isNotEmpty) {
      return localDisplayName;
    }
    return null;
  }

  static String? _defaultCurrentAuthUserIdProvider() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static String? _defaultCurrentAuthUserEmailProvider() {
    try {
      return FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  static String? _defaultCurrentAuthUserDisplayNameProvider() {
    try {
      return FirebaseAuth.instance.currentUser?.displayName;
    } catch (_) {
      return null;
    }
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

  Role _acceptedRole(DogMembership existingMembership, ShareInvitation invite) {
    if (existingMembership.role.isCanonicalAdmin) {
      return existingMembership.role;
    }
    return invite.role;
  }

  String? _resolveCloudDogId(Dog? dog) {
    if (dog == null) return null;
    final cloudId = dog.cloudId?.trim();
    if (cloudId != null && cloudId.isNotEmpty) {
      return cloudId;
    }
    final id = dog.id.trim();
    return id.isEmpty ? null : id;
  }

  String? _resolveDogName(Dog? dog) {
    if (dog == null) return null;
    final displayName = dog.displayName.trim();
    return displayName.isEmpty ? null : displayName;
  }

  Future<void> _upsertInviteEverywhere(ShareInvitation invite) async {
    await _inviteRepository.upsertInvite(invite);
    final cloudShareInviteWriter = _cloudShareInviteWriter ??
        _cloudInviteSyncService.upsertInviteBestEffort;
    await cloudShareInviteWriter(invite);
  }

  Future<void> _rehydrateAcceptedInvite({
    required ShareInvitation invite,
    required DogMembership membership,
    required String authUid,
  }) async {
    final cloudMembershipWritten = authUid.isEmpty
        ? false
        : await _cloudShareMembershipWriter(
            invite: invite,
            membership: membership,
          );
    _logAcceptBoxCounts(
      stage: 'after membership write',
      invite: invite,
      currentUserId: membership.userId,
      cloudMembershipWritten: cloudMembershipWritten,
    );

    if (authUid.isEmpty) {
      return;
    }

    try {
      final restoredDogs = await _restoreAccessibleDogs();
      debugPrint('[INVITE][ACCEPT] restore result dogs=$restoredDogs');
      await _pullAllVisibleData();
      debugPrint('[INVITE][ACCEPT] pull result complete');
    } catch (error, stackTrace) {
      debugPrint('[INVITE][ACCEPT] restore/pull failed: $error');
      debugPrint(stackTrace.toString());
    }

    _logAcceptBoxCounts(
      stage: 'after restore/pull',
      invite: invite,
      currentUserId: membership.userId,
      cloudMembershipWritten: cloudMembershipWritten,
    );
  }

  void _logAcceptState(
    String stage, {
    required ShareInvitation invite,
    required String currentUserId,
    required String authUid,
  }) {
    debugPrint(
      '[INVITE][ACCEPT] $stage authUid=${authUid.isEmpty ? 'null' : authUid} '
      'localUid=$currentUserId dogKey=${invite.dogKey} '
      'cloudDogId=${invite.cloudDogId ?? 'null'} inviteId=${invite.inviteId} '
      'role=${invite.role.name} status=${invite.status.name}',
    );
  }

  void _logAcceptMembershipResult(DogMembership membership) {
    debugPrint(
      '[INVITE][ACCEPT] local membership write success '
      'dogKey=${membership.dogKey} uid=${membership.userId} '
      'role=${membership.role.name} status=${membership.status.name}',
    );
  }

  void _logAcceptBoxCounts({
    required String stage,
    required ShareInvitation invite,
    required String currentUserId,
    required bool cloudMembershipWritten,
  }) {
    try {
      final dogs = dogsBox().values.toList(growable: false);
      final memberships = dogMembershipsBox().values.toList(growable: false);
      final visibleDogs = filterVisibleDogs(
        dogs: dogs,
        memberships: memberships.where(
          (membership) =>
              membership.userId.trim() == currentUserId &&
              membership.status == Status.active,
        ),
        currentUserId: currentUserId,
        currentUserIds: <String>{currentUserId},
      );
      debugPrint(
        '[INVITE][ACCEPT] $stage cloudMembershipWritten=$cloudMembershipWritten '
        'dogKey=${invite.dogKey} cloudDogId=${invite.cloudDogId ?? 'null'} '
        'dogsBox=${dogs.length} membershipsBox=${memberships.length} '
        'visibleDogs=${visibleDogs.length}',
      );
    } catch (error) {
      debugPrint('[INVITE][ACCEPT] $stage box count failed: $error');
    }
  }
}
