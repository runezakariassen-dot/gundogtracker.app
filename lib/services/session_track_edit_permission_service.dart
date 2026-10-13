import 'package:firebase_auth/firebase_auth.dart';

import '../data/hive_boxes.dart';
import '../models/dog.dart';
import '../models/dog_membership.dart';
import 'user_identity_service.dart';

class SessionTrackEditPermissionService {
  SessionTrackEditPermissionService({UserIdentityService? identityService})
      : _identityService = identityService ?? UserIdentityService();

  final UserIdentityService _identityService;

  bool canEdit({required String dogId, String? dogKey}) {
    return canEditFor(
      dogId: dogId,
      dogKey: dogKey,
      userIds: _currentUserIds(),
      dogs: dogsBox().values,
      memberships: dogMembershipsBox().values,
    );
  }

  static bool canEditFor({
    required String dogId,
    required Iterable<String> userIds,
    required Iterable<Dog> dogs,
    required Iterable<DogMembership> memberships,
    String? dogKey,
  }) {
    final normalizedUserIds =
        userIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    if (normalizedUserIds.isEmpty) return false;

    Dog? dog;
    for (final candidate in dogs) {
      if (candidate.id == dogId ||
          candidate.dogKey == dogId ||
          (dogKey != null && candidate.dogKey == dogKey)) {
        dog = candidate;
        break;
      }
    }
    if (dog != null &&
        <String?>{dog.ownerUserId, dog.cloudOwnerUid}
            .whereType<String>()
            .map((id) => id.trim())
            .any(normalizedUserIds.contains)) {
      return true;
    }

    final keys = <String>{dogId, if (dogKey != null) dogKey, dog?.dogKey ?? ''}
      ..removeWhere((key) => key.trim().isEmpty);
    return memberships.any(
      (membership) =>
          keys.contains(membership.dogKey) &&
          normalizedUserIds.contains(membership.userId.trim()) &&
          membership.status == Status.active &&
          membership.role != Role.viewer,
    );
  }

  Set<String> _currentUserIds() {
    final ids = <String>{};
    final localId = _identityService.getCurrentUserId().trim();
    if (localId.isNotEmpty) ids.add(localId);
    try {
      final authId = FirebaseAuth.instance.currentUser?.uid.trim();
      if (authId != null && authId.isNotEmpty) ids.add(authId);
    } catch (_) {
      // FirebaseAuth can be unavailable in local-only/test environments.
    }
    return ids;
  }
}
