import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/gps_point.dart';
import '../../models/track.dart';
import '../../repositories/track_repository.dart';

class TrackCloudFormatException implements Exception {
  const TrackCloudFormatException(this.message);

  final String message;

  @override
  String toString() => 'TrackCloudFormatException: $message';
}

typedef TrackMetadataReader = Future<Map<String, dynamic>?> Function(
  String dogId,
  String trackId,
);
typedef TrackMetadataWriter = Future<void> Function(
  String dogId,
  String trackId,
  Map<String, dynamic> payload,
);
typedef TrackBytesReader = Future<Uint8List?> Function(String storagePath);
typedef TrackBytesWriter = Future<void> Function(
  String storagePath,
  Uint8List bytes,
);

class FirestoreTrackSyncService {
  FirestoreTrackSyncService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    TrackRepository? trackRepository,
    TrackMetadataReader? metadataReader,
    TrackMetadataWriter? metadataWriter,
    TrackBytesReader? bytesReader,
    TrackBytesWriter? bytesWriter,
  }) : _trackRepository = trackRepository ?? TrackRepository() {
    final effectiveFirestore = metadataReader == null || metadataWriter == null
        ? (firestore ?? FirebaseFirestore.instance)
        : null;
    final effectiveStorage = bytesReader == null || bytesWriter == null
        ? (storage ?? FirebaseStorage.instance)
        : null;
    _metadataReader = metadataReader ??
        (dogId, trackId) async {
          final snapshot = await effectiveFirestore!
              .collection('dogs')
              .doc(dogId)
              .collection('tracks')
              .doc(trackId)
              .get();
          return snapshot.data();
        };
    _metadataWriter = metadataWriter ??
        (dogId, trackId, payload) => effectiveFirestore!
            .collection('dogs')
            .doc(dogId)
            .collection('tracks')
            .doc(trackId)
            .set(payload);
    _bytesReader = bytesReader ??
        (path) async {
          try {
            return await effectiveStorage!.ref(path).getData();
          } on FirebaseException catch (error) {
            if (error.code == 'object-not-found') return null;
            rethrow;
          }
        };
    _bytesWriter = bytesWriter ??
        (path, bytes) async {
          await effectiveStorage!.ref(path).putData(
                bytes,
                SettableMetadata(
                  contentType: 'application/json; charset=utf-8',
                ),
              );
        };
  }

  static final FirestoreTrackSyncService instance = FirestoreTrackSyncService();

  static const int schemaVersion = 1;

  final TrackRepository _trackRepository;
  late final TrackMetadataReader _metadataReader;
  late final TrackMetadataWriter _metadataWriter;
  late final TrackBytesReader _bytesReader;
  late final TrackBytesWriter _bytesWriter;

  static String storagePath({
    required String dogId,
    required String trackId,
  }) =>
      'dogs/$dogId/tracks/$trackId/track.json';

  static Map<String, dynamic> metadataPayload({
    required Track track,
    required String sessionId,
    required String cloudDogId,
  }) {
    return <String, dynamic>{
      'trackId': track.id,
      'sessionId': sessionId,
      'dogId': cloudDogId,
      'cloudDogId': cloudDogId,
      'source': track.source,
      'pointCount': track.points.length,
      'storagePath': storagePath(dogId: cloudDogId, trackId: track.id),
      'createdAt': Timestamp.fromDate(track.createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(track.createdAt.toUtc()),
      'schemaVersion': schemaVersion,
    };
  }

  static Uint8List serializeTrack(Track track) {
    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'trackId': track.id,
      'createdAt': track.createdAt.toUtc().toIso8601String(),
      'source': track.source,
      'pointCount': track.points.length,
      'points': track.points
          .map((point) => <String, dynamic>{
                'lat': point.lat,
                'lon': point.lon,
                'time': point.time.toUtc().toIso8601String(),
              })
          .toList(growable: false),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  static Track deserializeTrack(
    Uint8List bytes, {
    required String expectedTrackId,
    int? expectedPointCount,
  }) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (error) {
      throw TrackCloudFormatException('Invalid UTF-8/JSON: $error');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const TrackCloudFormatException('Root must be a JSON object.');
    }
    if (decoded['schemaVersion'] != schemaVersion) {
      throw const TrackCloudFormatException('Unsupported schemaVersion.');
    }
    final trackId = decoded['trackId'];
    if (trackId is! String || trackId != expectedTrackId) {
      throw const TrackCloudFormatException('trackId mismatch.');
    }
    final source = decoded['source'];
    final createdAtValue = decoded['createdAt'];
    final rawPoints = decoded['points'];
    if (source is! String || createdAtValue is! String || rawPoints is! List) {
      throw const TrackCloudFormatException('Missing required Track fields.');
    }
    final createdAt = DateTime.tryParse(createdAtValue);
    if (createdAt == null) {
      throw const TrackCloudFormatException('Invalid createdAt.');
    }

    final points = <GpsPoint>[];
    for (final rawPoint in rawPoints) {
      if (rawPoint is! Map<String, dynamic>) {
        throw const TrackCloudFormatException('Invalid point object.');
      }
      final lat = rawPoint['lat'];
      final lon = rawPoint['lon'];
      final timeValue = rawPoint['time'];
      if (lat is! num || lon is! num || timeValue is! String) {
        throw const TrackCloudFormatException('Invalid point fields.');
      }
      final latitude = lat.toDouble();
      final longitude = lon.toDouble();
      final time = DateTime.tryParse(timeValue);
      if (!latitude.isFinite || latitude < -90 || latitude > 90) {
        throw const TrackCloudFormatException('Invalid latitude.');
      }
      if (!longitude.isFinite || longitude < -180 || longitude > 180) {
        throw const TrackCloudFormatException('Invalid longitude.');
      }
      if (time == null) {
        throw const TrackCloudFormatException('Invalid point timestamp.');
      }
      points.add(GpsPoint(lat: latitude, lon: longitude, time: time));
    }

    final declaredPointCount = decoded['pointCount'];
    if (declaredPointCount is! int || declaredPointCount != points.length) {
      throw const TrackCloudFormatException('JSON pointCount mismatch.');
    }
    if (expectedPointCount != null && expectedPointCount != points.length) {
      throw const TrackCloudFormatException('Metadata pointCount mismatch.');
    }

    return Track(
      id: trackId,
      createdAt: createdAt,
      source: source,
      points: points,
    );
  }

  Future<void> ensureTrackUploaded({
    required String trackId,
    required String sessionId,
    required String cloudDogId,
  }) async {
    final track = await _trackRepository.getTrack(trackId);
    if (track == null) {
      throw StateError('Missing local Track for cloud upload: $trackId');
    }
    final existing = await _metadataReader(cloudDogId, trackId);
    if (existing != null) {
      _validateMetadata(
        existing,
        expectedTrackId: trackId,
        expectedCloudDogId: cloudDogId,
        expectedPointCount: track.points.length,
        expectedStoragePath: storagePath(dogId: cloudDogId, trackId: trackId),
      );
      final cloudTrack = await _downloadAndValidate(
        existing,
        expectedTrackId: trackId,
        expectedCloudDogId: cloudDogId,
      );
      if (!_sameTrack(track, cloudTrack)) {
        throw StateError(
            'Immutable cloud Track differs from local Track: $trackId');
      }
      return;
    }

    final bytes = serializeTrack(track);
    final path = storagePath(dogId: cloudDogId, trackId: trackId);
    final existingBytes = await _bytesReader(path);
    if (existingBytes != null) {
      final existingTrack = deserializeTrack(
        existingBytes,
        expectedTrackId: trackId,
        expectedPointCount: track.points.length,
      );
      if (!_sameTrack(track, existingTrack)) {
        throw StateError('Immutable Storage Track conflict: $trackId');
      }
    } else {
      await _bytesWriter(path, bytes);
    }
    await _metadataWriter(
      cloudDogId,
      trackId,
      metadataPayload(
        track: track,
        sessionId: sessionId,
        cloudDogId: cloudDogId,
      ),
    );
  }

  Future<void> ensureTrackDownloaded({
    required String trackId,
    required String cloudDogId,
  }) async {
    if (await _trackRepository.getTrack(trackId) != null) return;
    final metadata = await _metadataReader(cloudDogId, trackId);
    if (metadata == null) {
      throw StateError('Missing cloud Track metadata: $trackId');
    }
    final track = await _downloadAndValidate(
      metadata,
      expectedTrackId: trackId,
      expectedCloudDogId: cloudDogId,
    );
    if (await _trackRepository.getTrack(trackId) == null) {
      await _trackRepository.upsertTrack(track);
    }
  }

  Future<Track> _downloadAndValidate(
    Map<String, dynamic> metadata, {
    required String expectedTrackId,
    required String expectedCloudDogId,
  }) async {
    final pointCount = metadata['pointCount'];
    final path = metadata['storagePath'];
    _validateMetadata(
      metadata,
      expectedTrackId: expectedTrackId,
      expectedCloudDogId: expectedCloudDogId,
      expectedPointCount: pointCount is int ? pointCount : -1,
      expectedStoragePath: storagePath(
        dogId: expectedCloudDogId,
        trackId: expectedTrackId,
      ),
    );
    final bytes = await _bytesReader(path as String);
    if (bytes == null) {
      throw StateError('Cloud Track is empty: $expectedTrackId');
    }
    return deserializeTrack(
      bytes,
      expectedTrackId: expectedTrackId,
      expectedPointCount: pointCount as int,
    );
  }

  static void _validateMetadata(
    Map<String, dynamic>? metadata, {
    required String expectedTrackId,
    required String expectedCloudDogId,
    required int expectedPointCount,
    required String expectedStoragePath,
  }) {
    if (metadata == null ||
        metadata['schemaVersion'] != schemaVersion ||
        metadata['trackId'] != expectedTrackId ||
        metadata['dogId'] != expectedCloudDogId ||
        metadata['cloudDogId'] != expectedCloudDogId ||
        metadata['pointCount'] != expectedPointCount ||
        metadata['storagePath'] != expectedStoragePath) {
      throw const TrackCloudFormatException('Invalid Track metadata.');
    }
  }

  static bool _sameTrack(Track left, Track right) {
    if (left.id != right.id ||
        left.source != right.source ||
        left.createdAt.toUtc() != right.createdAt.toUtc() ||
        left.points.length != right.points.length) {
      return false;
    }
    for (var index = 0; index < left.points.length; index++) {
      final a = left.points[index];
      final b = right.points[index];
      if (a.lat != b.lat ||
          a.lon != b.lon ||
          a.time.toUtc() != b.time.toUtc()) {
        return false;
      }
    }
    return true;
  }
}
