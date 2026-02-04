import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/domain/repositories/active_session_draft_repository.dart';
import 'package:jakthund_app/domain/services/active_session_autosave_service.dart';

class _FakeDraftRepository implements ActiveSessionDraftRepository {
  int saveCount = 0;
  ActiveSessionDraft? lastDraft;

  @override
  Future<void> save(ActiveSessionDraft draft) async {
    saveCount += 1;
    lastDraft = draft;
  }

  @override
  Future<ActiveSessionDraft?> load() async => lastDraft;

  @override
  Future<void> clear() async {
    lastDraft = null;
  }

  @override
  Stream<ActiveSessionDraft?> watch() async* {
    yield lastDraft;
  }
}

void main() {
  test(
    'scheduleSave debounces and saves once',
    () async {
      final repo = _FakeDraftRepository();
      final service = ActiveSessionAutosaveService(repo);
      final draft = ActiveSessionDraft.now(
        sessionId: 'session-1',
        dogId: 'dog-1',
      );

      service.scheduleSave(draft, debounce: const Duration(milliseconds: 20));
      service.scheduleSave(draft, debounce: const Duration(milliseconds: 20));
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repo.saveCount, 1);
      expect(repo.lastDraft, isNotNull);
      expect(repo.lastDraft!.lastSavedAt.isAfter(draft.lastSavedAt), isTrue);
      service.dispose();
    },
    tags: ['ci'],
  );

  test(
    'flushSave saves immediately',
    () async {
      final repo = _FakeDraftRepository();
      final service = ActiveSessionAutosaveService(repo);
      final draft = ActiveSessionDraft.now(
        sessionId: 'session-2',
        dogId: 'dog-2',
      );

      await service.flushSave(draft);

      expect(repo.saveCount, 1);
      expect(repo.lastDraft, isNotNull);
      service.dispose();
    },
    tags: ['ci'],
  );

  test(
    'flushSave cancels pending debounce',
    () async {
      final repo = _FakeDraftRepository();
      final service = ActiveSessionAutosaveService(repo);
      final draft = ActiveSessionDraft.now(
        sessionId: 'session-3',
        dogId: 'dog-3',
      );

      service.scheduleSave(draft, debounce: const Duration(milliseconds: 50));
      await service.flushSave(draft);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(repo.saveCount, 1);
      service.dispose();
    },
    tags: ['ci'],
  );

  test(
    'multiple quick mutations result in single repo save',
    () {
      fakeAsync((async) {
        final repo = _FakeDraftRepository();
        final service = ActiveSessionAutosaveService(repo);
        final draft = ActiveSessionDraft(
          sessionId: 'session-4',
          dogId: 'dog-4',
          startedAt: DateTime(2024, 1, 1),
          lastSavedAt: DateTime(2024, 1, 1),
          activeMinutes: 0,
          birdCount: 0,
          standCount: 0,
          flushCount: 0,
        );

        for (var i = 0; i < 5; i++) {
          service.scheduleSave(draft,
              debounce: const Duration(milliseconds: 30));
        }

        async.elapse(const Duration(milliseconds: 29));
        expect(repo.saveCount, 0);

        async.elapse(const Duration(milliseconds: 30));
        expect(repo.saveCount, 1);
        service.dispose();
      });
    },
    tags: ['ci'],
  );
}
