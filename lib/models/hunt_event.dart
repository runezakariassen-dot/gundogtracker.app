import 'package:hive/hive.dart';

enum HuntEventType {
  stand,
  birdContact,
  flush,
  bump,
  birdDown,
  backing,
  emptyStand,
  other,
}

enum HuntEventSource { manual, gpxWaypoint, garminExplore, imported }

@HiveType(typeId: 52)
class HuntEvent {
  static const int currentSchemaVersion = 1;

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String sessionId;
  @HiveField(2)
  final String dogId;
  @HiveField(3)
  final String? dogKey;
  @HiveField(4)
  final String typeValue;
  @HiveField(5)
  final DateTime occurredAt;
  @HiveField(6)
  final String? sourceTrackId;
  @HiveField(7)
  final int? trackPointIndex;
  @HiveField(8)
  final double? latitude;
  @HiveField(9)
  final double? longitude;
  @HiveField(10)
  final String? birdSpecies;
  @HiveField(11)
  final String? note;
  @HiveField(12)
  final String sourceValue;
  @HiveField(13)
  final String? sourceWaypointName;
  @HiveField(14)
  final String? sourceWaypointSymbol;
  @HiveField(15)
  final DateTime createdAt;
  @HiveField(16)
  final DateTime updatedAt;
  @HiveField(17)
  final String createdByUserId;
  @HiveField(18)
  final String? updatedByUserId;
  @HiveField(19)
  final DateTime? deletedAt;
  @HiveField(20)
  final int schemaVersion;

  HuntEvent({
    required this.id,
    required this.sessionId,
    required this.dogId,
    this.dogKey,
    required HuntEventType type,
    required this.occurredAt,
    this.sourceTrackId,
    this.trackPointIndex,
    this.latitude,
    this.longitude,
    this.birdSpecies,
    this.note,
    HuntEventSource source = HuntEventSource.manual,
    this.sourceWaypointName,
    this.sourceWaypointSymbol,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUserId,
    this.updatedByUserId,
    this.deletedAt,
    this.schemaVersion = currentSchemaVersion,
  }) : typeValue = type.name,
       sourceValue = source.name;

  const HuntEvent._({
    required this.id,
    required this.sessionId,
    required this.dogId,
    this.dogKey,
    required this.typeValue,
    required this.occurredAt,
    this.sourceTrackId,
    this.trackPointIndex,
    this.latitude,
    this.longitude,
    this.birdSpecies,
    this.note,
    required this.sourceValue,
    this.sourceWaypointName,
    this.sourceWaypointSymbol,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUserId,
    this.updatedByUserId,
    this.deletedAt,
    required this.schemaVersion,
  });

  HuntEventType get type => HuntEventType.values.firstWhere(
    (value) => value.name == typeValue,
    orElse: () => HuntEventType.other,
  );

  HuntEventSource get source => HuntEventSource.values.firstWhere(
    (value) => value.name == sourceValue,
    orElse: () => HuntEventSource.imported,
  );

  bool get isDeleted => deletedAt != null;

  HuntEvent copyWith({
    HuntEventType? type,
    DateTime? occurredAt,
    String? birdSpecies,
    String? note,
    DateTime? updatedAt,
    String? updatedByUserId,
    DateTime? deletedAt,
  }) {
    return HuntEvent._(
      id: id,
      sessionId: sessionId,
      dogId: dogId,
      dogKey: dogKey,
      typeValue: type?.name ?? typeValue,
      occurredAt: occurredAt ?? this.occurredAt,
      sourceTrackId: sourceTrackId,
      trackPointIndex: trackPointIndex,
      latitude: latitude,
      longitude: longitude,
      birdSpecies: birdSpecies,
      note: note,
      sourceValue: sourceValue,
      sourceWaypointName: sourceWaypointName,
      sourceWaypointSymbol: sourceWaypointSymbol,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUserId: createdByUserId,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      deletedAt: deletedAt ?? this.deletedAt,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'sessionId': sessionId,
    'dogId': dogId,
    'dogKey': dogKey,
    'type': typeValue,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'sourceTrackId': sourceTrackId,
    'trackPointIndex': trackPointIndex,
    'latitude': latitude,
    'longitude': longitude,
    'birdSpecies': birdSpecies,
    'note': note,
    'source': sourceValue,
    'sourceWaypointName': sourceWaypointName,
    'sourceWaypointSymbol': sourceWaypointSymbol,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'createdByUserId': createdByUserId,
    'updatedByUserId': updatedByUserId,
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory HuntEvent.fromJson(Map<String, dynamic> json) => HuntEvent._(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    dogId: json['dogId'] as String,
    dogKey: json['dogKey'] as String?,
    typeValue: json['type'] as String,
    occurredAt: DateTime.parse(json['occurredAt'] as String).toUtc(),
    sourceTrackId: json['sourceTrackId'] as String?,
    trackPointIndex: json['trackPointIndex'] as int?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    birdSpecies: json['birdSpecies'] as String?,
    note: json['note'] as String?,
    sourceValue: json['source'] as String,
    sourceWaypointName: json['sourceWaypointName'] as String?,
    sourceWaypointSymbol: json['sourceWaypointSymbol'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
    createdByUserId: json['createdByUserId'] as String,
    updatedByUserId: json['updatedByUserId'] as String?,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String).toUtc(),
    schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
  );
}

class HuntEventAdapter extends TypeAdapter<HuntEvent> {
  @override
  final int typeId = 52;

  @override
  HuntEvent read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return HuntEvent._(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      dogId: fields[2] as String,
      dogKey: fields[3] as String?,
      typeValue: fields[4] as String,
      occurredAt: fields[5] as DateTime,
      sourceTrackId: fields[6] as String?,
      trackPointIndex: fields[7] as int?,
      latitude: fields[8] as double?,
      longitude: fields[9] as double?,
      birdSpecies: fields[10] as String?,
      note: fields[11] as String?,
      sourceValue: fields[12] as String,
      sourceWaypointName: fields[13] as String?,
      sourceWaypointSymbol: fields[14] as String?,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
      createdByUserId: fields[17] as String,
      updatedByUserId: fields[18] as String?,
      deletedAt: fields[19] as DateTime?,
      schemaVersion: fields[20] as int? ?? HuntEvent.currentSchemaVersion,
    );
  }

  @override
  void write(BinaryWriter writer, HuntEvent value) {
    final values = <int, dynamic>{
      0: value.id,
      1: value.sessionId,
      2: value.dogId,
      3: value.dogKey,
      4: value.typeValue,
      5: value.occurredAt,
      6: value.sourceTrackId,
      7: value.trackPointIndex,
      8: value.latitude,
      9: value.longitude,
      10: value.birdSpecies,
      11: value.note,
      12: value.sourceValue,
      13: value.sourceWaypointName,
      14: value.sourceWaypointSymbol,
      15: value.createdAt,
      16: value.updatedAt,
      17: value.createdByUserId,
      18: value.updatedByUserId,
      19: value.deletedAt,
      20: value.schemaVersion,
    };
    writer.writeByte(values.length);
    for (final entry in values.entries) {
      writer
        ..writeByte(entry.key)
        ..write(entry.value);
    }
  }
}
