import 'package:hive/hive.dart';

import 'package:jakthund_app/utils/json_encodable.dart';

@HiveType(typeId: 15)
class AchievedMilestone implements JsonEncodable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime achievedAt;

  AchievedMilestone({
    required this.id,
    required this.achievedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'achievedAt': achievedAt.toIso8601String(),
    };
  }
}

class AchievedMilestoneAdapter extends TypeAdapter<AchievedMilestone> {
  @override
  final int typeId = 15;

  @override
  AchievedMilestone read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return AchievedMilestone(
      id: fields[0] as String,
      achievedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AchievedMilestone obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.achievedAt);
  }
}
