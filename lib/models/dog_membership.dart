import 'package:hive/hive.dart';

@HiveType(typeId: 11)
enum Role {
  @HiveField(0)
  owner,
  @HiveField(1)
  editor,
  @HiveField(2)
  viewer,
  @HiveField(3)
  admin,
}

enum CanonicalRole {
  admin,
  user,
}

extension RoleCanonical on Role {
  CanonicalRole get canonical {
    switch (this) {
      case Role.owner:
      case Role.admin:
        return CanonicalRole.admin;
      case Role.editor:
      case Role.viewer:
        return CanonicalRole.user;
    }
  }

  bool get isCanonicalAdmin => canonical == CanonicalRole.admin;
  bool get isCanonicalUser => canonical == CanonicalRole.user;
}

@HiveType(typeId: 12)
enum Status {
  @HiveField(0)
  active,
  @HiveField(1)
  revoked,
  @HiveField(2)
  pending,
  @HiveField(3)
  accepted,
  @HiveField(4)
  cancelled,
  @HiveField(5)
  expired,
}

@HiveType(typeId: 7)
class DogMembership {
  @HiveField(0)
  final String dogKey;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final Role role;

  @HiveField(3)
  final Status status;

  @HiveField(4)
  final DateTime addedAt;

  @HiveField(5)
  final String addedByUserId;

  DogMembership({
    required this.dogKey,
    required this.userId,
    required this.role,
    required this.status,
    required this.addedAt,
    required this.addedByUserId,
  });

  DogMembership copyWith({
    Role? role,
    Status? status,
  }) {
    return DogMembership(
      dogKey: dogKey,
      userId: userId,
      role: role ?? this.role,
      status: status ?? this.status,
      addedAt: addedAt,
      addedByUserId: addedByUserId,
    );
  }
}

class DogMembershipAdapter extends TypeAdapter<DogMembership> {
  @override
  final int typeId = 7;

  @override
  DogMembership read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return DogMembership(
      dogKey: fields[0] as String,
      userId: fields[1] as String,
      role: fields[2] as Role,
      status: fields[3] as Status,
      addedAt: fields[4] as DateTime,
      addedByUserId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DogMembership obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dogKey)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.addedAt)
      ..writeByte(5)
      ..write(obj.addedByUserId);
  }
}

class RoleAdapter extends TypeAdapter<Role> {
  @override
  final int typeId = 11;

  @override
  Role read(BinaryReader reader) {
    final index = reader.readByte();
    return Role.values[index];
  }

  @override
  void write(BinaryWriter writer, Role obj) {
    writer.writeByte(obj.index);
  }
}

class StatusAdapter extends TypeAdapter<Status> {
  @override
  final int typeId = 12;

  @override
  Status read(BinaryReader reader) {
    final index = reader.readByte();
    return Status.values[index];
  }

  @override
  void write(BinaryWriter writer, Status obj) {
    writer.writeByte(obj.index);
  }
}
