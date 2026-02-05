import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/stats/stats_v2_aggregator.dart';
import 'package:jakthund_app/models/hunt_session.dart';

HuntSession _makeSession({
  required String dogId,
  required DateTime dateTime,
  int durationMinutes = 60,
  int birdsSeen = 0,
  int points = 0,
  int secondaryPoints = 0,
  int flushes = 0,
  int birdsShotCount = 0,
}) {
  return HuntSession(
    dogId: dogId,
    dateTime: dateTime,
    location: 'test',
    durationMinutes: durationMinutes,
    birdsSeen: birdsSeen,
    points: points,
    flushes: flushes,
    notes: '',
    secondaryPoints: secondaryPoints,
    birdsShotCount: birdsShotCount,
  );
}

void main() {
  group('StatsV2Aggregator', () {
    test('all dogs and year summary', () {
      final sessions = [
        _makeSession(
          dogId: 'dog-a',
          dateTime: DateTime(2024, 2, 1),
          durationMinutes: 40,
          birdsSeen: 2,
          points: 5,
          secondaryPoints: 1,
          flushes: 1,
          birdsShotCount: 1,
        ),
        _makeSession(
          dogId: 'dog-b',
          dateTime: DateTime(2024, 6, 10),
          durationMinutes: 80,
          birdsSeen: 3,
          points: 7,
          secondaryPoints: 3,
          flushes: 2,
          birdsShotCount: 2,
        ),
      ];

      final result = StatsV2Aggregator.aggregate(
        sessions: sessions,
        query: const StatsV2Query(periodType: StatsV2PeriodType.year, year: 2024),
      );

      expect(result.sessionsCount, 2);
      expect(result.activeMinutes, 120);
      expect(result.points, 12);
      expect(result.secondaryPoints, 4);
      expect(result.flushes, 3);
      expect(result.birdContacts, 5);
      expect(result.birdsDown, 3);
      expect(result.byYear.map((y) => y.year).toList(), [2024]);
      expect(result.byYear.first.sessionsCount, 2);
    });

    test('filters by single dog', () {
      final sessions = [
        _makeSession(
          dogId: 'dog-a',
          dateTime: DateTime(2024, 3, 1),
          durationMinutes: 30,
          birdsSeen: 1,
          points: 2,
          flushes: 1,
        ),
        _makeSession(
          dogId: 'dog-b',
          dateTime: DateTime(2024, 3, 2),
          durationMinutes: 10,
          birdsSeen: 1,
          points: 3,
          flushes: 2,
          secondaryPoints: 1,
          birdsShotCount: 1,
        ),
        _makeSession(
          dogId: 'dog-b',
          dateTime: DateTime(2024, 3, 5),
          durationMinutes: 20,
          birdsSeen: 2,
          points: 4,
          flushes: 0,
          secondaryPoints: 1,
          birdsShotCount: 2,
        ),
      ];

      final result = StatsV2Aggregator.aggregate(
        sessions: sessions,
        query: const StatsV2Query(
          periodType: StatsV2PeriodType.year,
          year: 2024,
          dogId: 'dog-b',
        ),
      );

      expect(result.sessionsCount, 2);
      expect(result.activeMinutes, 30);
      expect(result.points, 7);
      expect(result.secondaryPoints, 2);
      expect(result.flushes, 2);
      expect(result.birdContacts, 3);
      expect(result.birdsDown, 3);
      expect(result.byYear.single.year, 2024);
      expect(result.byYear.single.sessionsCount, 2);
    });

    test('winter season spans december from previous year', () {
      final sessions = [
        _makeSession(
          dogId: 'dog-a',
          dateTime: DateTime(2023, 12, 20),
          durationMinutes: 15,
          birdsSeen: 1,
          points: 5,
          flushes: 1,
          birdsShotCount: 1,
        ),
        _makeSession(
          dogId: 'dog-b',
          dateTime: DateTime(2024, 1, 8),
          durationMinutes: 20,
          birdsSeen: 2,
          points: 3,
          flushes: 1,
          secondaryPoints: 2,
          birdsShotCount: 0,
        ),
        _makeSession(
          dogId: 'dog-c',
          dateTime: DateTime(2024, 2, 28),
          durationMinutes: 25,
          birdsSeen: 2,
          points: 4,
          flushes: 2,
          secondaryPoints: 1,
          birdsShotCount: 2,
        ),
        _makeSession(
          dogId: 'dog-c',
          dateTime: DateTime(2024, 4, 1),
          durationMinutes: 50,
          birdsSeen: 5,
          points: 10,
          flushes: 5,
          secondaryPoints: 2,
          birdsShotCount: 3,
        ),
      ];

      final result = StatsV2Aggregator.aggregate(
        sessions: sessions,
        query: const StatsV2Query(
          periodType: StatsV2PeriodType.season,
          year: 2024,
          season: StatsV2Season.winter,
        ),
      );

      expect(result.sessionsCount, 3);
      expect(result.byYear.map((y) => y.year).toList(), [2023, 2024]);
      expect(result.byYear.first.sessionsCount, 1);
      expect(result.byYear.last.sessionsCount, 2);
      expect(result.birdContacts, 5);
    });

    test('custom range includes sessions on the to date', () {
      final sessions = [
        _makeSession(
          dogId: 'dog-a',
          dateTime: DateTime(2024, 2, 28, 23, 45),
          durationMinutes: 31,
          birdsSeen: 3,
          points: 6,
          flushes: 2,
        ),
        _makeSession(
          dogId: 'dog-b',
          dateTime: DateTime(2024, 3, 1),
          durationMinutes: 15,
          birdsSeen: 1,
          points: 1,
          flushes: 0,
        ),
      ];

      final result = StatsV2Aggregator.aggregate(
        sessions: sessions,
        query: StatsV2Query(
          periodType: StatsV2PeriodType.custom,
          from: DateTime(2024, 2, 1),
          to: DateTime(2024, 2, 28, 12),
        ),
      );

      expect(result.sessionsCount, 1);
      expect(result.activeMinutes, 31);
      expect(result.byYear.length, 1);
      expect(result.byYear.single.year, 2024);
    });
  });
}
