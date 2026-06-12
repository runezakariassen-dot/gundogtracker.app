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

  Future<void> seedMembership(DogMembership membership) async {
    await dogMembershipsBox()
        .put('${membership.dogKey}::${membership.userId}', membership);
  }

  void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_owner_');
    Hive.init(tempDir.path);

    registerAdapter(DogAdapter());
    registerAdapter(DogSexAdapter());
    registerAdapter(DogMembershipAdapter());
    registerAdapter(RoleAdapter());
    registerAdapter(StatusAdapter());
    registerAdapter(OwnershipTransferAdapter());
    registerAdapter(SyncTaskAdapter());
    registerAdapter<SyncStatus>(SyncStatusAdapter());

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

    final updatedDog = dogsBox.values
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

  test('owner can change another member role and it persists after reload',
      () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    const dogKey = 'NO400-45';
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'owner',
        role: Role.owner,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'member',
        role: Role.admin,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );

    final service = DomainDi.ownershipService(identityService: identity);
    final updated = await service.updateMembershipRole(
      dogKey: dogKey,
      targetUserId: 'member',
      role: Role.viewer,
    );

    expect(updated.role, Role.viewer);
    expect(
      dogMembershipsBox().get('$dogKey::member')?.role,
      Role.viewer,
    );

    await membershipsBox.close();
    membershipsBox = await Hive.openBox<DogMembership>(dogMembershipsBoxName);

    expect(
      membershipsBox.get('$dogKey::member')?.role,
      Role.viewer,
    );
  });

  test('owner can set member role to administrator', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    const dogKey = 'NO404-45';
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'owner',
        role: Role.owner,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'member',
        role: Role.viewer,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );

    final service = DomainDi.ownershipService(identityService: identity);
    final updated = await service.updateMembershipRole(
      dogKey: dogKey,
      targetUserId: 'member',
      role: Role.admin,
    );

    expect(updated.role, Role.admin);
    expect(dogMembershipsBox().get('$dogKey::member')?.role, Role.admin);
  });

  test('owner can set administrator back to user role', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    const dogKey = 'NO405-45';
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'owner',
        role: Role.owner,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'member',
        role: Role.admin,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );

    final service = DomainDi.ownershipService(identityService: identity);
    final updated = await service.updateMembershipRole(
      dogKey: dogKey,
      targetUserId: 'member',
      role: Role.viewer,
    );

    expect(updated.role, Role.viewer);
    expect(dogMembershipsBox().get('$dogKey::member')?.role, Role.viewer);
  });

  test('administrator cannot set role to owner', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('admin');

    const dogKey = 'NO406-45';
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'admin',
        role: Role.admin,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'member',
        role: Role.viewer,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );

    final service = DomainDi.ownershipService(identityService: identity);

    await expectLater(
      service.updateMembershipRole(
        dogKey: dogKey,
        targetUserId: 'member',
        role: Role.owner,
      ),
      throwsA(
        isA<MembershipRoleException>().having(
          (e) => e.code,
          'code',
          MembershipRoleError.ownerRoleLocked,
        ),
      ),
    );
  });

  test('administrator can change viewer and editor roles but not assign admin',
      () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('admin');

    const dogKey = 'NO401-45';
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'admin',
        role: Role.admin,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'member',
        role: Role.viewer,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );

    final service = DomainDi.ownershipService(identityService: identity);
    final updated = await service.updateMembershipRole(
      dogKey: dogKey,
      targetUserId: 'member',
      role: Role.editor,
    );

    expect(updated.role, Role.editor);

    await expectLater(
      service.updateMembershipRole(
        dogKey: dogKey,
        targetUserId: 'member',
        role: Role.admin,
      ),
      throwsA(
        isA<MembershipRoleException>().having(
          (e) => e.code,
          'code',
          MembershipRoleError.cannotPromoteToAdmin,
        ),
      ),
    );
  });

  test('user without access cannot change role', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('member');

    const dogKey = 'NO402-45';
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'member',
        role: Role.viewer,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'other',
        role: Role.viewer,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );

    final service = DomainDi.ownershipService(identityService: identity);

    await expectLater(
      service.updateMembershipRole(
        dogKey: dogKey,
        targetUserId: 'other',
        role: Role.editor,
      ),
      throwsA(
        isA<MembershipRoleException>().having(
          (e) => e.code,
          'code',
          MembershipRoleError.notAuthorized,
        ),
      ),
    );
  });

  test('owner role cannot be downgraded', () async {
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    const dogKey = 'NO403-45';
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'owner',
        role: Role.owner,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );
    await seedMembership(
      DogMembership(
        dogKey: dogKey,
        userId: 'co-owner',
        role: Role.owner,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
    );

    final service = DomainDi.ownershipService(identityService: identity);

    await expectLater(
      service.updateMembershipRole(
        dogKey: dogKey,
        targetUserId: 'co-owner',
        role: Role.editor,
      ),
      throwsA(
        isA<MembershipRoleException>().having(
          (e) => e.code,
          'code',
          MembershipRoleError.ownerRoleLocked,
        ),
      ),
    );
  });
}
