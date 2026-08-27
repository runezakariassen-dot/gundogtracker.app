import '../../models/dog.dart';
import '../../models/hunt_session.dart';
import '../../models/health_record.dart';

enum MergeDecision {
  insert,
  cloudNewer,
  localNewer,
  equal,
}

class SyncMergePolicy {
  const SyncMergePolicy._();

  static MergeDecision forDog({
    required Dog? local,
    required Dog cloud,
  }) {
    return _compareUpdatedAt(
      localUpdatedAt: local?.updatedAt,
      cloudUpdatedAt: cloud.updatedAt,
    );
  }

  static MergeDecision forSession({
    required HuntSession? local,
    required HuntSession cloud,
  }) {
    return _compareUpdatedAt(
      localUpdatedAt: local?.updatedAt,
      cloudUpdatedAt: cloud.updatedAt,
    );
  }

  static MergeDecision forHealthRecord({
    required HealthRecord? local,
    required HealthRecord cloud,
  }) {
    return _compareUpdatedAt(
      localUpdatedAt: local?.updatedAt,
      cloudUpdatedAt: cloud.updatedAt,
    );
  }

  static MergeDecision _compareUpdatedAt({
    required DateTime? localUpdatedAt,
    required DateTime cloudUpdatedAt,
  }) {
    if (localUpdatedAt == null) {
      return MergeDecision.insert;
    }

    final normalizedLocal = localUpdatedAt.toUtc();
    final normalizedCloud = cloudUpdatedAt.toUtc();

    if (normalizedLocal.isAfter(normalizedCloud)) {
      return MergeDecision.localNewer;
    }
    if (normalizedCloud.isAfter(normalizedLocal)) {
      return MergeDecision.cloudNewer;
    }
    return MergeDecision.equal;
  }
}
