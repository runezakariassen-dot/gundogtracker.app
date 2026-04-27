import 'package:hive/hive.dart';

@HiveType(typeId: 13)
enum SyncStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  sent,
  @HiveField(2)
  failed,
  @HiveField(3)
  inProgress,
}

@HiveType(typeId: 10)
class SyncTask {
  static const Object _noValue = Object();

  @HiveField(0)
  final String taskId;

  @HiveField(1)
  final String entityType;

  @HiveField(2)
  final String entityId;

  @HiveField(3)
  final Map<String, dynamic> payload;

  @HiveField(4)
  final SyncStatus status;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final int retryCount;

  @HiveField(7)
  final String? lastError;

  @HiveField(8)
  final DateTime? lastAttemptAt;

  @HiveField(9)
  final DateTime? nextAttemptAt;

  SyncTask({
    required this.taskId,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.lastAttemptAt,
    this.nextAttemptAt,
  });

  SyncTask copyWith({
    SyncStatus? status,
    int? retryCount,
    Object? lastError = _noValue,
    Object? lastAttemptAt = _noValue,
    Object? nextAttemptAt = _noValue,
  }) {
    return SyncTask(
      taskId: taskId,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      status: status ?? this.status,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: identical(lastError, _noValue)
          ? this.lastError
          : lastError as String?,
      lastAttemptAt: identical(lastAttemptAt, _noValue)
          ? this.lastAttemptAt
          : lastAttemptAt as DateTime?,
      nextAttemptAt: identical(nextAttemptAt, _noValue)
          ? this.nextAttemptAt
          : nextAttemptAt as DateTime?,
    );
  }
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 13;

  @override
  SyncStatus read(BinaryReader reader) {
    final index = reader.readByte();
    switch (index) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.sent;
      case 2:
        return SyncStatus.failed;
      case 3:
        return SyncStatus.inProgress;
      default:
        return SyncStatus.failed;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.pending:
        writer.writeByte(0);
        return;
      case SyncStatus.sent:
        writer.writeByte(1);
        return;
      case SyncStatus.failed:
        writer.writeByte(2);
        return;
      case SyncStatus.inProgress:
        writer.writeByte(3);
        return;
    }
  }
}

class SyncTaskAdapter extends TypeAdapter<SyncTask> {
  @override
  final int typeId = 10;

  @override
  SyncTask read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return SyncTask(
      taskId: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      payload: Map<String, dynamic>.from(fields[3] as Map),
      status: fields[4] as SyncStatus,
      createdAt: fields[5] as DateTime,
      retryCount: fields[6] as int? ?? 0,
      lastError: fields[7] as String?,
      lastAttemptAt: fields[8] as DateTime?,
      nextAttemptAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncTask obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.lastError)
      ..writeByte(8)
      ..write(obj.lastAttemptAt)
      ..writeByte(9)
      ..write(obj.nextAttemptAt);
  }
}
