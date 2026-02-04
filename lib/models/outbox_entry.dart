import 'package:hive/hive.dart';

@HiveType(typeId: 220)
class OutboxEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String dogId;

  @HiveField(2)
  final String table;

  @HiveField(3)
  final String op;

  @HiveField(4)
  final String clientOpId;

  @HiveField(5)
  final Map<String, dynamic>? row;

  @HiveField(6)
  final Map<String, dynamic>? pk;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final int attemptCount;

  @HiveField(9)
  final DateTime? lastAttemptAt;

  @HiveField(10)
  final String status;

  @HiveField(11)
  final String? lastError;

  OutboxEntry({
    required this.id,
    required this.dogId,
    required this.table,
    required this.op,
    required this.clientOpId,
    required this.createdAt,
    required this.status,
    this.row,
    this.pk,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastError,
  });

  OutboxEntry copyWith({
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? status,
    String? lastError,
  }) {
    return OutboxEntry(
      id: id,
      dogId: dogId,
      table: table,
      op: op,
      clientOpId: clientOpId,
      row: row,
      pk: pk,
      createdAt: createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }
}

class OutboxEntryAdapter extends TypeAdapter<OutboxEntry> {
  @override
  final int typeId = 220;

  @override
  OutboxEntry read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return OutboxEntry(
      id: fields[0] as String,
      dogId: fields[1] as String,
      table: fields[2] as String,
      op: fields[3] as String,
      clientOpId: fields[4] as String,
      row: (fields[5] as Map?)?.cast<String, dynamic>(),
      pk: (fields[6] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[7] as DateTime,
      attemptCount: fields[8] as int? ?? 0,
      lastAttemptAt: fields[9] as DateTime?,
      status: fields[10] as String? ?? 'pending',
      lastError: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OutboxEntry obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.table)
      ..writeByte(3)
      ..write(obj.op)
      ..writeByte(4)
      ..write(obj.clientOpId)
      ..writeByte(5)
      ..write(obj.row)
      ..writeByte(6)
      ..write(obj.pk)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.attemptCount)
      ..writeByte(9)
      ..write(obj.lastAttemptAt)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.lastError);
  }
}
