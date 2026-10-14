import 'package:hive/hive.dart';

import '../data/hive_boxes.dart';
import '../data/local/sync_outbox_service.dart';
import '../models/hunt_event.dart';

class HuntEventRepository {
  HuntEventRepository({
    Box<HuntEvent>? box,
    SyncOutboxService? outboxService,
    bool enableSync = true,
  }) : _box = box,
       _outboxService = outboxService,
       _enableSync = enableSync;

  final Box<HuntEvent>? _box;
  final SyncOutboxService? _outboxService;
  final bool _enableSync;

  Box<HuntEvent> get _store => _box ?? huntEventsBox();

  HuntEvent? getById(String id) => _store.get(id);

  List<HuntEvent> listForSession(
    String sessionId, {
    bool includeDeleted = false,
  }) {
    final events = _store.values
        .where(
          (event) =>
              event.sessionId == sessionId &&
              (includeDeleted || event.deletedAt == null),
        )
        .toList();
    events.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return events;
  }

  Future<void> upsert(HuntEvent event, {bool enqueueSync = true}) async {
    await _store.put(event.id, event);
    if (enqueueSync) await _outbox()?.enqueueUpsertHuntEvent(event);
  }

  Future<HuntEvent?> softDelete(
    String id, {
    required DateTime deletedAt,
    String? updatedByUserId,
    bool enqueueSync = true,
  }) async {
    final existing = getById(id);
    if (existing == null) return null;
    final tombstone = existing.copyWith(
      updatedAt: deletedAt.toUtc(),
      updatedByUserId: updatedByUserId,
      deletedAt: deletedAt.toUtc(),
    );
    await _store.put(id, tombstone);
    if (enqueueSync) await _outbox()?.enqueueDeleteHuntEvent(tombstone);
    return tombstone;
  }

  SyncOutboxService? _outbox() {
    if (!_enableSync) return null;
    if (_outboxService != null) return _outboxService;
    return Hive.isBoxOpen(syncTasksBoxName) ? SyncOutboxService() : null;
  }
}
