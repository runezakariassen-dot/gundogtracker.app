import 'package:hive/hive.dart';

import 'package:jakthund_app/utils/json_encodable.dart';

import 'gps_point.dart';

part 'track.g.dart';

@HiveType(typeId: 5)
class Track implements JsonEncodable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final String source;

  @HiveField(3)
  final List<GpsPoint> points;

  const Track({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.points,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
      'points': points.map((point) => point.toJson()).toList(),
    };
  }
}
