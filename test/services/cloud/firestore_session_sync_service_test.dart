import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/services/cloud/firestore_session_sync_service.dart';

void main() {
  HuntSession session({
    String? sessionId,
    String? createdByUserId,
  }) {
    return HuntSession(
      sessionId: sessionId,
      dogId: 'local-dog-1',
      dateTime: DateTime.utc(2026, 1, 1),
      location: 'Fjell',
      durationMinutes: 30,
      birdsSeen: 1,
      points: 1,
      flushes: 0,
      notes: '',
      createdByUserId: createdByUserId,
    );
  }

  test('existing creator wins over current sync user', () {
    final value = FirestoreSessionSyncService.resolveCreatedByUserId(
      session: session(createdByUserId: 'original-creator'),
      fallbackUserId: 'later-user',
    );

    expect(value, 'original-creator');
  });

  test('legacy session without creator uses current user fallback', () {
    final value = FirestoreSessionSyncService.resolveCreatedByUserId(
      session: session(),
      fallbackUserId: 'legacy-sync-user',
    );

    expect(value, 'legacy-sync-user');
  });

  test('stable session id wins over caller fallback', () {
    final value = FirestoreSessionSyncService.resolveSessionId(
      session: session(sessionId: 'stable-session-uuid'),
      fallbackSessionId: '1',
    );

    expect(value, 'stable-session-uuid');
  });

  test('legacy numeric session id remains unchanged', () {
    final legacy = session();
    final value = FirestoreSessionSyncService.resolveSessionId(
      session: legacy,
      fallbackSessionId: '42',
    );
    final payload = FirestoreSessionSyncService.instance.mapSessionToFirestore(
      sessionId: '42',
      session: legacy,
      cloudDogId: 'cloud-dog-1',
    );

    expect(value, '42');
    expect(payload['id'], '42');
    expect(payload['sessionId'], '42');
  });

  test('Firestore payload preserves model creator and stable id', () {
    final payload = FirestoreSessionSyncService.instance.mapSessionToFirestore(
      sessionId: 'legacy-local-key',
      session: session(
        sessionId: 'stable-session-uuid',
        createdByUserId: 'original-creator',
      ),
      cloudDogId: 'cloud-dog-1',
    );

    expect(payload['id'], 'stable-session-uuid');
    expect(payload['sessionId'], 'stable-session-uuid');
    expect(payload['createdByUserId'], 'original-creator');
  });

  test('cloud mapping without edit writes an explicit reset tombstone', () {
    final payload =
        FirestoreSessionSyncService.instance.mapSessionToFirestoreWithTrackEdit(
      sessionId: 'session-1',
      session: session(sessionId: 'session-1'),
      cloudDogId: 'cloud-dog-1',
      trackEdit: null,
    );

    final tombstone = payload['trackEdit'] as Map<String, dynamic>;
    expect(tombstone['schemaVersion'], 1);
    expect(tombstone['deletedAt'], isA<Timestamp>());
    expect(tombstone['updatedAt'], isA<Timestamp>());
  });

  test('cloud mapping embeds complete SessionTrackEdit metadata', () {
    final edit = SessionTrackEdit(
      sessionId: 'session-1',
      sourceTrackId: 'track-1',
      startIndexInclusive: 10,
      endIndexExclusive: 20,
      startTimeAnchor: DateTime.utc(2026, 1, 1, 10),
      endTimeAnchor: DateTime.utc(2026, 1, 1, 11),
      sourcePointCount: 30,
      sourceFingerprint: 'fingerprint',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedByUserId: 'editor-1',
    );

    final payload =
        FirestoreSessionSyncService.instance.mapSessionToFirestoreWithTrackEdit(
      sessionId: 'session-1',
      session: session(sessionId: 'session-1'),
      cloudDogId: 'cloud-dog-1',
      trackEdit: edit,
    );
    final cloudEdit = payload['trackEdit'] as Map<String, dynamic>;

    expect(cloudEdit['sourceTrackId'], 'track-1');
    expect(cloudEdit['startIndexInclusive'], 10);
    expect(cloudEdit['endIndexExclusive'], 20);
    expect(cloudEdit['sourceFingerprint'], 'fingerprint');
    expect(cloudEdit['updatedAt'], isA<Timestamp>());
  });
}
