import '../../data/hive_boxes.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../models/sync_task.dart';

class LocalSyncQueueRepository implements SyncQueueRepository {
  @override
  Future<void> addTask(SyncTask task) async {
    await syncTasksBox().put(task.taskId, task);
  }

  @override
  Future<List<SyncTask>> getPending({int? limit}) async {
    final pending = syncTasksBox()
        .values
        .where((task) => task.status == SyncStatus.pending)
        .toList();
    if (limit == null || limit <= 0 || pending.length <= limit) {
      return pending;
    }
    return pending.take(limit).toList();
  }

  @override
  Future<void> markSent(String taskId) async {
    await _updateStatus(taskId, SyncStatus.sent);
  }

  @override
  Future<void> markFailed(String taskId) async {
    await _updateStatus(taskId, SyncStatus.failed);
  }

  @override
  Future<void> clearAll() async {
    await syncTasksBox().clear();
  }

  Future<void> _updateStatus(String taskId, SyncStatus status) async {
    final box = syncTasksBox();
    final existing = box.get(taskId);
    if (existing == null) {
      return;
    }
    final updated = SyncTask(
      taskId: existing.taskId,
      entityType: existing.entityType,
      entityId: existing.entityId,
      payload: existing.payload,
      status: status,
      createdAt: existing.createdAt,
    );
    await box.put(taskId, updated);
  }
}
