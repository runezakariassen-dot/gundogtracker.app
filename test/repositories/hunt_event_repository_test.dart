import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/models/hunt_event.dart';
import 'package:jakthund_app/repositories/hunt_event_repository.dart';

void main() {
  late Directory directory;
  late Box<HuntEvent> box;
  late HuntEventRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hunt_event_repo_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(52)) Hive.registerAdapter(HuntEventAdapter());
    box = await Hive.openBox<HuntEvent>(huntEventsBoxName);
    repository = HuntEventRepository(box: box);
  });

  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'lists active session events chronologically and supports edits',
    () async {
      await repository.upsert(_event('late', 12), enqueueSync: false);
      await repository.upsert(
        _event('other-session', 8, sessionId: 'other'),
        enqueueSync: false,
      );
      await repository.upsert(_event('early', 9), enqueueSync: false);

      expect(repository.listForSession('session').map((e) => e.id), [
        'early',
        'late',
      ]);
      final edited = repository.getById('early')!.copyWith(note: 'Oppdatert');
      await repository.upsert(edited, enqueueSync: false);
      expect(repository.getById('early')!.note, 'Oppdatert');
    },
  );

  test(
    'soft delete keeps tombstone but excludes it from normal list',
    () async {
      await repository.upsert(_event('event', 9), enqueueSync: false);
      await repository.softDelete(
        'event',
        deletedAt: DateTime.utc(2026, 1, 2),
        enqueueSync: false,
      );
      expect(repository.listForSession('session'), isEmpty);
      expect(
        repository
            .listForSession('session', includeDeleted: true)
            .single
            .isDeleted,
        isTrue,
      );
    },
  );
}

HuntEvent _event(String id, int hour, {String sessionId = 'session'}) =>
    HuntEvent(
      id: id,
      sessionId: sessionId,
      dogId: 'dog',
      type: HuntEventType.stand,
      occurredAt: DateTime.utc(2026, 1, 1, hour),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      createdByUserId: 'owner',
    );
