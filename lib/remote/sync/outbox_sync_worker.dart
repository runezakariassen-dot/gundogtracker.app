// File: lib/remote/sync/outbox_sync_worker.dart
//
// Drains the Hive outbox (offline-first) and pushes best-effort changes to Firestore.
//
// v1: Handles dog upserts written to outbox with table == "dogs".
// - Uses OutboxService to manage statuses/attempts.
// - Uses DogSyncService to write Firestore docs.

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/outbox_service.dart';
import 'package:jakthund_app/models/outbox_entry.dart';
import 'package:jakthund_app/remote/services/dog_sync_service.dart';

class OutboxSyncWorker {
  OutboxSyncWorker({
    OutboxService? outbox,
  }) : _outbox = outbox ?? OutboxService(box: syncOutboxBox());

  final OutboxService _outbox;

  /// Process pending outbox entries for all dogs.
  ///
  /// - Picks up to [maxDogs] dogs that have pending entries
  /// - For each dog, processes up to [batchLimit] entries in chronological order
  /// - Marks entries inFlight -> done on success
  /// - On error: marks failed (attemptCount++, may become dead)
  Future<void> runOnce({
    int maxDogs = 25,
    int batchLimit = 50,
    int deadAfterAttempts = 10,
  }) async {
    final dogIds = _pendingDogIds(limit: maxDogs);
    if (dogIds.isEmpty) return;

    for (final dogId in dogIds) {
      final batch = _outbox.peekBatch(dogId: dogId, limit: batchLimit);
      if (batch.isEmpty) continue;

      final entryIds = batch.map((e) => e.id).toList();
      await _outbox.markInFlight(entryIds);

      for (final entry in batch) {
        try {
          final handled = await _handleEntry(entry);
          if (handled) {
            await _outbox.markDone([entry.id]);
          } else {
            await _outbox.markFailed(
              entry.id,
              UnsupportedError(
                'OutboxSyncWorker: Unsupported table/op: ${entry.table}/${entry.op}',
              ),
              deadAfterAttempts: deadAfterAttempts,
            );
          }
        } catch (e) {
          await _outbox.markFailed(
            entry.id,
            e,
            deadAfterAttempts: deadAfterAttempts,
          );
        }
      }
    }
  }

  /// Returns true if the entry was recognized and processed.
  Future<bool> _handleEntry(OutboxEntry entry) async {
    final table = (entry.table).trim().toLowerCase();
    final op = (entry.op).trim().toLowerCase();

    final isDogsTable = table == 'dogs' || table == 'dog';
    final isUpsert =
        op == 'upsert' || op == 'insert' || op == 'update' || op == 'set';

    if (!isDogsTable || !isUpsert) return false;

    // entry.row should contain the dog payload (Map) per your sync_contracts design.
    final payload = entry.row;

    await DogSyncService.syncDog(dog: payload);
    return true;
  }

  List<String> _pendingDogIds({required int limit}) {
    final box = syncOutboxBox();
    final ids = <String>{};

    for (final entry in box.values) {
      if (entry.status == OutboxService.statusPending) {
        ids.add(entry.dogId);
        if (limit > 0 && ids.length >= limit) break;
      }
    }

    return ids.toList();
  }
}
