import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/local_membership_repository.dart';
import 'package:jakthund_app/domain/repositories/membership_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/services/user_identity_service.dart';

class MediaPermissionService {
  MediaPermissionService({
    DogMembershipRepository? membershipRepository,
    UserIdentityService? identityService,
  })  : _membershipRepository =
            membershipRepository ?? LocalDogMembershipRepository(),
        _identityService = identityService ?? UserIdentityService();

  final DogMembershipRepository _membershipRepository;
  final UserIdentityService _identityService;

  Future<MediaAccess> resolveAccess(String? dogKey) async {
    if (dogKey == null || dogKey.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('[MEDIA] access check missing dogKey');
      }
      return MediaAccess(canEdit: false, role: null);
    }

    DogMembership? membership;
    for (final userId in _currentUserIds()) {
      final candidate =
          await _membershipRepository.getMembership(dogKey, userId);
      if (candidate != null) {
        membership = candidate;
        break;
      }
    }
    var canEdit = membership != null &&
        membership.status == Status.active &&
        (membership.role.isCanonicalAdmin || membership.role.isCanonicalUser);

    if (!canEdit && _isOwnerForDog(dogKey)) {
      canEdit = true;
    }

    if (kDebugMode) {
      final roleName = membership?.role.name ?? 'none';
      final statusName = membership?.status.name ?? 'unknown';
      debugPrint(
        '[MEDIA] access check dogKey=$dogKey role=$roleName status=$statusName canEdit=$canEdit',
      );
    }
    return MediaAccess(canEdit: canEdit, role: membership?.role);
  }

  Iterable<String> _currentUserIds() {
    final ids = <String>{};
    final localUid = _identityService.getCurrentUserId().trim();
    if (localUid.isNotEmpty) {
      ids.add(localUid);
    }
    try {
      final authUid = FirebaseAuth.instance.currentUser?.uid.trim();
      if (authUid != null && authUid.isNotEmpty) {
        ids.add(authUid);
      }
    } catch (_) {
      // Keep local identity only when FirebaseAuth is unavailable.
    }
    return ids;
  }

  bool _isOwnerForDog(String dogKey) {
    final normalizedKey = dogKey.trim();
    if (normalizedKey.isEmpty) {
      return false;
    }

    final dogs = dogsBox().values;
    Dog? dog;
    for (final entry in dogs) {
      if (entry.dogKey.trim() == normalizedKey || entry.id == normalizedKey) {
        dog = entry;
        break;
      }
    }
    if (dog == null) {
      return false;
    }

    final ownerId = dog.ownerUserId?.trim();
    if (ownerId == null || ownerId.isEmpty) {
      return false;
    }

    for (final userId in _currentUserIds()) {
      if (userId == ownerId) {
        return true;
      }
    }
    return false;
  }
}

class MediaAccess {
  MediaAccess({required this.canEdit, this.role});

  final bool canEdit;
  final Role? role;
}
