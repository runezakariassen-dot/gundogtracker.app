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
}) {
  final activeDogs = filterActiveDogs(dogs);
  final allowedDogKeys = currentUserId == null
      ? const <String>{}
      : memberships
          .where((membership) =>
              membership.userId.trim() == currentUserId &&
              membership.status == Status.active)
          .map((membership) => membership.dogKey)
          .toSet();

  return activeDogs.where((dog) {
    final hasMembership = allowedDogKeys.contains(dog.dogKey);
    final isOwner = currentUserId != null &&
        dog.ownerUserId != null &&
        dog.ownerUserId == currentUserId;
    return hasMembership || isOwner;
  }).toList(growable: false);
}

DogLimitCountSnapshot buildDogLimitCountSnapshot({
  required Iterable<Dog> dogs,
  required Iterable<DogMembership> memberships,
  required String? currentUserId,
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
  required String dogId,
}) {
  final visibleDogs = filterVisibleDogs(
    dogs: dogs,
    memberships: memberships,
    currentUserId: currentUserId,
  );

  for (final dog in visibleDogs) {
    if (dog.id == dogId || dog.name == dogId || dog.dogKey == dogId) {
      return dog;
    }
  }

  return null;
}
