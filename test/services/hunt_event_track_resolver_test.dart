import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/hunt_event.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/services/effective_track_resolver.dart';
import 'package:jakthund_app/services/hunt_event_track_resolver.dart';

void main() {
  final track = Track(
    id: 'raw-track',
    createdAt: DateTime.utc(2026),
    source: 'test',
    points: List.generate(
      6,
      (index) => GpsPoint(
        lat: 60 + index / 1000,
        lon: 10 + index / 1000,
        time: DateTime.utc(2026, 1, 1, 10, index),
      ),
    ),
  );
  SessionTrackEdit edit(int start, int end) => SessionTrackEdit(
    sessionId: 'session',
    sourceTrackId: track.id,
    startIndexInclusive: start,
    endIndexExclusive: end,
    startTimeAnchor: track.points[start].time,
    endTimeAnchor: track.points[end - 1].time,
    sourcePointCount: track.points.length,
    sourceFingerprint: EffectiveTrackResolver.fingerprint(track),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  HuntEvent eventAt(int index) => HuntEvent(
    id: 'event-$index',
    sessionId: 'session',
    dogId: 'dog',
    type: HuntEventType.stand,
    occurredAt: track.points[index].time,
    sourceTrackId: track.id,
    trackPointIndex: index,
    latitude: track.points[index].lat,
    longitude: track.points[index].lon,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    createdByUserId: 'owner',
  );

  test('untrimmed effective indexes are raw indexes', () {
    final selection = const HuntEventTrackResolver().selection(track, null);
    expect(selection.rawIndexForEffectiveIndex(4), 4);
  });

  test('trimmed selection maps back to raw indexes without mutating Track', () {
    final original = List<GpsPoint>.from(track.points);
    final selection = const HuntEventTrackResolver().selection(
      track,
      edit(2, 5),
    );
    expect(selection.points, hasLength(3));
    expect(selection.rawIndexForEffectiveIndex(0), 2);
    expect(selection.rawIndexForEffectiveIndex(2), 4);
    expect(track.points, orderedEquals(original));
  });

  test('events outside trim hide and reset makes them visible again', () {
    const resolver = HuntEventTrackResolver();
    expect(
      resolver.isVisibleOnEffectiveTrack(
        event: eventAt(3),
        rawTrack: track,
        edit: edit(2, 5),
      ),
      isTrue,
    );
    expect(
      resolver.isVisibleOnEffectiveTrack(
        event: eventAt(1),
        rawTrack: track,
        edit: edit(2, 5),
      ),
      isFalse,
    );
    expect(
      resolver.isVisibleOnEffectiveTrack(
        event: eventAt(1),
        rawTrack: track,
        edit: null,
      ),
      isTrue,
    );
  });
}
