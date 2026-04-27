import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/services/cloud/sync_merge_policy.dart';

void main() {
  group('SyncMergePolicy.forSession', () {
    test('returns insert when local session is missing', () {
      final cloud = _buildSession(updatedAt: DateTime.utc(2024, 1, 2));

      final decision = SyncMergePolicy.forSession(local: null, cloud: cloud);

      expect(decision, MergeDecision.insert);
    });

    test('returns cloudNewer when cloud session has newer updatedAt', () {
      final local = _buildSession(updatedAt: DateTime.utc(2024, 1, 1));
      final cloud = _buildSession(updatedAt: DateTime.utc(2024, 1, 2));

      final decision = SyncMergePolicy.forSession(local: local, cloud: cloud);

      expect(decision, MergeDecision.cloudNewer);
    });

    test('returns localNewer when local session has newer updatedAt', () {
      final local = _buildSession(updatedAt: DateTime.utc(2024, 1, 3));
      final cloud = _buildSession(updatedAt: DateTime.utc(2024, 1, 2));

      final decision = SyncMergePolicy.forSession(local: local, cloud: cloud);

      expect(decision, MergeDecision.localNewer);
    });

    test('returns equal for the same instant across timezones', () {
      final local = _buildSession(
        updatedAt: DateTime.parse('2024-01-02T11:00:00+01:00'),
      );
      final cloud = _buildSession(updatedAt: DateTime.utc(2024, 1, 2, 10));

      final decision = SyncMergePolicy.forSession(local: local, cloud: cloud);

      expect(decision, MergeDecision.equal);
    });
  });

  group('SyncMergePolicy.forDog', () {
    test('returns insert when local dog is missing', () {
      final cloud = _buildDog(updatedAt: DateTime.utc(2024, 1, 2));

      final decision = SyncMergePolicy.forDog(local: null, cloud: cloud);

      expect(decision, MergeDecision.insert);
    });

    test('returns cloudNewer when cloud dog has newer updatedAt', () {
      final local = _buildDog(updatedAt: DateTime.utc(2024, 1, 1));
      final cloud = _buildDog(updatedAt: DateTime.utc(2024, 1, 2));

      final decision = SyncMergePolicy.forDog(local: local, cloud: cloud);

      expect(decision, MergeDecision.cloudNewer);
    });

    test('returns localNewer when local dog has newer updatedAt', () {
      final local = _buildDog(updatedAt: DateTime.utc(2024, 1, 3));
      final cloud = _buildDog(updatedAt: DateTime.utc(2024, 1, 2));

      final decision = SyncMergePolicy.forDog(local: local, cloud: cloud);

      expect(decision, MergeDecision.localNewer);
    });

    test('returns equal when dog timestamps match', () {
      final timestamp = DateTime.utc(2024, 1, 2, 10);
      final local = _buildDog(updatedAt: timestamp);
      final cloud = _buildDog(updatedAt: timestamp);

      final decision = SyncMergePolicy.forDog(local: local, cloud: cloud);

      expect(decision, MergeDecision.equal);
    });
  });
}

Dog _buildDog({required DateTime updatedAt}) {
  return Dog(
    id: 'dog-1',
    name: 'Luna',
    dogKey: 'dog-key-1',
    regNrDisplay: 'NO12345/24',
    updatedAt: updatedAt,
    cloudId: 'cloud-dog-1',
  );
}

HuntSession _buildSession({required DateTime updatedAt}) {
  return HuntSession(
    dogId: 'dog-1',
    dogKey: 'dog-key-1',
    dateTime: DateTime.utc(2024, 1, 1, 8),
    location: 'Skog',
    durationMinutes: 60,
    birdsSeen: 2,
    points: 1,
    flushes: 1,
    notes: 'Test',
    updatedAt: updatedAt,
  );
}
