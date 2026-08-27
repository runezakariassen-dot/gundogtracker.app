import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../data/dto/dog_dto.dart';
import '../../data/hive_boxes.dart';
import '../../models/dog.dart';
import '../../models/hunt_session.dart';
import '../../models/health_record.dart';
import '../../models/sync_task.dart';
import '../../services/cloud/auto_sync_coordinator.dart';

class SyncOutboxTaskCounts {
  const SyncOutboxTaskCounts({
    this.pending = 0,
    this.inProgress = 0,
    this.failed = 0,
    this.sent = 0,
  });

  final int pending;
  final int inProgress;
  final int failed;
  final int sent;
}

class SyncOutboxEnqueueException implements Exception {
  const SyncOutboxEnqueueException(this.entityType, this.entityId);

  final String entityType;
  final String entityId;

  @override
  String toString() =>
      'Failed to persist outbox task type=$entityType entityId=$entityId';
}

class SyncOutboxService {
  SyncOutboxService({
    Box<SyncTask>? box,
    AutoSyncCoordinator? autoSyncCoordinator,
    DateTime Function()? now,
    bool enableAutoSync = true,
  })  : _box = box ?? syncTasksBox(),
        _autoSyncCoordinator = enableAutoSync
            ? (autoSyncCoordinator ?? AutoSyncCoordinator.instance)
            : null,
        _now = now ?? DateTime.now;

  static const int maxRetryCount = 4;

  final Box<SyncTask> _box;
  final Uuid _uuid = const Uuid();
  final AutoSyncCoordinator? _autoSyncCoordinator;
  final DateTime Function() _now;

  Future<void> enqueueUpsertDog(Dog dog) async {
    debugPrint('[SYNC][OUTBOX] enqueue type=dog_upsert entityId=${dog.id}');
    final saved = await _saveTask(
      entityType: 'dog_upsert',
      entityId: dog.id,
      payload: {
        ...dogToJson(dog),
        'operation': 'upsert',
      },
    );
    if (saved) {
      _triggerAutoSyncAfterEnqueue();
    }
  }

  Future<void> enqueueDeleteDog(
    Dog dog, {
    DateTime? deletedAt,
  }) async {
    final effectiveDeletedAt = deletedAt?.toUtc() ?? _now().toUtc();
    debugPrint('[SYNC][DELETE] enqueue dog delete: ${dog.id}');
    final saved = await _saveTask(
      entityType: 'dog_delete',
      entityId: dog.id,
      payload: {
        ...dogToJson(
          dog.copyWith(
            updatedAt: effectiveDeletedAt,
            deletedAt: effectiveDeletedAt,
          ),
        ),
        'operation': 'delete',
        'updatedAt': effectiveDeletedAt.toIso8601String(),
        'deletedAt': effectiveDeletedAt.toIso8601String(),
      },
    );
    if (saved) {
      _triggerAutoSyncAfterEnqueue();
    }
  }

  Future<void> enqueueUpsertSession(
    String sessionId,
    HuntSession session,
  ) async {
    debugPrint(
      '[SYNC][OUTBOX] enqueue type=session_upsert entityId=$sessionId',
    );
    final saved = await _saveTask(
      entityType: 'session_upsert',
      entityId: sessionId,
      payload: {
        ...session.toJson(),
        'operation': 'upsert',
        'id': sessionId,
        'sessionId': sessionId,
      },
    );
    if (saved) {
      _triggerAutoSyncAfterEnqueue();
    }
  }

  Future<void> enqueueDeleteSession(
    String sessionId,
    HuntSession session, {
    DateTime? deletedAt,
  }) async {
    final effectiveDeletedAt = deletedAt?.toUtc() ?? _now().toUtc();
    debugPrint('[SYNC][DELETE] enqueue session delete: $sessionId');
    final saved = await _saveTask(
      entityType: 'session_delete',
      entityId: sessionId,
      payload: {
        ...session.toJson(),
        'operation': 'delete',
        'id': sessionId,
        'sessionId': sessionId,
        'updatedAt': effectiveDeletedAt.toIso8601String(),
        'deletedAt': effectiveDeletedAt.toIso8601String(),
      },
    );
    if (saved) {
      _triggerAutoSyncAfterEnqueue();
    }
  }

  Future<void> enqueueUpsertHealthRecord(HealthRecord record) async {
    debugPrint(
      '[SYNC][OUTBOX] enqueue type=health_record_upsert '
      'entityId=${record.id}',
    );
    final saved = await _saveOrReplacePendingTask(
      entityType: 'health_record_upsert',
      entityId: record.id,
      payload: <String, dynamic>{
        'operation': 'upsert',
        'id': record.id,
        'dogId': record.dogId,
      },
    );
    if (saved) {
      _triggerAutoSyncAfterEnqueue();
      return;
    }
    throw SyncOutboxEnqueueException('health_record_upsert', record.id);
  }

  Future<List<SyncTask>> fetchPendingTasks({int limit = 20}) async {
    final currentNow = _now();
    final pending = <SyncTask>[];
    var skippedCooldownCount = 0;

    for (final task in _box.values) {
      if (task.status != SyncStatus.pending) {
        continue;
      }
      if (!_isReadyToRun(task, now: currentNow)) {
        skippedCooldownCount++;
        final nextAttemptAt = task.nextAttemptAt;
        debugPrint(
          '[SYNC][RETRY] skipped cooldown task=${task.taskId} '
          'retryAt=${nextAttemptAt?.toIso8601String()}',
        );
        continue;
      }
      pending.add(task);
    }

    pending.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final limited = (limit <= 0 || pending.length <= limit)
        ? pending
        : pending.take(limit).toList(growable: false);

    debugPrint(
      '[SYNC][OUTBOX] fetched pending count=${limited.length} '
      'total=${pending.length} cooldown_skipped=$skippedCooldownCount '
      'limit=$limit',
    );
    return limited;
  }

  SyncTask? latestTaskForEntity({
    required String entityType,
    required String entityId,
  }) {
    return latestTaskForEntityTypes(
      entityTypes: <String>{entityType},
      entityId: entityId,
    );
  }

  SyncTask? latestTaskForEntityTypes({
    required Set<String> entityTypes,
    required String entityId,
  }) {
    final normalizedEntityTypes = entityTypes
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    final normalizedEntityId = entityId.trim();
    SyncTask? latest;

    for (final task in _box.values) {
      if (!normalizedEntityTypes
          .contains(task.entityType.trim().toLowerCase())) {
        continue;
      }
      if (task.entityId.trim() != normalizedEntityId) {
        continue;
      }
      if (latest == null || _isTaskNewer(task, latest)) {
        latest = task;
      }
    }

    return latest;
  }

  Stream<void> watchTasks() {
    return _box.watch().map((_) {});
  }

  SyncOutboxTaskCounts taskCounts() {
    var pending = 0;
    var inProgress = 0;
    var failed = 0;
    var sent = 0;

    for (final task in _box.values) {
      switch (task.status) {
        case SyncStatus.pending:
          pending++;
        case SyncStatus.inProgress:
          inProgress++;
        case SyncStatus.failed:
          failed++;
        case SyncStatus.sent:
          sent++;
      }
    }

    return SyncOutboxTaskCounts(
      pending: pending,
      inProgress: inProgress,
      failed: failed,
      sent: sent,
    );
  }

  Stream<SyncOutboxTaskCounts> watchTaskCounts() async* {
    yield taskCounts();
    yield* watchTasks().map((_) => taskCounts());
  }

  bool isRetryEligible(
    SyncTask task, {
    DateTime? now,
    bool includeMaxRetryReached = false,
  }) {
    if (task.status != SyncStatus.failed) {
      return false;
    }

    if (_hasReachedMaxRetries(task) && !includeMaxRetryReached) {
      return false;
    }

    final nextAttemptAt = task.nextAttemptAt;
    if (nextAttemptAt == null) {
      return true;
    }

    return !nextAttemptAt.isAfter(now ?? _now());
  }

  Future<int> resetFailedTasksForAutomaticRetry({
    Set<String> entityTypes = const {
      'session_upsert',
      'session_delete',
      'dog_upsert',
      'dog_delete',
      'health_record_upsert',
    },
  }) {
    return _resetFailedTasksForRetry(
      entityTypes: entityTypes,
      ignoreCooldown: false,
      includeMaxRetryReached: false,
      resetRetryState: false,
    );
  }

  Future<int> resetFailedTasksForRetry({
    Set<String> entityTypes = const {
      'session_upsert',
      'session_delete',
      'dog_upsert',
      'dog_delete',
      'health_record_upsert',
    },
  }) {
    return _resetFailedTasksForRetry(
      entityTypes: entityTypes,
      ignoreCooldown: true,
      includeMaxRetryReached: true,
      resetRetryState: true,
    );
  }

  Future<int> _resetFailedTasksForRetry({
    required Set<String> entityTypes,
    required bool ignoreCooldown,
    required bool includeMaxRetryReached,
    required bool resetRetryState,
  }) async {
    final currentNow = _now();
    final normalizedEntityTypes = entityTypes
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();

    var resetCount = 0;
    var skippedCooldownCount = 0;
    var maxRetryReachedCount = 0;

    for (final entry in _box.toMap().entries) {
      final task = entry.value;
      final normalizedEntityType = task.entityType.trim().toLowerCase();
      final shouldReset = task.status == SyncStatus.failed &&
          normalizedEntityTypes.contains(normalizedEntityType);

      if (!shouldReset) {
        continue;
      }

      if (_hasReachedMaxRetries(task) && !includeMaxRetryReached) {
        maxRetryReachedCount++;
        debugPrint(
          '[SYNC][RETRY] max retries reached task=${task.taskId} '
          'retries=${task.retryCount}',
        );
        continue;
      }

      if (!ignoreCooldown && !isRetryEligible(task, now: currentNow)) {
        skippedCooldownCount++;
        debugPrint(
          '[SYNC][RETRY] skipped cooldown task=${task.taskId} '
          'retryAt=${task.nextAttemptAt?.toIso8601String()}',
        );
        continue;
      }

      await _box.put(
        entry.key,
        task.copyWith(
          status: SyncStatus.pending,
          retryCount: resetRetryState ? 0 : task.retryCount,
          nextAttemptAt: null,
        ),
      );
      resetCount++;
    }

    debugPrint(
      '[SYNC][RETRY] reset count=$resetCount '
      'cooldown_skipped=$skippedCooldownCount '
      'max_retries_skipped=$maxRetryReachedCount '
      'mode=${resetRetryState ? 'manual' : 'automatic'}',
    );
    return resetCount;
  }

  Future<void> markTaskInProgress(String taskId) async {
    final existing = _box.get(taskId);
    if (existing == null) {
      debugPrint('[SYNC][OUTBOX] missing task=$taskId for status=in_progress');
      return;
    }
    debugPrint('[SYNC][OUTBOX] task=$taskId status=in_progress');
    await _box.put(
      taskId,
      existing.copyWith(
        status: SyncStatus.inProgress,
        lastAttemptAt: _now(),
        lastError: null,
        nextAttemptAt: null,
      ),
    );
  }

  Future<void> markTaskDone(String taskId) async {
    final existing = _box.get(taskId);
    if (existing == null) {
      debugPrint('[SYNC][OUTBOX] missing task=$taskId for status=sent');
      return;
    }
    debugPrint('[SYNC][OUTBOX] task=$taskId status=sent');
    await _box.put(
      taskId,
      existing.copyWith(
        status: SyncStatus.sent,
        lastAttemptAt: _now(),
        lastError: null,
        nextAttemptAt: null,
      ),
    );
  }

  Future<void> markTaskFailed(String taskId, Object error) async {
    final existing = _box.get(taskId);
    if (existing == null) {
      debugPrint('[SYNC][OUTBOX] missing task=$taskId for status=failed');
      return;
    }

    final attemptedAt = _now();
    final nextRetryCount = existing.retryCount + 1;
    final errorText = error.toString();

    if (nextRetryCount >= maxRetryCount) {
      debugPrint(
        '[SYNC][RETRY] max retries reached task=$taskId retries=$nextRetryCount',
      );
      await _box.put(
        taskId,
        existing.copyWith(
          status: SyncStatus.failed,
          retryCount: nextRetryCount,
          lastAttemptAt: attemptedAt,
          lastError: errorText,
          nextAttemptAt: null,
        ),
      );
      return;
    }

    final nextAttemptAt = attemptedAt.add(_retryBackoffFor(nextRetryCount));
    debugPrint(
      '[SYNC][RETRY] scheduled task=$taskId retries=$nextRetryCount '
      'retryAt=${nextAttemptAt.toIso8601String()}',
    );
    await _box.put(
      taskId,
      existing.copyWith(
        status: SyncStatus.failed,
        retryCount: nextRetryCount,
        lastAttemptAt: attemptedAt,
        lastError: errorText,
        nextAttemptAt: nextAttemptAt,
      ),
    );
  }

  Future<void> markTaskWaitingForDependency(
    String taskId,
    Object error,
  ) async {
    final existing = _box.get(taskId);
    if (existing == null) return;
    await _box.put(
      taskId,
      existing.copyWith(
        status: SyncStatus.pending,
        lastAttemptAt: _now(),
        lastError: error.toString(),
        nextAttemptAt: null,
      ),
    );
  }

  Future<void> resetStaleInProgressTasks({
    Duration staleAfter = const Duration(minutes: 10),
  }) async {
    final cutoff = _now().subtract(staleAfter);
    for (final entry in _box.toMap().entries) {
      final task = entry.value;
      final lastAttemptAt = task.lastAttemptAt;
      if (task.status != SyncStatus.inProgress) {
        continue;
      }
      if (lastAttemptAt != null && lastAttemptAt.isAfter(cutoff)) {
        continue;
      }
      debugPrint('[SYNC][OUTBOX] reset stale task=${task.taskId}');
      await _box.put(
        entry.key,
        task.copyWith(
          status: SyncStatus.pending,
          lastError: task.lastError,
          nextAttemptAt: null,
        ),
      );
    }
  }

  Future<bool> _saveTask({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final taskId = _uuid.v4();
    try {
      final task = SyncTask(
        taskId: taskId,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        status: SyncStatus.pending,
        createdAt: _now(),
      );
      await _box.put(task.taskId, task);
      debugPrint(
        '[SYNC][OUTBOX] queued taskId=$taskId type=$entityType entityId=$entityId',
      );
      return true;
    } catch (error) {
      debugPrint(
        '[SYNC][OUTBOX] queue failed type=$entityType entityId=$entityId '
        'error=$error',
      );
      return false;
    }
  }

  Future<bool> _saveOrReplacePendingTask({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    MapEntry<dynamic, SyncTask>? pendingEntry;
    for (final entry in _box.toMap().entries) {
      if (entry.value.status == SyncStatus.pending &&
          entry.value.entityType == entityType &&
          entry.value.entityId == entityId) {
        pendingEntry = entry;
        break;
      }
    }
    if (pendingEntry == null) {
      return _saveTask(
        entityType: entityType,
        entityId: entityId,
        payload: payload,
      );
    }
    try {
      final existing = pendingEntry.value;
      await _box.put(
        pendingEntry.key,
        SyncTask(
          taskId: existing.taskId,
          entityType: entityType,
          entityId: entityId,
          payload: payload,
          status: SyncStatus.pending,
          createdAt: existing.createdAt,
        ),
      );
      return true;
    } catch (error) {
      debugPrint(
        '[SYNC][OUTBOX] replace failed type=$entityType entityId=$entityId '
        'error=$error',
      );
      return false;
    }
  }

  bool _isReadyToRun(
    SyncTask task, {
    required DateTime now,
  }) {
    final nextAttemptAt = task.nextAttemptAt;
    if (nextAttemptAt == null) {
      return true;
    }
    return !nextAttemptAt.isAfter(now);
  }

  bool _hasReachedMaxRetries(SyncTask task) {
    return task.retryCount >= maxRetryCount;
  }

  bool _isTaskNewer(SyncTask candidate, SyncTask current) {
    final createdAtComparison =
        candidate.createdAt.compareTo(current.createdAt);
    if (createdAtComparison != 0) {
      return createdAtComparison > 0;
    }

    final candidateAttempt =
        candidate.lastAttemptAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final currentAttempt =
        current.lastAttemptAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final lastAttemptComparison = candidateAttempt.compareTo(currentAttempt);
    if (lastAttemptComparison != 0) {
      return lastAttemptComparison > 0;
    }

    return candidate.taskId.compareTo(current.taskId) > 0;
  }

  void _triggerAutoSyncAfterEnqueue() {
    final autoSyncCoordinator = _autoSyncCoordinator;
    if (autoSyncCoordinator == null) {
      return;
    }

    if (!Hive.isBoxOpen(syncStateBoxName)) {
      debugPrint(
        '[SYNC][AUTO] skipped enqueue trigger: '
        'required box not open name=$syncStateBoxName',
      );
      return;
    }

    unawaited(autoSyncCoordinator.runAfterEnqueue());
  }

  Duration _retryBackoffFor(int retryCount) {
    if (retryCount <= 1) {
      return const Duration(seconds: 15);
    }
    if (retryCount == 2) {
      return const Duration(minutes: 1);
    }
    return const Duration(minutes: 5);
  }
}
