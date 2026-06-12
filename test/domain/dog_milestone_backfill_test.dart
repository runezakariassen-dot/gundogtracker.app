import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_backfill_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(DogMilestoneStateAdapter().typeId)) {
      Hive.registerAdapter(DogMilestoneStateAdapter());
    }
    if (!Hive.isAdapterRegistered(SessionTypeAdapter().typeId)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(HuntSessionAdapter().typeId)) {
      Hive.registerAdapter(HuntSessionAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('backfill records achievedAt when milestone thresholds are hit',
      () async {
    final sessionBox = await Hive.openBox<HuntSession>('sessions_records');
    await sessionBox.add(
      HuntSession(
        dogId: 'dog-1',
        dateTime: DateTime.utc(2023, 10, 1),
        location: '',
        durationMinutes: 20,
        birdsSeen: 0,
        points: 1,
        flushes: 0,
        notes: '',
      ),
    );
    await sessionBox.add(
      HuntSession(
        dogId: 'dog-1',
        dateTime: DateTime.utc(2023, 10, 2),
        location: '',
        durationMinutes: 30,
        birdsSeen: 0,
        points: 2,
        flushes: 0,
        notes: '',
      ),
    );

    final stateBox = await Hive.openBox<DogMilestoneState>('states_records');
    final repository = DogMilestoneStateRepository(box: stateBox);

    await repository.backfillFromSessionHistory(
      dogIds: ['dog-1'],
      sessions: sessionBox,
    );

    final state = await repository.getOrCreate('dog-1');
    expect(state.achievedIds, contains(MilestoneId.stands1));
    expect(state.achievedIds, contains(MilestoneId.sessions1));
    expect(
      state.achievedAt[MilestoneId.stands1],
      equals(DateTime.utc(2023, 10, 1)),
    );
    expect(
      state.achievedAt[MilestoneId.sessions1],
      equals(DateTime.utc(2023, 10, 1)),
    );

    await sessionBox.close();
    await stateBox.close();
  });

  test('backfill moves existing achievedAt to earliest historical session',
      () async {
    final stateBox = await Hive.openBox<DogMilestoneState>('states_existing');
    final existingDate = DateTime.utc(2023, 1, 1);
    final existingState = DogMilestoneState(
      dogId: 'dog-2',
      achievedIds: [MilestoneId.stands1],
      achievedAt: {MilestoneId.stands1: existingDate},
    );
    await stateBox.put('dog-2', existingState);

    final sessionBox = await Hive.openBox<HuntSession>('sessions_existing');
    await sessionBox.add(
      HuntSession(
        dogId: 'dog-2',
        dateTime: DateTime.utc(2023, 2, 1),
        location: '',
        durationMinutes: 25,
        birdsSeen: 0,
        points: 10,
        flushes: 0,
        notes: '',
      ),
    );

    final repository = DogMilestoneStateRepository(box: stateBox);
    await repository.backfillFromSessionHistory(
      dogIds: ['dog-2'],
      sessions: sessionBox,
    );

    final state = await repository.getOrCreate('dog-2');
    expect(
      state.achievedAt[MilestoneId.stands1],
      equals(DateTime.utc(2023, 2, 1)),
    );
    expect(state.achievedIds, contains(MilestoneId.stands10));
    expect(
      state.achievedAt[MilestoneId.stands10],
      equals(DateTime.utc(2023, 2, 1)),
    );

    await sessionBox.close();
    await stateBox.close();
  });
}
