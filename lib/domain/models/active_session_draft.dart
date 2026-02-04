import 'package:hive/hive.dart';

@HiveType(typeId: 48)
class ActiveSessionDraft {
  @HiveField(0)
  final String sessionId;
  @HiveField(1)
  final String dogId;
  @HiveField(2)
  final DateTime startedAt;
  @HiveField(3)
  final DateTime lastSavedAt;
  @HiveField(4)
  final int activeMinutes;
  @HiveField(5)
  final int birdCount;
  @HiveField(6)
  final int standCount;
  @HiveField(7)
  final int flushCount;
  @HiveField(8)
  final String? notes;
  @HiveField(9)
  final String? locationName;
  @HiveField(10)
  final String? trackId;

  ActiveSessionDraft({
    required this.sessionId,
    required this.dogId,
    required this.startedAt,
    required this.lastSavedAt,
    required this.activeMinutes,
    required this.birdCount,
    required this.standCount,
    required this.flushCount,
    this.notes,
    this.locationName,
    this.trackId,
  });

  factory ActiveSessionDraft.now({
    required String sessionId,
    required String dogId,
    DateTime? startedAt,
    int activeMinutes = 0,
    int birdCount = 0,
    int standCount = 0,
    int flushCount = 0,
    String? notes,
    String? locationName,
    String? trackId,
  }) {
    final now = DateTime.now();
    return ActiveSessionDraft(
      sessionId: sessionId,
      dogId: dogId,
      startedAt: startedAt ?? now,
      lastSavedAt: now,
      activeMinutes: activeMinutes,
      birdCount: birdCount,
      standCount: standCount,
      flushCount: flushCount,
      notes: notes,
      locationName: locationName,
      trackId: trackId,
    );
  }

  ActiveSessionDraft copyWith({
    String? sessionId,
    String? dogId,
    DateTime? startedAt,
    DateTime? lastSavedAt,
    int? activeMinutes,
    int? birdCount,
    int? standCount,
    int? flushCount,
    String? notes,
    String? locationName,
    String? trackId,
  }) {
    return ActiveSessionDraft(
      sessionId: sessionId ?? this.sessionId,
      dogId: dogId ?? this.dogId,
      startedAt: startedAt ?? this.startedAt,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      birdCount: birdCount ?? this.birdCount,
      standCount: standCount ?? this.standCount,
      flushCount: flushCount ?? this.flushCount,
      notes: notes ?? this.notes,
      locationName: locationName ?? this.locationName,
      trackId: trackId ?? this.trackId,
    );
  }
}

class ActiveSessionDraftAdapter extends TypeAdapter<ActiveSessionDraft> {
  @override
  final int typeId = 48;

  @override
  ActiveSessionDraft read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return ActiveSessionDraft(
      sessionId: fields[0] as String,
      dogId: fields[1] as String,
      startedAt: fields[2] as DateTime,
      lastSavedAt: fields[3] as DateTime,
      activeMinutes: fields[4] as int,
      birdCount: fields[5] as int,
      standCount: fields[6] as int,
      flushCount: fields[7] as int,
      notes: fields[8] as String?,
      locationName: fields[9] as String?,
      trackId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ActiveSessionDraft obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.startedAt)
      ..writeByte(3)
      ..write(obj.lastSavedAt)
      ..writeByte(4)
      ..write(obj.activeMinutes)
      ..writeByte(5)
      ..write(obj.birdCount)
      ..writeByte(6)
      ..write(obj.standCount)
      ..writeByte(7)
      ..write(obj.flushCount)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.locationName)
      ..writeByte(10)
      ..write(obj.trackId);
  }
}
