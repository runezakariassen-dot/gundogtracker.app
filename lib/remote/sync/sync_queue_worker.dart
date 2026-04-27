// File: lib/remote/sync/sync_queue_worker.dart
//
// Drains pending sync tasks from the local Hive-backed queue and pushes
// best-effort updates to Firestore.
//
// v1 focuses on Dog upserts (create/update).
// Firestore remains the source of truth once full sync is enabled; for now
// we do "push what we have" and keep local-first behavior.

import 'dart:convert';

import 'package:jakthund_app/domain/repositories/sync_queue_repository.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/remote/services/dog_sync_service.dart';

class SyncQueueWorker {
  final SyncQueueRepository _queue;

  SyncQueueWorker(this._queue);

  /// Run a single drain pass over pending tasks.
  ///
  /// - Processes up to [limit] tasks (default 50).
  /// - Marks tasks sent on success.
  /// - Marks tasks failed on error (kept for later inspection / retry policy).
  Future<void> runOnce({int limit = 50}) async {
    final pending = await _queue.getPending(limit: limit);
    if (pending.isEmpty) return;

    for (final task in pending) {
      try {
        final handled = await _handleTask(task);
        if (handled) {
          await _queue.markSent(task.taskId);
        } else {
          // Unknown task type in v1 -> mark failed so it doesn't loop forever.
          await _queue.markFailed(task.taskId);
        }
      } catch (_) {
        // Best-effort: do not crash the app or stop the loop.
        await _queue.markFailed(task.taskId);
      }
    }
  }

  /// Returns true if the task type was recognized and processed.
  Future<bool> _handleTask(SyncTask task) async {
    final type = _normalize(task.entityType);

    // We accept a few variants so we're resilient to naming.
    final isDog = type == 'dog' ||
        type == 'dogs' ||
        type == 'dog_upsert' ||
        type == 'dog:upsert';

    if (!isDog) return false;

    final payload = _normalizePayload(task.payload);

    // DogSyncService accepts dynamic and our DogRemoteDto can map from a Map payload.
    await DogSyncService.syncDog(dog: payload);
    return true;
  }

  String _normalize(String? v) => (v ?? '').trim().toLowerCase();

  /// Payload can be:
  /// - Map<String, dynamic> (ideal)
  /// - String (JSON)
  /// - anything else (passed through)
  dynamic _normalizePayload(dynamic payload) {
    if (payload == null) return <String, dynamic>{};

    if (payload is Map) {
      // Ensure string keys
      return payload.map((k, v) => MapEntry(k.toString(), v));
    }

    if (payload is String) {
      final s = payload.trim();
      if (s.isEmpty) return <String, dynamic>{};
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
        return decoded;
      } catch (_) {
        // Not valid JSON; pass through.
        return payload;
      }
    }

    return payload;
  }
}
