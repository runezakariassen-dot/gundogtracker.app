import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/services/cloud/network_awareness_service.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/services/cloud/sync_outbox_processor.dart';

class FakeNetworkAwarenessService implements NetworkAwarenessService {
  FakeNetworkAwarenessService({required this.online});

  final bool online;

  @override
  Future<bool> shouldProcessOutbox() async => online;

  @override
  Stream<bool> watchOnlineStatus({
    Duration pollInterval = const Duration(seconds: 20),
  }) {
    return const Stream<bool>.empty();
  }
}

void main() {
  late Directory tempDir;
  late Box<SyncTask> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_sync_processor_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }
    box = await Hive.openBox<SyncTask>('sync_outbox_processor_test');
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('dog_upsert processes to sent', () async {
    final outboxService = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final persistedDogs = <Dog>[];
    final processor = SyncOutboxProcessor(
      outboxService: outboxService,
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      dogUpsertHandler: (dog) async {
        return dog.copyWith(
          cloudId: 'cloud-${dog.id}',
          cloudOwnerUid: 'owner-1',
        );
      },
      persistSyncedDog: (dog) async {
        persistedDogs.add(dog);
      },
    );

    await outboxService.enqueueUpsertDog(
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'NO12345',
        regNrDisplay: 'NO123/45',
      ),
    );

    await processor.runOnce();

    expect(box.values.single.status, SyncStatus.sent);
    expect(persistedDogs, hasLength(1));
    expect(persistedDogs.single.cloudId, 'cloud-dog-1');
    expect(persistedDogs.single.cloudOwnerUid, 'owner-1');
  });

  test('mixed batch with dog_upsert and session_upsert', () async {
    final outboxService = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final processed = <String>[];
    final processor = SyncOutboxProcessor(
      outboxService: outboxService,
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      dogUpsertHandler: (dog) async {
        processed.add('dog:${dog.id}');
        return dog;
      },
      sessionUpsertHandler: ({
        required String sessionId,
        required HuntSession session,
      }) async {
        processed.add('session:$sessionId');
      },
      persistSyncedDog: (dog) async {},
    );

    await outboxService.enqueueUpsertDog(
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'NO12345',
        regNrDisplay: 'NO123/45',
      ),
    );
    await outboxService.enqueueUpsertSession(
      'session-1',
      HuntSession(
        dogId: 'dog-1',
        dateTime: DateTime(2024, 1, 1, 9, 0),
        location: 'Skog',
        durationMinutes: 45,
        birdsSeen: 2,
        points: 3,
        flushes: 1,
        notes: 'Mixed batch',
        sessionType: SessionType.training,
      ),
    );

    await processor.runOnce(limit: 10);

    expect(
      processed,
      unorderedEquals(['dog:dog-1', 'session:session-1']),
    );
    expect(box.values.every((task) => task.status == SyncStatus.sent), isTrue);
  });

  test('dog_delete pushes tombstone to cloud and marks task sent', () async {
    final outboxService = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final deleted = <String>[];
    final processor = SyncOutboxProcessor(
      outboxService: outboxService,
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      dogDeleteHandler: (dog) async {
        deleted.add('${dog.id}:${dog.deletedAt?.toIso8601String()}');
      },
      persistSyncedDog: (dog) async {},
    );
    final deletedAt = DateTime.utc(2026, 3, 22, 12);

    await outboxService.enqueueDeleteDog(
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'NO12345',
        regNrDisplay: 'NO123/45',
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      ),
      deletedAt: deletedAt,
    );

    await processor.runOnce(limit: 10);

    expect(
      deleted,
      <String>['dog-1:${deletedAt.toIso8601String()}'],
    );
    expect(box.values.single.status, SyncStatus.sent);
  });

  test('session_delete pushes tombstone to cloud and marks task sent',
      () async {
    final outboxService = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final deleted = <String>[];
    final processor = SyncOutboxProcessor(
      outboxService: outboxService,
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      sessionDeleteHandler: ({
        required String sessionId,
        required HuntSession session,
      }) async {
        deleted.add('$sessionId:${session.deletedAt?.toIso8601String()}');
      },
      persistSyncedDog: (dog) async {},
    );
    final deletedAt = DateTime.utc(2026, 3, 22, 12);

    await outboxService.enqueueDeleteSession(
      'session-1',
      HuntSession(
        dogId: 'dog-1',
        dateTime: DateTime(2024, 1, 1, 9, 0),
        location: 'Skog',
        durationMinutes: 45,
        birdsSeen: 2,
        points: 3,
        flushes: 1,
        notes: 'Delete',
        sessionType: SessionType.training,
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      ),
      deletedAt: deletedAt,
    );

    await processor.runOnce(limit: 10);

    expect(
      deleted,
      <String>['session-1:${deletedAt.toIso8601String()}'],
    );
    expect(box.values.single.status, SyncStatus.sent);
  });

  test('does not run processor when offline and leaves tasks pending',
      () async {
    final outboxService = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final processor = SyncOutboxProcessor(
      outboxService: outboxService,
      networkAwarenessService: FakeNetworkAwarenessService(online: false),
      dogUpsertHandler: (dog) async => dog,
      persistSyncedDog: (dog) async {},
    );

    await outboxService.enqueueUpsertDog(
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'NO12345',
        regNrDisplay: 'NO123/45',
      ),
    );

    await processor.runOnce();

    expect(box.values.single.status, SyncStatus.pending);
  });

  test('online and retry works after offline skip', () async {
    final outboxService = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final processorOffline = SyncOutboxProcessor(
      outboxService: outboxService,
      networkAwarenessService: FakeNetworkAwarenessService(online: false),
      dogUpsertHandler: (dog) async => dog,
      persistSyncedDog: (dog) async {},
    );

    await outboxService.enqueueUpsertDog(
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'NO12345',
        regNrDisplay: 'NO123/45',
      ),
    );

    await processorOffline.runOnce();
    expect(box.values.single.status, SyncStatus.pending);

    final processorOnline = SyncOutboxProcessor(
      outboxService: outboxService,
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      dogUpsertHandler: (dog) async => dog.copyWith(cloudId: 'cloud-1'),
      persistSyncedDog: (dog) async {},
    );

    await processorOnline.runOnce();
    expect(box.values.single.status, SyncStatus.sent);
  });
}
