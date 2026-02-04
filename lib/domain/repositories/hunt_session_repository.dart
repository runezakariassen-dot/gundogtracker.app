import '../../models/hunt_session.dart';

abstract class HuntSessionRepository {
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
  });

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
  });

  Future<void> closeSession(String sessionId, DateTime endedAt);

  Future<HuntSession?> getSession(String sessionId);
  Future<List<HuntSession>> listSessionsForDog(String dogId);
}
