import 'package:hive/hive.dart';

import 'package:jakthund_app/utils/json_encodable.dart';

@HiveType(typeId: 18)
class DogMilestoneState implements JsonEncodable {
  @HiveField(0)
  final String dogId;

  @HiveField(1)
  final List<String> achievedIds;

  @HiveField(2)
  final DateTime? lastEvaluatedAt;

  @HiveField(3)
  final Map<String, DateTime> achievedAt;

  DogMilestoneState({
    required this.dogId,
    List<String>? achievedIds,
    this.lastEvaluatedAt,
    Map<String, DateTime>? achievedAt,
  })  : achievedIds = List.unmodifiable(achievedIds ?? const []),
        achievedAt = Map.unmodifiable(achievedAt ?? const {});

  DogMilestoneState copyWith({
    List<String>? achievedIds,
    DateTime? lastEvaluatedAt,
    Map<String, DateTime>? achievedAt,
  }) {
    return DogMilestoneState(
      dogId: dogId,
      achievedIds: achievedIds ?? this.achievedIds,
      lastEvaluatedAt: lastEvaluatedAt ?? this.lastEvaluatedAt,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'dogId': dogId,
      'achievedIds': achievedIds,
      'lastEvaluatedAt': lastEvaluatedAt?.toIso8601String(),
      'achievedAt': achievedAt.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }
}

class DogMilestoneStateAdapter extends TypeAdapter<DogMilestoneState> {
  @override
  final int typeId = 18;

  @override
  DogMilestoneState read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    final rawAchievedAt = fields[3];
    final achievedAt = rawAchievedAt is Map
        ? rawAchievedAt.cast<String, DateTime>()
        : <String, DateTime>{};
    return DogMilestoneState(
      dogId: fields[0] as String,
      achievedIds: (fields[1] as List?)?.cast<String>(),
      lastEvaluatedAt: fields[2] as DateTime?,
      achievedAt: achievedAt,
    );
  }

  @override
  void write(BinaryWriter writer, DogMilestoneState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dogId)
      ..writeByte(1)
      ..write(obj.achievedIds)
      ..writeByte(2)
      ..write(obj.lastEvaluatedAt)
      ..writeByte(3)
      ..write(obj.achievedAt);
  }
}
