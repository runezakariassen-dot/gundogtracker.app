import '../../models/sync_task.dart';

abstract class SyncQueueRepository {
  Future<void> addTask(SyncTask task);
  Future<List<SyncTask>> getPending({int? limit});
  Future<void> markSent(String taskId);
  Future<void> markFailed(String taskId);
  Future<void> clearAll();
}
