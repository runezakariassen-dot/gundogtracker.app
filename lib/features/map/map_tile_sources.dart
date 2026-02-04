class MapTileSource {
  const MapTileSource({
    required this.key,
    required this.label,
    required this.urlTemplate,
    required this.attribution,
    required this.storeName,
  });

  final String key;
  final String label;
  final String urlTemplate;
  final String attribution;
  final String storeName;
}

// TODO: Sett tile-leverandor som tillater offline nedlasting i produksjon.
const String standardStyleUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

// TODO: Sett tile-leverandor som tillater offline nedlasting i produksjon.
const String terrainStyleUrlTemplate =
    'https://tile.opentopomap.org/{z}/{x}/{y}.png';

const MapTileSource standardTileSource = MapTileSource(
  key: 'standard',
  label: 'Standard',
  urlTemplate: standardStyleUrlTemplate,
  attribution: 'OpenStreetMap contributors',
  storeName: 'map_tiles_standard',
);

const MapTileSource terrainTileSource = MapTileSource(
  key: 'terrain',
  label: 'Terreng',
  urlTemplate: terrainStyleUrlTemplate,
  attribution: 'OpenTopoMap (CC-BY-SA)',
  storeName: 'map_tiles_terrain',
);

const List<MapTileSource> mapTileSources = [
  standardTileSource,
  terrainTileSource,
];

MapTileSource tileSourceByKey(String key) {
  for (final source in mapTileSources) {
    if (source.key == key) return source;
  }
  return standardTileSource;
}
