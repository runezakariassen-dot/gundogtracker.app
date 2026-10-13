import 'package:hive/hive.dart';

import '../data/hive_boxes.dart';
import '../models/session_track_edit.dart';

class SessionTrackEditRepository {
  SessionTrackEditRepository({Box<SessionTrackEdit>? box}) : _box = box;

  final Box<SessionTrackEdit>? _box;

  Box<SessionTrackEdit> get _store => _box ?? sessionTrackEditsBox();

  SessionTrackEdit? get(String sessionId) => _store.get(sessionId);

  Future<void> save(SessionTrackEdit edit) => _store.put(edit.sessionId, edit);

  Future<void> delete(String sessionId) => _store.delete(sessionId);
}
