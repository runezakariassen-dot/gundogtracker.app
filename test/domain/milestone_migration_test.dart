import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';
import 'package:jakthund_app/models/achieved_milestone.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/models/hunt_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_migration_');
    Hive.init(tempDir.path);
    registerDomainAdapters();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('migrates Dog.achievedMilestones into DogMilestoneState once', () async {
    final dogsBox = await Hive.openBox<Dog>(dogsBoxName);
    final dog = Dog(
      name: 'Fido',
      dogKey: 'fido',
      regNrDisplay: '123',
      achievedMilestones: [
        AchievedMilestone(
          id: MilestoneId.sessions10,
          achievedAt: DateTime.utc(2023),
        ),
        AchievedMilestone(
          id: 'first_point',
          achievedAt: DateTime.utc(2023),
        ),
      ],
    );
    await dogsBox.add(dog);
    await dogsBox.close();

    final settingsBox = await Hive.openBox<dynamic>(appSettingsBoxName);
    await Hive.openBox<Dog>(dogsBoxName);
    await Hive.openBox<DogMilestoneState>(dogMilestoneStateBoxName);
    await Hive.openBox<HuntSession>(sessionsBoxName);

    final stateRepo = DogMilestoneStateRepository();

    await migrateDogMilestonesToStateIfNeeded();
    final migratedState = await stateRepo.getOrCreate(dog.id);

    expect(
      migratedState.achievedIds.toSet(),
      containsAll(<String>{MilestoneId.sessions10, MilestoneId.stands1}),
    );
    expect(
      migratedState.achievedAt[MilestoneId.sessions10],
      equals(DateTime.utc(2023)),
    );
    expect(
      migratedState.achievedAt[MilestoneId.stands1],
      equals(DateTime.utc(2023)),
    );

    expect(settingsBox.get(dogMilestoneStateMigrationKey), isTrue);
    await settingsBox.put(dogMilestoneStateMigrationKey, false);
    await migrateDogMilestonesToStateIfNeeded();

    final rerunState = await stateRepo.getOrCreate(dog.id);
    expect(rerunState.achievedIds.toSet(),
        equals(migratedState.achievedIds.toSet()));
  });
}
