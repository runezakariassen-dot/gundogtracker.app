import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/services/gpx_importer.dart';

void main() {
  test(
    'GpxImporter parser et enkelt spor',
    () {
      const gpx = '''
<gpx version="1.1" creator="Test">
  <trk>
    <name>Demo</name>
    <trkseg>
      <trkpt lat="63.1234" lon="10.4321">
        <time>2024-01-01T10:00:00Z</time>
      </trkpt>
      <trkpt lat="63.2234" lon="10.5321">
        <time>2024-01-01T10:05:00Z</time>
      </trkpt>
    </trkseg>
  </trk>
</gpx>
''';

      final points = GpxImporter.parse(gpx);
      expect(points, isNotEmpty);
      expect(points.length, 2);
      expect(points.first.lat, closeTo(63.1234, 0.0001));
      expect(points.first.lon, closeTo(10.4321, 0.0001));
      expect(points.first.time.toUtc(), DateTime.parse('2024-01-01T10:00:00Z'));
    },
    tags: ['slow'],
  );

  test(
    'GpxImporter støtter namespaces',
    () {
      const gpx = '''
<gpx xmlns="http://www.topografix.com/GPX/1/1" version="1.1" creator="Demo">
  <trk>
    <trkseg>
      <ns:trkpt xmlns:ns="http://www.topografix.com/GPX/1/1" lat="60.1" lon="11.2">
        <ns:time>2024-02-01T12:00:00Z</ns:time>
      </ns:trkpt>
    </trkseg>
  </trk>
</gpx>
''';

      final points = GpxImporter.parse(gpx);
      expect(points.length, 1);
      expect(points.first.lat, closeTo(60.1, 0.0001));
      expect(points.first.lon, closeTo(11.2, 0.0001));
      expect(points.first.time.toUtc(), DateTime.parse('2024-02-01T12:00:00Z'));
    },
    tags: ['slow'],
  );

  test(
    'GpxImporter fyller inn tid når <time> mangler',
    () {
      const gpx = '''
<gpx version="1.1">
  <trk>
    <trkseg>
      <trkpt lat="61.0" lon="9.0" />
      <trkpt lat="61.1" lon="9.1" />
      <trkpt lat="61.2" lon="9.2" />
    </trkseg>
  </trk>
</gpx>
''';

      final points = GpxImporter.parse(gpx);
      expect(points.length, 3);
      final first = points.first.time;
      final second = points[1].time;
      final third = points[2].time;

      expect(second.isAfter(first) || second.isAtSameMomentAs(first), isTrue);
      expect(third.isAfter(second) || third.isAtSameMomentAs(second), isTrue);
    },
    tags: ['slow'],
  );

  test(
    'GpxImporter faller tilbake til rute-punkter',
    () {
      const gpx = '''
<gpx version="1.1">
  <rte>
    <name>Route</name>
    <rtept lat="62.1" lon="8.1">
      <time>2024-03-01T08:00:00Z</time>
    </rtept>
    <rtept lat="62.2" lon="8.2">
      <time>2024-03-01T08:05:00Z</time>
    </rtept>
  </rte>
</gpx>
''';

      final points = GpxImporter.parse(gpx);
      expect(points.length, 2);
      expect(points.first.lat, closeTo(62.1, 0.0001));
      expect(points.first.lon, closeTo(8.1, 0.0001));
    },
    tags: ['slow'],
  );

  test(
    'GpxImporter faller tilbake til waypoints',
    () {
      const gpx = '''
<gpx version="1.1">
  <wpt lat="64.1" lon="7.1">
    <time>2024-04-01T09:00:00Z</time>
  </wpt>
  <wpt lat="64.2" lon="7.2">
    <time>2024-04-01T09:05:00Z</time>
  </wpt>
</gpx>
''';

      final points = GpxImporter.parse(gpx);
      expect(points.length, 2);
      expect(points.first.lat, closeTo(64.1, 0.0001));
      expect(points.first.lon, closeTo(7.1, 0.0001));
    },
    tags: ['slow'],
  );

  test(
    'GpxImporter prioriterer trkpt over rtept',
    () {
      const gpx = '''
<gpx version="1.1">
  <trk>
    <trkseg>
      <trkpt lat="70.0" lon="10.0">
        <time>2024-05-01T10:00:00Z</time>
      </trkpt>
    </trkseg>
  </trk>
  <rte>
    <rtept lat="999.0" lon="999.0">
      <time>2024-05-01T10:05:00Z</time>
    </rtept>
  </rte>
</gpx>
''';

      final points = GpxImporter.parse(gpx);
      expect(points.length, 1);
      expect(points.first.lat, closeTo(70.0, 0.0001));
      expect(points.first.lon, closeTo(10.0, 0.0001));
    },
    tags: ['slow'],
  );
}
