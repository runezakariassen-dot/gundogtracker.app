import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_constants.dart';
import 'package:jakthund_app/domain/settings/settings_repository.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_repo_');
    HivePathService.setOverridePathForTesting(tempDir.path);
    HiveLifecycleService.resetForTesting();
    registerDomainAdapters();
    await HiveLifecycleService.init();
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  SettingsRepository createRepository() {
    final box = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    return SettingsRepository(box);
  }

  test('user profile is saved and restored after hive restart', () async {
    final repository = createRepository();
    const name = 'Rune Zakariassen';
    const phone = '+47 12345678';
    const email = 'rune@example.com';
    const personalStandGoal = 100;
    const lastCelebratedStandGoal = 100;
    final lastBirthdayGreetingShownDate = DateTime(2026, 4, 28);
    final birthDate = DateTime(1989, 7, 14);

    await repository.setUserProfile(
      UserProfileSettings(
        name: name,
        phone: phone,
        email: email,
        birthDate: birthDate,
        personalStandGoal: personalStandGoal,
      ),
    );
    await repository
        .setLastCelebratedPersonalStandGoal(lastCelebratedStandGoal);
    await repository.setLastBirthdayGreetingShownDate(
      lastBirthdayGreetingShownDate,
    );

    final saved = repository.getUserProfile();
    expect(saved.name, name);
    expect(saved.phone, phone);
    expect(saved.email, email);
    expect(saved.birthDate, birthDate);
    expect(saved.personalStandGoal, personalStandGoal);
    expect(
      repository.getLastCelebratedPersonalStandGoal(),
      lastCelebratedStandGoal,
    );
    expect(
      repository.getLastBirthdayGreetingShownDate(),
      lastBirthdayGreetingShownDate,
    );

    await Hive.close();
    HiveLifecycleService.resetForTesting();
    registerDomainAdapters();
    await HiveLifecycleService.init();

    final reloaded = createRepository().getUserProfile();
    expect(reloaded.name, name);
    expect(reloaded.phone, phone);
    expect(reloaded.email, email);
    expect(reloaded.birthDate, birthDate);
    expect(reloaded.personalStandGoal, personalStandGoal);
    expect(
      createRepository().getLastCelebratedPersonalStandGoal(),
      lastCelebratedStandGoal,
    );
    expect(
      createRepository().getLastBirthdayGreetingShownDate(),
      lastBirthdayGreetingShownDate,
    );
  });

  test(
      'user profile allows null birth date, empty contact fields and empty goal',
      () async {
    final repository = createRepository();

    await repository.setUserProfile(
      const UserProfileSettings(
        name: 'Tester',
        phone: '',
        email: '   ',
        birthDate: null,
        personalStandGoal: 0,
      ),
    );

    final profile = repository.getUserProfile();
    expect(profile.name, 'Tester');
    expect(profile.phone, isNull);
    expect(profile.email, isNull);
    expect(profile.birthDate, isNull);
    expect(profile.personalStandGoal, isNull);
    expect(repository.getLastCelebratedPersonalStandGoal(), isNull);
    expect(repository.getLastBirthdayGreetingShownDate(), isNull);
  });

  test('profile data is isolated per user id in app settings', () async {
    final box = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);

    await box.put(currentUserIdKey, 'user-a');
    final repoA = SettingsRepository(box);
    await repoA.setUserProfile(
      UserProfileSettings(
        name: 'Zakka-OAS',
        birthDate: DateTime(1990, 5, 17),
      ),
    );

    await box.put(currentUserIdKey, 'user-b');
    final repoB = SettingsRepository(box);
    final profileB = repoB.getUserProfile();

    expect(profileB.name, isNull);
    expect(profileB.birthDate, isNull);

    await repoB.setUserProfile(
      UserProfileSettings(
        name: 'Bruker B',
        birthDate: DateTime(1992, 7, 1),
      ),
    );

    await box.put(currentUserIdKey, 'user-a');
    final reloadedA = SettingsRepository(box).getUserProfile();
    expect(reloadedA.name, 'Zakka-OAS');
    expect(reloadedA.birthDate, DateTime(1990, 5, 17));

    await box.put(currentUserIdKey, 'user-b');
    final reloadedB = SettingsRepository(box).getUserProfile();
    expect(reloadedB.name, 'Bruker B');
    expect(reloadedB.birthDate, DateTime(1992, 7, 1));
  });
}
