import 'package:hive/hive.dart';

import '../models/map_settings.dart';

enum MapTileMode { online, offline }

class MapTileConfig {
  const MapTileConfig({
    required this.mode,
    required this.urlTemplate,
    required this.attribution,
  });

  final MapTileMode mode;
  final String urlTemplate;
  final String attribution;
}

const MapTileConfig _onlineDefaultConfig = MapTileConfig(
  mode: MapTileMode.online,
  urlTemplate: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
  attribution: '© OpenStreetMap contributors',
);

const String _mapSettingsBoxName = 'mapSettings';
const String _mapSettingsKey = 'map';

MapTileConfig getCurrentMapTileConfig() {
  if (!Hive.isBoxOpen(_mapSettingsBoxName)) {
    return _onlineDefaultConfig;
  }

  final settingsBox = Hive.box<MapSettings>(_mapSettingsBoxName);
  MapSettings? settings = settingsBox.get(_mapSettingsKey);

  if (settings == null) {
    settings = MapSettings(mode: MapTileMode.online.name);
    settingsBox.put(_mapSettingsKey, settings);
    return _onlineDefaultConfig;
  }

  final mode = settings.mode == MapTileMode.offline.name
      ? MapTileMode.offline
      : MapTileMode.online;

  if (mode == MapTileMode.offline) {
    if (settings.offlineMbtilesPath == null ||
        settings.offlineMbtilesPath!.isEmpty) {
      return _onlineDefaultConfig;
    }
    // Offline not implemented yet; fallback to online config
    return _onlineDefaultConfig;
  }

  if (_onlineDefaultConfig.urlTemplate.isEmpty) {
    return _onlineDefaultConfig;
  }

  return _onlineDefaultConfig;
}
