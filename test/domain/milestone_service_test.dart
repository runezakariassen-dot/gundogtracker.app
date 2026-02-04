import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/domain/milestones/milestone_evaluator.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/milestones/milestone_service.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';
import 'package:jakthund_app/domain/repositories/hunt_session_repository.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/models/hunt_session.dart';

void main() {
  test('MilestoneService awards stands tiers for points', () async {
    final sessionDate = DateTime.utc(2024, 1, 1);
    final service = MilestoneService(
      evaluator: evaluateMilestones,
      milestoneStateRepository: _InMemoryDogMilestoneStateRepository(),
      huntSessionRepository: _FakeHuntSessionRepository([
        HuntSession(
          dogId: 'dog-1',
          dateTime: sessionDate,
          location: '',
          durationMinutes: 5,
          birdsSeen: 0,
          points: 220,
          flushes: 0,
          notes: '',
        ),
      ]),
    );

    final newIds = await service.evaluateForDog(
      'dog-1',
      sessionDateTime: sessionDate,
    );
    expect(newIds, contains(MilestoneId.stands100));
    expect(newIds, contains(MilestoneId.stands200));
  });

  test('MilestoneService stops stand tiers at next milestone', () async {
    final sessionDate = DateTime.utc(2024, 1, 2);
    final service = MilestoneService(
      evaluator: evaluateMilestones,
      milestoneStateRepository: _InMemoryDogMilestoneStateRepository(),
      huntSessionRepository: _FakeHuntSessionRepository([
        HuntSession(
          dogId: 'dog-2',
          dateTime: sessionDate,
          location: '',
          durationMinutes: 5,
          birdsSeen: 0,
          points: 250,
          flushes: 0,
          notes: '',
        ),
      ]),
    );

    final newIds = await service.evaluateForDog(
      'dog-2',
      sessionDateTime: sessionDate,
    );

    const expected = [
      MilestoneId.stands1,
      MilestoneId.stands10,
      MilestoneId.stands25,
      MilestoneId.stands50,
      MilestoneId.stands100,
      MilestoneId.stands200,
    ];
    for (final id in expected) {
      expect(newIds, contains(id));
    }
    expect(newIds, isNot(contains(MilestoneId.stands300)));
  });
}

class _FakeHuntSessionRepository implements HuntSessionRepository {
  _FakeHuntSessionRepository(this._sessions);

  final List<HuntSession> _sessions;

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
    return 'session-${_sessions.length}';
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
    throw UnimplementedError();
  }

  @override
  Future<void> closeSession(String sessionId, DateTime endedAt) async {
    throw UnimplementedError();
  }

  @override
  Future<HuntSession?> getSession(String sessionId) async {
    return null;
  }

  @override
  Future<List<HuntSession>> listSessionsForDog(String dogId) async {
    return _sessions.where((session) => session.dogId == dogId).toList();
  }
}

class _InMemoryDogMilestoneStateRepository
    implements DogMilestoneStateRepository {
  final Map<String, DogMilestoneState> _store = {};

  @override
  Future<BackfillResult> backfillFromSessionHistory({
    required Iterable<String> dogIds,
    Box<HuntSession>? sessions,
  }) async {
    return BackfillResult(
      dogsProcessed: dogIds.length,
      sessionsProcessed: 0,
    );
  }
  
  @override
  Future<DogMilestoneState> getOrCreate(String dogId) async {
    return _store.putIfAbsent(
      dogId,
      () => DogMilestoneState(
        dogId: dogId,
        achievedIds: const [],
        lastEvaluatedAt: null,
      ),
    );
  }

  @override
  Future<void> save(DogMilestoneState state) async {
    _store[state.dogId] = state;
  }

  @override
  Future<void> delete(String dogId) async {
    _store.remove(dogId);
  }
}
