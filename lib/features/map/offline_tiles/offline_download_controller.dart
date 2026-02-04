import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

class OfflineDownloadController {
  OfflineDownloadController({
    required this.store,
    required this.tileSourceKey,
    required this.tileLayer,
  });

  final FMTCStore store;
  final String tileSourceKey;
  final TileLayer tileLayer;

  Object? _instanceId;

  Object? get instanceId => _instanceId;

  LatLngBounds buildBoundsFromCenter(LatLng center, double radiusKm) {
    final latDelta = radiusKm / 110.574;
    final lonDelta = radiusKm / (111.320 * cos(center.latitude * pi / 180));
    return LatLngBounds(
      LatLng(center.latitude - latDelta, center.longitude - lonDelta),
      LatLng(center.latitude + latDelta, center.longitude + lonDelta),
    );
  }

  int estimateWorkload(LatLngBounds bounds, int minZoom, int maxZoom) {
    var total = 0;
    for (var zoom = minZoom; zoom <= maxZoom; zoom++) {
      final xMin = _lonToTileX(bounds.west, zoom);
      final xMax = _lonToTileX(bounds.east, zoom);
      final yMin = _latToTileY(bounds.north, zoom);
      final yMax = _latToTileY(bounds.south, zoom);
      total += (xMax - xMin + 1) * (yMax - yMin + 1);
    }
    return total;
  }

  ({Stream<DownloadProgress> progress, DownloadableRegion region})
      startDownload({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    int parallelThreads = 2,
    int maxBufferLength = 60,
    bool skipExistingTiles = true,
  }) {
    final region = RectangleRegion(bounds).toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: tileLayer,
    );
    _instanceId = DateTime.now().microsecondsSinceEpoch;
    final download = store.download.startForeground(
      region: region,
      parallelThreads: parallelThreads,
      maxBufferLength: maxBufferLength,
      skipExistingTiles: skipExistingTiles,
      instanceId: _instanceId!,
    );
    return (progress: download.downloadProgress, region: region);
  }

  Future<void> cancelDownload() async {
    if (_instanceId == null) return;
    await store.download.cancel(instanceId: _instanceId!);
  }

  int _lonToTileX(double lon, int zoom) {
    final n = 1 << zoom;
    return ((lon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
  }

  int _latToTileY(double lat, int zoom) {
    final n = 1 << zoom;
    final clamped = lat.clamp(-85.05112878, 85.05112878).toDouble();
    final rad = clamped * pi / 180.0;
    final merc = log(tan(rad) + 1 / cos(rad));
    final y = (1 - merc / pi) / 2 * n;
    return y.floor().clamp(0, n - 1);
  }
}
