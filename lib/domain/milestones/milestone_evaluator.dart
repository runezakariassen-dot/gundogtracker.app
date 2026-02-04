import 'dog_stats.dart';
import 'milestone_catalog.dart';
import 'milestone_helpers.dart';
import 'milestone_models.dart';

typedef MilestoneEvaluator = List<MilestoneDef> Function({
  required DogStats stats,
  required Set<String> achievedIds,
});

List<MilestoneDef> evaluateMilestones({
  required DogStats stats,
  required Set<String> achievedIds,
}) {
  final newlyAchieved = <MilestoneDef>[];
  for (final config in milestoneCatalog) {
    final def = config.def;

    if (_isStandMilestone(def)) {
      continue;
    }

    // Ikke gi samme milepæl på nytt
    if (achievedIds.contains(def.id)) continue;

    if (_ruleSatisfied(config.rule, stats)) {
      newlyAchieved.add(def);
    }
  }

  newlyAchieved.addAll(
    evaluateStandThresholds(
      totalPoints: stats.totalPoints,
      achievedIds: achievedIds,
    ),
  );

  return newlyAchieved;
}

bool _ruleSatisfied(MilestoneRule rule, DogStats stats) {
  switch (rule.type) {
    case MilestoneRuleType.totalSessionsAtLeast:
      return stats.totalSessions >= rule.threshold;

    case MilestoneRuleType.totalPointsAtLeast:
      return stats.totalPoints >= rule.threshold;

    case MilestoneRuleType.totalContactsAtLeast:
      // Ikke implementert ennå
      return false;

    case MilestoneRuleType.totalActiveSecondsAtLeast:
      return stats.totalActiveSeconds >= rule.threshold;

    case MilestoneRuleType.totalBirdsAtLeast:
      return stats.totalBirdsShot >= rule.threshold;

    case MilestoneRuleType.firstPointEver:
      return stats.totalPoints >= 1;

    case MilestoneRuleType.firstFlushEver:
      return stats.totalFlushes >= 1;
  }
}

bool _isStandMilestone(MilestoneDef def) => def.id.startsWith('stands_');
