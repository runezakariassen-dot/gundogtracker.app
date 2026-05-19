import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/domain/repositories/active_session_draft_repository.dart';
import 'package:jakthund_app/domain/services/active_session_autosave_service.dart';
import 'package:jakthund_app/features/session/active_session_controller.dart';

class _FakeDraftRepository implements ActiveSessionDraftRepository {
  int saveCount = 0;
  ActiveSessionDraft? lastDraft;
  int clearCount = 0;

  @override
  Future<void> save(ActiveSessionDraft draft) async {
    saveCount += 1;
    lastDraft = draft;
  }

  @override
  Future<ActiveSessionDraft?> load() async => lastDraft;

  @override
  Future<void> clear() async {
    clearCount += 1;
    lastDraft = null;
  }

  @override
  Stream<ActiveSessionDraft?> watch() async* {
    yield lastDraft;
  }
}

class _RecordingDraftRepository extends _FakeDraftRepository {
  _RecordingDraftRepository(this.events);

  final List<String> events;

  @override
  Future<void> clear() async {
    events.add('clear');
    await super.clear();
  }
}

class _FakeAutosaveService extends ActiveSessionAutosaveService {
  _FakeAutosaveService(this.repo) : super(repo);

  final _FakeDraftRepository repo;
  ActiveSessionDraft? lastScheduled;
  ActiveSessionDraft? lastFlushed;
  int cancelCount = 0;

  @override
  void scheduleSave(
    ActiveSessionDraft draft, {
    Duration debounce = const Duration(milliseconds: 700),
  }) {
    lastScheduled = draft;
  }

  @override
  Future<void> flushSave(ActiveSessionDraft draft) async {
    lastFlushed = draft;
  }

  @override
  void cancelPendingSave() {
    cancelCount += 1;
  }
}

void main() {
  test(
    'restoreFromDraft populates state correctly',
    () {
      final repo = _FakeDraftRepository();
      final autosave = _FakeAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
      );

      final startedAt = DateTime(2024, 1, 2, 10, 30);
      final draft = ActiveSessionDraft(
        sessionId: 'session-1',
        dogId: 'dog-1',
        startedAt: startedAt,
        lastSavedAt: DateTime(2024, 1, 2, 10, 35),
        activeMinutes: 12,
        birdCount: 3,
        standCount: 4,
        tomstandCount: 2,
        flushCount: 1,
        notes: 'Notat',
        locationName: 'Terreng',
        trackId: 'track-1',
      );

      controller.restoreFromDraft(draft);

      final state = controller.state;
      expect(state.sessionId, draft.sessionId);
      expect(state.dogId, draft.dogId);
      expect(state.startedAt, startedAt);
      expect(state.activeMinutes, draft.activeMinutes);
      expect(state.birdCount, draft.birdCount);
      expect(state.standCount, draft.standCount);
      expect(state.tomstandCount, draft.tomstandCount);
      expect(state.flushCount, draft.flushCount);
      expect(state.notes, draft.notes);
      expect(state.locationName, draft.locationName);
      expect(state.trackId, draft.trackId);
    },
    tags: ['ci'],
  );

  test(
    'restoreFromDraft handles null notes consistently',
    () {
      final repo = _FakeDraftRepository();
      final autosave = _FakeAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
      );

      final draft = ActiveSessionDraft(
        sessionId: 's-2',
        dogId: 'dog-2',
        startedAt: DateTime.utc(2024, 2, 2),
        lastSavedAt: DateTime.utc(2024, 2, 2, 0, 5),
        activeMinutes: 5,
        birdCount: 1,
        standCount: 0,
        flushCount: 0,
        notes: null,
        locationName: 'Location',
        trackId: null,
      );

      controller.restoreFromDraft(draft);

      expect(controller.state.notes, isNull);
      expect(controller.state.locationName, 'Location');
      expect(controller.state.sessionId, 's-2');
    },
    tags: ['ci'],
  );

  test(
    'incrementStand schedules autosave',
    () {
      final repo = _FakeDraftRepository();
      final autosave = _FakeAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
        now: () => DateTime(2024, 1, 2, 9, 0),
      );

      controller.setDogId('dog-1');
      controller.setStartedAt(DateTime(2024, 1, 2, 9, 0));
      autosave.lastScheduled = null;

      controller.incrementStand();

      expect(autosave.lastScheduled, isNotNull);
      expect(autosave.lastScheduled!.standCount, 1);
    },
    tags: ['ci'],
  );

  test(
    'incrementStand triggers autosave with updated count and notes',
    () {
      final repo = _FakeDraftRepository();
      final autosave = _FakeAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
        now: () => DateTime(2024, 3, 3, 8, 0),
      );

      controller.setDogId('dog-3');
      controller.setStartedAt(DateTime(2024, 3, 3, 8, 0));

      controller.incrementStand();
      controller.incrementStand();
      controller.incrementStand();

      final scheduled = autosave.lastScheduled;
      expect(scheduled, isNotNull);
      expect(scheduled!.standCount, 3);

      controller.setNotes('   abc   ');
      final scheduledNotes = autosave.lastScheduled;
      expect(scheduledNotes, isNotNull);
      expect(scheduledNotes!.notes, 'abc');
    },
    tags: ['ci'],
  );

  test(
    'setTomstandCount clamps negatives and schedules autosave',
    () {
      final repo = _FakeDraftRepository();
      final autosave = _FakeAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
        now: () => DateTime(2024, 1, 2, 9, 0),
      );

      controller.setDogId('dog-1');
      controller.setTomstandCount(3);

      expect(controller.state.tomstandCount, 3);
      expect(autosave.lastScheduled, isNotNull);
      expect(autosave.lastScheduled!.tomstandCount, 3);

      controller.setTomstandCount(-1);

      expect(controller.state.tomstandCount, 0);
      expect(autosave.lastScheduled!.tomstandCount, 0);
    },
    tags: ['ci'],
  );

  test(
    'finalizeSession clears draft after success',
    () async {
      final repo = _FakeDraftRepository();
      final autosave = _FakeAutosaveService(repo);
      var finalizeCalled = false;
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
        finalizeSession: () async {
          finalizeCalled = true;
        },
      );

      await controller.finalizeSession();

      expect(finalizeCalled, isTrue);
      expect(repo.clearCount, 1);
    },
    tags: ['ci'],
  );

  test(
    'flushAutosave writes latest draft immediately',
    () async {
      final repo = _FakeDraftRepository();
      final autosave = ActiveSessionAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
      );

      controller.setDogId('dog-flush');
      controller.incrementStand();

      expect(repo.saveCount, 0);
      await controller.flushAutosave();
      expect(repo.saveCount, 1);
      expect(repo.lastDraft!.standCount, 1);

      autosave.dispose();
    },
    tags: ['ci'],
  );

  test(
    'finalizeSession_onSuccess_persists_session_then_clears_draft',
    () async {
      final events = <String>[];
      final repo = _RecordingDraftRepository(events);
      final autosave = _FakeAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
        finalizeSession: () async {
          events.add('save');
        },
      );

      await controller.finalizeSession();

      expect(events, ['save', 'clear']);
      expect(repo.clearCount, 1);
    },
    tags: ['ci'],
  );

  test(
    'finalizeSession_onFailure_does_not_clear_draft',
    () async {
      final events = <String>[];
      final repo = _RecordingDraftRepository(events);
      final autosave = _FakeAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
        finalizeSession: () async {
          events.add('save');
          throw Exception('boom');
        },
      );

      await expectLater(
        controller.finalizeSession(),
        throwsA(isA<Exception>()),
      );

      expect(events, ['save']);
      expect(repo.clearCount, 0);
    },
    tags: ['ci'],
  );

  test(
    'discardDraft_clears_repo_and_resets_state',
    () async {
      final repo = _FakeDraftRepository();
      final autosave = _FakeAutosaveService(repo);
      final controller = ActiveSessionController(
        autosaveService: autosave,
        draftRepository: repo,
        draftEnabled: true,
      );

      controller.setDogId('dog-discard');
      controller.incrementStand();

      await controller.discardDraft();

      expect(repo.clearCount, 1);
      expect(controller.state.dogId, isNull);
      expect(controller.state.standCount, 0);
      expect(autosave.cancelCount, 1);
    },
    tags: ['ci'],
  );
}
