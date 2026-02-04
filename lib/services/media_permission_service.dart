import 'package:flutter/foundation.dart';

import 'package:jakthund_app/data/local/local_membership_repository.dart';
import 'package:jakthund_app/domain/repositories/membership_repository.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/services/user_identity_service.dart';

class MediaPermissionService {
  MediaPermissionService({
    DogMembershipRepository? membershipRepository,
    UserIdentityService? identityService,
  })  : _membershipRepository = membershipRepository ?? LocalDogMembershipRepository(),
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

    final membership =
        await _membershipRepository.getMembership(dogKey, _identityService.getCurrentUserId());
    final canEdit = membership != null &&
        membership.status == Status.active &&
        (membership.role.isCanonicalAdmin || membership.role.isCanonicalUser);
    if (kDebugMode) {
      final roleName = membership?.role.name ?? 'none';
      final statusName = membership?.status.name ?? 'unknown';
      debugPrint(
        '[MEDIA] access check dogKey=$dogKey role=$roleName status=$statusName canEdit=$canEdit',
      );
    }
    return MediaAccess(canEdit: canEdit, role: membership?.role);
  }
}

class MediaAccess {
  MediaAccess({required this.canEdit, this.role});

  final bool canEdit;
  final Role? role;
}
