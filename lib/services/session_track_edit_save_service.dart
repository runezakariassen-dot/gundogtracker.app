import 'package:hive/hive.dart';

import '../data/hive_boxes.dart';
import '../data/local/sync_outbox_service.dart';
import '../models/hunt_session.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';
import '../repositories/session_track_edit_repository.dart';
import 'effective_track_resolver.dart';

class SessionTrackEditSaveService {
  SessionTrackEditSaveService({
    SessionTrackEditRepository? editRepository,
    Box<HuntSession>? sessions,
    SyncOutboxService? outboxService,
  })  : _edits = editRepository ?? SessionTrackEditRepository(),
        _sessions = sessions ?? sessionsBox(),
        _outbox = outboxService ?? SyncOutboxService();

  final SessionTrackEditRepository _edits;
  final Box<HuntSession> _sessions;
  final SyncOutboxService _outbox;

  Future<void> save({
    required Object sessionKey,
    required HuntSession session,
    required Track rawTrack,
    required int startIndexInclusive,
    required int endIndexExclusive,
    required DateTime now,
    String? updatedByUserId,
  }) async {
    final sessionId = stableSessionId(sessionKey, session);
    final current = _edits.get(sessionId);
    if (startIndexInclusive == 0 &&
        endIndexExclusive == rawTrack.points.length) {
      await _edits.delete(sessionId);
    } else {
      await _edits.save(SessionTrackEdit(
        sessionId: sessionId,
        sourceTrackId: rawTrack.id,
        startIndexInclusive: startIndexInclusive,
        endIndexExclusive: endIndexExclusive,
        startTimeAnchor: rawTrack.points[startIndexInclusive].time.toUtc(),
        endTimeAnchor: rawTrack.points[endIndexExclusive - 1].time.toUtc(),
        sourcePointCount: rawTrack.points.length,
        sourceFingerprint: EffectiveTrackResolver.fingerprint(rawTrack),
        createdAt: current?.createdAt ?? now.toUtc(),
        updatedAt: now.toUtc(),
        updatedByUserId: updatedByUserId,
      ));
    }
    await _updateSessionAndEnqueue(sessionKey, session, sessionId, now);
  }

  Future<void> reset({
    required Object sessionKey,
    required HuntSession session,
    required DateTime now,
  }) async {
    final sessionId = stableSessionId(sessionKey, session);
    await _edits.delete(sessionId);
    await _updateSessionAndEnqueue(sessionKey, session, sessionId, now);
  }

  Future<void> _updateSessionAndEnqueue(
    Object sessionKey,
    HuntSession session,
    String sessionId,
    DateTime now,
  ) async {
    final updated = session.copyWith(updatedAt: now.toUtc());
    await _sessions.put(sessionKey, updated);
    await _outbox.enqueueUpsertSession(sessionId, updated);
  }

  static String stableSessionId(Object sessionKey, HuntSession session) {
    final id = session.sessionId?.trim();
    return id != null && id.isNotEmpty ? id : sessionKey.toString();
  }
}
