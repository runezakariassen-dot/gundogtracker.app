import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../models/dog.dart';
import '../../models/hunt_session.dart';
import '../../models/sync_task.dart';

class SyncCleanupResult {
  const SyncCleanupResult({
    this.removedTasks = 0,
    this.removedRecords = 0,
    this.skippedCandidates = 0,
  });

  final int removedTasks;
  final int removedRecords;
  final int skippedCandidates;
}

class SyncCleanupService {
  SyncCleanupService({
    Box<SyncTask>? outboxBox,
    Box<Dog>? dogBox,
    Box<HuntSession>? sessionBox,
    DateTime Function()? now,
    Duration sentTaskRetention = const Duration(days: 7),
    Duration tombstoneRetention = const Duration(days: 30),
    Future<void> Function()? onStart,
  })  : _outboxBox = outboxBox ?? syncTasksBox(),
        _dogBox = dogBox ?? dogsBox(),
        _sessionBox = sessionBox ?? sessionsBox(),
        _now = now ?? DateTime.now,
        _sentTaskRetention = sentTaskRetention,
        _tombstoneRetention = tombstoneRetention,
        _onStart = onStart;

  final Box<SyncTask> _outboxBox;
  final Box<Dog> _dogBox;
  final Box<HuntSession> _sessionBox;
  final DateTime Function() _now;
  final Duration _sentTaskRetention;
  final Duration _tombstoneRetention;
  final Future<void> Function()? _onStart;

  bool _isRunning = false;

  Future<SyncCleanupResult> runCleanup() async {
    if (_isRunning) {
      debugPrint(
          '[SYNC][CLEANUP] skipped unsafe candidate: cleanup already running');
      return const SyncCleanupResult();
    }

    _isRunning = true;
    try {
      debugPrint('[SYNC][CLEANUP] start');
      final onStart = _onStart;
      if (onStart != null) {
        await onStart();
      }

      var removedTasks = 0;
      var removedRecords = 0;
      var skippedCandidates = 0;
      final now = _now().toUtc();

      final dogCleanup = await _cleanupDogTombstones(now);
      removedRecords += dogCleanup.removedRecords;
      skippedCandidates += dogCleanup.skippedCandidates;

      final sessionCleanup = await _cleanupSessionTombstones(now);
      removedRecords += sessionCleanup.removedRecords;
      skippedCandidates += sessionCleanup.skippedCandidates;

      removedTasks += await _cleanupSentTasks(now);

      debugPrint(
        '[SYNC][CLEANUP] complete '
        'removedTasks=$removedTasks removedRecords=$removedRecords',
      );
      return SyncCleanupResult(
        removedTasks: removedTasks,
        removedRecords: removedRecords,
        skippedCandidates: skippedCandidates,
      );
    } finally {
      _isRunning = false;
    }
  }

  Future<SyncCleanupResult> _cleanupDogTombstones(DateTime now) async {
    var removedRecords = 0;
    var skippedCandidates = 0;

    for (final entry in _dogBox.toMap().entries) {
      final dog = entry.value;
      final deletedAt = dog.deletedAt?.toUtc();
      if (deletedAt == null) {
        continue;
      }
      if (now.difference(deletedAt) < _tombstoneRetention) {
        continue;
      }
      if (_hasUnsafeOutboxTask(
        entityTypes: const <String>{'dog_upsert', 'dog_delete'},
        entityId: dog.id,
      )) {
        skippedCandidates++;
        debugPrint(
          '[SYNC][CLEANUP] skipped unsafe candidate: '
          'dog=${dog.id} active_outbox_task=true',
        );
        continue;
      }

      await _dogBox.delete(entry.key);
      removedRecords++;
      debugPrint('[SYNC][CLEANUP] tombstone removed: dog=${dog.id}');
    }

    return SyncCleanupResult(
      removedRecords: removedRecords,
      skippedCandidates: skippedCandidates,
    );
  }

  Future<SyncCleanupResult> _cleanupSessionTombstones(DateTime now) async {
    var removedRecords = 0;
    var skippedCandidates = 0;

    for (final entry in _sessionBox.toMap().entries) {
      final session = entry.value;
      final deletedAt = session.deletedAt?.toUtc();
      if (deletedAt == null) {
        continue;
      }
      if (now.difference(deletedAt) < _tombstoneRetention) {
        continue;
      }
      final entityId = _sessionEntityId(entry.key);
      if (_hasUnsafeOutboxTask(
        entityTypes: const <String>{'session_upsert', 'session_delete'},
        entityId: entityId,
      )) {
        skippedCandidates++;
        debugPrint(
          '[SYNC][CLEANUP] skipped unsafe candidate: '
          'session=$entityId active_outbox_task=true',
        );
        continue;
      }

      await _sessionBox.delete(entry.key);
      removedRecords++;
      debugPrint('[SYNC][CLEANUP] tombstone removed: session=$entityId');
    }

    return SyncCleanupResult(
      removedRecords: removedRecords,
      skippedCandidates: skippedCandidates,
    );
  }

  Future<int> _cleanupSentTasks(DateTime now) async {
    var removedTasks = 0;

    for (final entry in _outboxBox.toMap().entries) {
      final task = entry.value;
      if (task.status != SyncStatus.sent) {
        continue;
      }

      final sentAt = (task.lastAttemptAt ?? task.createdAt).toUtc();
      if (now.difference(sentAt) < _sentTaskRetention) {
        continue;
      }

      await _outboxBox.delete(entry.key);
      removedTasks++;
      debugPrint(
        '[SYNC][CLEANUP] sent task removed: '
        '${task.entityType} entityId=${task.entityId}',
      );
    }

    return removedTasks;
  }

  bool _hasUnsafeOutboxTask({
    required Set<String> entityTypes,
    required String entityId,
  }) {
    final normalizedEntityId = entityId.trim();
    final normalizedEntityTypes =
        entityTypes.map((value) => value.trim().toLowerCase()).toSet();

    for (final task in _outboxBox.values) {
      if (!normalizedEntityTypes
          .contains(task.entityType.trim().toLowerCase())) {
        continue;
      }
      if (task.entityId.trim() != normalizedEntityId) {
        continue;
      }
      if (task.status == SyncStatus.pending ||
          task.status == SyncStatus.inProgress ||
          task.status == SyncStatus.failed) {
        return true;
      }
    }

    return false;
  }

  String _sessionEntityId(dynamic hiveKey) {
    return hiveKey.toString().trim();
  }
}
