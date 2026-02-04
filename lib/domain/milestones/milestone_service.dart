import '../../domain/repositories/dog_milestone_state_repository.dart';
import '../../domain/repositories/hunt_session_repository.dart';
import '../../models/session_type.dart';
import 'dog_stats.dart';
import 'milestone_catalog.dart';
import 'milestone_evaluator.dart';
import 'milestone_helpers.dart';
import 'milestone_models.dart';

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
    final stats = await _calculateStats(dogId);

    // Normalize achieved set (defensive against duplicates / null-ish data).
    final achieved = <String>{...state.achievedIds};

    // Evaluate catalog, including stand thresholds.
    final defs = _evaluateMilestones(stats: stats, achievedIds: achieved);

    if (defs.isEmpty) {
      // Still update evaluation timestamp.
      await _stateRepository.save(
        state.copyWith(lastEvaluatedAt: sessionDateTime),
      );
      return const [];
    }

    // Dedupe and stable ordering (use sortOrder, then id).
    final byId = <String, MilestoneDef>{};
    for (final d in defs) {
      // If somehow the same id appears twice, keep the “best” (lowest sortOrder).
      final existing = byId[d.id];
      if (existing == null) {
        byId[d.id] = d;
      } else if (d.sortOrder < existing.sortOrder) {
        byId[d.id] = d;
      }
    }

    final newly = byId.values.where((d) => !achieved.contains(d.id)).toList()
      ..sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        return c != 0 ? c : a.id.compareTo(b.id);
      });

    if (newly.isEmpty) {
      await _stateRepository.save(
        state.copyWith(lastEvaluatedAt: sessionDateTime),
      );
      return const [];
    }

    // Union-merge to avoid duplicates and ensure idempotency.
    final unionAchieved = <String>{...achieved, ...newly.map((d) => d.id)};
    final ensuredAchieved = completeBirdMilestones(unionAchieved);
    final helperNewIds = ensuredAchieved.difference(unionAchieved);

    final updatedAchievedAt = Map<String, DateTime>.from(state.achievedAt);
    for (final id in [...newly.map((d) => d.id), ...helperNewIds]) {
      updatedAchievedAt.putIfAbsent(id, () => sessionDateTime);
    }

    final updated = state.copyWith(
      achievedIds: ensuredAchieved.toList(growable: false),
      lastEvaluatedAt: sessionDateTime,
      achievedAt: updatedAchievedAt,
    );

    await _stateRepository.save(updated);

    final resultIds = <String>[
      ...newly.map((d) => d.id),
      ...helperNewIds,
    ];
    resultIds.sort((a, b) {
      final defA = milestoneDefById(a);
      final defB = milestoneDefById(b);
      final orderA = defA?.sortOrder ?? 0;
      final orderB = defB?.sortOrder ?? 0;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.compareTo(b);
    });

    return resultIds;
  }

  Future<DogStats> _calculateStats(String dogId) async {
    final sessions = await _sessionRepository.listSessionsForDog(dogId);
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
}
