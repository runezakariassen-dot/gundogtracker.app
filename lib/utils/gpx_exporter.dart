import 'package:intl/intl.dart';
import '../models/gps_point.dart';

class GPXExporter {
  /// Lager en enkel GPX 1.1 track med <trkpt lat="" lon=""><time>..</time></trkpt>
  static String exportToGpx({
    required String trackName,
    required List<GpsPoint> points,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="FuglehundApp">');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>$trackName</name>');
    buffer.writeln('    <trkseg>');

    // GPX forventer ofte UTC/ISO
    final formatter = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'");

    for (final p in points) {
      final time = formatter.format(p.time.toUtc());
      buffer.writeln(
        '      <trkpt lat="${p.lat}" lon="${p.lon}"><time>$time</time></trkpt>',
      );
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }
}
