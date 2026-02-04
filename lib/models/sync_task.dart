import 'package:hive/hive.dart';

@HiveType(typeId: 13)
enum SyncStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  sent,
  @HiveField(2)
  failed,
}

@HiveType(typeId: 10)
class SyncTask {
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

  SyncTask({
    required this.taskId,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.status,
    required this.createdAt,
  });
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 13;

  @override
  SyncStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return SyncStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    writer.writeByte(obj.index);
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
    );
  }

  @override
  void write(BinaryWriter writer, SyncTask obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.createdAt);
  }
}
