import '../models/gps_point.dart';
import '../models/hunt_event.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';
import 'hunt_event_track_resolver.dart';

class HuntReplayEvent {
  const HuntReplayEvent({
    required this.event,
    required this.effectiveTrackPointIndex,
    required this.point,
    required this.elapsed,
  });

  final HuntEvent event;
  final int effectiveTrackPointIndex;
  final GpsPoint point;
  final Duration elapsed;
}

class HuntReplayEventResolver {
  const HuntReplayEventResolver();

  List<HuntReplayEvent> resolve({
    required Track rawTrack,
    required SessionTrackEdit? edit,
    required Iterable<HuntEvent> events,
  }) {
    const trackResolver = HuntEventTrackResolver();
    final selection = trackResolver.selection(rawTrack, edit);
    if (selection.points.isEmpty) return const [];
    final firstMicros =
        selection.points.first.time.toUtc().microsecondsSinceEpoch;
    final resolved = <HuntReplayEvent>[];

    for (final event in events) {
      if (!trackResolver.isVisibleOnEffectiveTrack(
        event: event,
        rawTrack: rawTrack,
        edit: edit,
      )) {
        continue;
      }
      final rawIndex = event.trackPointIndex;
      if (rawIndex == null) continue;
      final effectiveIndex = rawIndex - selection.rawStartIndex;
      if (effectiveIndex < 0 || effectiveIndex >= selection.points.length) {
        continue;
      }
      final point = selection.points[effectiveIndex];
      final offsetMicros =
          point.time.toUtc().microsecondsSinceEpoch - firstMicros;
      resolved.add(
        HuntReplayEvent(
          event: event,
          effectiveTrackPointIndex: effectiveIndex,
          point: point,
          elapsed: Duration(
            microseconds: offsetMicros < 0 ? 0 : offsetMicros,
          ),
        ),
      );
    }

    resolved.sort((a, b) {
      final byTime = a.elapsed.compareTo(b.elapsed);
      return byTime != 0 ? byTime : a.event.id.compareTo(b.event.id);
    });
    return List.unmodifiable(resolved);
  }
}
