import '../models/gps_point.dart';

class GpxImporter {
  static List<GpsPoint> parsePoints(String gpx) {
    final points = <GpsPoint>[];

    final trkptRe = RegExp(
      r'<trkpt[^>]*lat="([^"]+)"[^>]*lon="([^"]+)"[^>]*>([\s\S]*?)</trkpt>',
      caseSensitive: false,
    );
    final timeRe = RegExp(r'<time>([^<]+)</time>', caseSensitive: false);

    for (final m in trkptRe.allMatches(gpx)) {
      final lat = double.tryParse(m.group(1) ?? '');
      final lon = double.tryParse(m.group(2) ?? '');
      if (lat == null || lon == null) continue;

      final inner = m.group(3) ?? '';
      final tm = timeRe.firstMatch(inner);
      if (tm == null) continue;

      final tRaw = (tm.group(1) ?? '').trim();
      final time = DateTime.tryParse(tRaw);
      if (time == null) continue;

      points.add(GpsPoint(lat: lat, lon: lon, time: time.toLocal()));
    }

    points.sort((a, b) => a.time.compareTo(b.time));
    return points;
  }
}
