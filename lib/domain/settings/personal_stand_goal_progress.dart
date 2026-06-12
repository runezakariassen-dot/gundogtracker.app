import 'dart:math' as math;

import 'package:jakthund_app/domain/stats/stats_v2_aggregator.dart';
import 'package:jakthund_app/models/hunt_session.dart';

class PersonalStandGoalProgress {
  const PersonalStandGoalProgress({
    required this.totalStands,
    required this.goal,
  });

  final int totalStands;
  final int? goal;

  bool get hasGoal => goal != null && goal! > 0;

  bool get isGoalReached => hasGoal && totalStands >= goal!;

  double get progressValue {
    if (!hasGoal) {
      return 0;
    }
    return math.min(totalStands, goal!) / goal!;
  }

  int get progressPercent {
    if (!hasGoal) {
      return 0;
    }
    return (progressValue * 100).round();
  }

  bool shouldCelebrate({required int? lastCelebratedGoal}) {
    if (!isGoalReached) {
      return false;
    }
    return lastCelebratedGoal == null || goal! > lastCelebratedGoal;
  }

  static PersonalStandGoalProgress fromSessions({
    required Iterable<HuntSession> sessions,
    required int? goal,
  }) {
    final sessionList =
        sessions.where((session) => !session.isDeleted).toList();
    if (sessionList.isEmpty) {
      return PersonalStandGoalProgress(
          totalStands: 0, goal: _normalizeGoal(goal));
    }

    final sorted = List<HuntSession>.from(sessionList)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final result = StatsV2Aggregator.aggregate(
      sessions: sorted,
      query: StatsV2Query(
        periodType: StatsV2PeriodType.custom,
        from: sorted.first.dateTime,
        to: sorted.last.dateTime,
      ),
    );

    return PersonalStandGoalProgress(
      totalStands: result.points,
      goal: _normalizeGoal(goal),
    );
  }

  static int? _normalizeGoal(int? goal) {
    if (goal == null || goal <= 0) {
      return null;
    }
    return goal;
  }
}
