import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_di.dart';

import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/services/user_identity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_sync_');
    HivePathService.setOverridePathForTesting(tempDir.path);
    HiveLifecycleService.resetForTesting();
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    await tempDir.delete(recursive: true);
  });

  test('upsert dog enqueues pending sync task', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO555/55',
      name: 'Loke',
    );

    final tasks = syncTasksBox().values.toList();
    expect(tasks, hasLength(1));
    expect(tasks.first.status, SyncStatus.pending);
    expect(tasks.first.entityType, 'dog_upsert');
    expect(tasks.first.entityId, dog.id);
  });

  test('upsert invite enqueues pending sync task', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO556/55',
      name: 'Runa',
    );
    await syncTasksBox().clear();

    final invite = await DomainDi.sharingService(
      identityService: identity,
      cloudShareInviteWriter: (_) async {},
    ).createShareInvite(
      dogKey: dog.dogKey,
      recipientEmail: 'runa@example.com',
    );

    final tasks = syncTasksBox().values.toList();
    expect(tasks, hasLength(1));
    expect(tasks.first.status, SyncStatus.pending);
    expect(tasks.first.entityType, 'share_invitation');
    expect(tasks.first.entityId, invite.inviteId);
  });

  test('upsert transfer enqueues pending sync task', () async {
    await initDomainLayer();
    final identity = UserIdentityService();
    await identity.setCurrentUserId('owner');

    final dog = await DomainDi.dogService(identityService: identity).createDog(
      regNrInput: 'NO557/55',
      name: 'Ask',
    );
    await syncTasksBox().clear();

    final transfer = await DomainDi.ownershipService(identityService: identity)
        .initiateTransfer(
      dog.dogKey,
      'new-owner',
    );

    final tasks = syncTasksBox().values.toList();
    expect(tasks, hasLength(1));
    expect(tasks.first.status, SyncStatus.pending);
    expect(tasks.first.entityType, 'ownership_transfer');
    expect(tasks.first.entityId, transfer.transferId);
  });
}
