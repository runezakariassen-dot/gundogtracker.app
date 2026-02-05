import 'package:flutter/foundation.dart';

import '../domain/repositories/dog_repository.dart';
import '../domain/repositories/membership_repository.dart';
import '../models/dog_membership.dart';

Future<void> ensureCurrentUserMemberships({
  required String userId,
  required DogRepository dogRepository,
  required DogMembershipRepository membershipRepository,
  DateTime Function()? nowProvider,
  void Function(String message)? log,
}) async {
  final logger = log ?? debugPrint;
  if (userId.isEmpty) {
    logger('[BACKFILL] Skipping membership backfill (empty user id)');
    return;
  }

  final dogs = await dogRepository.getMyDogs();
  if (dogs.isEmpty) {
    logger('[BACKFILL] Skipping membership backfill (no dogs)');
    return;
  }

  logger('[BACKFILL] Membership backfill start user=$userId dogs=${dogs.length}');
  var created = 0;
  var skippedWithoutKey = 0;

  for (final dog in dogs) {
    final dogKey = dog.dogKey.trim();
    if (dogKey.isEmpty) {
      skippedWithoutKey++;
      continue;
    }

    final existing = await membershipRepository.getMembership(dogKey, userId);
    if (existing != null) {
      continue;
    }

    final membership = DogMembership(
      dogKey: dogKey,
      userId: userId,
      role: Role.owner,
      status: Status.active,
      addedAt: nowProvider?.call() ?? DateTime.now(),
      addedByUserId: userId,
    );
    await membershipRepository.upsertMembership(membership);
    created++;
  }

  if (skippedWithoutKey > 0) {
    logger(
      '[BACKFILL] Skipped $skippedWithoutKey dog(s) without dogKey for user=$userId',
    );
  }

  logger(
    '[BACKFILL] Membership backfill complete user=$userId dogs=${dogs.length} created=$created',
  );
}
