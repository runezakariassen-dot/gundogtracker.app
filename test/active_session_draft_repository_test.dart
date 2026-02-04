import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/repositories/local_active_session_draft_repository.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<ActiveSessionDraft> draftBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('active_session_draft_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(ActiveSessionDraftAdapter());
    }
    draftBox =
        await Hive.openBox<ActiveSessionDraft>(activeSessionDraftBoxName);
  });

  setUp(() async {
    await draftBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test(
    'save then load returns same values',
    () async {
      final repo = LocalActiveSessionDraftRepository();
      final draft = ActiveSessionDraft.now(
        sessionId: 'session-1',
        dogId: 'dog-1',
        activeMinutes: 12,
        birdCount: 3,
        standCount: 5,
        flushCount: 1,
        notes: 'Notat',
        locationName: 'Skog',
        trackId: 'track-1',
      );
      await repo.save(draft);

      final loaded = await repo.load();
      expect(loaded, isNotNull);
      expect(loaded!.sessionId, draft.sessionId);
      expect(loaded.dogId, draft.dogId);
      expect(loaded.activeMinutes, draft.activeMinutes);
      expect(loaded.birdCount, draft.birdCount);
      expect(loaded.standCount, draft.standCount);
      expect(loaded.flushCount, draft.flushCount);
      expect(loaded.notes, draft.notes);
      expect(loaded.locationName, draft.locationName);
      expect(loaded.trackId, draft.trackId);
    },
    tags: ['ci'],
  );

  test(
    'clear removes draft',
    () async {
      final repo = LocalActiveSessionDraftRepository();
      await repo.save(
        ActiveSessionDraft.now(
          sessionId: 'session-2',
          dogId: 'dog-2',
        ),
      );
      await repo.clear();
      final loaded = await repo.load();
      expect(loaded, isNull);
    },
    tags: ['ci'],
  );

  test(
    'watch emits when draft is saved',
    () async {
      final repo = LocalActiveSessionDraftRepository();
      final stream = repo.watch();
      final draft = ActiveSessionDraft.now(
        sessionId: 'session-3',
        dogId: 'dog-3',
      );
      final emittedFuture =
          stream.firstWhere((value) => value?.sessionId == 'session-3');
      await repo.save(draft);
      final emitted = await emittedFuture;
      expect(emitted, isNotNull);
      expect(emitted!.dogId, 'dog-3');
    },
    tags: ['ci'],
  );
}
