import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/dog_membership_repository_with_outbox.dart';
import 'package:jakthund_app/data/local/outbox_service.dart';
import 'package:jakthund_app/domain/repositories/membership_repository.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/outbox_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<OutboxEntry> outboxBox;
  bool outboxAdapterRegistered = false;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('jakthund_membership_outbox_');
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

  test('upsertMembership enqueues outbox entry', () async {
    final repo = DogMembershipRepositoryWithOutbox(
      local: _InMemoryDogMembershipRepository(),
      outbox: OutboxService(box: outboxBox),
    );

    final membership = DogMembership(
      dogKey: 'NO123-45',
      userId: 'user-1',
      role: Role.viewer,
      status: Status.active,
      addedAt: DateTime(2024, 1, 1),
      addedByUserId: 'owner',
    );

    await repo.upsertMembership(membership);

    final entries = outboxBox.values.toList();
    expect(entries, hasLength(1));
    expect(entries.first.table, 'dog_memberships');
    expect(entries.first.op, 'upsert');
    expect(entries.first.dogId, 'NO123-45');
  });
}

class _InMemoryDogMembershipRepository implements DogMembershipRepository {
  DogMembership? _stored;

  @override
  Future<DogMembership?> getMembership(String dogKey, String userId) async {
    final stored = _stored;
    if (stored == null) return null;
    if (stored.dogKey == dogKey && stored.userId == userId) {
      return stored;
    }
    return null;
  }

  @override
  Future<List<DogMembership>> getMembershipsForDog(String dogKey) async {
    final stored = _stored;
    if (stored == null || stored.dogKey != dogKey) return [];
    return [stored];
  }

  @override
  Future<void> upsertMembership(DogMembership membership) async {
    _stored = membership;
  }
}
