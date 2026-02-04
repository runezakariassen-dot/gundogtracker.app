import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/statistics/statistics_aggregator.dart';
import 'package:jakthund_app/models/hunt_session.dart';

void main() {
  group('StatisticsAggregator.aggregate', () {
    test('empty list returns empty stats', () {
      final res = StatisticsAggregator.aggregate([]);

      expect(res.totalSessions, 0);
      expect(res.totalActiveTime, Duration.zero);
      expect(res.totalBirdContacts, 0);
      expect(res.totalPoints, 0);
      expect(res.totalFlushes, 0);
      expect(res.firstSessionDate, isNull);
      expect(res.lastSessionDate, isNull);
    });

    test('one session aggregates correctly', () {
      final session = HuntSession(
        dogId: 'dog1',
        dateTime: DateTime(2025, 1, 1, 10, 0),
        location: 'Egersund',
        durationMinutes: 30,
        birdsSeen: 2,
        points: 1,
        flushes: 3,
        notes: 'test',
      );

      final res = StatisticsAggregator.aggregate([session]);

      expect(res.totalSessions, 1);
      expect(res.totalActiveTime, const Duration(minutes: 30));
      expect(res.totalBirdContacts, 2);
      expect(res.totalPoints, 1);
      expect(res.totalFlushes, 3);
      expect(res.firstSessionDate, DateTime(2025, 1, 1, 10, 0));
      expect(res.lastSessionDate, DateTime(2025, 1, 1, 10, 0));
    });

    test('multiple sessions sums and finds first/last date', () {
      final s1 = HuntSession(
        dogId: 'dog1',
        dateTime: DateTime(2025, 1, 2, 10, 0),
        location: 'Egersund',
        durationMinutes: 20,
        birdsSeen: 1,
        points: 0,
        flushes: 1,
        notes: 'test',
      );

      final s2 = HuntSession(
        dogId: 'dog1',
        dateTime: DateTime(2025, 1, 1, 10, 0),
        location: 'Egersund',
        durationMinutes: 40,
        birdsSeen: 2,
        points: 2,
        flushes: 0,
        notes: 'test',
      );

      final res = StatisticsAggregator.aggregate([s1, s2]);

      expect(res.totalSessions, 2);
      expect(res.totalActiveTime, const Duration(minutes: 60));
      expect(res.totalBirdContacts, 3);
      expect(res.totalPoints, 2);
      expect(res.totalFlushes, 1);
      expect(res.firstSessionDate, DateTime(2025, 1, 1, 10, 0));
      expect(res.lastSessionDate, DateTime(2025, 1, 2, 10, 0));
    });

    test('includes secondaryPoints in totalPoints', () {
      final session = HuntSession(
        dogId: 'dog1',
        dateTime: DateTime(2025, 1, 1, 10, 0),
        location: 'Egersund',
        durationMinutes: 10,
        birdsSeen: 0,
        points: 1,
        secondaryPoints: 2,
        flushes: 0,
        notes: 'test',
      );

      final res = StatisticsAggregator.aggregate([session]);

      expect(res.totalPoints, 3);
    });

    test('aggregateForDog filters sessions by dogId', () {
      final dog1 = HuntSession(
        dogId: 'dog1',
        dateTime: DateTime(2025, 1, 1, 10, 0),
        location: 'Egersund',
        durationMinutes: 30,
        birdsSeen: 2,
        points: 1,
        flushes: 0,
        notes: 'dog1',
      );

      final dog2 = HuntSession(
        dogId: 'dog2',
        dateTime: DateTime(2025, 1, 2, 10, 0),
        location: 'Egersund',
        durationMinutes: 40,
        birdsSeen: 3,
        points: 2,
        flushes: 1,
        notes: 'dog2',
      );

      final res = StatisticsAggregator.aggregateForDog(
        [dog1, dog2],
        'dog1',
      );

      expect(res.totalSessions, 1);
      expect(res.totalActiveTime, const Duration(minutes: 30));
      expect(res.totalBirdContacts, 2);
      expect(res.totalPoints, 1);
      expect(res.totalFlushes, 0);
      expect(res.firstSessionDate, DateTime(2025, 1, 1, 10, 0));
      expect(res.lastSessionDate, DateTime(2025, 1, 1, 10, 0));
    });
  });
}
