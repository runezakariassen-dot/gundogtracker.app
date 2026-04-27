import '../models/gps_point.dart';
import '../repositories/session_repository.dart';
import '../services/gpx_importer.dart';

class ImportGpxToSession {
  ImportGpxToSession({
    SessionRepository? sessionRepository,
  }) : _sessionRepository = sessionRepository ?? SessionRepository();

  final SessionRepository _sessionRepository;

  Future<void> call({
    required String sessionId,
    required String gpxXml,
  }) async {
    final points = _parsePoints(gpxXml);
    if (points.length < 2) {
      throw const FormatException('GPX må inneholde minst to punkter');
    }

    await _sessionRepository.replaceTrackForSession(
      sessionId,
      points,
      source: 'gpx_import',
    );
  }

  List<GpsPoint> _parsePoints(String gpxXml) {
    try {
      return GpxImporter.parse(gpxXml);
    } catch (e) {
      throw FormatException('Ugyldig GPX-data: $e');
    }
  }
}
