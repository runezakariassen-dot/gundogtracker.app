import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../models/health_record.dart';
import '../hive_boxes.dart';
import 'sync_outbox_service.dart';

class LocalHealthRecordRepository {
  LocalHealthRecordRepository({
    Box<HealthRecord>? box,
    SyncOutboxService? syncOutboxService,
    DateTime Function()? now,
  })  : _box = box ?? healthRecordsBox(),
        _syncOutboxService = syncOutboxService,
        _now = now ?? DateTime.now;

  final Box<HealthRecord> _box;
  final SyncOutboxService? _syncOutboxService;
  final DateTime Function() _now;
  final Uuid _uuid = const Uuid();

  Future<HealthRecord> create({
    required String dogId,
    String? dogKey,
    required HealthRecordType type,
    required String title,
    String? description,
    String? productName,
    String? dose,
    required DateTime recordedAt,
    DateTime? nextDueAt,
    HealthRepeatInterval? repeatInterval,
    String? createdByUserId,
  }) async {
    final timestamp = _now();
    final record = HealthRecord(
      id: _uuid.v4(),
      dogId: dogId,
      dogKey: dogKey,
      type: type,
      title: title,
      description: description,
      productName: productName,
      dose: dose,
      recordedAt: recordedAt,
      nextDueAt: nextDueAt,
      repeatInterval: repeatInterval,
      createdByUserId: createdByUserId,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _box.put(record.id, record);
    await _enqueue(record);
    return record;
  }

  Future<HealthRecord> upsert(HealthRecord record) async {
    final existing = _box.get(record.id);
    if (existing != null && existing.dogId != record.dogId) {
      throw ArgumentError.value(
        record.dogId,
        'record.dogId',
        'An existing health record cannot be moved to another dog.',
      );
    }
    final updated = record.copyWith(
      dogKey: existing?.dogKey ?? record.dogKey,
      createdAt: existing?.createdAt ?? record.createdAt,
      updatedAt: _now(),
    );
    await _box.put(updated.id, updated);
    await _enqueue(updated);
    return updated;
  }

  HealthRecord? getById(String id) => _box.get(id);

  List<HealthRecord> listByDogId(
    String dogId, {
    bool includeDeleted = false,
  }) {
    final records = _box.values
        .where((record) =>
            record.dogId == dogId && (includeDeleted || !record.isDeleted))
        .toList(growable: false);
    records.sort((a, b) {
      final recordedAtComparison = b.recordedAt.compareTo(a.recordedAt);
      if (recordedAtComparison != 0) return recordedAtComparison;

      final createdAtComparison = b.createdAt.compareTo(a.createdAt);
      if (createdAtComparison != 0) return createdAtComparison;

      return a.id.compareTo(b.id);
    });
    return records;
  }

  Future<HealthRecord?> softDelete(String id) async {
    final existing = _box.get(id);
    if (existing == null) return null;
    final timestamp = _now();
    final deleted = existing.copyWith(
      updatedAt: timestamp,
      deletedAt: timestamp,
    );
    await _box.put(id, deleted);
    await _enqueue(deleted);
    return deleted;
  }

  Future<void> _enqueue(HealthRecord record) async {
    final service = _syncOutboxService ??
        (Hive.isBoxOpen(syncTasksBoxName) ? SyncOutboxService() : null);
    await service?.enqueueUpsertHealthRecord(record);
  }
}
