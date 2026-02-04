import 'package:hive/hive.dart';

import 'package:jakthund_app/utils/json_encodable.dart';

part 'gps_point.g.dart';

@HiveType(typeId: 3)
class GpsPoint implements JsonEncodable {
  @HiveField(0)
  final double lat;

  @HiveField(1)
  final double lon;

  @HiveField(2)
  final DateTime time;

  GpsPoint({
    required this.lat,
    required this.lon,
    required this.time,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'time': time.toIso8601String(),
    };
  }
}
