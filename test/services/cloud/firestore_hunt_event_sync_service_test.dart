import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/hunt_event.dart';
import 'package:jakthund_app/services/cloud/firestore_hunt_event_sync_service.dart';
import 'package:jakthund_app/services/cloud/sync_merge_policy.dart';

void main() {
  test('maps event to dogs/{dogId}/events/{eventId} and back', () {
    final event = _event(updatedAt: DateTime.utc(2026, 1, 2));
    expect(
      FirestoreHuntEventSyncService.documentPath('cloud-dog', event.id),
      'dogs/cloud-dog/events/event-1',
    );
    final data = FirestoreHuntEventSyncService.toFirestore(
      event,
      cloudDogId: 'cloud-dog',
    );
    final restored = FirestoreHuntEventSyncService.fromFirestore(
      data,
      eventId: event.id,
      localDogId: 'local-dog',
      localDogKey: 'DOG-1',
    );
    expect(restored.dogId, 'local-dog');
    expect(restored.trackPointIndex, 3);
    expect(restored.updatedAt, event.updatedAt);
  });

  test('merge policy handles insert cloudNewer localNewer and equal', () {
    final cloud = _event(updatedAt: DateTime.utc(2026, 1, 2));
    expect(
      SyncMergePolicy.forHuntEvent(local: null, cloud: cloud),
      MergeDecision.insert,
    );
    expect(
      SyncMergePolicy.forHuntEvent(
        local: _event(updatedAt: DateTime.utc(2026, 1, 1)),
        cloud: cloud,
      ),
      MergeDecision.cloudNewer,
    );
    expect(
      SyncMergePolicy.forHuntEvent(
        local: _event(updatedAt: DateTime.utc(2026, 1, 3)),
        cloud: cloud,
      ),
      MergeDecision.localNewer,
    );
    expect(
      SyncMergePolicy.forHuntEvent(
        local: _event(updatedAt: cloud.updatedAt),
        cloud: cloud,
      ),
      MergeDecision.equal,
    );
  });
}

HuntEvent _event({required DateTime updatedAt}) => HuntEvent(
  id: 'event-1',
  sessionId: 'session-1',
  dogId: 'local-dog',
  type: HuntEventType.flush,
  occurredAt: DateTime.utc(2026, 1, 1, 10),
  sourceTrackId: 'track-1',
  trackPointIndex: 3,
  latitude: 60,
  longitude: 10,
  source: HuntEventSource.manual,
  createdAt: DateTime.utc(2026),
  updatedAt: updatedAt,
  createdByUserId: 'owner',
);
