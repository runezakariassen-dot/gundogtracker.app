import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/dto/dog_dto.dart';
import '../../data/hive_boxes.dart';
import '../../data/local/sync_outbox_service.dart';
import '../../models/dog.dart';
import '../../models/hunt_session.dart';
import '../../models/session_type.dart';
import '../../models/sync_task.dart';
import 'firestore_dog_sync_service.dart';
import 'firestore_session_sync_service.dart';
import 'network_awareness_service.dart';

typedef DogUpsertHandler = Future<Dog> Function(Dog dog);
typedef DogDeleteHandler = Future<void> Function(Dog dog);
typedef SessionUpsertHandler = Future<void> Function({
  required String sessionId,
  required HuntSession session,
});
typedef SessionDeleteHandler = Future<void> Function({
  required String sessionId,
  required HuntSession session,
});
typedef SyncedDogPersistence = Future<void> Function(Dog dog);

class SyncOutboxProcessor {
  SyncOutboxProcessor({
    SyncOutboxService? outboxService,
    FirestoreDogSyncService? dogSyncService,
    FirestoreSessionSyncService? sessionSyncService,
    NetworkAwarenessService? networkAwarenessService,
    DogUpsertHandler? dogUpsertHandler,
    DogDeleteHandler? dogDeleteHandler,
    SessionUpsertHandler? sessionUpsertHandler,
    SessionDeleteHandler? sessionDeleteHandler,
    SyncedDogPersistence? persistSyncedDog,
  })  : _outboxService = outboxService ?? SyncOutboxService(),
        _dogSyncService = dogSyncService ?? FirestoreDogSyncService.instance,
        _sessionSyncService =
            sessionSyncService ?? FirestoreSessionSyncService.instance,
        _networkAwarenessService =
            networkAwarenessService ?? NetworkAwarenessServiceImpl(),
        _dogUpsertHandler = dogUpsertHandler,
        _dogDeleteHandler = dogDeleteHandler,
        _sessionUpsertHandler = sessionUpsertHandler,
        _sessionDeleteHandler = sessionDeleteHandler,
        _persistSyncedDog = persistSyncedDog;

  final SyncOutboxService _outboxService;
  final FirestoreDogSyncService _dogSyncService;
  final FirestoreSessionSyncService _sessionSyncService;
  final NetworkAwarenessService _networkAwarenessService;
  final DogUpsertHandler? _dogUpsertHandler;
  final DogDeleteHandler? _dogDeleteHandler;
  final SessionUpsertHandler? _sessionUpsertHandler;
  final SessionDeleteHandler? _sessionDeleteHandler;
  final SyncedDogPersistence? _persistSyncedDog;

  Future<void> runOnce({int limit = 20}) async {
    debugPrint('[SYNC][PROCESSOR] started limit=$limit');

    final allowed = await _networkAwarenessService.shouldProcessOutbox();
    if (!allowed) {
      debugPrint('[SYNC][PROCESSOR] skipped due to offline network status');
      return;
    }

    await _outboxService.resetStaleInProgressTasks();

    final tasks = await _outboxService.fetchPendingTasks(limit: limit);
    debugPrint('[SYNC][PROCESSOR] fetched count=${tasks.length}');

    var successCount = 0;
    var failureCount = 0;

    for (final task in tasks) {
      await _outboxService.markTaskInProgress(task.taskId);
      try {
        await _processTask(task);
        await _outboxService.markTaskDone(task.taskId);
        successCount++;
        debugPrint(
          '[SYNC][PROCESSOR] success type=${task.entityType} '
          'entityId=${task.entityId}',
        );
      } catch (error, stackTrace) {
        failureCount++;
        await _outboxService.markTaskFailed(task.taskId, error);
        debugPrint(
          '[SYNC][PROCESSOR] failure type=${task.entityType} '
          'entityId=${task.entityId} error=$error',
        );
        debugPrint(stackTrace.toString());
      }
    }

    debugPrint(
      '[SYNC][PROCESSOR] completed success=$successCount failure=$failureCount',
    );
  }

  Future<void> _processTask(SyncTask task) async {
    switch (_normalize(task.entityType)) {
      case 'dog_upsert':
      case 'dog:upsert':
        final dog = dogFromJson(_normalizePayload(task.payload));
        final latestDogTask = _outboxService.latestTaskForEntityTypes(
          entityTypes: const <String>{'dog_upsert', 'dog_delete'},
          entityId: dog.id,
        );
        if (latestDogTask != null &&
            _normalize(latestDogTask.entityType) == 'dog_delete' &&
            latestDogTask.taskId != task.taskId) {
          debugPrint('[SYNC][DELETE] skipped stale dog upsert: ${dog.id}');
          return;
        }
        final syncedDog = await _upsertDog(dog);
        await _persistDog(syncedDog);
        return;
      case 'dog_delete':
      case 'dog:delete':
        final deletedDog = dogFromJson(_normalizePayload(task.payload));
        await _deleteDog(deletedDog);
        return;
      case 'session_upsert':
      case 'session:upsert':
        final payload = _normalizePayload(task.payload);
        final sessionId = task.entityId.trim();
        if (sessionId.isEmpty) {
          throw const FormatException('Missing or invalid sessionId.');
        }
        final latestSessionTask = _outboxService.latestTaskForEntityTypes(
          entityTypes: const <String>{'session_upsert', 'session_delete'},
          entityId: sessionId,
        );
        if (latestSessionTask != null &&
            _normalize(latestSessionTask.entityType) == 'session_delete' &&
            latestSessionTask.taskId != task.taskId) {
          debugPrint(
            '[SYNC][DELETE] skipped stale session upsert: $sessionId',
          );
          return;
        }
        final session = _mapSessionPayloadToModel(payload: payload);
        await _upsertSession(sessionId: sessionId, session: session);
        return;
      case 'session_delete':
      case 'session:delete':
        final payload = _normalizePayload(task.payload);
        final sessionId = task.entityId.trim();
        if (sessionId.isEmpty) {
          throw const FormatException('Missing or invalid sessionId.');
        }
        final session = _mapSessionPayloadToModel(payload: payload);
        await _deleteSession(sessionId: sessionId, session: session);
        return;
    }

    throw StateError('Unsupported task type: ${task.entityType}');
  }

  Future<Dog> _upsertDog(Dog dog) {
    final handler = _dogUpsertHandler;
    if (handler != null) {
      return handler(dog);
    }
    return _dogSyncService.upsertDog(dog);
  }

  Future<void> _deleteDog(Dog dog) {
    final handler = _dogDeleteHandler;
    if (handler != null) {
      return handler(dog);
    }
    return _dogSyncService.tombstoneDog(dog);
  }

  Future<void> _upsertSession({
    required String sessionId,
    required HuntSession session,
  }) {
    final handler = _sessionUpsertHandler;
    if (handler != null) {
      return handler(sessionId: sessionId, session: session);
    }
    return _sessionSyncService.upsertSession(
      sessionId: sessionId,
      session: session,
    );
  }

  Future<void> _deleteSession({
    required String sessionId,
    required HuntSession session,
  }) {
    final handler = _sessionDeleteHandler;
    if (handler != null) {
      return handler(sessionId: sessionId, session: session);
    }
    return _sessionSyncService.tombstoneSession(
      sessionId: sessionId,
      session: session,
    );
  }

  Future<void> _persistDog(Dog dog) {
    final persistSyncedDog = _persistSyncedDog;
    if (persistSyncedDog != null) {
      return persistSyncedDog(dog);
    }
    return _persistDogWithCloudMetadata(dog);
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> payload) {
    return payload.map((key, value) => MapEntry(key.toString(), value));
  }

  String _normalize(String value) => value.trim().toLowerCase();

  HuntSession _mapSessionPayloadToModel({
    required Map<String, dynamic> payload,
  }) {
    final dogId = _requiredString(
      payload,
      'dogId',
      fallbackKeys: const ['dog_id'],
    );

    return HuntSession(
      dogId: dogId,
      dogKey: _optionalString(payload, 'dogKey'),
      dateTime: _readDateTime(payload, 'dateTime') ?? DateTime.now(),
      location: _readLocation(payload, 'location'),
      durationMinutes: _nonNegative(_readInt(payload, 'durationMinutes') ?? 0),
      birdsSeen: _nonNegative(_readInt(payload, 'birdsSeen') ?? 0),
      points: _nonNegative(_readInt(payload, 'points') ?? 0),
      flushes: _nonNegative(_readInt(payload, 'flushes') ?? 0),
      notes: _optionalString(payload, 'notes') ?? '',
      secondaryPoints: _nonNegative(_readInt(payload, 'secondaryPoints') ?? 0),
      tomstandCount: _nonNegative(_readInt(payload, 'tomstandCount') ?? 0),
      trackKey: _readInt(payload, 'trackKey'),
      trackId: _optionalString(payload, 'trackId'),
      birdSpecies: _readStringList(payload, 'birdSpecies'),
      mediaPaths: _readStringList(payload, 'mediaPaths'),
      createdByUserId: _optionalString(payload, 'createdByUserId'),
      sessionType:
          sessionTypeFromString(_optionalString(payload, 'sessionType')),
      birdsShotCount: _nonNegative(_readInt(payload, 'birdsShotCount') ?? 0),
      birdsShotSpecies: _optionalString(payload, 'birdsShotSpecies'),
      updatedAt: _readDateTime(
            payload,
            'updatedAt',
            fallbackKeys: const ['updated_at'],
          ) ??
          _readDateTime(payload, 'dateTime') ??
          DateTime.now(),
      deletedAt: _readDateTime(
        payload,
        'deletedAt',
        fallbackKeys: const ['deleted_at'],
      ),
    );
  }

  String _requiredString(
    Map<String, dynamic> payload,
    String key, {
    List<String> fallbackKeys = const [],
  }) {
    final value = _optionalString(payload, key, fallbackKeys: fallbackKeys);
    if (value != null && value.isNotEmpty) {
      return value;
    }
    throw FormatException('Missing or invalid string for "$key".');
  }

  String? _optionalString(
    Map<String, dynamic> payload,
    String key, {
    List<String> fallbackKeys = const [],
  }) {
    final raw = _readFromPayload(payload, key, fallbackKeys: fallbackKeys);
    return _coerceOptionalString(raw);
  }

  String? _coerceOptionalString(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final normalized = raw.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _readLocation(
    Map<String, dynamic> payload,
    String key, {
    List<String> fallbackKeys = const [],
  }) {
    final raw = _readFromPayload(payload, key, fallbackKeys: fallbackKeys);
    if (raw == null) {
      return '';
    }
    if (raw is String) {
      return HuntSession.normalizeLocation(raw);
    }
    return HuntSession.normalizeLocation(raw.toString());
  }

  int? _readInt(Map<String, dynamic> payload, String key) {
    final raw = _readFromPayload(payload, key);
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  DateTime? _readDateTime(
    Map<String, dynamic> payload,
    String key, {
    List<String> fallbackKeys = const [],
  }) {
    final raw = _readFromPayload(payload, key, fallbackKeys: fallbackKeys);
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }

  List<String> _readStringList(Map<String, dynamic> payload, String key) {
    final raw = _readFromPayload(payload, key);
    if (raw is! List) {
      return const [];
    }
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  dynamic _readFromPayload(
    Map<String, dynamic> payload,
    String key, {
    List<String> fallbackKeys = const [],
  }) {
    if (payload.containsKey(key)) {
      return payload[key];
    }
    for (final fallbackKey in fallbackKeys) {
      if (payload.containsKey(fallbackKey)) {
        return payload[fallbackKey];
      }
    }
    return null;
  }

  int _nonNegative(int value) => value < 0 ? 0 : value;

  Future<void> _persistDogWithCloudMetadata(Dog dog) async {
    final box = dogsBox();
    final key = _findDogHiveKey(box, dog.id);
    if (key == null) {
      return;
    }
    await box.put(key, dog);
  }

  dynamic _findDogHiveKey(Box<Dog> box, String dogId) {
    for (final entry in box.toMap().entries) {
      if (entry.value.id == dogId) {
        return entry.key;
      }
    }
    return null;
  }
}
