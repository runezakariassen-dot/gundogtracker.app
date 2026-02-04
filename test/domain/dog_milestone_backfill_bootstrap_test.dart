import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_constants.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var _adaptersRegistered = false;

  late Directory tempDir;
  late Box<Dog> dogsBox;
  late Box<dynamic> settingsBox;
  late Box<DogMilestoneState> stateBox;
  late Box<HuntSession> sessionsBox;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('jakthund_backfill_bootstrap_');
    Hive.init(tempDir.path);
    if (!_adaptersRegistered) {
      Hive.registerAdapter(DogAdapter());
      Hive.registerAdapter(DogSexAdapter());
      Hive.registerAdapter(DogMilestoneStateAdapter());
      Hive.registerAdapter(HuntSessionAdapter());
      Hive.registerAdapter(SessionTypeAdapter());
      _adaptersRegistered = true;
    }

    dogsBox = await Hive.openBox<Dog>('dogs_backfill_bootstrap');
    settingsBox = await Hive.openBox<dynamic>(appSettingsBoxName);
    stateBox =
        await Hive.openBox<DogMilestoneState>('dog_milestone_state_bootstrap');
    sessionsBox = await Hive.openBox<HuntSession>(sessionsBoxName);
  });

  tearDown(() async {
    await sessionsBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('repair-run executes when flag true but state empty', () async {
    final dog = Dog(name: 'Rex', dogKey: 'rex', regNrDisplay: '123');
    await dogsBox.add(dog);

    final firstSession = HuntSession(
      dogId: dog.id,
      dateTime: DateTime.utc(2023, 10, 14),
      location: '',
      durationMinutes: 60,
      birdsSeen: 0,
      points: 1,
      flushes: 0,
      notes: '',
    );

    await sessionsBox.clear();
    await sessionsBox.add(firstSession);
    await settingsBox.put(dogMilestoneHistoryBackfillKey, true);

    final repository = _CountingDogMilestoneStateRepository(box: stateBox);

    await ensureDogMilestonesBackfilled(
      dogs: dogsBox.values,
      settingsBox: settingsBox,
      stateRepository: repository,
      huntsessionsBox: sessionsBox,
    );

    expect(repository.backfillCalls, 1);
    final state = await repository.getOrCreate(dog.id);
    expect(state.achievedIds, isNotEmpty);
    expect(state.achievedAt, isNotEmpty);
  });

  test('backfill skipped when flag true and state already populated', () async {
    final dog = Dog(name: 'Zeus', dogKey: 'zeus', regNrDisplay: '321');
    await dogsBox.add(dog);

    await sessionsBox.clear();
    await sessionsBox.add(
      HuntSession(
        dogId: dog.id,
        dateTime: DateTime.utc(2024, 2, 1),
        location: '',
        durationMinutes: 60,
        birdsSeen: 0,
        points: 2,
        flushes: 0,
        notes: '',
      ),
    );
    await settingsBox.put(dogMilestoneHistoryBackfillKey, true);

    final existingState = DogMilestoneState(
      dogId: dog.id,
      achievedIds: [MilestoneId.sessions1],
      achievedAt: {MilestoneId.sessions1: DateTime.utc(2024, 1, 1)},
    );
    await stateBox.put(dog.id, existingState);

    final repository = _CountingDogMilestoneStateRepository(box: stateBox);

    await ensureDogMilestonesBackfilled(
      dogs: dogsBox.values,
      settingsBox: settingsBox,
      stateRepository: repository,
      huntsessionsBox: sessionsBox,
    );

    expect(repository.backfillCalls, 0);
    final state = await repository.getOrCreate(dog.id);
    expect(state.achievedIds, equals(existingState.achievedIds));
  });
}

class _CountingDogMilestoneStateRepository extends DogMilestoneStateRepository {
  _CountingDogMilestoneStateRepository({Box<DogMilestoneState>? box})
      : super(box: box);

  int backfillCalls = 0;

  @override
  Future<BackfillResult> backfillFromSessionHistory({
    required Iterable<String> dogIds,
    Box<HuntSession>? sessions,
  }) async {
    backfillCalls++;
    return super.backfillFromSessionHistory(
      dogIds: dogIds,
      sessions: sessions,
    );
  }
}
