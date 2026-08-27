import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/services/cloud/network_awareness_service.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/models/health_record.dart';
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

  test('health record task resolves latest local record and cloud dog id',
      () async {
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(HealthRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DogAdapter());
    if (!Hive.isAdapterRegistered(222)) {
      Hive.registerAdapter(DogSexAdapter());
    }
    final healthBox = await Hive.openBox<HealthRecord>('health_records');
    final dogBox = await Hive.openBox<Dog>('dogs');
    final outboxService = SyncOutboxService(
      box: box,
      enableAutoSync: false,
    );
    final record = HealthRecord(
      id: 'health-1',
      dogId: 'dog-1',
      type: HealthRecordType.medication,
      title: 'Latest title',
      recordedAt: DateTime.utc(2026, 1, 1),
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    await healthBox.put(record.id, record);
    await dogBox.put(
      'dog-1',
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'DOG-1',
        regNrDisplay: 'NO12345/24',
        cloudId: 'cloud-dog-1',
      ),
    );
    await outboxService.enqueueUpsertHealthRecord(record);
    final pushed = <String>[];
    final processor = SyncOutboxProcessor(
      outboxService: outboxService,
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      healthRecordBox: healthBox,
      dogBox: dogBox,
      healthRecordUpsertHandler: ({
        required HealthRecord record,
        required String cloudDogId,
      }) async {
        pushed.add('$cloudDogId:${record.title}');
      },
    );

    await processor.runOnce();

    expect(pushed, <String>['cloud-dog-1:Latest title']);
    expect(box.values.single.status, SyncStatus.sent);
  });

  test('missing cloud id waits without retry increment and later completes',
      () async {
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(HealthRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DogAdapter());
    if (!Hive.isAdapterRegistered(222)) {
      Hive.registerAdapter(DogSexAdapter());
    }
    final healthBox = await Hive.openBox<HealthRecord>('health_retry');
    final dogBox = await Hive.openBox<Dog>('dogs_retry');
    final record = HealthRecord(
      id: 'health-retry',
      dogId: 'dog-retry',
      type: HealthRecordType.other,
      title: 'Retry',
      recordedAt: DateTime(2026, 7, 20),
      createdAt: DateTime.utc(2026, 7, 20),
      updatedAt: DateTime.utc(2026, 7, 20),
    );
    final dog = Dog(
      id: 'dog-retry',
      name: 'Birk',
      dogKey: 'DOG-RETRY',
      regNrDisplay: 'NO12345/24',
    );
    await healthBox.put(record.id, record);
    await dogBox.put(dog.id, dog);
    final outbox = SyncOutboxService(box: box, enableAutoSync: false);
    await outbox.enqueueUpsertHealthRecord(record);
    final originalTaskId = box.values.single.taskId;
    var pushes = 0;
    final processor = SyncOutboxProcessor(
      outboxService: outbox,
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      healthRecordBox: healthBox,
      dogBox: dogBox,
      healthRecordUpsertHandler: ({
        required HealthRecord record,
        required String cloudDogId,
      }) async {
        pushes++;
      },
    );

    await processor.runOnce();
    expect(box.values.single.status, SyncStatus.pending);
    expect(box.values.single.retryCount, 0);
    expect(box.values.single.taskId, originalTaskId);
    expect(box.length, 1);
    expect(pushes, 0);

    await dogBox.put(dog.id, dog.copyWith(cloudId: 'cloud-dog-retry'));
    await processor.runOnce();
    expect(box.values.single.status, SyncStatus.sent);
    expect(box.values.single.retryCount, 0);
    expect(box.values.single.taskId, originalTaskId);
    expect(box.length, 1);
    expect(pushes, 1);
  });

  test('one failing health record does not stop the next task', () async {
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(HealthRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DogAdapter());
    if (!Hive.isAdapterRegistered(222)) {
      Hive.registerAdapter(DogSexAdapter());
    }
    final healthBox = await Hive.openBox<HealthRecord>('health_batch');
    final dogBox = await Hive.openBox<Dog>('dogs_batch');
    await dogBox.put(
      'dog-1',
      Dog(
        id: 'dog-1',
        name: 'Birk',
        dogKey: 'DOG-1',
        regNrDisplay: 'NO12345/24',
        cloudId: 'cloud-dog-1',
      ),
    );
    final first = _healthRecord('health-fail');
    final second = _healthRecord('health-success');
    await healthBox.put(first.id, first);
    await healthBox.put(second.id, second);
    final outbox = SyncOutboxService(box: box, enableAutoSync: false);
    await outbox.enqueueUpsertHealthRecord(first);
    await outbox.enqueueUpsertHealthRecord(second);
    final pushed = <String>[];
    final processor = SyncOutboxProcessor(
      outboxService: outbox,
      networkAwarenessService: FakeNetworkAwarenessService(online: true),
      healthRecordBox: healthBox,
      dogBox: dogBox,
      healthRecordUpsertHandler: ({
        required HealthRecord record,
        required String cloudDogId,
      }) async {
        if (record.id == first.id) throw StateError('network failure');
        pushed.add(record.id);
      },
    );

    await processor.runOnce(limit: 10);

    expect(pushed, <String>[second.id]);
    expect(
      box.values.firstWhere((task) => task.entityId == first.id).status,
      SyncStatus.failed,
    );
    expect(
      box.values.firstWhere((task) => task.entityId == second.id).status,
      SyncStatus.sent,
    );
  });
}

HealthRecord _healthRecord(String id) => HealthRecord(
      id: id,
      dogId: 'dog-1',
      type: HealthRecordType.other,
      title: id,
      recordedAt: DateTime(2026, 7, 20),
      createdAt: DateTime.utc(2026, 7, 20),
      updatedAt: DateTime.utc(2026, 7, 20),
    );
