import 'dart:async';

import '../models/active_session_draft.dart';
import '../repositories/active_session_draft_repository.dart';

class ActiveSessionAutosaveService {
  ActiveSessionAutosaveService(this._repository);

  final ActiveSessionDraftRepository _repository;
  Timer? _debounce;

  void scheduleSave(
    ActiveSessionDraft draft, {
    Duration debounce = const Duration(milliseconds: 700),
  }) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () async {
      final updated = draft.copyWith(lastSavedAt: DateTime.now());
      await _repository.save(updated);
    });
  }

  Future<void> flushSave(ActiveSessionDraft draft) async {
    _debounce?.cancel();
    final updated = draft.copyWith(lastSavedAt: DateTime.now());
    await _repository.save(updated);
  }

  void cancelPendingSave() {
    _debounce?.cancel();
    _debounce = null;
  }

  void dispose() {
    _debounce?.cancel();
    _debounce = null;
  }
}
