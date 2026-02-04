import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/domain_di.dart';
import 'package:jakthund_app/domain/domain_errors.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/models/ownership_transfer.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/services/user_identity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Dog> dogsBox;
  late Box<DogMembership> membershipsBox;
  late Box<OwnershipTransfer> transfersBox;
  late Box<SyncTask> syncTasksBox;
  late Box<dynamic> settingsBox;

  void _registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_owner_');
    Hive.init(tempDir.path);

    _registerAdapter(DogAdapter());
    _registerAdapter(DogSexAdapter());
    _registerAdapter(DogMembershipAdapter());
    _registerAdapter(RoleAdapter());
    _registerAdapter(StatusAdapter());
    _registerAdapter(OwnershipTransferAdapter());
    _registerAdapter(SyncTaskAdapter());
    _registerAdapter<SyncStatus>(SyncStatusAdapter());

    dogsBox = await Hive.openBox<Dog>(dogsBoxName);
    membershipsBox = await Hive.openBox<DogMembership>(dogMembershipsBoxName);
    transfersBox =
        await Hive.openBox<OwnershipTransfer>(ownershipTransfersBoxName);
    syncTasksBox = await Hive.openBox<SyncTask>(syncTasksBoxName);
    settingsBox = await Hive.openBox<dynamic>(appSettingsBoxName);

    await dogsBox.clear();
    await membershipsBox.clear();
    await transfersBox.clear();
    await syncTasksBox.clear();
    await settingsBox.clear();
  });

  tearDown(() async {
    await dogsBox.close();
    await membershipsBox.close();
    await transfersBox.close();
    await syncTasksBox.close();
    await settingsBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('initiate and accept transfer updates roles', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO300/45',
      name: 'Bella',
    );

    final service = DomainDi.ownershipService(identityService: identity);
    final transfer = await service.initiateTransfer(dog.dogKey, 'new-owner');

    expect(transfer.status, Status.pending);

    await identity.setCurrentUserId('new-owner');
    await service.acceptTransfer(transfer.transferId);

    final updatedDog = dogsBox
        .values
        .firstWhere((entry) => entry.dogKey == dog.dogKey, orElse: () => dog);
    expect(updatedDog.ownerUserId, 'new-owner');

    final memberships = dogMembershipsBox();
    final newOwnerMembership = memberships.get('${dog.dogKey}::new-owner');
    final oldOwnerMembership = memberships.get('${dog.dogKey}::owner');

    expect(newOwnerMembership, isNotNull);
    expect(newOwnerMembership!.role, Role.owner);
    expect(newOwnerMembership.status, Status.active);

    expect(oldOwnerMembership, isNotNull);
    expect(oldOwnerMembership!.role, Role.editor);
    expect(oldOwnerMembership.status, Status.active);

    final storedTransfer = ownershipTransfersBox().get(transfer.transferId);
    expect(storedTransfer, isNotNull);
    expect(storedTransfer!.status, Status.accepted);
  });

  test('non-owner cannot initiate transfer', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO301/45',
      name: 'Nala',
    );

    await identity.setCurrentUserId('member');
    final service = DomainDi.ownershipService(identityService: identity);

    await expectLater(
      service.initiateTransfer(dog.dogKey, 'new-owner'),
      throwsA(
        isA<TransferException>()
            .having((e) => e.code, 'code', TransferError.notOwner),
      ),
    );
  });

  test('only recipient can accept transfer', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO302/45',
      name: 'Sora',
    );

    final service = DomainDi.ownershipService(identityService: identity);
    final transfer = await service.initiateTransfer(dog.dogKey, 'new-owner');

    await identity.setCurrentUserId('other');
    await expectLater(
      service.acceptTransfer(transfer.transferId),
      throwsA(
        isA<TransferException>()
            .having((e) => e.code, 'code', TransferError.notRecipient),
      ),
    );
  });

  test('expired transfer is rejected and marked expired', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO303/45',
      name: 'Pia',
    );

    final transfer = OwnershipTransfer(
      transferId: 'transfer-expired',
      dogKey: dog.dogKey,
      fromUserId: 'owner',
      toUserId: 'new-owner',
      status: Status.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      expiresAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    await ownershipTransfersBox().put(transfer.transferId, transfer);

    await identity.setCurrentUserId('new-owner');
    await expectLater(
      DomainDi.ownershipService(identityService: identity)
          .acceptTransfer(transfer.transferId),
      throwsA(
        isA<TransferException>()
            .having((e) => e.code, 'code', TransferError.transferExpired),
      ),
    );

    final stored = ownershipTransfersBox().get(transfer.transferId);
    expect(stored, isNotNull);
    expect(stored!.status, Status.expired);
  });

  test('only owner can cancel transfer', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO304/45',
      name: 'Kira',
    );

    final service = DomainDi.ownershipService(identityService: identity);
    final transfer = await service.initiateTransfer(dog.dogKey, 'new-owner');

    await identity.setCurrentUserId('new-owner');
    await expectLater(
      service.cancelTransfer(transfer.transferId),
      throwsA(
        isA<TransferException>()
            .having((e) => e.code, 'code', TransferError.notOwner),
      ),
    );

    await identity.setCurrentUserId('owner');
    await service.cancelTransfer(transfer.transferId);
    final stored = ownershipTransfersBox().get(transfer.transferId);
    expect(stored, isNotNull);
    expect(stored!.status, Status.cancelled);
  });
}
