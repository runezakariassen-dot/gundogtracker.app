import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../domain/models/active_session_draft.dart';
import '../../domain/repositories/active_session_draft_repository.dart';

class LocalActiveSessionDraftRepository
    implements ActiveSessionDraftRepository {
  static const String _draftKey = 'draft';

  Box<ActiveSessionDraft> _box() => activeSessionDraftBox();

  @override
  Future<void> save(ActiveSessionDraft draft) async {
    await _box().put(_draftKey, draft);
  }

  @override
  Future<ActiveSessionDraft?> load() async {
    final value = _box().get(_draftKey);
    if (value is ActiveSessionDraft) {
      return value;
    }
    return null;
  }

  @override
  Future<void> clear() async {
    await _box().delete(_draftKey);
  }

  @override
  Stream<ActiveSessionDraft?> watch() {
    return _box().watch(key: _draftKey).map((event) {
      if (event.deleted) {
        return null;
      }
      return event.value as ActiveSessionDraft?;
    });
  }
}
