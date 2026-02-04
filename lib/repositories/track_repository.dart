import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/hive_boxes.dart';
import '../models/track.dart';

class TrackRepository {
  Box<Track> _box() => tracksBox();

  Future<Track?> getTrack(String trackId) async {
    return _box().get(trackId);
  }

  Future<void> upsertTrack(Track track, {bool downsampled = false}) async {
    await _box().put(track.id, track);
    final stored = _box().get(track.id);
    final storedPoints = stored?.points.length ?? 0;
    debugPrint(
      '[TRACK] upsert trackId=${track.id} points=${track.points.length} '
      'downsampled=$downsampled stored=$storedPoints',
    );
    if (stored == null) {
      debugPrint('[TRACK] failed to persist trackId=${track.id}');
    }
  }

  Future<void> deleteTrack(String trackId) async {
    await _box().delete(trackId);
  }
}
