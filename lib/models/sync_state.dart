import 'package:hive/hive.dart';

@HiveType(typeId: 221)
class SyncState {
  @HiveField(0)
  final String dogId;

  @HiveField(1)
  final DateTime? lastPulledAt;

  @HiveField(2)
  final DateTime? lastPushedAt;

  @HiveField(3)
  final DateTime? lastServerTime;

  SyncState({
    required this.dogId,
    this.lastPulledAt,
    this.lastPushedAt,
    this.lastServerTime,
  });

  SyncState copyWith({
    DateTime? lastPulledAt,
    DateTime? lastPushedAt,
    DateTime? lastServerTime,
  }) {
    return SyncState(
      dogId: dogId,
      lastPulledAt: lastPulledAt ?? this.lastPulledAt,
      lastPushedAt: lastPushedAt ?? this.lastPushedAt,
      lastServerTime: lastServerTime ?? this.lastServerTime,
    );
  }
}

class SyncStateAdapter extends TypeAdapter<SyncState> {
  @override
  final int typeId = 221;

  @override
  SyncState read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return SyncState(
      dogId: fields[0] as String,
      lastPulledAt: fields[1] as DateTime?,
      lastPushedAt: fields[2] as DateTime?,
      lastServerTime: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dogId)
      ..writeByte(1)
      ..write(obj.lastPulledAt)
      ..writeByte(2)
      ..write(obj.lastPushedAt)
      ..writeByte(3)
      ..write(obj.lastServerTime);
  }
}
