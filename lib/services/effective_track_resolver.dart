import 'dart:collection';

import '../models/gps_point.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';

class EffectiveTrackResult {
  const EffectiveTrackResult({
    required this.points,
    required this.editApplied,
    this.fallbackReason,
  });

  final List<GpsPoint> points;
  final bool editApplied;
  final String? fallbackReason;
}

class EffectiveTrackResolver {
  const EffectiveTrackResolver();

  EffectiveTrackResult resolve(Track rawTrack, SessionTrackEdit? edit) {
    if (edit == null) return _raw(rawTrack);
    final reason = validationError(rawTrack, edit);
    if (reason != null) return _raw(rawTrack, reason: reason);
    return EffectiveTrackResult(
      points: UnmodifiableListView<GpsPoint>(rawTrack.points.sublist(
        edit.startIndexInclusive,
        edit.endIndexExclusive,
      )),
      editApplied: true,
    );
  }

  String? validationError(Track rawTrack, SessionTrackEdit edit) {
    if (edit.schemaVersion != SessionTrackEdit.currentSchemaVersion) {
      return 'unsupportedSchemaVersion';
    }
    if (edit.sourceTrackId != rawTrack.id) return 'sourceTrackIdMismatch';
    if (edit.sourcePointCount != rawTrack.points.length) {
      return 'sourcePointCountMismatch';
    }
    if (edit.sourceFingerprint != fingerprint(rawTrack)) {
      return 'sourceFingerprintMismatch';
    }
    if (edit.startIndexInclusive < 0) return 'startBeforeZero';
    if (edit.endIndexExclusive > rawTrack.points.length) {
      return 'endAfterPointCount';
    }
    if (edit.startIndexInclusive >= edit.endIndexExclusive) {
      return 'emptyOrReversedRange';
    }
    if (rawTrack.points[edit.startIndexInclusive].time.toUtc() !=
        edit.startTimeAnchor.toUtc()) {
      return 'startTimeAnchorMismatch';
    }
    if (rawTrack.points[edit.endIndexExclusive - 1].time.toUtc() !=
        edit.endTimeAnchor.toUtc()) {
      return 'endTimeAnchorMismatch';
    }
    return null;
  }

  static String fingerprint(Track track) {
    // FNV-1a 32-bit keeps the calculation deterministic on native and web.
    const offset = 0x811c9dc5;
    const prime = 0x01000193;
    const mask = 0xffffffff;
    var hash = offset;
    void add(String value) {
      for (final byte in value.codeUnits) {
        hash ^= byte;
        hash = (hash * prime) & mask;
      }
      hash ^= 0xff;
      hash = (hash * prime) & mask;
    }

    add(track.id);
    add(track.points.length.toString());
    for (final point in track.points) {
      add(point.lat.toStringAsPrecision(17));
      add(point.lon.toStringAsPrecision(17));
      add(point.time.toUtc().microsecondsSinceEpoch.toString());
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  EffectiveTrackResult _raw(Track track, {String? reason}) =>
      EffectiveTrackResult(
        points: UnmodifiableListView<GpsPoint>(track.points),
        editApplied: false,
        fallbackReason: reason,
      );
}
