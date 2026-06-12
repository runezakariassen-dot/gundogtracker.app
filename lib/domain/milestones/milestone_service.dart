import '../../data/hive_boxes.dart';
import '../../domain/repositories/dog_milestone_state_repository.dart';
import '../../domain/repositories/hunt_session_repository.dart';
import '../../models/session_type.dart';
import '../../services/hive_lifecycle_service.dart';
import 'dog_stats.dart';
import 'milestone_catalog.dart';
import 'milestone_evaluator.dart';
import 'milestone_helpers.dart';

class MilestoneService {
  MilestoneService({
    required MilestoneEvaluator evaluator,
    required DogMilestoneStateRepository milestoneStateRepository,
    required HuntSessionRepository huntSessionRepository,
  })  : _evaluateMilestones = evaluator,
        _stateRepository = milestoneStateRepository,
        _sessionRepository = huntSessionRepository;

  final MilestoneEvaluator _evaluateMilestones;
  final DogMilestoneStateRepository _stateRepository;
  final HuntSessionRepository _sessionRepository;

  /// Returns IDs for milestones that are newly achieved for this dog.
  Future<List<String>> evaluateForDog(
    String dogId, {
    required DateTime sessionDateTime,
  }) async {
    final state = await _stateRepository.getOrCreate(dogId);
    final snapshot = await _calculateHistoricalSnapshot(dogId);
    final previousAchieved = <String>{...state.achievedIds};
    final newly = snapshot.achievedIds.difference(previousAchieved).toList()
      ..sort(_compareMilestoneIds);

    final updated = state.copyWith(
      achievedIds: snapshot.sortedAchievedIds,
      lastEvaluatedAt: sessionDateTime,
      achievedAt: snapshot.achievedAt,
    );

    await _stateRepository.save(updated);

    return newly;
  }

  /// Evaluates milestone goals and returns which ones are newly achieved.
  /// This should be called after evaluateForDog to check if goals are reached.
  Future<List<String>> evaluateGoalsForDog(
    String dogId, {
    required DateTime sessionDateTime,
  }) async {
    final stats = await _calculateStats(dogId);
    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);

    final seasonGoal =
        (settingsBox.get(milestoneSeasonGoalPointsKey) as int?) ?? 0;
    final personalGoal =
        (settingsBox.get(milestonePersonalGoalPointsKey) as int?) ?? 0;
    final seasonAchieved =
        (settingsBox.get(milestoneSeasonGoalAchievedKey) as bool?) ?? false;
    final personalAchieved =
        (settingsBox.get(milestonePersonalGoalAchievedKey) as bool?) ?? false;

    final newlyAchieved = <String>[];

    if (seasonGoal > 0 && !seasonAchieved && stats.totalPoints >= seasonGoal) {
      newlyAchieved.add('season_goal');
      await settingsBox.put(milestoneSeasonGoalAchievedKey, true);
    }

    if (personalGoal > 0 &&
        !personalAchieved &&
        stats.totalPoints >= personalGoal) {
      newlyAchieved.add('personal_goal');
      await settingsBox.put(milestonePersonalGoalAchievedKey, true);
    }

    return newlyAchieved;
  }

  Future<DogStats> _calculateStats(String dogId) async {
    final sessions = (await _sessionRepository.listSessionsForDog(dogId))
        .where((session) => !session.isDeleted)
        .toList(growable: false);
    if (sessions.isEmpty) {
      return const DogStats(
        totalSessions: 0,
        totalPoints: 0,
        totalFlushes: 0,
        totalActiveSeconds: 0,
        totalBirdsShot: 0,
      );
    }

    var totalSessions = 0;
    var totalPoints = 0;
    var totalFlushes = 0;
    var totalBirdsShot = 0;
    var totalActiveSeconds = 0;

    for (final session in sessions) {
      totalSessions += 1;
      totalPoints += session.points;
      totalFlushes += session.flushes;
      totalActiveSeconds += session.durationMinutes * 60;
      if (session.sessionType == SessionType.hunting) {
        totalBirdsShot += session.birdsShotCount;
      }
    }

    return DogStats(
      totalSessions: totalSessions,
      totalPoints: totalPoints,
      totalFlushes: totalFlushes,
      totalActiveSeconds: totalActiveSeconds,
      totalBirdsShot: totalBirdsShot,
    );
  }

  Future<_HistoricalMilestoneSnapshot> _calculateHistoricalSnapshot(
    String dogId,
  ) async {
    final sessions = (await _sessionRepository.listSessionsForDog(dogId))
        .where((session) => !session.isDeleted)
        .toList(growable: false)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final achieved = <String>{};
    final achievedAt = <String, DateTime>{};

    var totalSessions = 0;
    var totalPoints = 0;
    var totalFlushes = 0;
    var totalBirdsShot = 0;
    var totalActiveSeconds = 0;

    for (final session in sessions) {
      totalSessions += 1;
      totalPoints += session.points;
      totalFlushes += session.flushes;
      totalActiveSeconds += session.durationMinutes * 60;
      if (session.sessionType == SessionType.hunting) {
        totalBirdsShot += session.birdsShotCount;
      }

      final stats = DogStats(
        totalSessions: totalSessions,
        totalPoints: totalPoints,
        totalFlushes: totalFlushes,
        totalActiveSeconds: totalActiveSeconds,
        totalBirdsShot: totalBirdsShot,
      );
      final reachedDefs = _evaluateMilestones(
        stats: stats,
        achievedIds: const <String>{},
      );

      for (final def in reachedDefs) {
        achieved.add(def.id);
        achievedAt.putIfAbsent(def.id, () => session.dateTime);
      }
    }

    final ensuredAchieved = completeBirdMilestones(achieved);
    for (final id in ensuredAchieved) {
      achievedAt.putIfAbsent(id, () => _fallbackAchievedAt(id, achievedAt));
    }

    final sorted = ensuredAchieved.toList(growable: false)
      ..sort(_compareMilestoneIds);
    return _HistoricalMilestoneSnapshot(
      achievedIds: ensuredAchieved,
      sortedAchievedIds: sorted,
      achievedAt: achievedAt,
    );
  }

  DateTime _fallbackAchievedAt(
    String id,
    Map<String, DateTime> achievedAt,
  ) {
    if (achievedAt[id] != null) {
      return achievedAt[id]!;
    }
    DateTime? fallback;
    for (final entry in achievedAt.entries) {
      if (!birdMilestoneIds.contains(entry.key)) continue;
      if (fallback == null || entry.value.isBefore(fallback)) {
        fallback = entry.value;
      }
    }
    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

int _compareMilestoneIds(String a, String b) {
  final defA = milestoneDefById(a);
  final defB = milestoneDefById(b);
  final orderA = defA?.sortOrder ?? 0;
  final orderB = defB?.sortOrder ?? 0;
  if (orderA != orderB) return orderA.compareTo(orderB);
  return a.compareTo(b);
}

class _HistoricalMilestoneSnapshot {
  const _HistoricalMilestoneSnapshot({
    required this.achievedIds,
    required this.sortedAchievedIds,
    required this.achievedAt,
  });

  final Set<String> achievedIds;
  final List<String> sortedAchievedIds;
  final Map<String, DateTime> achievedAt;
}
