import 'package:hive/hive.dart';

import 'dog_membership.dart';

@HiveType(typeId: 8)
class ShareInvitation {
  @HiveField(0)
  final String inviteId;

  @HiveField(1)
  final String dogKey;

  @HiveField(2)
  final Role role;

  @HiveField(3)
  final String token;

  @HiveField(4)
  final DateTime expiresAt;

  @HiveField(5)
  final Status status;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String recipientEmail;

  @HiveField(8)
  final String? recipientUserId;

  @HiveField(9)
  final String createdByUserId;

  ShareInvitation({
    required this.inviteId,
    required this.dogKey,
    required this.role,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.recipientEmail,
    this.recipientUserId,
    required this.createdByUserId,
  });

  ShareInvitation copyWith({
    Role? role,
    Status? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? recipientEmail,
    String? recipientUserId,
    String? createdByUserId,
  }) {
    return ShareInvitation(
      inviteId: inviteId,
      dogKey: dogKey,
      role: role ?? this.role,
      token: token,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }
}

class ShareInvitationAdapter extends TypeAdapter<ShareInvitation> {
  @override
  final int typeId = 8;

  @override
  ShareInvitation read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return ShareInvitation(
      inviteId: fields[0] as String,
      dogKey: fields[1] as String,
      role: fields[2] as Role,
      token: fields[3] as String,
      createdAt:
          fields[6] as DateTime? ?? fields[4] as DateTime? ?? DateTime.now(),
      expiresAt: fields[4] as DateTime,
      status: fields[5] as Status,
      recipientEmail: fields[7] as String? ?? '',
      recipientUserId: fields[8] as String?,
      createdByUserId: fields[9] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ShareInvitation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.inviteId)
      ..writeByte(1)
      ..write(obj.dogKey)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.token)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.expiresAt)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.recipientEmail)
      ..writeByte(8)
      ..write(obj.recipientUserId)
      ..writeByte(9)
      ..write(obj.createdByUserId);
  }
}
