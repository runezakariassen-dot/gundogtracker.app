import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_di.dart';
import 'package:jakthund_app/domain/dogs/dog_visibility.dart';
import 'package:jakthund_app/domain/domain_errors.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/share_invitation.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/services/user_identity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    HiveLifecycleService.resetForTesting();

    tempDir = await Directory.systemTemp.createTemp('jakthund_share_');
    HivePathService.setOverridePathForTesting(tempDir.path);
  });

  tearDown(() async {
    HiveLifecycleService.resetForTesting();

    await Hive.close();
    HivePathService.setOverridePathForTesting(null);
    await tempDir.delete(recursive: true);
  });

  test('owner can create invite', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO123/45',
      name: 'Birk',
    );

    final sharing = DomainDi.sharingService(identityService: identity);
    final invite = await sharing.createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'owner@example.com',
    );

    expect(invite.dogKey, dog.dogKey);
    expect(invite.role, Role.editor);
    expect(invite.status, Status.pending);
  });

  test('owner uid can create invite without local owner membership', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');
    final dog = _buildDog(
      id: 'dog-owner',
      dogKey: 'DOG-OWNER',
      ownerUserId: 'owner',
      cloudOwnerUid: 'owner',
    );
    await dogsBox().add(dog);

    final invite = await DomainDi.sharingService(identityService: identity)
        .createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'friend@example.com',
    );

    expect(invite.dogKey, dog.dogKey);
    expect(invite.createdByUserId, 'owner');
  });

  test('admin member can create invite for shared dog', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('admin-user');
    final dog = _buildDog(
      id: 'dog-shared-admin',
      dogKey: 'DOG-SHARED-ADMIN',
      ownerUserId: 'owner',
    );
    await dogsBox().add(dog);
    await dogMembershipsBox().put(
      '${dog.dogKey}::admin-user',
      _membership(
        dogKey: dog.dogKey,
        userId: 'admin-user',
        role: Role.admin,
        status: Status.active,
      ),
    );

    final invite = await DomainDi.sharingService(identityService: identity)
        .createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'admin-share@example.com',
    );

    expect(invite.dogKey, dog.dogKey);
  });

  test('viewer cannot create invite for shared dog', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('viewer-user');
    final dog = _buildDog(
      id: 'dog-viewer',
      dogKey: 'DOG-VIEWER',
      ownerUserId: 'owner',
    );
    await dogsBox().add(dog);
    await dogMembershipsBox().put(
      '${dog.dogKey}::viewer-user',
      _membership(
        dogKey: dog.dogKey,
        userId: 'viewer-user',
        role: Role.viewer,
        status: Status.active,
      ),
    );

    await expectLater(
      DomainDi.sharingService(identityService: identity).createShareInvite(
        dogKey: dog.dogKey,
        recipientEmail: 'viewer-share@example.com',
      ),
      throwsA(
        isA<ShareException>()
            .having((e) => e.code, 'code', ShareError.notOwner),
      ),
    );
  });

  test('revoked admin member cannot create invite', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('admin-user');
    final dog = _buildDog(
      id: 'dog-revoked',
      dogKey: 'DOG-REVOKED',
      ownerUserId: 'owner',
    );
    await dogsBox().add(dog);
    await dogMembershipsBox().put(
      '${dog.dogKey}::admin-user',
      _membership(
        dogKey: dog.dogKey,
        userId: 'admin-user',
        role: Role.admin,
        status: Status.revoked,
      ),
    );

    await expectLater(
      DomainDi.sharingService(identityService: identity).createShareInvite(
        dogKey: dog.dogKey,
        recipientEmail: 'revoked-share@example.com',
      ),
      throwsA(
        isA<ShareException>()
            .having((e) => e.code, 'code', ShareError.notOwner),
      ),
    );
  });

  test('dog visible to owner is shareable by owner', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');
    final dog = _buildDog(
      id: 'dog-visible-owner',
      dogKey: 'DOG-VISIBLE-OWNER',
      ownerUserId: 'owner',
      cloudOwnerUid: 'owner',
    );
    await dogsBox().add(dog);

    final visibleDogs = filterVisibleDogs(
      dogs: dogsBox().values,
      memberships: dogMembershipsBox().values,
      currentUserId: 'owner',
    );
    expect(visibleDogs.map((dog) => dog.id), <String>['dog-visible-owner']);

    final invite = await DomainDi.sharingService(identityService: identity)
        .createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'visible-owner@example.com',
    );
    expect(invite.dogKey, dog.dogKey);
  });

  test('non-owner cannot create invite', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO200/45',
      name: 'Rex',
    );

    await identity.setCurrentUserId('member');
    final sharing = DomainDi.sharingService(identityService: identity);

    await expectLater(
      sharing.createShareInvite(
        dogKey: dog.dogKey,
        recipientEmail: 'member@example.com',
      ),
      throwsA(
        isA<ShareException>()
            .having((e) => e.code, 'code', ShareError.notOwner),
      ),
    );
  });

  test('accept creates membership', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO124/45',
      name: 'Luna',
    );

    final sharing = DomainDi.sharingService(identityService: identity);
    final invite = await sharing.createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'luna@example.com',
    );

    await identity.setCurrentUserId('member');
    final membership = await sharing.acceptShareInvite(token: invite.token);

    expect(membership.role, Role.editor);
    expect(membership.status, Status.active);
    expect(membership.userId, 'member');
  });

  test('accept returns existing membership when already member', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO126/45',
      name: 'Tara',
    );

    final sharing = DomainDi.sharingService(identityService: identity);
    final invite = await sharing.createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'tara@example.com',
    );

    await identity.setCurrentUserId('member');
    final existing = DogMembership(
      dogKey: dog.dogKey,
      userId: 'member',
      role: Role.viewer,
      status: Status.active,
      addedAt: DateTime.now(),
      addedByUserId: 'owner',
    );
    await dogMembershipsBox().put('${dog.dogKey}::member', existing);

    final membership = await sharing.acceptShareInvite(token: invite.token);
    expect(membership.userId, existing.userId);

    final storedInvite = shareInvitesBox().get(invite.inviteId);
    expect(storedInvite, isNotNull);
    expect(storedInvite!.status, Status.accepted);
  });

  test('accept rejects expired invite', () async {
    await initDomainLayer();

    final invite = ShareInvitation(
      inviteId: 'invite-old',
      dogKey: 'NO210-45',
      role: Role.viewer,
      token: 'TOKENOLD',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      status: Status.pending,
      recipientEmail: 'old@example.com',
      recipientUserId: null,
      createdByUserId: 'owner',
    );

    await shareInvitesBox().put(invite.inviteId, invite);

    final identity = UserIdentityService();
    await identity.setCurrentUserId('member');
    await expectLater(
      DomainDi.sharingService(identityService: identity)
          .acceptShareInvite(token: invite.token),
      throwsA(
        isA<ShareException>()
            .having((e) => e.code, 'code', ShareError.inviteExpired),
      ),
    );

    final storedInvite = shareInvitesBox().get(invite.inviteId);
    expect(storedInvite, isNotNull);
    expect(storedInvite!.status, Status.expired);
  });

  test('accept rejects revoked invite', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO212/45',
      name: 'Siv',
    );

    final sharing = DomainDi.sharingService(identityService: identity);
    final invite = await sharing.createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'siv@example.com',
    );
    await sharing.revokeShareInvite(inviteId: invite.inviteId);

    await identity.setCurrentUserId('member');
    await expectLater(
      sharing.acceptShareInvite(token: invite.token),
      throwsA(
        isA<ShareException>()
            .having((e) => e.code, 'code', ShareError.inviteRevoked),
      ),
    );
  });

  test('revoke only owner can revoke', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO211/45',
      name: 'Zorro',
    );

    final sharing = DomainDi.sharingService(identityService: identity);
    final invite = await sharing.createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'zorro@example.com',
    );

    await identity.setCurrentUserId('member');
    await expectLater(
      sharing.revokeShareInvite(inviteId: invite.inviteId),
      throwsA(
        isA<ShareException>()
            .having((e) => e.code, 'code', ShareError.notOwner),
      ),
    );

    await identity.setCurrentUserId('owner');
    await sharing.revokeShareInvite(inviteId: invite.inviteId);

    final storedInvite = shareInvitesBox().get(invite.inviteId);
    expect(storedInvite, isNotNull);
    expect(storedInvite!.status, Status.revoked);
  });
}

Dog _buildDog({
  required String id,
  required String dogKey,
  required String ownerUserId,
  String? cloudOwnerUid,
}) {
  return Dog(
    id: id,
    name: 'Test2',
    dogKey: dogKey,
    regNrDisplay: 'NO123/45',
    ownerUserId: ownerUserId,
    cloudOwnerUid: cloudOwnerUid,
    cloudId: id,
    updatedAt: DateTime.utc(2026, 1, 1, 12),
  );
}

DogMembership _membership({
  required String dogKey,
  required String userId,
  required Role role,
  required Status status,
}) {
  return DogMembership(
    dogKey: dogKey,
    userId: userId,
    role: role,
    status: status,
    addedAt: DateTime.utc(2026, 1, 1, 12),
    addedByUserId: 'owner',
  );
}
