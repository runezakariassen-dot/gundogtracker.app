import '../models/active_session_draft.dart';

abstract class ActiveSessionDraftRepository {
  Future<void> save(ActiveSessionDraft draft);
  Future<ActiveSessionDraft?> load();
  Future<void> clear();
  Stream<ActiveSessionDraft?> watch();
}
