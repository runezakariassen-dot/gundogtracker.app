import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/services/effective_track_resolver.dart';
import 'package:jakthund_app/utils/gpx_exporter.dart';

void main() {
  const resolver = EffectiveTrackResolver();

  Track track(int count, {String id = 'track-1', bool duplicateTimes = false}) {
    final start = DateTime.utc(2026, 1, 1, 9);
    return Track(
      id: id,
      createdAt: start,
      source: 'test',
      points: List.generate(
        count,
        (index) => GpsPoint(
          lat: 60 + index / 10000,
          lon: 10 + index / 10000,
          time:
              start.add(Duration(seconds: duplicateTimes ? index ~/ 2 : index)),
        ),
      ),
    );
  }

  SessionTrackEdit editFor(
    Track source, {
    int start = 0,
    int? end,
    String? sourceTrackId,
    int? sourcePointCount,
  }) {
    final exclusiveEnd = end ?? source.points.length;
    return SessionTrackEdit(
      sessionId: 'session-uuid',
      sourceTrackId: sourceTrackId ?? source.id,
      startIndexInclusive: start,
      endIndexExclusive: exclusiveEnd,
      startTimeAnchor: source.points[start].time,
      endTimeAnchor: source.points[exclusiveEnd - 1].time,
      sourcePointCount: sourcePointCount ?? source.points.length,
      sourceFingerprint: EffectiveTrackResolver.fingerprint(source),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  test('no edit returns every raw point without copying or modifying Track',
      () {
    final raw = track(5);
    final before = List<GpsPoint>.from(raw.points);

    final result = resolver.resolve(raw, null);

    expect(result.points, before);
    expect(result.editApplied, isFalse);
    expect(raw.points, orderedEquals(before));
  });

  test('trims start, end, and both using authoritative indexes', () {
    final raw = track(6, duplicateTimes: true);

    expect(resolver.resolve(raw, editFor(raw, start: 2)).points,
        raw.points.sublist(2));
    expect(resolver.resolve(raw, editFor(raw, end: 4)).points,
        raw.points.sublist(0, 4));
    expect(
      resolver.resolve(raw, editFor(raw, start: 1, end: 5)).points,
      raw.points.sublist(1, 5),
    );
  });

  test('supports one- and two-point ranges', () {
    final one = track(1);
    final two = track(2);

    expect(resolver.resolve(one, editFor(one)).points, hasLength(1));
    expect(resolver.resolve(two, editFor(two, start: 1)).points,
        [two.points.last]);
  });

  test('invalid range and source mismatches safely fall back to raw Track', () {
    final raw = track(4);
    final valid = editFor(raw, start: 1, end: 3);
    final invalidRange = SessionTrackEdit(
      sessionId: valid.sessionId,
      sourceTrackId: valid.sourceTrackId,
      startIndexInclusive: 3,
      endIndexExclusive: 3,
      startTimeAnchor: raw.points[3].time,
      endTimeAnchor: raw.points[2].time,
      sourcePointCount: valid.sourcePointCount,
      sourceFingerprint: valid.sourceFingerprint,
      createdAt: valid.createdAt,
      updatedAt: valid.updatedAt,
    );

    expect(resolver.resolve(raw, invalidRange).points, raw.points);
    expect(
      resolver
          .resolve(raw, editFor(raw, sourceTrackId: 'other'))
          .fallbackReason,
      'sourceTrackIdMismatch',
    );
    expect(
      resolver.resolve(raw, editFor(raw, sourcePointCount: 99)).fallbackReason,
      'sourcePointCountMismatch',
    );
  });

  test('large Garmin-sized synthetic Track resolves deterministically', () {
    final raw = track(3000);
    final result = resolver.resolve(raw, editFor(raw, start: 100, end: 2900));

    expect(result.points, hasLength(2800));
    expect(result.points.first, same(raw.points[100]));
    expect(result.points.last, same(raw.points[2899]));
  });

  test('effective GPX export contains only trimmed points', () {
    final raw = track(5);
    final effective = resolver.resolve(raw, editFor(raw, start: 1, end: 4));

    final gpx =
        GPXExporter.exportToGpx(trackName: 'trimmed', points: effective.points);

    expect('<trkpt'.allMatches(gpx), hasLength(3));
    expect(gpx, isNot(contains(raw.points.first.time.toIso8601String())));
    expect(raw.points, hasLength(5));
  });
}
