import '../../models/hunt_session.dart';
import '../../models/session_type.dart';

class HuntSessionDto {
  HuntSessionDto({
    required this.id,
    required this.dogId,
    required this.dateTime,
    required this.location,
    required this.durationMinutes,
    required this.birdsSeen,
    required this.points,
    required this.flushes,
    required this.notes,
    required this.secondaryPoints,
    this.dogKey,
    this.trackKey,
    this.trackId,
    List<String>? birdSpecies,
    List<String>? mediaPaths,
    this.createdByUserId,
    this.sessionType = SessionType.training,
    this.birdsShotCount = 0,
    this.birdsShotSpecies,
  })  : birdSpecies = birdSpecies ?? const [],
        mediaPaths = mediaPaths ?? const [];

  final String id;
  final String dogId;
  final String? dogKey;
  final DateTime dateTime;
  final String location;
  final int durationMinutes;
  final int birdsSeen;
  final int points;
  final int flushes;
  final String notes;
  final int secondaryPoints;
  final int? trackKey;
  final String? trackId;
  final List<String> birdSpecies;
  final List<String> mediaPaths;
  final String? createdByUserId;
  final SessionType sessionType;
  final int birdsShotCount;
  final String? birdsShotSpecies;

  factory HuntSessionDto.fromJson(Map<String, dynamic> json) {
    return HuntSessionDto(
      id: _requireString(json, 'id'),
      dogId: _requireString(json, 'dogId'),
      dogKey: _readString(json, 'dogKey'),
      dateTime: _requireDate(json, 'dateTime'),
      location: _requireString(json, 'location'),
      durationMinutes: _requireInt(json, 'durationMinutes'),
      birdsSeen: _requireInt(json, 'birdsSeen'),
      points: _requireInt(json, 'points'),
      flushes: _requireInt(json, 'flushes'),
      notes: _requireString(json, 'notes'),
      secondaryPoints: _requireInt(json, 'secondaryPoints'),
      trackKey: _readInt(json, 'trackKey'),
      trackId: _readString(json, 'trackId'),
      birdSpecies: _readStringList(json, 'birdSpecies'),
      mediaPaths: _readStringList(json, 'mediaPaths'),
      createdByUserId: _readString(json, 'createdByUserId'),
      sessionType: sessionTypeFromString(_readString(json, 'sessionType')),
      birdsShotCount: _readInt(json, 'birdsShotCount') ?? 0,
      birdsShotSpecies: _readString(json, 'birdsShotSpecies'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'dogKey': dogKey,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'durationMinutes': durationMinutes,
      'birdsSeen': birdsSeen,
      'points': points,
      'flushes': flushes,
      'notes': notes,
      'secondaryPoints': secondaryPoints,
      'trackKey': trackKey,
      'trackId': trackId,
      'birdSpecies': birdSpecies,
      'mediaPaths': mediaPaths,
      'createdByUserId': createdByUserId,
      'sessionType': sessionType.name,
      'birdsShotCount': birdsShotCount,
      'birdsShotSpecies': birdsShotSpecies,
    };
  }

  factory HuntSessionDto.fromModel(String id, HuntSession session) {
    return HuntSessionDto(
      id: id,
      dogId: session.dogId,
      dogKey: session.dogKey,
      dateTime: session.dateTime,
      location: session.location,
      durationMinutes: session.durationMinutes,
      birdsSeen: session.birdsSeen,
      points: session.points,
      flushes: session.flushes,
      notes: session.notes,
      secondaryPoints: session.secondaryPoints,
      trackKey: session.trackKey,
      trackId: session.trackId,
      birdSpecies: session.birdSpecies,
      mediaPaths: session.mediaPaths,
      createdByUserId: session.createdByUserId,
      sessionType: session.sessionType,
      birdsShotCount: session.birdsShotCount,
      birdsShotSpecies: session.birdsShotSpecies,
    );
  }

  HuntSession toModel() {
    return HuntSession(
      dogId: dogId,
      dogKey: dogKey,
      dateTime: dateTime,
      location: location,
      durationMinutes: durationMinutes,
      birdsSeen: birdsSeen,
      points: points,
      flushes: flushes,
      notes: notes,
      secondaryPoints: secondaryPoints,
      trackKey: trackKey,
      trackId: trackId,
      birdSpecies: birdSpecies,
      mediaPaths: mediaPaths,
      createdByUserId: createdByUserId,
      sessionType: sessionType,
      birdsShotCount: birdsShotCount,
      birdsShotSpecies: birdsShotSpecies,
    );
  }
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid string for "$key".');
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('Invalid string for "$key".');
}

DateTime _requireDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = _parseDate(value);
  if (parsed == null) {
    throw FormatException('Missing or invalid date for "$key".');
  }
  return parsed;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  throw const FormatException('Invalid date value.');
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('Missing or invalid int for "$key".');
}

int? _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw FormatException('Invalid int for "$key".');
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return <String>[];
  }
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  throw FormatException('Invalid list for "$key".');
}
