import 'package:hive/hive.dart';

import 'package:jakthund_app/utils/json_encodable.dart';

import 'gps_point.dart';

part 'gps_track.g.dart';

@HiveType(typeId: 4)
class GpsTrack implements JsonEncodable {
  @HiveField(0)
  final String dogId;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final DateTime endTime;

  @HiveField(3)
  final List<GpsPoint> points;

  GpsTrack({
    required this.dogId,
    required this.startTime,
    required this.endTime,
    required this.points,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'dogId': dogId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'points': points.map((point) => point.toJson()).toList(),
    };
  }
}
