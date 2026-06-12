import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/data/local/sync_state_store.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type.dart';
import 'package:jakthund_app/models/session_type_adapter.dart';
import 'package:jakthund_app/models/share_invitation.dart';
import 'package:jakthund_app/models/sync_state.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/services/cloud/firestore_dog_sync_service.dart';
import 'package:jakthund_app/services/cloud/firestore_session_sync_service.dart';
import 'package:jakthund_app/services/cloud/network_awareness_service.dart';
import 'package:jakthund_app/services/cloud/pull_sync_service.dart';

class FakeFirestoreDogSyncService implements FirestoreDogSyncService {
  FakeFirestoreDogSyncService({this.dogsToReturn = const []});

  final List<Dog> dogsToReturn;
  final List<DateTime?> updatedAfterCalls = <DateTime?>[];

  @override
  Future<List<Map<String, dynamic>>> fetchAccessibleDogs() async {
    throw UnimplementedError();
  }

  @override
  Future<List<Dog>> fetchAccessibleDogsAsModels({
    DateTime? updatedAfter,
  }) async {
    updatedAfterCalls.add(updatedAfter);
    return dogsToReturn;
  }

  @override
  Dog mapFirestoreDogToDog(Map<String, dynamic> data, String dogId) {
    throw UnimplementedError();
  }

  @override
  Future<int> restoreAccessibleDogsToHive() async {
    throw UnimplementedError();
  }

  @override
  Future<void> ensureLocalMembershipForDog(Dog dog) async {
    return;
  }

  @override
  Future<bool> revokeCurrentUserMembershipBestEffort({
    required Dog dog,
    required DogMembership membership,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> tombstoneDog(Dog dog) async {
    throw UnimplementedError();
  }

  @override
  Future<void> tombstoneDogBestEffort(Dog dog) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> upsertShareInviteMembershipBestEffort({
    required ShareInvitation invite,
    required DogMembership membership,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Dog> upsertDog(Dog dog) async {
    throw UnimplementedError();
  }
}

class SessionFetchCall {
  SessionFetchCall({
    required this.dogCloudId,
    required this.updatedAfter,
  });

  final String? dogCloudId;
  final DateTime? updatedAfter;
}

class FakeFirestoreSessionSyncService implements FirestoreSessionSyncService {
  FakeFirestoreSessionSyncService({
    this.fullEntries = const <String, List<MapEntry<String, HuntSession>>>{},
    this.deltaEntries = const <String, List<MapEntry<String, HuntSession>>>{},
    this.supportsDelta = true,
    this.throwForDogCloudId,
  });

  final Map<String, List<MapEntry<String, HuntSession>>> fullEntries;
  final Map<String, List<MapEntry<String, HuntSession>>> deltaEntries;
  final bool supportsDelta;
  final String? throwForDogCloudId;
  final List<SessionFetchCall> calls = <SessionFetchCall>[];

  int deltaFetches = 0;
  int fallbackFullFetches = 0;

  @override
  Future<List<HuntSession>> fetchSessionsForDogAsModels(
    String? dogCloudId, {
    DateTime? updatedAfter,
  }) async {
    final entries = await fetchSessionEntriesWithIdsForDog(
      dogCloudId,
      updatedAfter: updatedAfter,
    );
    return entries.map((entry) => entry.value).toList(growable: false);
  }

  @override
  Future<List<HuntSession>> fetchSessionEntriesForDogAsModels(
    String? dogCloudId, {
    DateTime? updatedAfter,
  }) async {
    final entries = await fetchSessionEntriesWithIdsForDog(
      dogCloudId,
      updatedAfter: updatedAfter,
    );
    return entries.map((entry) => entry.value).toList(growable: false);
  }

  @override
  Future<List<MapEntry<String, HuntSession>>> fetchSessionEntriesWithIdsForDog(
    String? dogCloudId, {
    DateTime? updatedAfter,
  }) async {
    calls.add(
        SessionFetchCall(dogCloudId: dogCloudId, updatedAfter: updatedAfter));

    if (throwForDogCloudId != null && throwForDogCloudId == dogCloudId) {
      throw StateError('session fetch failed for $dogCloudId');
    }

    if (updatedAfter != null && supportsDelta) {
      deltaFetches++;
      return deltaEntries[dogCloudId] ??
          const <MapEntry<String, HuntSession>>[];
    }

    if (updatedAfter != null && !supportsDelta) {
      fallbackFullFetches++;
    }

    return fullEntries[dogCloudId] ?? const <MapEntry<String, HuntSession>>[];
  }

  @override
  HuntSession mapFirestoreSessionToSession(
    Map<String, dynamic> data,
    String sessionId,
    String dogCloudId,
  ) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> mapSessionToFirestore({
    required String sessionId,
    required HuntSession session,
    required String cloudDogId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> restoreSessionsForDogToHive(String? dogCloudId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> upsertSession({
    required String sessionId,
    required HuntSession session,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> upsertSessionBestEffort({
    required String sessionId,
    required HuntSession session,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> tombstoneSession({
    required String sessionId,
    required HuntSession session,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> tombstoneSessionBestEffort({
    required String sessionId,
    required HuntSession session,
  }) async {
    throw UnimplementedError();
  }
}

class FakeNetworkAwarenessService implements NetworkAwarenessService {
  FakeNetworkAwarenessService({this.online = true});

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Dog> dogBox;
  late Box<HuntSession> sessionBox;
  late Box<SyncState> syncBox;
  late Box<SyncTask> outboxBox;
  late SyncStateStore syncStateStore;
  late SyncOutboxService outboxService;
  late FakeFirestoreDogSyncService fakeDogSync;
  late FakeFirestoreSessionSyncService fakeSessionSync;
  late FakeNetworkAwarenessService fakeNetwork;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pull_sync_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HuntSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DogAdapter());
    }
    if (!Hive.isAdapterRegistered(221)) {
      Hive.registerAdapter(SyncStateAdapter());
    }
    if (!Hive.isAdapterRegistered(222)) {
      Hive.registerAdapter(DogSexAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }

    dogBox = await Hive.openBox<Dog>('dogs_test');
    sessionBox = await Hive.openBox<HuntSession>('sessions_test');
    syncBox = await Hive.openBox<SyncState>('sync_state_test');
    outboxBox = await Hive.openBox<SyncTask>('sync_outbox_test');

    syncStateStore = SyncStateStore(box: syncBox);
    outboxService = SyncOutboxService(box: outboxBox, enableAutoSync: false);
    fakeDogSync = FakeFirestoreDogSyncService();
    fakeSessionSync = FakeFirestoreSessionSyncService();
    fakeNetwork = FakeNetworkAwarenessService();
  });

  tearDown(() async {
    await dogBox.close();
    await sessionBox.close();
    await syncBox.close();
    await outboxBox.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('skips pull when offline', () async {
    fakeNetwork = FakeNetworkAwarenessService(online: false);

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2),
    );

    await service.pullAllVisibleData();

    expect(dogBox.length, 0);
    expect(sessionBox.length, 0);
    expect(syncStateStore.getLastSuccessfulPullAt(), isNull);
  });

  test('first pull without cursor uses full fetch and updates cursor',
      () async {
    final dog = _buildDog(updatedAt: DateTime.utc(2024, 1, 1, 9));
    final session = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 1, 10),
      notes: 'full fetch session',
    );
    final pullStartedAt = DateTime.utc(2024, 1, 2, 12);

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[dog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      fullEntries: <String, List<MapEntry<String, HuntSession>>>{
        dog.cloudId!: <MapEntry<String, HuntSession>>[
          MapEntry<String, HuntSession>('session-1', session),
        ],
      },
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => pullStartedAt,
    );

    await service.pullAllVisibleData();

    expect(fakeDogSync.updatedAfterCalls, <DateTime?>[null]);
    expect(fakeSessionSync.calls.single.updatedAfter, isNull);
    expect(syncStateStore.getLastSuccessfulPullAt(), pullStartedAt);
    expect(dogBox.length, 1);
    expect(sessionBox.length, 1);
    expect(sessionBox.get('session-1')?.notes, 'full fetch session');
  });

  test('later pull with cursor uses delta fetch', () async {
    final cursor = DateTime.utc(2024, 1, 2, 8);
    final pullStartedAt = DateTime.utc(2024, 1, 2, 12);
    final dog = _buildDog(updatedAt: DateTime.utc(2024, 1, 1, 9));
    final session = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 9),
      notes: 'delta session',
    );
    await syncStateStore.setLastSuccessfulPullAt(cursor);

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[dog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      deltaEntries: <String, List<MapEntry<String, HuntSession>>>{
        dog.cloudId!: <MapEntry<String, HuntSession>>[
          MapEntry<String, HuntSession>('session-2', session),
        ],
      },
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => pullStartedAt,
    );

    await service.pullAllVisibleData();

    expect(fakeDogSync.updatedAfterCalls, <DateTime?>[cursor]);
    expect(fakeSessionSync.calls.single.updatedAfter, cursor);
    expect(fakeSessionSync.deltaFetches, 1);
    expect(sessionBox.get('session-2')?.notes, 'delta session');
    expect(syncStateStore.getLastSuccessfulPullAt(), pullStartedAt);
  });

  test('cursor is unchanged when pull fails', () async {
    final oldCursor = DateTime.utc(2024, 1, 2, 8);
    final dog = _buildDog(updatedAt: DateTime.utc(2024, 1, 1, 9));
    await syncStateStore.setLastSuccessfulPullAt(oldCursor);

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[dog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      throwForDogCloudId: dog.cloudId,
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2, 12),
    );

    await expectLater(service.pullAllVisibleData(), throwsStateError);

    expect(syncStateStore.getLastSuccessfulPullAt(), oldCursor);
  });

  test('new cloud session after cursor is pulled into local storage', () async {
    final cursor = DateTime.utc(2024, 1, 2, 8);
    final dog = _buildDog(updatedAt: DateTime.utc(2024, 1, 1, 9));
    final session = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 9),
      notes: 'new remote session',
    );
    await syncStateStore.setLastSuccessfulPullAt(cursor);

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[dog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      deltaEntries: <String, List<MapEntry<String, HuntSession>>>{
        dog.cloudId!: <MapEntry<String, HuntSession>>[
          MapEntry<String, HuntSession>('session-3', session),
        ],
      },
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2, 12),
    );

    await service.pullAllVisibleData();

    expect(sessionBox.length, 1);
    expect(sessionBox.get('session-3')?.notes, 'new remote session');
  });

  test('member pulls sessions created by other active members', () async {
    final dog = _buildDog(updatedAt: DateTime.utc(2024, 1, 1, 9));
    final ownerSession = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 9),
      notes: 'owner session',
    ).copyWith(createdByUserId: 'owner-a');
    final otherMemberSession = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 10),
      notes: 'member-c session',
    ).copyWith(createdByUserId: 'member-c');

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[dog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      fullEntries: <String, List<MapEntry<String, HuntSession>>>{
        dog.cloudId!: <MapEntry<String, HuntSession>>[
          MapEntry<String, HuntSession>('session-owner', ownerSession),
          MapEntry<String, HuntSession>('session-member-c', otherMemberSession),
        ],
      },
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2, 12),
    );

    await service.pullAllVisibleData();

    expect(sessionBox.length, 2);
    expect(sessionBox.get('session-owner')?.notes, 'owner session');
    expect(sessionBox.get('session-owner')?.dogId, dog.id);
    expect(sessionBox.get('session-member-c')?.notes, 'member-c session');
    expect(sessionBox.get('session-member-c')?.dogId, dog.id);
  });

  test('older cloud session does not overwrite newer local session', () async {
    final cursor = DateTime.utc(2024, 1, 2, 8);
    final localDog = _buildDog(
      id: 'local-dog-1',
      updatedAt: DateTime.utc(2024, 1, 3, 9),
    );
    final cloudDog = localDog.copyWith(
      updatedAt: DateTime.utc(2024, 1, 1, 9),
    );
    final localSession = _buildSession(
      dogId: localDog.id,
      updatedAt: DateTime.utc(2024, 1, 3, 11),
      notes: 'local newer',
    );
    final cloudSession = _buildSession(
      dogId: cloudDog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 9),
      notes: 'cloud older',
    );
    await dogBox.put(localDog.id, localDog);
    await sessionBox.put('session-4', localSession);
    await syncStateStore.setLastSuccessfulPullAt(cursor);

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[cloudDog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      deltaEntries: <String, List<MapEntry<String, HuntSession>>>{
        cloudDog.cloudId!: <MapEntry<String, HuntSession>>[
          MapEntry<String, HuntSession>('session-4', cloudSession),
        ],
      },
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 3, 12),
    );

    await service.pullAllVisibleData();

    expect(sessionBox.length, 1);
    expect(sessionBox.get('session-4')?.notes, 'local newer');
    expect(
      sessionBox.get('session-4')?.updatedAt,
      DateTime.utc(2024, 1, 3, 11),
    );
  });

  test('cloud tombstone removes local session during delta pull', () async {
    final cursor = DateTime.utc(2024, 1, 2, 8);
    final dog = _buildDog(updatedAt: DateTime.utc(2024, 1, 1, 9));
    final localSession = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 7),
      notes: 'existing local session',
    );
    final tombstoneSession = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 9),
      notes: 'deleted in cloud',
      deletedAt: DateTime.utc(2024, 1, 2, 9),
    );
    await dogBox.put(dog.id, dog);
    await sessionBox.put('session-6', localSession);
    await syncStateStore.setLastSuccessfulPullAt(cursor);

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[dog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      deltaEntries: <String, List<MapEntry<String, HuntSession>>>{
        dog.cloudId!: <MapEntry<String, HuntSession>>[
          MapEntry<String, HuntSession>('session-6', tombstoneSession),
        ],
      },
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2, 12),
    );

    await service.pullAllVisibleData();

    expect(sessionBox.containsKey('session-6'), isFalse);
  });

  test('cloud dog tombstone hides local dog during delta pull', () async {
    final cursor = DateTime.utc(2024, 1, 2, 8);
    final localDog = _buildDog(updatedAt: DateTime.utc(2024, 1, 2, 7));
    final cloudDog = _buildDog(
      updatedAt: DateTime.utc(2024, 1, 2, 9),
      deletedAt: DateTime.utc(2024, 1, 2, 9),
    );
    await dogBox.put(localDog.id, localDog);
    await syncStateStore.setLastSuccessfulPullAt(cursor);

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[cloudDog]);
    fakeSessionSync = FakeFirestoreSessionSyncService();

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2, 12),
    );

    await service.pullAllVisibleData();

    final storedDog = dogBox.get(localDog.id);
    expect(storedDog, isNotNull);
    expect(storedDog!.deletedAt, DateTime.utc(2024, 1, 2, 9));
  });

  test('local delete tombstone prevents session resurrection on later pull',
      () async {
    final cursor = DateTime.utc(2024, 1, 2, 8);
    final deletedAt = DateTime.utc(2024, 1, 2, 10);
    final dog = _buildDog(updatedAt: DateTime.utc(2024, 1, 1, 9));
    final cloudSession = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 9),
      notes: 'should not resurrect',
    );
    await syncStateStore.setLastSuccessfulPullAt(cursor);
    await outboxService.enqueueDeleteSession(
      'session-7',
      _buildSession(
        dogId: dog.id,
        updatedAt: deletedAt,
        notes: 'deleted locally',
        deletedAt: deletedAt,
      ),
      deletedAt: deletedAt,
    );

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[dog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      deltaEntries: <String, List<MapEntry<String, HuntSession>>>{
        dog.cloudId!: <MapEntry<String, HuntSession>>[
          MapEntry<String, HuntSession>('session-7', cloudSession),
        ],
      },
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2, 12),
    );

    await service.pullAllVisibleData();

    expect(sessionBox.containsKey('session-7'), isFalse);
  });

  test('local dog delete tombstone prevents dog resurrection on later pull',
      () async {
    final cursor = DateTime.utc(2024, 1, 2, 8);
    final deletedAt = DateTime.utc(2024, 1, 2, 10);
    final cloudDog = _buildDog(updatedAt: DateTime.utc(2024, 1, 2, 9));
    await dogBox.put(
      'local-dog-1',
      _buildDog(
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      ),
    );
    await syncStateStore.setLastSuccessfulPullAt(cursor);
    await outboxService.enqueueDeleteDog(
      _buildDog(
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      ),
      deletedAt: deletedAt,
    );

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[cloudDog]);
    fakeSessionSync = FakeFirestoreSessionSyncService();

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2, 12),
    );

    await service.pullAllVisibleData();

    final storedDog = dogBox.get('local-dog-1');
    expect(storedDog, isNotNull);
    expect(storedDog!.deletedAt, deletedAt);
  });

  test('falls back to full fetch when delta query cannot be used', () async {
    final cursor = DateTime.utc(2024, 1, 2, 8);
    final dog = _buildDog(updatedAt: DateTime.utc(2024, 1, 1, 9));
    final session = _buildSession(
      dogId: dog.id,
      updatedAt: DateTime.utc(2024, 1, 2, 9),
      notes: 'fallback session',
    );
    await syncStateStore.setLastSuccessfulPullAt(cursor);

    fakeDogSync = FakeFirestoreDogSyncService(dogsToReturn: <Dog>[dog]);
    fakeSessionSync = FakeFirestoreSessionSyncService(
      supportsDelta: false,
      fullEntries: <String, List<MapEntry<String, HuntSession>>>{
        dog.cloudId!: <MapEntry<String, HuntSession>>[
          MapEntry<String, HuntSession>('session-5', session),
        ],
      },
    );

    final service = PullSyncService(
      dogSyncService: fakeDogSync,
      sessionSyncService: fakeSessionSync,
      networkAwarenessService: fakeNetwork,
      syncStateStore: syncStateStore,
      outboxService: outboxService,
      dogBox: dogBox,
      sessionBox: sessionBox,
      now: () => DateTime.utc(2024, 1, 2, 12),
    );

    await service.pullAllVisibleData();

    expect(fakeSessionSync.calls.single.updatedAfter, cursor);
    expect(fakeSessionSync.deltaFetches, 0);
    expect(fakeSessionSync.fallbackFullFetches, 1);
    expect(sessionBox.get('session-5')?.notes, 'fallback session');
  });
}

Dog _buildDog({
  String id = 'local-dog-1',
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  return Dog(
    id: id,
    name: 'Birk',
    dogKey: 'DOG-1',
    regNrDisplay: 'NO12345/24',
    cloudId: 'cloud-dog-1',
    updatedAt: updatedAt ?? DateTime.utc(2024, 1, 1),
    deletedAt: deletedAt,
    sex: DogSex.male,
  );
}

HuntSession _buildSession({
  required String dogId,
  required DateTime updatedAt,
  required String notes,
  DateTime? deletedAt,
}) {
  return HuntSession(
    dogId: dogId,
    dogKey: 'DOG-1',
    dateTime: DateTime.utc(2024, 1, 1, 8),
    location: 'Skogen',
    durationMinutes: 45,
    birdsSeen: 3,
    points: 8,
    flushes: 1,
    notes: notes,
    sessionType: SessionType.training,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}
