import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/settings/personal_stand_goal_progress.dart';
import 'package:jakthund_app/models/hunt_session.dart';

void main() {
  HuntSession session({
    required String dogId,
    required int points,
    DateTime? dateTime,
    DateTime? deletedAt,
  }) {
    return HuntSession(
      dogId: dogId,
      dateTime: dateTime ?? DateTime(2026, 1, 1),
      location: 'Trondheim',
      durationMinutes: 60,
      birdsSeen: 0,
      points: points,
      flushes: 0,
      notes: '',
      deletedAt: deletedAt,
    );
  }

  test('aggregates total stands across multiple dogs correctly', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [
        session(dogId: 'dog-a', points: 40, dateTime: DateTime(2026, 1, 1)),
        session(dogId: 'dog-b', points: 25, dateTime: DateTime(2026, 1, 2)),
        session(dogId: 'dog-c', points: 35, dateTime: DateTime(2026, 1, 3)),
      ],
      goal: 100,
    );

    expect(progress.totalStands, 100);
  });

  test('null or empty goal is allowed', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [session(dogId: 'dog-a', points: 42)],
      goal: null,
    );

    expect(progress.hasGoal, isFalse);
    expect(progress.progressPercent, 0);
    expect(progress.progressValue, 0);
  });

  test('percentage is calculated correctly', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [
        session(dogId: 'dog-a', points: 20, dateTime: DateTime(2026, 1, 1)),
        session(dogId: 'dog-b', points: 22, dateTime: DateTime(2026, 1, 2)),
      ],
      goal: 100,
    );

    expect(progress.totalStands, 42);
    expect(progress.progressPercent, 42);
    expect(progress.progressValue, 0.42);
  });

  test('overachieved goal caps progress at 100 percent', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [
        session(dogId: 'dog-a', points: 40, dateTime: DateTime(2026, 1, 1)),
        session(dogId: 'dog-b', points: 44, dateTime: DateTime(2026, 1, 2)),
        session(dogId: 'dog-c', points: 40, dateTime: DateTime(2026, 1, 3)),
      ],
      goal: 100,
    );

    expect(progress.totalStands, 124);
    expect(progress.progressPercent, 100);
    expect(progress.progressValue, 1.0);
  });

  test('deleted sessions are excluded from total stands', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [
        session(dogId: 'dog-a', points: 40, dateTime: DateTime(2026, 1, 1)),
        session(
          dogId: 'dog-b',
          points: 10,
          dateTime: DateTime(2026, 1, 2),
          deletedAt: DateTime(2026, 1, 4),
        ),
      ],
      goal: 100,
    );

    expect(progress.totalStands, 40);
    expect(progress.progressPercent, 40);
  });

  test('goal reached triggers celebration when it has not been celebrated', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [session(dogId: 'dog-a', points: 100)],
      goal: 100,
    );

    expect(progress.isGoalReached, isTrue);
    expect(progress.shouldCelebrate(lastCelebratedGoal: null), isTrue);
  });

  test('goal not reached does not trigger celebration', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [session(dogId: 'dog-a', points: 99)],
      goal: 100,
    );

    expect(progress.isGoalReached, isFalse);
    expect(progress.shouldCelebrate(lastCelebratedGoal: null), isFalse);
  });

  test('same goal is only celebrated once', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [session(dogId: 'dog-a', points: 100)],
      goal: 100,
    );

    expect(progress.shouldCelebrate(lastCelebratedGoal: 100), isFalse);
  });

  test('higher goal can be celebrated again after previous goal', () {
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: [session(dogId: 'dog-a', points: 150)],
      goal: 150,
    );

    expect(progress.shouldCelebrate(lastCelebratedGoal: 100), isTrue);
  });
}
