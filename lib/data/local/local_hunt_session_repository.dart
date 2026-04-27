import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../data/hive_boxes.dart';
import '../../domain/repositories/hunt_session_repository.dart';
import '../../models/hunt_session.dart';

class LocalHuntSessionRepository implements HuntSessionRepository {
  LocalHuntSessionRepository({Box<HuntSession>? box})
      : _box = box ?? sessionsBox();

  final Box<HuntSession> _box;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> createSession({
    required String dogId,
    required DateTime startedAt,
    String? dogKey,
    String locationName = '',
    int timeActiveSeconds = 0,
    int birdContacts = 0,
    int points = 0,
    int flushes = 0,
    String notes = '',
    int secondaryPoints = 0,
    List<String>? birdSpecies,
    List<String>? mediaPaths,
    String? createdByUserId,
  }) async {
    final sessionId = _uuid.v4();
    final session = HuntSession(
      dogId: dogId,
      dogKey: dogKey,
      dateTime: startedAt,
      location: locationName,
      durationMinutes: _toMinutes(timeActiveSeconds),
      birdsSeen: birdContacts,
      points: points,
      flushes: flushes,
      notes: notes,
      secondaryPoints: secondaryPoints,
      birdSpecies: birdSpecies,
      mediaPaths: mediaPaths,
      createdByUserId: createdByUserId,
    );
    await _box.put(sessionId, session);
    return sessionId;
  }

  @override
  Future<void> updateSession(
    String sessionId, {
    String? locationName,
    int? timeActiveSeconds,
    int? birdContacts,
    int? points,
    int? flushes,
    String? notes,
    int? secondaryPoints,
    List<String>? birdSpecies,
    List<String>? mediaPaths,
  }) async {
    final existing = _box.get(sessionId);
    if (existing == null) {
      throw StateError('Fant ikke okt med id=$sessionId');
    }
    final updated = existing.copyWith(
      location: locationName,
      durationMinutes:
          timeActiveSeconds != null ? _toMinutes(timeActiveSeconds) : null,
      birdsSeen: birdContacts,
      points: points,
      flushes: flushes,
      notes: notes,
      secondaryPoints: secondaryPoints,
      birdSpecies: birdSpecies,
      mediaPaths: mediaPaths,
    );
    await _box.put(sessionId, updated);
  }

  @override
  Future<void> closeSession(String sessionId, DateTime endedAt) async {
    final existing = _box.get(sessionId);
    if (existing == null) {
      throw StateError('Fant ikke okt med id=$sessionId');
    }
    final minutes = endedAt.difference(existing.dateTime).inMinutes;
    final updated = existing.copyWith(
      durationMinutes: minutes < 0 ? 0 : minutes,
    );
    await _box.put(sessionId, updated);
  }

  @override
  Future<HuntSession?> getSession(String sessionId) async {
    final session = _box.get(sessionId);
    if (session == null || session.isDeleted) {
      return null;
    }
    return session;
  }

  @override
  Future<List<HuntSession>> listSessionsForDog(String dogId) async {
    return _box.values
        .where((session) => session.dogId == dogId && !session.isDeleted)
        .toList(growable: false);
  }

  int _toMinutes(int seconds) {
    if (seconds <= 0) {
      return 0;
    }
    return seconds ~/ 60;
  }
}
