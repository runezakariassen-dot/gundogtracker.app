import 'package:hive/hive.dart';

part 'map_settings.g.dart';

@HiveType(typeId: 6)
class MapSettings extends HiveObject {
  @HiveField(0)
  final String mode;

  @HiveField(1)
  final String? offlineMbtilesPath;

  MapSettings({
    required this.mode,
    this.offlineMbtilesPath,
  });

  MapSettings copyWith({
    String? mode,
    String? offlineMbtilesPath,
  }) {
    return MapSettings(
      mode: mode ?? this.mode,
      offlineMbtilesPath: offlineMbtilesPath ?? this.offlineMbtilesPath,
    );
  }
}
