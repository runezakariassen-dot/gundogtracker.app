import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/models/session_type_adapter.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/repositories/session_track_edit_repository.dart';
import 'package:jakthund_app/services/session_track_edit_save_service.dart';

void main() {
  late Directory tempDir;
  late Box<HuntSession> sessions;
  late Box<SessionTrackEdit> edits;
  late Box<SyncTask> tasks;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('track_edit_save_');
    Hive.init(tempDir.path);
    void register<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    }

    register(SessionTypeAdapter());
    register(HuntSessionAdapter());
    register(SessionTrackEditAdapter());
    register(SyncStatusAdapter());
    register(SyncTaskAdapter());
    sessions = await Hive.openBox<HuntSession>('sessions');
    edits = await Hive.openBox<SessionTrackEdit>('edits');
    tasks = await Hive.openBox<SyncTask>('tasks');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  HuntSession session(String? id) => HuntSession(
        sessionId: id,
        dogId: 'dog-1',
        dateTime: DateTime.utc(2026),
        location: '',
        durationMinutes: 120,
        birdsSeen: 0,
        points: 0,
        flushes: 0,
        notes: '',
        trackId: 'track-1',
      );

  Track rawTrack() => Track(
        id: 'track-1',
        createdAt: DateTime.utc(2026),
        source: 'garmin',
        points: List.generate(
          5,
          (index) => GpsPoint(
            lat: 60 + index / 100,
            lon: 10 + index / 100,
            time: DateTime.utc(2026).add(Duration(minutes: index)),
          ),
        ),
      );

  Future<void> exercise(Object key, HuntSession value) async {
    await sessions.put(key, value);
    final track = rawTrack();
    final originalPoints = List<GpsPoint>.from(track.points);
    final service = SessionTrackEditSaveService(
      editRepository: SessionTrackEditRepository(box: edits),
      sessions: sessions,
      outboxService: SyncOutboxService(box: tasks, enableAutoSync: false),
    );
    final id = value.sessionId ?? key.toString();
    final savedAt = DateTime.utc(2026, 2, 1);

    await service.save(
      sessionKey: key,
      session: value,
      rawTrack: track,
      startIndexInclusive: 1,
      endIndexExclusive: 4,
      now: savedAt,
      updatedByUserId: 'editor',
    );

    expect(edits.get(id)?.endIndexExclusive, 4);
    expect(sessions.get(key)?.updatedAt, savedAt);
    expect(tasks.values.single.entityType, 'session_upsert');
    expect(tasks.values.single.entityId, id);
    expect(track.points, orderedEquals(originalPoints));

    await service.reset(
        sessionKey: key,
        session: value,
        now: savedAt.add(const Duration(minutes: 1)));
    expect(edits.get(id), isNull);
    expect(tasks.values.where((task) => task.entityId == id), hasLength(2));
    expect(track.points, orderedEquals(originalPoints));
  }

  test('UUID session save/reset persists metadata and outbox', () async {
    await exercise(1, session('session-uuid'));
  });

  test('legacy int-key session save/reset uses key string', () async {
    await exercise(42, session(null));
  });
}
