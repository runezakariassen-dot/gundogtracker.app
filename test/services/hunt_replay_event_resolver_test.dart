import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/hunt_event.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/services/effective_track_resolver.dart';
import 'package:jakthund_app/services/hunt_replay_event_resolver.dart';

void main() {
  final points = List.generate(
    5,
    (index) => GpsPoint(
      lat: 60 + index / 1000,
      lon: 10 + index / 1000,
      time: DateTime.utc(2026).add(Duration(seconds: index * 10)),
    ),
  );
  final track = Track(
    id: 'track',
    createdAt: DateTime.utc(2026),
    source: 'test',
    points: points,
  );
  final edit = SessionTrackEdit(
    sessionId: 'session',
    sourceTrackId: track.id,
    startIndexInclusive: 1,
    endIndexExclusive: 4,
    startTimeAnchor: points[1].time,
    endTimeAnchor: points[3].time,
    sourcePointCount: points.length,
    sourceFingerprint: EffectiveTrackResolver.fingerprint(track),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  HuntEvent event(String id, int? rawIndex, {String? sourceTrackId = 'track'}) {
    return HuntEvent(
      id: id,
      sessionId: 'session',
      dogId: 'dog',
      type: HuntEventType.stand,
      occurredAt: DateTime.utc(2026),
      sourceTrackId: sourceTrackId,
      trackPointIndex: rawIndex,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      createdByUserId: 'owner',
    );
  }

  test('maps raw indices into effective positions and filters trim bounds', () {
    final rawBefore = List<GpsPoint>.from(track.points);
    final resolved = const HuntReplayEventResolver().resolve(
      rawTrack: track,
      edit: edit,
      events: [
        event('before', 0),
        event('first', 1),
        event('inside', 2),
        event('last', 3),
        event('after', 4),
        event('invalid', 99),
        event('missing', null),
        event('other-track', 2, sourceTrackId: 'other'),
      ],
    );

    expect(resolved.map((item) => item.event.id), ['first', 'inside', 'last']);
    expect(resolved.map((item) => item.effectiveTrackPointIndex), [0, 1, 2]);
    expect(resolved.map((item) => item.elapsed.inSeconds), [0, 10, 20]);
    expect(track.points, orderedEquals(rawBefore));
  });
}
