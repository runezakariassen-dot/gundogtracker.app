import 'package:flutter/foundation.dart';

import '../../models/dog.dart';
import '../../models/dog_membership.dart';

bool isDogVisibleInUi(Dog? dog) => dog != null && !dog.isDeleted;

class DogLimitCountSnapshot {
  const DogLimitCountSnapshot({
    required this.visibleDogs,
    required this.countedDogs,
  });

  final List<Dog> visibleDogs;
  final List<Dog> countedDogs;
}

List<Dog> filterActiveDogs(Iterable<Dog> dogs) {
  return dogs.where((dog) {
    if (dog.isDeleted) {
      if (kDebugMode) {
        debugPrint('[UI][VISIBILITY] hidden deleted dog: ${dog.id}');
      }
      return false;
    }
    return true;
  }).toList(growable: false);
}

List<Dog> filterVisibleDogs({
  required Iterable<Dog> dogs,
  required Iterable<DogMembership> memberships,
  required String? currentUserId,
  Iterable<String>? currentUserIds,
}) {
  final activeDogs = filterActiveDogs(dogs);
  final normalizedUserIds = <String>{};
  if (currentUserId != null && currentUserId.trim().isNotEmpty) {
    normalizedUserIds.add(currentUserId.trim());
  }
  if (currentUserIds != null) {
    for (final userId in currentUserIds) {
      final trimmed = userId.trim();
      if (trimmed.isNotEmpty) {
        normalizedUserIds.add(trimmed);
      }
    }
  }
  final allowedDogKeys = memberships
      .where((membership) =>
          normalizedUserIds.contains(membership.userId.trim()) &&
          membership.status == Status.active)
      .map((membership) => membership.dogKey)
      .toSet();

  if (kDebugMode) {
    debugPrint(
      '[TF][VISIBILITY] currentUserId=$currentUserId '
      'currentUserIds=${normalizedUserIds.toList()} '
      'activeMembershipDogKeys=${allowedDogKeys.toList()}',
    );
  }

  return activeDogs.where((dog) {
    final hasMembership = allowedDogKeys.contains(dog.dogKey);
    final ownerId = dog.ownerUserId?.trim();
    final isOwner = ownerId != null &&
        ownerId.isNotEmpty &&
        normalizedUserIds.contains(ownerId);
    final ownerFallback = isOwner && !hasMembership;
    final visible = hasMembership || isOwner;

    if (kDebugMode) {
      debugPrint(
        '[TF][VISIBILITY][DOG] name=${dog.name} dogKey=${dog.dogKey} '
        'deletedAt=${dog.deletedAt} hasActiveMembership=$hasMembership '
        'ownerFallback=$ownerFallback visible=$visible',
      );
    }

    return visible;
  }).toList(growable: false);
}

DogLimitCountSnapshot buildDogLimitCountSnapshot({
  required Iterable<Dog> dogs,
  required Iterable<DogMembership> memberships,
  required String? currentUserId,
  Iterable<String>? currentUserIds,
}) {
  // Log every dog currently in the box so we can see which ones survive
  // filterVisibleDogs vs which are unexpectedly still counted.
  for (final dog in dogs) {
    // ignore: avoid_print
    print(
      '[SUBSCRIPTION][DOG_LIMIT] box entry: id=${dog.id} '
      'dogKey=${dog.dogKey} isDeleted=${dog.isDeleted} '
      'ownerUserId=${dog.ownerUserId}',
    );
  }

  final visibleDogs = filterVisibleDogs(
    dogs: dogs,
    memberships: memberships,
    currentUserId: currentUserId,
    currentUserIds: currentUserIds,
  );
  for (final dog in visibleDogs) {
    // ignore: avoid_print
    print(
      '[SUBSCRIPTION][DOG_LIMIT] counting: id=${dog.id} '
      'dogKey=${dog.dogKey} isDeleted=${dog.isDeleted}',
    );
  }
  // ignore: avoid_print
  print('[SUBSCRIPTION][DOG_LIMIT] visible dogs: ${visibleDogs.length}');
  // ignore: avoid_print
  print(
    '[SUBSCRIPTION][DOG_LIMIT] counted dogs: ${visibleDogs.length}',
  );
  return DogLimitCountSnapshot(
    visibleDogs: visibleDogs,
    countedDogs: visibleDogs,
  );
}

Dog? findVisibleDogById({
  required Iterable<Dog> dogs,
  required Iterable<DogMembership> memberships,
  required String? currentUserId,
  Iterable<String>? currentUserIds,
  required String dogId,
}) {
  final visibleDogs = filterVisibleDogs(
    dogs: dogs,
    memberships: memberships,
    currentUserId: currentUserId,
    currentUserIds: currentUserIds,
  );

  for (final dog in visibleDogs) {
    if (dog.id == dogId || dog.name == dogId || dog.dogKey == dogId) {
      return dog;
    }
  }

  return null;
}
