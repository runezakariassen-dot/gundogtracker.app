import '../models/gps_point.dart';
import '../models/hunt_event.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';
import 'effective_track_resolver.dart';

class HuntEventTrackSelection {
  const HuntEventTrackSelection({
    required this.points,
    required this.rawStartIndex,
  });

  final List<GpsPoint> points;
  final int rawStartIndex;

  int rawIndexForEffectiveIndex(int index) {
    if (index < 0 || index >= points.length) {
      throw RangeError.index(index, points, 'index');
    }
    return rawStartIndex + index;
  }
}

class HuntEventTrackResolver {
  const HuntEventTrackResolver();

  HuntEventTrackSelection selection(Track rawTrack, SessionTrackEdit? edit) {
    final effective = const EffectiveTrackResolver().resolve(rawTrack, edit);
    final validEdit = edit != null && effective.editApplied;
    return HuntEventTrackSelection(
      points: effective.points,
      rawStartIndex: validEdit ? edit.startIndexInclusive : 0,
    );
  }

  bool isVisibleOnEffectiveTrack({
    required HuntEvent event,
    required Track rawTrack,
    required SessionTrackEdit? edit,
  }) {
    if (event.deletedAt != null) return false;
    if (event.sourceTrackId != null && event.sourceTrackId != rawTrack.id) {
      return false;
    }
    final index = event.trackPointIndex;
    if (index == null) return event.latitude != null && event.longitude != null;
    if (index < 0 || index >= rawTrack.points.length) return false;
    final effective = const EffectiveTrackResolver().resolve(rawTrack, edit);
    if (!effective.editApplied || edit == null) return true;
    return index >= edit.startIndexInclusive && index < edit.endIndexExclusive;
  }
}
