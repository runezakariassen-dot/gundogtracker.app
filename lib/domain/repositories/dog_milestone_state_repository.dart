import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../milestones/dog_stats.dart';
import '../milestones/milestone_evaluator.dart';
import '../milestones/milestone_helpers.dart';
import '../../models/dog_milestone_state.dart';
import '../../models/hunt_session.dart';
import '../../models/session_type.dart';

class DogMilestoneStateRepository {
  DogMilestoneStateRepository({Box<DogMilestoneState>? box})
      : _box = box ?? dogMilestoneStateBox();

  final Box<DogMilestoneState> _box;

  /// Hent eksisterende state, eller opprett en ny for hunden.
  /// Normaliserer achievedIds defensivt.
  Future<DogMilestoneState> getOrCreate(String dogId) async {
    final existing = _box.get(dogId);
    if (existing != null) {
      return _normalized(existing);
    }

    final state = DogMilestoneState(
      dogId: dogId,
      achievedIds: const [],
      lastEvaluatedAt: null,
    );

    await _box.put(dogId, state);
    return state;
  }

  /// Lagre state på en idempotent måte.
  /// Sikrer at achievedIds ikke inneholder duplikater.
  Future<void> save(DogMilestoneState state) async {
    final normalized = _normalized(state);
    await _box.put(normalized.dogId, normalized);
  }

  /// Slett state for én hund (brukes ved f.eks. fjerning av hund).
  Future<void> delete(String dogId) async {
    await _box.delete(dogId);
  }

  /// Backfill:
  /// - Leser alle økter per hund
  /// - Sorterer kronologisk
  /// - Evaluerer milestones ved hvert steg
  /// - Setter achievedAt første gang terskel nås
  /// - Reparerer også manglende achievedAt for allerede oppnådde milestones
  Future<BackfillResult> backfillFromSessionHistory({
    required Iterable<String> dogIds,
    Box<HuntSession>? sessions,
  }) async {
    var dogsProcessed = 0;
    var sessionsProcessed = 0;

    final sessionsBoxRef = sessions ?? sessionsBox();

    for (final dogId in dogIds) {
      final dogSessions = sessionsBoxRef.values
          .where((s) => s.dogId == dogId)
          .toList(growable: false);

      if (dogSessions.isEmpty) continue;

      dogsProcessed++;
      sessionsProcessed += dogSessions.length;

      dogSessions.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      debugPrint('[MILESTONE] Backfill start dogId=$dogId '
          'sessions=${dogSessions.length}');

      final state = await getOrCreate(dogId);

      // Eksisterende data
      final achieved = <String>{...state.achievedIds};
      final achievedAt = Map<String, DateTime>.from(state.achievedAt);

      // Løpende summer
      var totalSessions = 0;
      var totalPointsOrStands = 0;
      var totalFlushes = 0;
      var totalActiveSeconds = 0;
      var totalBirdsShot = 0;

      var changed = false;
      int newIdsAdded = 0;
      var achievedAtFilled = 0;

      for (final session in dogSessions) {
        totalSessions += 1;

        // NB: Prosjektet bruker "points" som stand-telling flere steder.
        // Hvis du har eget stand-felt senere, bytt til det.
        totalPointsOrStands += session.points;

        totalFlushes += session.flushes;
        totalActiveSeconds += session.durationMinutes * 60;

        if (session.sessionType == SessionType.hunting) {
          totalBirdsShot += session.birdsShotCount;
        }

        final stats = DogStats(
          totalSessions: totalSessions,
          totalPoints: totalPointsOrStands,
          totalFlushes: totalFlushes,
          totalActiveSeconds: totalActiveSeconds,
          totalBirdsShot: totalBirdsShot,
        );

        // Kritisk: ikke filtrer på achievedIds her.
        // Vi vil ha "alt som er nådd så langt", slik at achievedAt kan backfilles
        // første gang milestone dukker opp i kronologisk løp.
        final reachedDefs =
            evaluateMilestones(stats: stats, achievedIds: const <String>{});

        if (reachedDefs.isEmpty) continue;

        for (final def in reachedDefs) {
          final id = def.id;

          if (!achieved.contains(id)) {
            achieved.add(id);
            newIdsAdded++;
            changed = true;
          }

          // Første gang terskelen passeres: sett achievedAt
          if (!achievedAt.containsKey(id)) {
            achievedAt[id] = session.dateTime;
            achievedAtFilled++;
            changed = true;

            debugPrint(
              '[MILESTONE] dogId=$dogId milestone=$id achievedAt=${session.dateTime.toIso8601String()} '
              '(sessions=$totalSessions points=$totalPointsOrStands flushes=$totalFlushes activeSec=$totalActiveSeconds)',
            );
          }
        }

        final highestBirdIndex = birdMilestoneIds
            .lastIndexWhere((id) => achieved.contains(id));
        if (highestBirdIndex >= 0) {
          for (var idx = 0; idx < highestBirdIndex; idx++) {
            final id = birdMilestoneIds[idx];
            if (achieved.contains(id)) continue;
            achieved.add(id);
            newIdsAdded++;
            changed = true;
            if (!achievedAt.containsKey(id)) {
              achievedAt[id] = session.dateTime;
              achievedAtFilled++;
            }
          }
        }
      }

      if (changed) {
        await save(
          state.copyWith(
            achievedIds: achieved.toList(growable: false),
            achievedAt: achievedAt,
          ),
        );

        debugPrint(
          '[MILESTONE] Backfill saved dogId=$dogId '
          'totalAchieved=${achieved.length} newIds=$newIdsAdded achievedAtFilled=$achievedAtFilled '
          'finalSessions=$totalSessions finalPoints=$totalPointsOrStands finalFlushes=$totalFlushes',
        );
      } else {
        debugPrint(
          '[MILESTONE] Backfill no changes dogId=$dogId '
          '(achieved=${achieved.length}, achievedAt=${achievedAt.length})',
        );
      }
    }

    return BackfillResult(
      dogsProcessed: dogsProcessed,
      sessionsProcessed: sessionsProcessed,
    );
  }

  /// Intern normalisering:
  /// - fjerner duplikater i achievedIds
  /// - bevarer rekkefølge deterministisk (sortert)
  DogMilestoneState _normalized(DogMilestoneState state) {
    final uniqueIds = <String>{
      ...state.achievedIds,
      ...state.achievedAt.keys,
    };

    // Sortering gir stabil lagring og lettere debugging
    final sorted = uniqueIds.toList()..sort();

    final normalizedAchievedAt = <String, DateTime>{};
    for (final entry in state.achievedAt.entries) {
      normalizedAchievedAt[entry.key] = entry.value;
    }

    return state.copyWith(
      achievedIds: sorted,
      achievedAt: normalizedAchievedAt,
    );
  }
}

class BackfillResult {
  const BackfillResult({
    required this.dogsProcessed,
    required this.sessionsProcessed,
  });

  final int dogsProcessed;
  final int sessionsProcessed;
}
