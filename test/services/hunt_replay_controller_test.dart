import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/services/effective_track_resolver.dart';
import 'package:jakthund_app/services/hunt_replay_controller.dart';
import 'package:jakthund_app/pages/hunt_replay_page.dart';

void main() {
  GpsPoint point(int seconds, {double? lat, double? lon}) => GpsPoint(
        lat: lat ?? seconds.toDouble(),
        lon: lon ?? seconds.toDouble(),
        time: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
      );

  test('timeline interpolates location from GPS timestamps', () {
    final timeline = HuntReplayTimeline([
      point(0, lat: 60, lon: 10),
      point(10, lat: 61, lon: 12),
    ]);

    final frame = timeline.frameAt(const Duration(seconds: 5))!;
    expect(frame.latitude, 60.5);
    expect(frame.longitude, 11);
    expect(frame.elapsed, const Duration(seconds: 5));
  });

  test('effective trimmed points define replay start and end', () {
    final raw = Track(
      id: 'track',
      createdAt: DateTime.utc(2026),
      source: 'test',
      points: [point(0), point(10), point(20), point(30)],
    );
    final original = List<GpsPoint>.from(raw.points);
    final edit = SessionTrackEdit(
      sessionId: 'session',
      sourceTrackId: raw.id,
      startIndexInclusive: 1,
      endIndexExclusive: 3,
      startTimeAnchor: raw.points[1].time,
      endTimeAnchor: raw.points[2].time,
      sourcePointCount: raw.points.length,
      sourceFingerprint: EffectiveTrackResolver.fingerprint(raw),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    final effective = const EffectiveTrackResolver().resolve(raw, edit).points;
    final replay = HuntReplayController(effective);
    expect(replay.frame!.latitude, raw.points[1].lat);
    replay.seekToProgress(1);
    expect(replay.frame!.latitude, raw.points[2].lat);
    expect(raw.points, orderedEquals(original));
    replay.dispose();
  });

  test('play pause speed seek end and restart are safe', () {
    for (final speed in HuntReplayController.supportedSpeeds) {
      final replay = HuntReplayController([point(0), point(100)]);
      replay.setSpeed(speed);
      replay.play();
      replay.advanceBy(const Duration(seconds: 1));
      expect(replay.elapsed.inSeconds, speed.toInt());
      replay.pause();
      final paused = replay.elapsed;
      replay.advanceBy(const Duration(seconds: 5));
      expect(replay.elapsed, paused);

      replay.seekToProgress(0.5);
      expect(replay.elapsed, const Duration(seconds: 50));
      expect(replay.frame!.latitude, 50);
      replay.play();
      replay.advanceBy(const Duration(seconds: 100));
      expect(replay.elapsed, replay.totalDuration);
      expect(replay.isPlaying, isFalse);
      replay.play();
      expect(replay.elapsed, Duration.zero);
      replay.dispose();
    }
  });

  test('one point and bad timestamps are safe', () {
    final onePoint = HuntReplayTimeline([point(10)]);
    expect(onePoint.totalDuration, Duration.zero);
    expect(onePoint.frameAt(Duration.zero)!.latitude, 10);

    final bad = HuntReplayTimeline([
      point(10),
      point(10, lat: 11),
      point(5, lat: 12),
      point(20, lat: 13),
    ]);
    expect(bad.totalDuration, const Duration(seconds: 10));
    expect(bad.frameAt(const Duration(seconds: 5)), isNotNull);
  });

  test('empty timeline is safe', () {
    final replay = HuntReplayController(const []);
    replay.play();
    replay.seekToProgress(1);
    expect(replay.frame, isNull);
    expect(replay.isPlaying, isFalse);
    replay.dispose();
  });

  test('duration formatting is timezone independent', () {
    expect(
      formatReplayDuration(const Duration(hours: 2, minutes: 47, seconds: 12)),
      '02:47:12',
    );
  });

  test('approximately 3000 points initialize and seek', () {
    final points = List.generate(3001, point);
    final replay = HuntReplayController(points);
    replay.seekToProgress(0.75);
    expect(replay.frame, isNotNull);
    expect(replay.elapsed, const Duration(seconds: 2250));
    replay.dispose();
  });

  testWidgets('dispose during playback leaves no timer exception',
      (tester) async {
    final replay = HuntReplayController([point(0), point(100)]);
    replay.play();
    replay.dispose();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
