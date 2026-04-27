import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../data/local/sync_outbox_service.dart';
import '../../data/local/sync_state_store.dart';
import '../../models/dog.dart';
import '../../models/gps_track.dart';
import '../../models/hunt_session.dart';
import '../../models/sync_task.dart';
import '../hive_lifecycle_service.dart';
import 'firestore_dog_sync_service.dart';
import 'firestore_session_sync_service.dart';
import 'network_awareness_service.dart';
import 'sync_merge_policy.dart';

class PullSyncService {
  PullSyncService({
    FirestoreDogSyncService? dogSyncService,
    FirestoreSessionSyncService? sessionSyncService,
    NetworkAwarenessService? networkAwarenessService,
    SyncStateStore? syncStateStore,
    SyncOutboxService? outboxService,
    Box<Dog>? dogBox,
    Box<HuntSession>? sessionBox,
    DateTime Function()? now,
  })  : _dogSyncService = dogSyncService ?? FirestoreDogSyncService.instance,
        _sessionSyncService =
            sessionSyncService ?? FirestoreSessionSyncService.instance,
        _networkAwarenessService =
            networkAwarenessService ?? NetworkAwarenessServiceImpl(),
        _syncStateStore = syncStateStore ?? SyncStateStore(),
        _outboxService =
            outboxService ?? SyncOutboxService(enableAutoSync: false),
        _dogBox = dogBox,
        _sessionBox = sessionBox,
        _now = now ?? DateTime.now;

  final FirestoreDogSyncService _dogSyncService;
  final FirestoreSessionSyncService _sessionSyncService;
  final NetworkAwarenessService _networkAwarenessService;
  final SyncStateStore _syncStateStore;
  final SyncOutboxService _outboxService;
  final Box<Dog>? _dogBox;
  final Box<HuntSession>? _sessionBox;
  final DateTime Function() _now;

  Future<void> pullAllVisibleData() async {
    final pullStartedAt = _now().toUtc();
    final lastSuccessfulPullAt = _syncStateStore.getLastSuccessfulPullAt();

    debugPrint('[SYNC][DELTA] start');
    debugPrint(
      '[SYNC][DELTA] cursor lastSuccessfulPullAt='
      '${lastSuccessfulPullAt?.toUtc().toIso8601String() ?? 'null'}',
    );

    final allowed = await _networkAwarenessService.shouldProcessOutbox();
    if (!allowed) {
      debugPrint('[SYNC][PULL] skipped due to offline network status');
      debugPrint('[SYNC][DELTA] pull failed cursor unchanged');
      return;
    }

    try {
      final visibleDogs = await _dogSyncService.fetchAccessibleDogsAsModels(
        updatedAfter: lastSuccessfulPullAt,
      );
      debugPrint('[SYNC][DELTA] dog delta fetch count: ${visibleDogs.length}');
      debugPrint('[SYNC][PULL] visible dogs count: ${visibleDogs.length}');

      for (final dog in visibleDogs) {
        await _pullDogIfNeeded(dog);
        if (dog.deletedAt != null) {
          continue;
        }
        await _pullSessionsForDog(
          dog,
          updatedAfter: lastSuccessfulPullAt,
        );
      }

      await _syncStateStore.setLastSuccessfulPullAt(pullStartedAt);
      debugPrint(
        '[SYNC][DELTA] pull success updated cursor: '
        '${pullStartedAt.toIso8601String()}',
      );
      debugPrint('[SYNC][PULL] complete');
      debugPrint('[SYNC][DELTA] complete');
    } catch (error, stackTrace) {
      debugPrint('[SYNC][PULL] failed: $error');
      debugPrint(stackTrace.toString());
      debugPrint('[SYNC][DELTA] pull failed cursor unchanged');
      debugPrint('[SYNC][DELTA] complete');
      rethrow;
    }
  }

  Future<void> _pullDogIfNeeded(Dog cloudDog) async {
    final cloudId = cloudDog.cloudId;
    if (cloudId == null || cloudId.isEmpty) {
      return;
    }

    debugPrint('[SYNC][PULL] fetching dog: $cloudId');

    final localDog = _findLocalDogByCloudId(cloudId);
    final dogTaskEntityId = localDog?.id ?? cloudDog.id;
    final latestDogTask = _outboxService.latestTaskForEntityTypes(
      entityTypes: const <String>{'dog_upsert', 'dog_delete'},
      entityId: dogTaskEntityId,
    );
    final localDeletedAt = _readDeleteTimestamp(latestDogTask);
    final cloudDeletedAt = cloudDog.deletedAt?.toUtc();

    if (cloudDeletedAt != null) {
      await _applyCloudDogTombstone(
        cloudId: cloudId,
        localDog: localDog,
        cloudDog: cloudDog,
        cloudDeletedAt: cloudDeletedAt,
      );
      return;
    }

    if (latestDogTask != null &&
        _normalizeTaskType(latestDogTask.entityType) == 'dog_delete' &&
        localDeletedAt != null &&
        !localDeletedAt.isBefore(cloudDog.updatedAt.toUtc())) {
      debugPrint(
        '[SYNC][DELETE] skipped resurrect local newer: '
        '$cloudId localDeletedAt=${localDeletedAt.toIso8601String()} '
        'cloudUpdatedAt=${cloudDog.updatedAt.toUtc().toIso8601String()}',
      );
      return;
    }

    final decision = SyncMergePolicy.forDog(local: localDog, cloud: cloudDog);

    switch (decision) {
      case MergeDecision.insert:
        await _insertLocalDog(cloudDog);
        debugPrint('[SYNC][PULL] inserted local dog: $cloudId');
        break;
      case MergeDecision.cloudNewer:
        await _updateLocalDog(cloudDog);
        debugPrint('[SYNC][PULL] updated local dog: $cloudId');
        break;
      case MergeDecision.localNewer:
        debugPrint('[SYNC][PULL] skipped local newer: $cloudId');
        break;
      case MergeDecision.equal:
        debugPrint('[SYNC][PULL] equal/noop dog: $cloudId');
        break;
    }
  }

  Future<void> _applyCloudDogTombstone({
    required String cloudId,
    required Dog? localDog,
    required Dog cloudDog,
    required DateTime cloudDeletedAt,
  }) async {
    if (localDog == null) {
      debugPrint(
        '[SYNC][DELETE] pull dog tombstone applied locally: '
        '$cloudId already_missing=true',
      );
      return;
    }

    if (localDog.updatedAt.toUtc().isAfter(cloudDeletedAt)) {
      debugPrint(
        '[SYNC][DELETE] skipped resurrect local newer: '
        '$cloudId localUpdatedAt=${localDog.updatedAt.toUtc().toIso8601String()} '
        'cloudDeletedAt=${cloudDeletedAt.toIso8601String()}',
      );
      return;
    }

    final box = _dogBox ?? dogsBox();
    final hiveKey = _resolveDogHiveKey(localDog.id, cloudId);
    if (hiveKey == null) {
      debugPrint(
        '[SYNC][DELETE] pull dog tombstone applied locally: '
        '$cloudId already_missing=true',
      );
      return;
    }

    await box.put(
      hiveKey,
      cloudDog.copyWith(
        id: localDog.id,
        dogKey: localDog.dogKey,
      ),
    );
    debugPrint('[SYNC][DELETE] pull dog tombstone applied locally: $cloudId');
    debugPrint('[SYNC][DELETE] dog hidden from visibility: $cloudId');
  }

  Future<void> _pullSessionsForDog(
    Dog dog, {
    DateTime? updatedAfter,
  }) async {
    final cloudId = dog.cloudId;
    if (cloudId == null || cloudId.isEmpty) {
      return;
    }

    debugPrint('[SYNC][PULL] fetching sessions for dog: $cloudId');

    final cloudSessionEntries =
        await _sessionSyncService.fetchSessionEntriesWithIdsForDog(
      cloudId,
      updatedAfter: updatedAfter,
    );
    debugPrint(
      '[SYNC][DELTA] session delta fetch count: ${cloudSessionEntries.length} '
      'for dog: $cloudId',
    );

    for (final entry in cloudSessionEntries) {
      final sessionId = entry.key;
      final cloudSession = entry.value;
      await _pullSessionIfNeeded(cloudSession, dog, sessionId);
    }
  }

  Future<void> _pullSessionIfNeeded(
    HuntSession cloudSession,
    Dog dog,
    String sessionId,
  ) async {
    final cloudDeletedAt = cloudSession.deletedAt?.toUtc();
    final localDeleteTask = _outboxService.latestTaskForEntity(
      entityType: 'session_delete',
      entityId: sessionId,
    );
    final latestSessionTask = _outboxService.latestTaskForEntityTypes(
      entityTypes: const <String>{'session_upsert', 'session_delete'},
      entityId: sessionId,
    );
    final localDeletedAt = _readDeleteTimestamp(localDeleteTask);
    final localSession = _findLocalSessionById(sessionId);

    if (cloudDeletedAt != null) {
      await _applyCloudTombstone(
        sessionId: sessionId,
        localSession: localSession,
        cloudDeletedAt: cloudDeletedAt,
      );
      return;
    }

    if (latestSessionTask != null &&
        _normalizeTaskType(latestSessionTask.entityType) == 'session_delete' &&
        localDeletedAt != null &&
        !localDeletedAt.isBefore(cloudSession.updatedAt.toUtc())) {
      debugPrint(
        '[SYNC][DELETE] skipped resurrect local newer: '
        '$sessionId localDeletedAt=${localDeletedAt.toIso8601String()} '
        'cloudUpdatedAt=${cloudSession.updatedAt.toUtc().toIso8601String()}',
      );
      return;
    }

    final decision =
        SyncMergePolicy.forSession(local: localSession, cloud: cloudSession);
    final localizedCloudSession = cloudSession.copyWith(
      dogId: dog.id,
      dogKey: dog.dogKey,
      updatedAt: cloudSession.updatedAt,
      deletedAt: null,
    );

    switch (decision) {
      case MergeDecision.insert:
        await _insertLocalSession(localizedCloudSession, sessionId);
        debugPrint('[SYNC][PULL] inserted local session: $sessionId');
        break;
      case MergeDecision.cloudNewer:
        await _updateLocalSession(localizedCloudSession, sessionId);
        debugPrint('[SYNC][PULL] updated local session: $sessionId');
        break;
      case MergeDecision.localNewer:
        debugPrint('[SYNC][PULL] skipped local newer: $sessionId');
        break;
      case MergeDecision.equal:
        debugPrint('[SYNC][PULL] equal/noop session: $sessionId');
        break;
    }
  }

  Future<void> _applyCloudTombstone({
    required String sessionId,
    required HuntSession? localSession,
    required DateTime cloudDeletedAt,
  }) async {
    if (localSession == null) {
      debugPrint(
        '[SYNC][DELETE] pull tombstone applied locally: $sessionId '
        'already_missing=true',
      );
      return;
    }

    if (localSession.updatedAt.toUtc().isAfter(cloudDeletedAt)) {
      debugPrint(
        '[SYNC][DELETE] skipped resurrect local newer: '
        '$sessionId localUpdatedAt=${localSession.updatedAt.toUtc().toIso8601String()} '
        'cloudDeletedAt=${cloudDeletedAt.toIso8601String()}',
      );
      return;
    }

    await _deleteLocalSession(sessionId, localSession);
    debugPrint('[SYNC][DELETE] pull tombstone applied locally: $sessionId');
  }

  Future<void> _insertLocalDog(Dog dog) async {
    final box = _dogBox ?? dogsBox();
    await box.add(dog);
  }

  Future<void> _updateLocalDog(Dog dog) async {
    final box = _dogBox ?? dogsBox();
    for (final entry in box.toMap().entries) {
      if (entry.value.cloudId == dog.cloudId) {
        await box.put(entry.key, dog.copyWith(id: entry.value.id));
        return;
      }
    }
  }

  Future<void> _insertLocalSession(
    HuntSession session,
    String sessionId,
  ) async {
    final box = _sessionBox ?? sessionsBox();
    await box.put(_resolveSessionHiveKey(sessionId), session);
  }

  Future<void> _updateLocalSession(
    HuntSession session,
    String sessionId,
  ) async {
    final box = _sessionBox ?? sessionsBox();
    await box.put(_resolveSessionHiveKey(sessionId), session);
  }

  Future<void> _deleteLocalSession(
    String sessionId,
    HuntSession session,
  ) async {
    final trackKey = session.trackKey;
    if (trackKey != null) {
      await HiveLifecycleService.getBox<GpsTrack>(gpsTracksBoxName)
          .delete(trackKey);
    }
    final box = _sessionBox ?? sessionsBox();
    await box.delete(_resolveSessionHiveKey(sessionId));
  }

  Dog? _findLocalDogByCloudId(String cloudId) {
    final box = _dogBox ?? dogsBox();
    for (final dog in box.values) {
      if (dog.cloudId == cloudId) {
        return dog;
      }
    }
    return null;
  }

  dynamic _resolveDogHiveKey(String dogId, String cloudId) {
    final box = _dogBox ?? dogsBox();
    for (final entry in box.toMap().entries) {
      final dog = entry.value;
      if (dog.id == dogId || dog.cloudId == cloudId) {
        return entry.key;
      }
    }
    return null;
  }

  HuntSession? _findLocalSessionById(String sessionId) {
    final box = _sessionBox ?? sessionsBox();
    return box.get(_resolveSessionHiveKey(sessionId));
  }

  dynamic _resolveSessionHiveKey(String sessionId) {
    final numeric = int.tryParse(sessionId);
    return numeric ?? sessionId;
  }

  DateTime? _readDeleteTimestamp(SyncTask? task) {
    if (task == null) {
      return null;
    }

    final deletedAt = task.payload['deletedAt'];
    if (deletedAt is DateTime) {
      return deletedAt.toUtc();
    }
    if (deletedAt is String && deletedAt.trim().isNotEmpty) {
      return DateTime.tryParse(deletedAt)?.toUtc();
    }
    return null;
  }

  String _normalizeTaskType(String value) => value.trim().toLowerCase();
}
