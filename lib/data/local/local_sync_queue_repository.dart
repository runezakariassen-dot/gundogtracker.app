import 'package:flutter/foundation.dart';

import '../../data/hive_boxes.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../models/sync_task.dart';

class LocalSyncQueueRepository implements SyncQueueRepository {
  @override
  Future<void> addTask(SyncTask task) async {
    debugPrint('[SYNC][QUEUE] addTask: ${_describeTask(task)}');
    await syncTasksBox().put(task.taskId, task);
    final saved = syncTasksBox().get(task.taskId);
    debugPrint(
      '[SYNC][QUEUE] addTask saved: '
      '${saved == null ? 'null' : _describeTask(saved)}',
    );
  }

  @override
  Future<List<SyncTask>> getPending({int? limit}) async {
    final box = syncTasksBox();
    debugPrint(
      '[SYNC][QUEUE] getPending start: boxCount=${box.length} limit=$limit',
    );
    final pending = <SyncTask>[];
    for (final entry in box.toMap().entries) {
      final task = entry.value;
      final include = task.status == SyncStatus.pending;
      final reason = include
          ? 'included status=pending'
          : 'excluded status=${task.status.name}';
      debugPrint(
        '[SYNC][QUEUE] getPending inspect: '
        'boxKey=${entry.key} ${_describeTask(task)} reason=$reason',
      );
      if (include) {
        pending.add(task);
      }
    }
    debugPrint(
        '[SYNC][QUEUE] getPending result: pendingCount=${pending.length}');
    if (limit == null || limit <= 0 || pending.length <= limit) {
      return pending;
    }
    return pending.take(limit).toList();
  }

  @override
  Future<void> markSent(String taskId) async {
    final existing = syncTasksBox().get(taskId);
    debugPrint(
      '[SYNC][QUEUE] markSent: '
      '${existing == null ? 'missing taskId=$taskId' : _describeTask(existing)}',
    );
    await _updateStatus(taskId, SyncStatus.sent);
  }

  @override
  Future<void> markFailed(String taskId) async {
    final box = syncTasksBox();
    final existing = box.get(taskId);
    if (existing == null) {
      debugPrint('[SYNC][QUEUE] markFailed skipped missing taskId=$taskId');
      return;
    }
    debugPrint('[SYNC][QUEUE] markFailed: ${_describeTask(existing)}');
    await box.put(
      taskId,
      existing.copyWith(
        status: SyncStatus.failed,
        retryCount: existing.retryCount + 1,
        lastAttemptAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> clearAll() async {
    debugPrint('[SYNC][QUEUE] clearAll: boxCount=${syncTasksBox().length}');
    await syncTasksBox().clear();
  }

  Future<void> _updateStatus(String taskId, SyncStatus status) async {
    final box = syncTasksBox();
    final existing = box.get(taskId);
    if (existing == null) {
      debugPrint(
        '[SYNC][QUEUE] updateStatus skipped missing: '
        'taskId=$taskId nextStatus=${status.name}',
      );
      return;
    }
    debugPrint(
      '[SYNC][QUEUE] updateStatus: '
      '${_describeTask(existing)} nextStatus=${status.name}',
    );
    final updated = existing.copyWith(
      status: status,
      lastAttemptAt: DateTime.now(),
    );
    await box.put(taskId, updated);
  }

  String _describeTask(SyncTask task) {
    return 'taskId=${task.taskId} '
        'entityType=${task.entityType} '
        'entityId=${task.entityId} '
        'status=${task.status.name} '
        'retryCount=${task.retryCount} '
        'createdAt=${task.createdAt.toIso8601String()} '
        'lastAttemptAt=${task.lastAttemptAt?.toIso8601String()} '
        'lastError=${task.lastError} '
        'payload=${task.payload}';
  }
}
