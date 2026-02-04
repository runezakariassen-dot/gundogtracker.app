import 'package:hive/hive.dart';

part 'offline_region_metadata.g.dart';

@HiveType(typeId: 14)
class OfflineRegionMetadata extends HiveObject {
  OfflineRegionMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
    required this.minZoom,
    required this.maxZoom,
    required this.tileSourceKey,
    this.radiusKm,
    this.storeName,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final double minLat;

  @HiveField(4)
  final double minLon;

  @HiveField(5)
  final double maxLat;

  @HiveField(6)
  final double maxLon;

  @HiveField(7)
  final int minZoom;

  @HiveField(8)
  final int maxZoom;

  @HiveField(9)
  final String tileSourceKey;

  @HiveField(10)
  final double? radiusKm;

  @HiveField(11)
  final String? storeName;
}
