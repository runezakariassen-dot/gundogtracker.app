import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/outbox_service.dart';
import 'package:jakthund_app/data/remote/sync_contracts.dart';
import 'package:jakthund_app/models/outbox_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool outboxAdapterRegistered = false;
  late Directory tempDir;
  late Box<OutboxEntry> outboxBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_outbox_');
    Hive.init(tempDir.path);
    if (!outboxAdapterRegistered) {
      Hive.registerAdapter(OutboxEntryAdapter());
      outboxAdapterRegistered = true;
    }
    outboxBox = await Hive.openBox<OutboxEntry>(syncOutboxBoxName);
    await outboxBox.clear();
  });

  tearDown(() async {
    await outboxBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('enqueue upsert creates pending outbox entry', () async {
    final service = OutboxService(box: outboxBox);

    final change = RemoteChange(
      table: 'dogs',
      op: 'upsert',
      clientOpId: 'op-1',
      row: {'id': 'dog-1'},
    );

    await service.enqueue(dogId: 'dog-1', change: change);

    final entries = outboxBox.values.toList();
    expect(entries, hasLength(1));
    expect(entries.first.op, 'upsert');
    expect(entries.first.status, OutboxService.statusPending);
    expect(entries.first.row, isNotNull);
  });

  test('enqueue delete creates entry with pk', () async {
    final service = OutboxService(box: outboxBox);

    final change = RemoteChange(
      table: 'dogs',
      op: 'delete',
      clientOpId: 'op-2',
      pk: {'id': 'dog-1'},
    );

    await service.enqueue(dogId: 'dog-1', change: change);

    final entry = outboxBox.values.first;
    expect(entry.op, 'delete');
    expect(entry.pk, {'id': 'dog-1'});
  });

  test('peekBatch and status transitions work', () async {
    final service = OutboxService(box: outboxBox);

    final change = RemoteChange(
      table: 'dogs',
      op: 'upsert',
      clientOpId: 'op-3',
      row: {'id': 'dog-1'},
    );

    await service.enqueue(dogId: 'dog-1', change: change);
    final batch = service.peekBatch(dogId: 'dog-1', limit: 10);
    expect(batch, hasLength(1));

    await service.markInFlight([batch.first.id]);
    final inFlight = outboxBox.get(batch.first.id);
    expect(inFlight!.status, OutboxService.statusInFlight);

    await service.markFailed(batch.first.id, Exception('oops'),
        deadAfterAttempts: 1);
    final failed = outboxBox.get(batch.first.id);
    expect(failed!.status, OutboxService.statusDead);
    expect(failed.attemptCount, 1);

    await service.markDone([batch.first.id]);
    final done = outboxBox.get(batch.first.id);
    expect(done!.status, OutboxService.statusDone);
  });
}
