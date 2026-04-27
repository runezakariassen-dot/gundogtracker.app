// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/milestones/milestone_evaluator.dart';
import 'package:jakthund_app/domain/milestones/milestone_service.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';
import 'package:jakthund_app/domain/repositories/hunt_session_repository.dart';
import 'package:jakthund_app/models/achieved_milestone.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_milestones_');
    HivePathService.setOverridePathForTesting(tempDir.path);
    HiveLifecycleService.resetForTesting();
    await initDomainLayer();
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    await tempDir.delete(recursive: true);
  });

  test('Milestone flows do not write to Dog.achievedMilestones', () async {
    final dogsBox = Hive.box<Dog>(dogsBoxName);
    await dogsBox.clear();
    final dog = Dog(
      name: 'Legacy',
      dogKey: 'legacy',
      regNrDisplay: '000',
      achievedMilestones: [
        AchievedMilestone(id: 'legacy_point', achievedAt: DateTime.utc(2023)),
      ],
    );
    final key = await dogsBox.add(dog);

    final settingsBox = Hive.box<dynamic>(appSettingsBoxName);
    await settingsBox.put(dogMilestoneStateMigrationKey, false);
    await migrateDogMilestonesToStateIfNeeded();

    final stateRepo = DogMilestoneStateRepository();
    final migratedState = await stateRepo.getOrCreate(dog.id);
    expect(
      migratedState.achievedIds,
      contains('legacy_point'),
    );

    final sessionDate = DateTime.utc(2024, 5, 5);
    final service = MilestoneService(
      evaluator: evaluateMilestones,
      milestoneStateRepository: DogMilestoneStateRepository(),
      huntSessionRepository: _FakeHuntSessionRepository([
        HuntSession(
          dogId: dog.id,
          dateTime: sessionDate,
          location: '',
          durationMinutes: 1,
          birdsSeen: 0,
          points: 0,
          flushes: 0,
          notes: '',
        ),
      ]),
    );

    await service.evaluateForDog(
      dog.id,
      sessionDateTime: sessionDate,
    );

    final storedDog = dogsBox.get(key);
    expect(storedDog, isNotNull);
    expect(
      storedDog!.achievedMilestones.map((item) => item.id),
      equals(dog.achievedMilestones.map((item) => item.id)),
    );
  });

  test(
      'MilestoneService writes only to DogMilestoneState when awarding milestone',
      () async {
    final dogsBox = Hive.box<Dog>(dogsBoxName);
    await dogsBox.clear();
    final dog = Dog(
      name: 'Canonical',
      dogKey: 'canonical',
      regNrDisplay: '111',
    );
    final key = await dogsBox.add(dog);

    final sessionDate = DateTime.utc(2024, 6, 1);
    final service = MilestoneService(
      evaluator: evaluateMilestones,
      milestoneStateRepository: DogMilestoneStateRepository(),
      huntSessionRepository: _FakeHuntSessionRepository([
        HuntSession(
          dogId: dog.id,
          dateTime: sessionDate,
          location: '',
          durationMinutes: 1,
          birdsSeen: 0,
          points: 1,
          flushes: 0,
          notes: '',
        ),
      ]),
    );

    final newIds = await service.evaluateForDog(
      dog.id,
      sessionDateTime: sessionDate,
    );

    expect(newIds, contains(MilestoneId.stands1));

    final stateRepo = DogMilestoneStateRepository();
    final state = await stateRepo.getOrCreate(dog.id);
    expect(state.achievedIds, contains(MilestoneId.stands1));

    final storedDog = dogsBox.get(key);
    expect(storedDog, isNotNull);
    expect(storedDog!.achievedMilestones, isEmpty);
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
  }) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> closeSession(String sessionId, DateTime endedAt) {
    throw UnimplementedError();
  }

  @override
  Future<HuntSession?> getSession(String sessionId) {
    throw UnimplementedError();
  }

  @override
  Future<List<HuntSession>> listSessionsForDog(String dogId) async {
    return _sessions.where((session) => session.dogId == dogId).toList();
  }
}
