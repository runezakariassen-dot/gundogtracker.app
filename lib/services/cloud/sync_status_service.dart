import '../../data/local/sync_outbox_service.dart';
import '../../models/sync_task.dart' as outbox;

enum SyncStatus {
  synced,
  pending,
  inProgress,
  failed,
}

class SyncStatusService {
  SyncStatusService({
    SyncOutboxService? outboxService,
  }) : _outboxService =
            outboxService ?? SyncOutboxService(enableAutoSync: false);

  final SyncOutboxService _outboxService;

  SyncStatus statusForSession(String sessionId) {
    return statusForEntity(
      entityType: 'session_upsert',
      entityId: sessionId,
    );
  }

  SyncStatus statusForDog(String dogId) {
    return statusForEntity(
      entityType: 'dog_upsert',
      entityId: dogId,
    );
  }

  SyncStatus statusForEntity({
    required String entityType,
    required String entityId,
  }) {
    final task = _outboxService.latestTaskForEntity(
      entityType: entityType,
      entityId: entityId,
    );
    return mapTaskStatus(task?.status);
  }

  Stream<SyncStatus> watchSessionStatus(String sessionId) async* {
    yield statusForSession(sessionId);
    yield* _outboxService
        .watchTasks()
        .map((_) => statusForSession(sessionId))
        .distinct();
  }

  Stream<SyncStatus> watchDogStatus(String dogId) async* {
    yield statusForDog(dogId);
    yield* _outboxService
        .watchTasks()
        .map((_) => statusForDog(dogId))
        .distinct();
  }

  SyncStatus mapTaskStatus(outbox.SyncStatus? status) {
    switch (status) {
      case outbox.SyncStatus.pending:
        return SyncStatus.pending;
      case outbox.SyncStatus.inProgress:
        return SyncStatus.inProgress;
      case outbox.SyncStatus.failed:
        return SyncStatus.failed;
      case outbox.SyncStatus.sent:
      case null:
        return SyncStatus.synced;
    }
  }
}
