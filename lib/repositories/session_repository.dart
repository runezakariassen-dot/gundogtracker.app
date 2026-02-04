import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import '../models/gps_point.dart';
import '../models/hunt_session.dart';
import '../models/track.dart';
import 'track_repository.dart';

class SessionRepository {
  SessionRepository({TrackRepository? trackRepository})
      : _trackRepository = trackRepository ?? TrackRepository();

  final TrackRepository _trackRepository;
  final Uuid _uuid = const Uuid();

  Box<HuntSession> _box() => sessionsBox();

  Future<void> replaceTrackForSession(
    String sessionId,
    List<GpsPoint> points, {
    required String source,
  }) async {
    final box = _box();
    final dynamic key = _resolveKey(sessionId);
    final session = box.get(key);
    if (session == null) {
      throw StateError('Kunne ikke finne økt med id=$sessionId');
    }

    final oldTrackId = session.trackId;
    final newTrack = Track(
      id: _uuid.v4(),
      createdAt: DateTime.now().toUtc(),
      source: source,
      points: points,
    );

    await _trackRepository.upsertTrack(newTrack);

    final updatedSession = session.copyWith(trackId: newTrack.id);
    await box.put(key, updatedSession);

    if (oldTrackId != null) {
      await _trackRepository.deleteTrack(oldTrackId);
    }
  }

  Future<Track?> getTrackForSession(String sessionId) async {
    final session = _box().get(_resolveKey(sessionId));
    final trackId = session?.trackId;
    if (trackId == null) return null;
    return _trackRepository.getTrack(trackId);
  }

  dynamic _resolveKey(String sessionId) {
    final numeric = int.tryParse(sessionId);
    return numeric ?? sessionId;
  }
}
