import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/dogs/dog_visibility.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_constants.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/services/account_switch_data_clearer.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_account_switch_');
    HivePathService.setOverridePathForTesting(tempDir.path);
    HiveLifecycleService.resetForTesting();
    resetDomainBootstrapForTesting();
    await initDomainLayer();
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    await tempDir.delete(recursive: true);
  });

  test('account switch clears previous user dogs sessions and memberships',
      () async {
    final settings = Hive.box<dynamic>(appSettingsBoxName);
    await settings.put(currentUserIdKey, 'user-a');

    await dogsBox().add(
      Dog(
        id: 'dog-a',
        name: 'Dog A',
        dogKey: 'NO123-45',
        regNrDisplay: 'NO12345/20',
        ownerUserId: 'user-a',
      ),
    );
    await dogMembershipsBox().add(
      DogMembership(
        dogKey: 'NO123-45',
        userId: 'user-b',
        role: Role.owner,
        status: Status.active,
        addedAt: DateTime(2024),
        addedByUserId: 'user-b',
      ),
    );
    await sessionsBox().add(
      HuntSession(
        dogId: 'dog-a',
        dogKey: 'NO123-45',
        dateTime: DateTime(2024),
        location: 'Field',
        durationMinutes: 60,
        birdsSeen: 1,
        points: 1,
        flushes: 0,
        notes: '',
      ),
    );

    expect(
      filterVisibleDogs(
        dogs: dogsBox().values,
        memberships: dogMembershipsBox().values.where(
              (membership) => membership.userId == 'user-b',
            ),
        currentUserId: 'user-b',
      ),
      hasLength(1),
    );

    await AccountSwitchDataClearer.clearUserScopedData(
      oldUid: 'user-a',
      newUid: 'user-b',
    );
    await settings.put(currentUserIdKey, 'user-b');

    expect(dogsBox(), isEmpty);
    expect(sessionsBox(), isEmpty);
    expect(dogMembershipsBox(), isEmpty);
    expect(
      filterVisibleDogs(
        dogs: dogsBox().values,
        memberships: dogMembershipsBox().values.where(
              (membership) => membership.userId == 'user-b',
            ),
        currentUserId: 'user-b',
      ),
      isEmpty,
    );
  });
}
