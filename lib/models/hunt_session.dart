import 'package:hive/hive.dart';

import 'package:jakthund_app/utils/json_encodable.dart';
import 'session_type.dart';

part 'hunt_session.g.dart';

@HiveType(typeId: 1)
class HuntSession extends HiveObject implements JsonEncodable {
  static const Object _noValue = Object();

  @HiveField(0)
  final String dogId;

  @HiveField(13)
  final String? dogKey;

  @HiveField(1)
  final DateTime dateTime;

  @HiveField(2)
  final String location;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final int birdsSeen;

  @HiveField(5)
  final int points;

  @HiveField(6)
  final int flushes;

  @HiveField(7)
  final String notes;

  @HiveField(12)
  final int secondaryPoints;

  @HiveField(20)
  final int tomstandCount;

  @HiveField(8)
  final int? trackKey;

  @HiveField(9)
  final String? trackId;

  @HiveField(10)
  final List<String> birdSpecies;

  @HiveField(11)
  final List<String> mediaPaths;

  @HiveField(14)
  final String? createdByUserId;

  @HiveField(15)
  final SessionType sessionType;

  @HiveField(16)
  final int birdsShotCount;

  @HiveField(17)
  final String? birdsShotSpecies;

  @HiveField(18)
  final DateTime updatedAt;

  @HiveField(19)
  final DateTime? deletedAt;

  static String normalizeLocation(String? value) {
    if (value == null) {
      return '';
    }
    return value.trim();
  }

  HuntSession({
    required this.dogId,
    this.dogKey,
    required this.dateTime,
    required String location,
    required this.durationMinutes,
    required this.birdsSeen,
    required this.points,
    required this.flushes,
    required this.notes,
    int? secondaryPoints,
    int? tomstandCount,
    this.trackKey,
    this.trackId,
    List<String>? birdSpecies,
    List<String>? mediaPaths,
    this.createdByUserId,
    SessionType? sessionType,
    int? birdsShotCount,
    this.birdsShotSpecies,
    DateTime? updatedAt,
    this.deletedAt,
  })  : location = normalizeLocation(location),
        birdSpecies = birdSpecies ?? const [],
        mediaPaths = mediaPaths ?? const [],
        secondaryPoints = secondaryPoints ?? 0,
        tomstandCount = tomstandCount ?? 0,
        sessionType = sessionType ?? SessionType.training,
        birdsShotCount = birdsShotCount ?? 0,
        updatedAt = updatedAt ?? DateTime.now();

  HuntSession copyWith({
    String? dogId,
    String? dogKey,
    DateTime? dateTime,
    String? location,
    int? durationMinutes,
    int? birdsSeen,
    int? points,
    int? flushes,
    String? notes,
    int? secondaryPoints,
    int? tomstandCount,
    int? trackKey,
    String? trackId,
    List<String>? birdSpecies,
    List<String>? mediaPaths,
    String? createdByUserId,
    SessionType? sessionType,
    int? birdsShotCount,
    String? birdsShotSpecies,
    DateTime? updatedAt,
    Object? deletedAt = _noValue,
  }) {
    return HuntSession(
      dogId: dogId ?? this.dogId,
      dogKey: dogKey ?? this.dogKey,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      birdsSeen: birdsSeen ?? this.birdsSeen,
      points: points ?? this.points,
      flushes: flushes ?? this.flushes,
      notes: notes ?? this.notes,
      secondaryPoints: secondaryPoints ?? this.secondaryPoints,
      tomstandCount: tomstandCount ?? this.tomstandCount,
      trackKey: trackKey ?? this.trackKey,
      trackId: trackId ?? this.trackId,
      birdSpecies: birdSpecies ?? List<String>.from(this.birdSpecies),
      mediaPaths: mediaPaths ?? List<String>.from(this.mediaPaths),
      createdByUserId: createdByUserId ?? this.createdByUserId,
      sessionType: sessionType ?? this.sessionType,
      birdsShotCount: birdsShotCount ?? this.birdsShotCount,
      birdsShotSpecies: birdsShotSpecies ?? this.birdsShotSpecies,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: identical(deletedAt, _noValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
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
      'tomstandCount': tomstandCount,
      'trackKey': trackKey,
      'trackId': trackId,
      'birdSpecies': birdSpecies,
      'mediaPaths': mediaPaths,
      'createdByUserId': createdByUserId,
      'sessionType': sessionType.name,
      'birdsShotCount': birdsShotCount,
      'birdsShotSpecies': birdsShotSpecies,
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  bool get isDeleted => deletedAt != null;
}
