import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_di.dart';
import 'package:jakthund_app/domain/domain_errors.dart';
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
