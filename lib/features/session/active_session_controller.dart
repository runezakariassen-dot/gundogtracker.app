import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/active_session_draft.dart';
import '../../domain/repositories/active_session_draft_repository.dart';
import '../../domain/services/active_session_autosave_service.dart';

@immutable
class ActiveSessionState {
  static const _unset = Object();

  const ActiveSessionState({
    this.sessionId,
    this.dogId,
    this.startedAt,
    this.activeMinutes = 0,
    this.birdCount = 0,
    this.standCount = 0,
    this.tomstandCount = 0,
    this.flushCount = 0,
    this.notes,
    this.locationName,
    this.trackId,
  });

  final String? sessionId;
  final String? dogId;
  final DateTime? startedAt;
  final int activeMinutes;
  final int birdCount;
  final int standCount;
  final int tomstandCount;
  final int flushCount;
  final String? notes;
  final String? locationName;
  final String? trackId;

  ActiveSessionState copyWith({
    Object? sessionId = _unset,
    Object? dogId = _unset,
    Object? startedAt = _unset,
    int? activeMinutes,
    int? birdCount,
    int? standCount,
    int? tomstandCount,
    int? flushCount,
    Object? notes = _unset,
    Object? locationName = _unset,
    Object? trackId = _unset,
  }) {
    return ActiveSessionState(
      sessionId: sessionId == _unset ? this.sessionId : sessionId as String?,
      dogId: dogId == _unset ? this.dogId : dogId as String?,
      startedAt: startedAt == _unset ? this.startedAt : startedAt as DateTime?,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      birdCount: birdCount ?? this.birdCount,
      standCount: standCount ?? this.standCount,
      tomstandCount: tomstandCount ?? this.tomstandCount,
      flushCount: flushCount ?? this.flushCount,
      notes: notes == _unset ? this.notes : notes as String?,
      locationName:
          locationName == _unset ? this.locationName : locationName as String?,
      trackId: trackId == _unset ? this.trackId : trackId as String?,
    );
  }
}

typedef ActiveSessionFinalizer = Future<void> Function();

class ActiveSessionController extends ChangeNotifier {
  ActiveSessionController({
    required ActiveSessionAutosaveService autosaveService,
    required ActiveSessionDraftRepository draftRepository,
    ActiveSessionFinalizer? finalizeSession,
    ActiveSessionState? initialState,
    bool draftEnabled = false,
    Uuid? uuid,
    DateTime Function()? now,
  })  : _autosaveService = autosaveService,
        _draftRepository = draftRepository,
        _finalizeSession = finalizeSession,
        _draftEnabled = draftEnabled,
        _uuid = uuid ?? const Uuid(),
        _now = now ?? DateTime.now,
        _state = initialState ?? const ActiveSessionState();

  final ActiveSessionAutosaveService _autosaveService;
  final ActiveSessionDraftRepository _draftRepository;
  final ActiveSessionFinalizer? _finalizeSession;
  final Uuid _uuid;
  final DateTime Function() _now;
  bool _draftEnabled;
  ActiveSessionState _state;

  ActiveSessionState get state => _state;
  bool get draftEnabled => _draftEnabled;

  set draftEnabled(bool value) {
    if (_draftEnabled == value) return;
    _draftEnabled = value;
  }

  void replaceState(ActiveSessionState state, {bool notify = true}) {
    _state = state;
    if (notify) {
      notifyListeners();
    }
  }

  void restoreFromDraft(ActiveSessionDraft draft) {
    _state = ActiveSessionState(
      sessionId: draft.sessionId,
      dogId: draft.dogId,
      startedAt: draft.startedAt,
      activeMinutes: draft.activeMinutes,
      birdCount: draft.birdCount,
      standCount: draft.standCount,
      tomstandCount: draft.tomstandCount,
      flushCount: draft.flushCount,
      notes: draft.notes,
      locationName: draft.locationName,
      trackId: draft.trackId,
    );
    notifyListeners();
  }

  void setDogId(String? dogId) {
    _updateState(_state.copyWith(dogId: dogId));
  }

  void setStartedAt(DateTime? startedAt) {
    _updateState(_state.copyWith(startedAt: startedAt));
  }

  void setActiveMinutes(int minutes) {
    final value = minutes < 0 ? 0 : minutes;
    _updateState(_state.copyWith(activeMinutes: value));
  }

  void setBirdCount(int count) {
    final value = count < 0 ? 0 : count;
    _updateState(_state.copyWith(birdCount: value));
  }

  void setStandCount(int count) {
    final value = count < 0 ? 0 : count;
    _updateState(_state.copyWith(standCount: value));
  }

  void setTomstandCount(int count) {
    final value = count < 0 ? 0 : count;
    _updateState(_state.copyWith(tomstandCount: value));
  }

  void setFlushCount(int count) {
    final value = count < 0 ? 0 : count;
    _updateState(_state.copyWith(flushCount: value));
  }

  void setNotes(String value) {
    _updateState(_state.copyWith(notes: _normalizeText(value)));
  }

  void setLocationName(String? value) {
    _updateState(_state.copyWith(locationName: _normalizeText(value)));
  }

  void setTrackId(String? trackId) {
    _updateState(_state.copyWith(trackId: trackId));
  }

  void incrementStand() {
    _updateState(_state.copyWith(standCount: _state.standCount + 1));
  }

  void incrementFlush() {
    _updateState(_state.copyWith(flushCount: _state.flushCount + 1));
  }

  void incrementBird() {
    _updateState(_state.copyWith(birdCount: _state.birdCount + 1));
  }

  Future<void> finalizeSession() async {
    if (_finalizeSession == null) return;
    await _finalizeSession();
    if (_draftEnabled) {
      await _draftRepository.clear();
    }
  }

  Future<void> discardDraft() async {
    if (!_draftEnabled) return;
    _autosaveService.cancelPendingSave();
    _state = const ActiveSessionState();
    notifyListeners();
    await _draftRepository.clear();
  }

  Future<void> flushAutosave() async {
    final draft = _toDraft();
    if (draft == null) return;
    await _autosaveService.flushSave(draft);
  }

  void scheduleAutosave() {
    _scheduleAutosave();
  }

  void _updateState(ActiveSessionState next) {
    _state = next;
    notifyListeners();
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    final draft = _toDraft();
    if (draft == null) return;
    _autosaveService.scheduleSave(draft);
  }

  ActiveSessionDraft? _toDraft() {
    if (!_draftEnabled) return null;
    final dogId = _state.dogId;
    if (dogId == null) return null;
    final sessionId = _state.sessionId ?? _uuid.v4();
    final startedAt = _state.startedAt ?? _now();
    if (sessionId != _state.sessionId || startedAt != _state.startedAt) {
      _state = _state.copyWith(sessionId: sessionId, startedAt: startedAt);
    }
    return ActiveSessionDraft(
      sessionId: sessionId,
      dogId: dogId,
      startedAt: startedAt,
      lastSavedAt: _now(),
      activeMinutes: _state.activeMinutes,
      birdCount: _state.birdCount,
      standCount: _state.standCount,
      tomstandCount: _state.tomstandCount,
      flushCount: _state.flushCount,
      notes: _normalizeText(_state.notes),
      locationName: _normalizeText(_state.locationName),
      trackId: _state.trackId,
    );
  }

  String? _normalizeText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
