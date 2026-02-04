import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../data/hive_boxes.dart';
import '../../data/remote/sync_contracts.dart';
import '../../models/outbox_entry.dart';

class OutboxService {
  OutboxService({Box<OutboxEntry>? box}) : _box = box ?? syncOutboxBox();

  final Box<OutboxEntry> _box;
  final Uuid _uuid = const Uuid();

  static const String statusPending = 'pending';
  static const String statusInFlight = 'inFlight';
  static const String statusDone = 'done';
  static const String statusDead = 'dead';

  Future<void> enqueue({
    required String dogId,
    required RemoteChange change,
  }) async {
    final entry = OutboxEntry(
      id: _uuid.v4(),
      dogId: dogId,
      table: change.table,
      op: change.op,
      clientOpId: change.clientOpId.isEmpty ? _uuid.v4() : change.clientOpId,
      row: change.row,
      pk: change.pk,
      createdAt: DateTime.now(),
      status: statusPending,
    );
    await _box.put(entry.id, entry);
  }

  List<OutboxEntry> peekBatch({
    required String dogId,
    int limit = 50,
  }) {
    final pending = _box.values
        .where((entry) => entry.dogId == dogId && entry.status == statusPending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (limit <= 0 || pending.length <= limit) {
      return pending;
    }
    return pending.take(limit).toList();
  }

  Future<void> markInFlight(List<String> entryIds) async {
    await _updateStatus(entryIds, statusInFlight);
  }

  Future<void> markDone(List<String> entryIds) async {
    await _updateStatus(entryIds, statusDone);
  }

  Future<void> markFailed(
    String entryId,
    Object error, {
    int deadAfterAttempts = 10,
  }) async {
    final existing = _box.get(entryId);
    if (existing == null) {
      return;
    }
    final nextAttempts = existing.attemptCount + 1;
    final nextStatus =
        nextAttempts >= deadAfterAttempts ? statusDead : statusPending;
    final updated = existing.copyWith(
      attemptCount: nextAttempts,
      lastAttemptAt: DateTime.now(),
      status: nextStatus,
      lastError: error.toString(),
    );
    await _box.put(entryId, updated);
  }

  Future<void> _updateStatus(List<String> entryIds, String status) async {
    for (final id in entryIds) {
      final existing = _box.get(id);
      if (existing == null) {
        continue;
      }
      final updated = existing.copyWith(status: status);
      await _box.put(id, updated);
    }
  }
}
