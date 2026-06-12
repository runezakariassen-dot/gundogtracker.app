import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/dogs/dog_visibility.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/services/account_switch_rehydrator.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('jakthund_account_rehydrate_');
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

  test('rehydrate writes new user cloud dogs and memberships to local Hive',
      () async {
    var pullCalled = false;
    final rehydrator = AccountSwitchRehydrator(
      restoreAccessibleDogsToHive: () async {
        await dogsBox().add(
          Dog(
            id: 'dog-b',
            name: 'Dog B',
            dogKey: 'NO222-45',
            regNrDisplay: 'NO22245/20',
            ownerUserId: 'user-b',
            cloudId: 'cloud-dog-b',
            cloudOwnerUid: 'user-b',
          ),
        );
        await dogMembershipsBox().add(
          DogMembership(
            dogKey: 'NO222-45',
            userId: 'user-b',
            role: Role.owner,
            status: Status.active,
            addedAt: DateTime(2024),
            addedByUserId: 'user-b',
          ),
        );
        return 1;
      },
      pullAllVisibleData: () async {
        pullCalled = true;
      },
    );

    expect(dogsBox(), isEmpty);
    expect(dogMembershipsBox(), isEmpty);

    await rehydrator.rehydrateForCurrentUser();

    expect(pullCalled, isTrue);
    expect(dogsBox(), hasLength(1));
    expect(dogMembershipsBox(), hasLength(1));
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
  });
}
