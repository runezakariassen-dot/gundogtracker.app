import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/models/track_adapter_v2.dart';
import 'package:jakthund_app/repositories/track_repository.dart';
import 'package:jakthund_app/services/cloud/firestore_track_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Track> trackBox;
  late TrackRepository repository;
  late Map<String, Map<String, dynamic>> metadata;
  late Map<String, Uint8List> objects;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('track_cloud_sync_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GpsPointAdapter());
    if (!Hive.isAdapterRegistered(16)) Hive.registerAdapter(TrackAdapterV2());
    trackBox = await Hive.openBox<Track>('tracks_test');
    repository = TrackRepository(box: trackBox);
    metadata = <String, Map<String, dynamic>>{};
    objects = <String, Uint8List>{};
  });

  tearDown(() async {
    await trackBox.close();
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  FirestoreTrackSyncService service({
    TrackRepository? trackRepository,
    TrackBytesWriter? bytesWriter,
  }) {
    return FirestoreTrackSyncService(
      trackRepository: trackRepository ?? repository,
      metadataReader: (dogId, trackId) async => metadata['$dogId/$trackId'],
      metadataWriter: (dogId, trackId, payload) async {
        metadata['$dogId/$trackId'] = Map<String, dynamic>.from(payload);
      },
      bytesReader: (path) async => objects[path],
      bytesWriter: bytesWriter ??
          (path, bytes) async {
            objects[path] = Uint8List.fromList(bytes);
          },
    );
  }

  test('Storage JSON round-trip preserves one point and unicode source', () {
    final original = track(points: 1, source: 'Zöe – råspor 🐕');
    final restored = FirestoreTrackSyncService.deserializeTrack(
      FirestoreTrackSyncService.serializeTrack(original),
      expectedTrackId: original.id,
      expectedPointCount: 1,
    );

    expect(restored.id, original.id);
    expect(restored.source, original.source);
    expect(restored.points.single.lat, original.points.single.lat);
    expect(restored.points.single.lon, original.points.single.lon);
    expect(restored.points.single.time, original.points.single.time);
  });

  test('large 3000 point Track round-trips', () {
    final original = track(points: 3000);
    final restored = FirestoreTrackSyncService.deserializeTrack(
      FirestoreTrackSyncService.serializeTrack(original),
      expectedTrackId: original.id,
      expectedPointCount: 3000,
    );

    expect(restored.points, hasLength(3000));
    expect(restored.points.last.lat, original.points.last.lat);
    expect(restored.points.last.time, original.points.last.time);
  });

  test('upload writes Storage before metadata and is idempotent', () async {
    final original = track(points: 3);
    await repository.upsertTrack(original);
    final calls = <String>[];
    final sync = FirestoreTrackSyncService(
      trackRepository: repository,
      metadataReader: (dogId, trackId) async {
        calls.add('read-metadata');
        return metadata['$dogId/$trackId'];
      },
      metadataWriter: (dogId, trackId, payload) async {
        calls.add('write-metadata');
        metadata['$dogId/$trackId'] = Map<String, dynamic>.from(payload);
      },
      bytesReader: (path) async {
        calls.add('read-storage');
        return objects[path];
      },
      bytesWriter: (path, bytes) async {
        calls.add('write-storage');
        objects[path] = Uint8List.fromList(bytes);
      },
    );

    await sync.ensureTrackUploaded(
      trackId: original.id,
      sessionId: 'session-1',
      cloudDogId: 'dog-1',
    );
    expect(calls.indexOf('write-storage'),
        lessThan(calls.indexOf('write-metadata')));
    expect(metadata['dog-1/${original.id}']?['pointCount'], 3);
    expect(metadata['dog-1/${original.id}']?['sessionId'], 'session-1');
    final unchanged = await repository.getTrack(original.id);
    expect(unchanged?.points, hasLength(3));
    expect(unchanged?.points.first.lat, original.points.first.lat);
    expect(unchanged?.points.last.time, original.points.last.time);

    calls.clear();
    await sync.ensureTrackUploaded(
      trackId: original.id,
      sessionId: 'session-1',
      cloudDogId: 'dog-1',
    );
    expect(calls, isNot(contains('write-storage')));
    expect(calls, isNot(contains('write-metadata')));
  });

  test('failed upload is retried without completing metadata early', () async {
    final original = track(points: 2);
    await repository.upsertTrack(original);
    var attempts = 0;
    final sync = service(bytesWriter: (path, bytes) async {
      attempts++;
      if (attempts == 1) throw StateError('temporary upload failure');
      objects[path] = Uint8List.fromList(bytes);
    });

    await expectLater(
      sync.ensureTrackUploaded(
        trackId: original.id,
        sessionId: 'session-1',
        cloudDogId: 'dog-1',
      ),
      throwsStateError,
    );
    expect(metadata, isEmpty);

    await sync.ensureTrackUploaded(
      trackId: original.id,
      sessionId: 'session-1',
      cloudDogId: 'dog-1',
    );
    expect(attempts, 2);
    expect(metadata, isNotEmpty);
  });

  test('download validates and persists Track', () async {
    final original = track(points: 4);
    final path = FirestoreTrackSyncService.storagePath(
      dogId: 'dog-1',
      trackId: original.id,
    );
    metadata['dog-1/${original.id}'] =
        FirestoreTrackSyncService.metadataPayload(
      track: original,
      sessionId: 'session-1',
      cloudDogId: 'dog-1',
    );
    objects[path] = FirestoreTrackSyncService.serializeTrack(original);

    await service().ensureTrackDownloaded(
      trackId: original.id,
      cloudDogId: 'dog-1',
    );

    expect((await repository.getTrack(original.id))?.points, hasLength(4));
  });

  test('corrupt JSON and pointCount mismatch do not persist Track', () async {
    final original = track(points: 2);
    final path = FirestoreTrackSyncService.storagePath(
      dogId: 'dog-1',
      trackId: original.id,
    );
    metadata['dog-1/${original.id}'] =
        FirestoreTrackSyncService.metadataPayload(
      track: original,
      sessionId: 'session-1',
      cloudDogId: 'dog-1',
    );
    objects[path] = Uint8List.fromList(<int>[0xff, 0xfe]);

    await expectLater(
      service().ensureTrackDownloaded(
        trackId: original.id,
        cloudDogId: 'dog-1',
      ),
      throwsA(isA<TrackCloudFormatException>()),
    );
    expect(await repository.getTrack(original.id), isNull);

    objects[path] = FirestoreTrackSyncService.serializeTrack(original);
    metadata['dog-1/${original.id}']!['pointCount'] = 99;
    await expectLater(
      service().ensureTrackDownloaded(
        trackId: original.id,
        cloudDogId: 'dog-1',
      ),
      throwsA(isA<TrackCloudFormatException>()),
    );
    expect(await repository.getTrack(original.id), isNull);
  });

  test('corrupt cloud Track never overwrites a valid local Track', () async {
    final local = track(points: 3, source: 'valid local original');
    await repository.upsertTrack(local);
    final path = FirestoreTrackSyncService.storagePath(
      dogId: 'dog-1',
      trackId: local.id,
    );
    metadata['dog-1/${local.id}'] = FirestoreTrackSyncService.metadataPayload(
      track: local,
      sessionId: 'session-1',
      cloudDogId: 'dog-1',
    );
    objects[path] = Uint8List.fromList(<int>[0xff, 0xfe]);

    await service().ensureTrackDownloaded(
      trackId: local.id,
      cloudDogId: 'dog-1',
    );

    final unchanged = await repository.getTrack(local.id);
    expect(unchanged?.source, 'valid local original');
    expect(unchanged?.points, hasLength(3));
  });

  test('invalid coordinates are rejected', () {
    final original = track(points: 1);
    final json = String.fromCharCodes(
      FirestoreTrackSyncService.serializeTrack(original),
    ).replaceFirst('60.0', '91.0');

    expect(
      () => FirestoreTrackSyncService.deserializeTrack(
        Uint8List.fromList(json.codeUnits),
        expectedTrackId: original.id,
      ),
      throwsA(isA<TrackCloudFormatException>()),
    );
  });
}

Track track({required int points, String source = 'Garmin GPX'}) {
  return Track(
    id: 'track-1',
    createdAt: DateTime.utc(2026, 3, 7, 9),
    source: source,
    points: List<GpsPoint>.generate(
      points,
      (index) => GpsPoint(
        lat: 60.0 + index / 100000,
        lon: 10.0 + index / 100000,
        time: DateTime.utc(2026, 3, 7, 9).add(Duration(seconds: index)),
      ),
    ),
  );
}
