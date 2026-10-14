import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/models/hunt_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hunt_event_model_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(52)) Hive.registerAdapter(HuntEventAdapter());
  });

  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('adapter round-trip preserves all event fields and tombstone', () async {
    final box = await Hive.openBox<HuntEvent>(huntEventsBoxName);
    final event = _event(
      type: HuntEventType.birdDown,
      deletedAt: DateTime.utc(2026, 1, 2),
    );
    await box.put(event.id, event);
    await box.close();

    final reopened = await Hive.openBox<HuntEvent>(huntEventsBoxName);
    final restored = reopened.get(event.id)!;
    expect(restored.id, '550e8400-e29b-41d4-a716-446655440000');
    expect(restored.type, HuntEventType.birdDown);
    expect(restored.source, HuntEventSource.gpxWaypoint);
    expect(restored.trackPointIndex, 42);
    expect(restored.latitude, 60.1);
    expect(restored.longitude, 10.2);
    expect(restored.birdSpecies, 'Rype');
    expect(restored.note, 'Rolig stand');
    expect(restored.sourceWaypointName, '0006');
    expect(restored.sourceWaypointSymbol, 'Covey');
    expect(restored.deletedAt, DateTime.utc(2026, 1, 2));
  });

  test('all stable event types survive JSON and nullable GPS is supported', () {
    for (final type in HuntEventType.values) {
      final event = HuntEvent(
        id: 'event-${type.name}',
        sessionId: 'session-1',
        dogId: 'dog-1',
        type: type,
        occurredAt: DateTime.utc(2026),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        createdByUserId: 'user-1',
      );
      final restored = HuntEvent.fromJson(event.toJson());
      expect(restored.type, type);
      expect(restored.latitude, isNull);
      expect(restored.longitude, isNull);
      expect(restored.trackPointIndex, isNull);
    }
  });
}

HuntEvent _event({required HuntEventType type, DateTime? deletedAt}) =>
    HuntEvent(
      id: '550e8400-e29b-41d4-a716-446655440000',
      sessionId: 'session-1',
      dogId: 'dog-1',
      dogKey: 'DOG-1',
      type: type,
      occurredAt: DateTime.utc(2026, 1, 1, 10),
      sourceTrackId: 'track-1',
      trackPointIndex: 42,
      latitude: 60.1,
      longitude: 10.2,
      birdSpecies: 'Rype',
      note: 'Rolig stand',
      source: HuntEventSource.gpxWaypoint,
      sourceWaypointName: '0006',
      sourceWaypointSymbol: 'Covey',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1, 11),
      createdByUserId: 'user-1',
      updatedByUserId: 'user-2',
      deletedAt: deletedAt,
    );
