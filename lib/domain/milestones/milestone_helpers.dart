import 'milestone_catalog.dart';
import 'milestone_id.dart';
import 'milestone_models.dart';

const List<int> standThresholds = <int>[
  1,
  10,
  25,
  50,
  100,
  200,
  300,
  400,
  500,
  600,
  700,
  800,
  900,
  1000,
];

const List<int> birdThresholds = standThresholds;

const List<String> birdMilestoneIds = <String>[
  MilestoneId.birdsFelled1,
  MilestoneId.birdsFelled10,
  MilestoneId.birdsFelled25,
  MilestoneId.birdsFelled50,
  MilestoneId.birdsFelled100,
  MilestoneId.birdsFelled200,
  MilestoneId.birdsFelled300,
  MilestoneId.birdsFelled400,
  MilestoneId.birdsFelled500,
  MilestoneId.birdsFelled600,
  MilestoneId.birdsFelled700,
  MilestoneId.birdsFelled800,
  MilestoneId.birdsFelled900,
  MilestoneId.birdsFelled1000,
];

/// Ensure that if a higher bird milestone is achieved, all lower thresholds are marked too.
Set<String> completeBirdMilestones(Set<String> achievedIds) {
  final complete = <String>{...achievedIds};
  for (var index = birdMilestoneIds.length - 1; index >= 0; index--) {
    final id = birdMilestoneIds[index];
    if (!complete.contains(id)) continue;

    complete.addAll(birdMilestoneIds.take(index));
    break;
  }

  return complete;
}

List<MilestoneDef> evaluateStandThresholds({
  required int totalPoints,
  required Set<String> achievedIds,
}) {
  final newlyAchieved = <MilestoneDef>[];

  for (final threshold in standThresholds) {
    if (totalPoints < threshold) continue;
    final def = milestoneDefById('stands_$threshold');
    if (def == null) continue;
    if (achievedIds.contains(def.id)) continue;
    newlyAchieved.add(def);
  }

  return newlyAchieved;
}

int thresholdFromMilestoneId(String id) {
  final parts = id.split('_');
  if (parts.isEmpty) return 0;
  final last = parts.last;
  return int.tryParse(last) ?? 0;
}
