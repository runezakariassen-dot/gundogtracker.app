import 'package:hive/hive.dart';

import 'dog_membership.dart';

@HiveType(typeId: 9)
class OwnershipTransfer {
  @HiveField(0)
  final String transferId;

  @HiveField(1)
  final String dogKey;

  @HiveField(2)
  final String fromUserId;

  @HiveField(3)
  final String toUserId;

  @HiveField(4)
  final Status status;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime expiresAt;

  OwnershipTransfer({
    required this.transferId,
    required this.dogKey,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  OwnershipTransfer copyWith({
    Status? status,
  }) {
    return OwnershipTransfer(
      transferId: transferId,
      dogKey: dogKey,
      fromUserId: fromUserId,
      toUserId: toUserId,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}

class OwnershipTransferAdapter extends TypeAdapter<OwnershipTransfer> {
  @override
  final int typeId = 9;

  @override
  OwnershipTransfer read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return OwnershipTransfer(
      transferId: fields[0] as String,
      dogKey: fields[1] as String,
      fromUserId: fields[2] as String,
      toUserId: fields[3] as String,
      status: fields[4] as Status,
      createdAt: fields[5] as DateTime,
      expiresAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OwnershipTransfer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.transferId)
      ..writeByte(1)
      ..write(obj.dogKey)
      ..writeByte(2)
      ..write(obj.fromUserId)
      ..writeByte(3)
      ..write(obj.toUserId)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.expiresAt);
  }
}
