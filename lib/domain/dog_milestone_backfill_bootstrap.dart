import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/hive_boxes.dart';
import '../domain/domain_constants.dart';
import '../domain/repositories/dog_milestone_state_repository.dart';
import '../models/dog.dart';
import '../models/hunt_session.dart';

Future<void> ensureDogMilestonesBackfilled({
  required Iterable<Dog> dogs,
  required Box<dynamic> settingsBox,
  required DogMilestoneStateRepository stateRepository,
  Box<HuntSession>? huntsessionsBox,
}) async {
  final dogList = dogs.where((dog) => !dog.isDeleted).toList(growable: false);
  debugPrint('[MILESTONE] Backfill start dogs=${dogList.length}');

  final box = huntsessionsBox ?? sessionsBox();
  debugPrint('[MILESTONE] Sessions in huntsessionsBox=${box.length}');

  if (dogList.isEmpty) {
    debugPrint('[MILESTONE] Backfill skipped (no dogs)');
    return;
  }

  if (box.isEmpty) {
    debugPrint('[MILESTONE] Backfill skipped (no sessions)');
    return;
  }

  final alreadyBackfilled =
      (settingsBox.get(dogMilestoneHistoryBackfillKey) as bool?) ?? false;
  if (alreadyBackfilled) {
    final repairNeeded = await _needsRepairRun(
      stateRepository,
      dogList,
      huntsessionsBox: box,
    );
    if (!repairNeeded) {
      debugPrint('[MILESTONE] Backfill skipped (flag true + state ok)');
      return;
    }
    debugPrint(
      '[MILESTONE] Backfill repair-run triggered (flag true but missing state)',
    );
  }

  final stats = await stateRepository.backfillFromSessionHistory(
    dogIds: dogList.map((dog) => dog.id),
    sessions: box,
  );
  await settingsBox.put(dogMilestoneHistoryBackfillKey, true);
  debugPrint(
    '[MILESTONE] Backfill executed (${stats.dogsProcessed} dogs, '
    '${stats.sessionsProcessed} sessions)',
  );
}

Future<bool> _needsRepairRun(
  DogMilestoneStateRepository stateRepository,
  List<Dog> dogs, {
  required Box<HuntSession> huntsessionsBox,
}) async {
  for (final dog in dogs) {
    final state = await stateRepository.getOrCreate(dog.id);
    final hasAchievements =
        state.achievedIds.isNotEmpty && state.achievedAt.isNotEmpty;
    if (hasAchievements) {
      continue;
    }
    final hasSessions = huntsessionsBox.values
        .any((session) => session.dogId == dog.id && !session.isDeleted);
    if (hasSessions) {
      return true;
    }
  }
  return false;
}
