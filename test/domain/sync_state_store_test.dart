import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/sync_state_store.dart';
import 'package:jakthund_app/models/sync_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<SyncState> syncBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_sync_state_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(221)) {
      Hive.registerAdapter(SyncStateAdapter());
    }
    syncBox = await Hive.openBox<SyncState>(syncStateBoxName);
  });

  tearDown(() async {
    await syncBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('getOrCreate and set timestamps per dog', () async {
    final store = SyncStateStore(box: syncBox);

    final created = store.getOrCreate('dog-1');
    expect(created.dogId, 'dog-1');
    expect(created.lastPulledAt, isNull);

    final pulledAt = DateTime(2024, 1, 1);
    await store.setLastPulledAt('dog-1', pulledAt);
    final updated = store.getOrCreate('dog-1');
    expect(updated.lastPulledAt, pulledAt);

    final pushedAt = DateTime(2024, 1, 2);
    await store.setLastPushedAt('dog-1', pushedAt);
    final updated2 = store.getOrCreate('dog-1');
    expect(updated2.lastPushedAt, pushedAt);
  });
}
