import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../models/gps_point.dart';

void logGpx(String msg) {
  if (kDebugMode) {
    debugPrint(msg);
  }
}

class GpxImporter {
  static List<GpsPoint> parse(String gpxXml) {
    XmlDocument document;
    try {
      document = XmlDocument.parse(gpxXml);
    } on XmlParserException catch (e) {
      throw FormatException('Invalid GPX: ${e.message}');
    }

    if (kDebugMode) {
      final lines = gpxXml.split('\n');
      final previewLines = lines.take(40).join('\n');
      logGpx(
        'GPX parse preview (first ${lines.length < 40 ? lines.length : 40} lines):\n$previewLines',
      );

      final root = document.rootElement;
      final childNames = root.children
          .whereType<XmlElement>()
          .map((element) => element.name.local)
          .toSet()
          .join(', ');
      logGpx('GPX child elements: [$childNames]');
    }

    final trkpts = _findPoints(document, 'trkpt');
    final rtepts = _findPoints(document, 'rtept');
    final wpts = _findPoints(document, 'wpt');
    final totalPoints = trkpts.length + rtepts.length + wpts.length;
    final elements = _selectPointElements(
      trkpts: trkpts,
      rtepts: rtepts,
      wpts: wpts,
    );

    if (totalPoints == 0) {
      throw const FormatException(
        'Fant for få spor-punkter i GPX-filen. Eksporter et lagret spor (track) fra enheten.',
      );
    }

    if (trkpts.isEmpty && rtepts.isEmpty && wpts.length == 1) {
      throw const FormatException(
        'GPX-filen inneholder kun et punkt (waypoint), ikke et spor. På Garmin: Track Manager → Lagre spor → Eksporter/Del GPX.',
      );
    }

    if (kDebugMode) {
      logGpx(
        'GPX counts - trkpt:${trkpts.length}, rtept:${rtepts.length}, wpt:${wpts.length}',
      );
      logGpx(
        'GPX parse: using ${elements.length} ${trkpts.isNotEmpty ? 'trkpt' : rtepts.isNotEmpty ? 'rtept' : 'wpt'} elements',
      );
      if (elements.isNotEmpty) {
        logGpx(
          'GPX parse: first element raw: ${elements.first.toXmlString(pretty: true)}',
        );
      }
    }

    if (elements.isEmpty) {
      throw const FormatException('No track points found in GPX');
    }

    final rawPoints = <_RawPoint>[];

    for (final element in elements) {
      final latStr = element.getAttribute('lat');
      final lonStr = element.getAttribute('lon');
      final lat = double.tryParse(latStr ?? '');
      final lon = double.tryParse(lonStr ?? '');

      if (kDebugMode) {
        logGpx('GPX parse: point lat="$latStr" lon="$lonStr"');
      }

      if (lat == null || lon == null) {
        if (kDebugMode) {
          logGpx('GPX parse: skipping point due to invalid lat/lon');
        }
        continue;
      }

      final timeText = _extractTime(element);
      if (kDebugMode) {
        logGpx('GPX parse: extracted time="$timeText"');
      }

      final parsedTime = timeText != null ? DateTime.tryParse(timeText) : null;
      if (parsedTime == null && timeText != null && kDebugMode) {
        logGpx('GPX parse: invalid time format: $timeText');
      }

      rawPoints.add(
        _RawPoint(
          lat: lat,
          lon: lon,
          timeUtc: parsedTime?.toUtc(),
        ),
      );
    }

    if (rawPoints.isEmpty) {
      throw const FormatException('No track points found in GPX');
    }

    final firstWithTime = rawPoints.firstWhere(
      (point) => point.timeUtc != null,
      orElse: () => rawPoints.first,
    );
    final baseTime = firstWithTime.timeUtc ?? DateTime.now().toUtc();

    final points = <GpsPoint>[];
    for (var i = 0; i < rawPoints.length; i++) {
      final raw = rawPoints[i];
      final timeUtc = raw.timeUtc ?? baseTime.add(Duration(seconds: i));
      points.add(
        GpsPoint(
          lat: raw.lat,
          lon: raw.lon,
          time: timeUtc.toLocal(),
        ),
      );
    }

    return points;
  }

  static String? _extractTime(XmlElement element) {
    return _findFirstChildText(element, 'time');
  }

  static List<XmlElement> _findPoints(XmlDocument doc, String localName) {
    return doc.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == localName)
        .toList();
  }

  static List<XmlElement> _selectPointElements({
    required List<XmlElement> trkpts,
    required List<XmlElement> rtepts,
    required List<XmlElement> wpts,
  }) {
    if (trkpts.isNotEmpty) {
      return trkpts;
    }
    if (rtepts.isNotEmpty) {
      return rtepts;
    }
    return wpts;
  }

  static String? _findFirstChildText(XmlElement element, String localName) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (child.name.local != localName) {
        continue;
      }

      final value = child.innerText.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class _RawPoint {
  _RawPoint({
    required this.lat,
    required this.lon,
    required this.timeUtc,
  });

  final double lat;
  final double lon;
  final DateTime? timeUtc;
}
