import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/milestones/dog_stats.dart';
import 'package:jakthund_app/domain/milestones/milestone_catalog.dart';
import 'package:jakthund_app/domain/milestones/milestone_evaluator.dart';
import 'package:jakthund_app/domain/milestones/milestone_helpers.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';

void main() {
  test('century milestone definitions exist in catalog', () {
    final def100 = milestoneDefById(MilestoneId.stands100);
    final def200 = milestoneDefById(MilestoneId.stands200);

    expect(def100, isNotNull);
    expect(def100!.title, contains('100'));
    expect(def200, isNotNull);
    expect(def200!.title, contains('200'));
  });

  test('evaluateMilestones awards new defs for sessions points', () {
    final results = evaluateMilestones(
      stats: const DogStats(
        totalSessions: 10,
        totalPoints: 0,
        totalFlushes: 0,
        totalActiveSeconds: 0,
        totalBirdsShot: 0,
      ),
      achievedIds: const {MilestoneId.stands1},
    ).map((def) => def.id);

    expect(results, contains(MilestoneId.sessions10));
  });

  test('stand thresholds to 1000 have milestone definitions', () {
    for (final threshold in standThresholds) {
      final id = 'stands_$threshold';
      expect(
        milestoneDefById(id),
        isNotNull,
        reason: 'Missing milestone definition for $id',
      );
    }
  });
}
