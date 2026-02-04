enum MilestoneCategory { sessions, firsts, points, contacts, time }

class MilestoneDef {
  final String id;
  final MilestoneCategory category;
  final String title;
  final String subtitle;
  final String? icon;
  final int sortOrder;

  const MilestoneDef({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sortOrder,
  });
}

enum MilestoneRuleType {
  totalSessionsAtLeast,
  totalPointsAtLeast,
  totalContactsAtLeast,
  totalActiveSecondsAtLeast,
  firstPointEver,
  firstFlushEver,
  totalBirdsAtLeast,
}

class MilestoneRule {
  final MilestoneRuleType type;
  final int threshold;

  const MilestoneRule(this.type, {this.threshold = 0});
}

class MilestoneConfig {
  final MilestoneDef def;
  final MilestoneRule rule;

  const MilestoneConfig({required this.def, required this.rule});
}
