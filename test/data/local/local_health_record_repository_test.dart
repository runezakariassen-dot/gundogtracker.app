import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/local_health_record_repository.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/models/health_record.dart';
import 'package:jakthund_app/models/sync_task.dart';

void main() {
  late Directory tempDir;
  late Box<HealthRecord> box;
  late Box<SyncTask> outboxBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('health_record_repo_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(HealthRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }
    box = await Hive.openBox<HealthRecord>('health_records_test');
    outboxBox = await Hive.openBox<SyncTask>('health_records_outbox_test');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Hive round-trip', () {
    test('custom repeat days must be positive at runtime', () {
      expect(
        () => HealthRepeatInterval.customDays(0),
        throwsArgumentError,
      );
      expect(
        () => HealthRepeatInterval.customDays(-1),
        throwsArgumentError,
      );
    });

    test('copyWith can explicitly clear nullable fields', () {
      final record = _record(
        id: 'record-copy',
        dogKey: 'DOG-1',
        description: 'Description',
        productName: 'Product',
        dose: '20 mg',
        nextDueAt: DateTime.utc(2027),
        repeatInterval: const HealthRepeatInterval.yearly(),
        createdByUserId: 'user-1',
        deletedAt: DateTime.utc(2026, 7, 1),
      );

      final cleared = record.copyWith(
        dogKey: null,
        description: null,
        productName: null,
        dose: null,
        nextDueAt: null,
        repeatInterval: null,
        createdByUserId: null,
        deletedAt: null,
        updatedAt: DateTime.utc(2026, 7, 2),
      );

      expect(cleared.dogKey, isNull);
      expect(cleared.description, isNull);
      expect(cleared.productName, isNull);
      expect(cleared.dose, isNull);
      expect(cleared.nextDueAt, isNull);
      expect(cleared.repeatInterval, isNull);
      expect(cleared.createdByUserId, isNull);
      expect(cleared.deletedAt, isNull);
      expect(cleared.updatedAt, DateTime.utc(2026, 7, 2));
    });

    test('preserves a complete record, type, repetition, and dates', () async {
      final record = _record(
        id: 'record-complete',
        type: HealthRecordType.vaccination,
        dogKey: 'DOG-1',
        description: 'Annual booster',
        productName: 'Vaccine A',
        dose: '1.5 ml',
        nextDueAt: DateTime.utc(2027, 2, 3, 10, 30),
        repeatInterval: HealthRepeatInterval.customDays(45),
        createdByUserId: 'user-1',
        deletedAt: DateTime.utc(2026, 4, 5, 12),
      );

      await box.put(record.id, record);
      await box.close();
      box = await Hive.openBox<HealthRecord>('health_records_test');

      final restored = box.get(record.id);
      expect(restored, isNotNull);
      expect(restored!.id, record.id);
      expect(restored.dogId, record.dogId);
      expect(restored.dogKey, record.dogKey);
      expect(restored.type, HealthRecordType.vaccination);
      expect(restored.title, record.title);
      expect(restored.description, record.description);
      expect(restored.productName, record.productName);
      expect(restored.dose, record.dose);
      expect(restored.recordedAt, record.recordedAt);
      expect(restored.nextDueAt, record.nextDueAt);
      expect(restored.repeatInterval, HealthRepeatInterval.customDays(45));
      expect(restored.createdByUserId, record.createdByUserId);
      expect(restored.createdAt, record.createdAt);
      expect(restored.updatedAt, record.updatedAt);
      expect(restored.deletedAt, record.deletedAt);
    });

    test('preserves null optional fields and fixed repetition', () async {
      final record = _record(
        id: 'record-minimal',
        type: HealthRecordType.deworming,
        repeatInterval: const HealthRepeatInterval.everyThreeMonths(),
      );

      await box.put(record.id, record);
      await box.close();
      box = await Hive.openBox<HealthRecord>('health_records_test');
      final restored = box.get(record.id);

      expect(restored, isNotNull);
      expect(restored!.dogKey, isNull);
      expect(restored.description, isNull);
      expect(restored.productName, isNull);
      expect(restored.dose, isNull);
      expect(restored.nextDueAt, isNull);
      expect(
        restored.repeatInterval,
        const HealthRepeatInterval.everyThreeMonths(),
      );
      expect(restored.createdByUserId, isNull);
      expect(restored.deletedAt, isNull);
    });

    test('invalid stored custom repeat data falls back to none', () {
      for (final invalidDays in <dynamic>[null, 0, -1, '30']) {
        final restored = _readAdapterFields(<int, dynamic>{
          ..._requiredAdapterFields(),
          10: HealthRepeatKind.customDays.name,
          11: invalidDays,
        });

        expect(
          restored.repeatInterval,
          const HealthRepeatInterval.none(),
          reason: 'invalid custom days: $invalidDays',
        );
      }
    });

    test('unknown stored enum values use safe fallbacks', () {
      final restored = _readAdapterFields(<int, dynamic>{
        ..._requiredAdapterFields(),
        3: 'futureHealthType',
        10: 'futureRepeatKind',
      });

      expect(restored.type, HealthRecordType.other);
      expect(restored.repeatInterval, const HealthRepeatInterval.none());
    });

    test('missing newer fields use defaults without crashing', () {
      final recordedAt = DateTime.utc(2025, 1, 2);
      final restored = _readAdapterFields(<int, dynamic>{
        0: 'legacy-record',
        1: 'dog-1',
        3: HealthRecordType.vaccination.name,
        4: 'Legacy vaccine',
        8: recordedAt,
      });

      expect(restored.createdAt, recordedAt);
      expect(restored.updatedAt, recordedAt);
      expect(restored.repeatInterval, isNull);
      expect(restored.dogKey, isNull);
      expect(restored.nextDueAt, isNull);
      expect(restored.deletedAt, isNull);
    });

    test('wrong optional field types are ignored', () {
      final restored = _readAdapterFields(<int, dynamic>{
        ..._requiredAdapterFields(),
        2: 123,
        5: <String>['not', 'text'],
        6: true,
        7: 20,
        9: 'not-a-date',
        12: 'not-a-date',
        13: false,
        14: 123,
        15: <String, String>{'not': 'text'},
      });

      expect(restored.dogKey, isNull);
      expect(restored.description, isNull);
      expect(restored.productName, isNull);
      expect(restored.dose, isNull);
      expect(restored.nextDueAt, isNull);
      expect(restored.createdAt, restored.recordedAt);
      expect(restored.updatedAt, restored.recordedAt);
      expect(restored.deletedAt, isNull);
      expect(restored.createdByUserId, isNull);
    });

    test('corrupt required identity and date fields throw clear HiveErrors',
        () {
      for (final field in <int>[0, 1, 4, 8]) {
        final fields = _requiredAdapterFields()..[field] = null;

        expect(
          () => _readAdapterFields(fields),
          throwsA(isA<HiveError>()),
          reason: 'required field $field',
        );
      }
    });
  });

  group('LocalHealthRecordRepository', () {
    test('create assigns UUID and timestamps and getById finds it', () async {
      final now = DateTime.utc(2026, 7, 19, 9);
      final repository = LocalHealthRecordRepository(box: box, now: () => now);

      final created = await repository.create(
        dogId: 'dog-1',
        type: HealthRecordType.tickTreatment,
        title: 'Bravecto',
        recordedAt: DateTime.utc(2026, 7, 18),
      );

      expect(
        created.id,
        matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        )),
      );
      expect(created.createdAt, now);
      expect(created.updatedAt, now);
      expect(repository.getById(created.id)?.id, created.id);
      expect(box.get(created.id)?.id, created.id);
    });

    test('upsert updates the record but preserves createdAt', () async {
      final times = <DateTime>[
        DateTime.utc(2026, 7, 19, 9),
        DateTime.utc(2026, 7, 19, 10),
      ];
      var index = 0;
      final repository = LocalHealthRecordRepository(
        box: box,
        now: () => times[index++],
      );
      final created = await repository.create(
        dogId: 'dog-1',
        dogKey: 'DOG-1',
        type: HealthRecordType.medication,
        title: 'Original',
        recordedAt: DateTime.utc(2026, 7, 18),
        createdByUserId: 'user-1',
      );

      final updated = await repository.upsert(
        created.copyWith(
          title: 'Updated',
          createdAt: DateTime.utc(2000),
          description: 'Changed',
        ),
      );

      expect(updated.title, 'Updated');
      expect(updated.description, 'Changed');
      expect(updated.id, created.id);
      expect(updated.dogId, created.dogId);
      expect(updated.dogKey, created.dogKey);
      expect(updated.createdByUserId, created.createdByUserId);
      expect(updated.createdAt, times[0]);
      expect(updated.updatedAt, times[1]);
      expect(box.length, 1);
    });

    test('listByDogId filters and sorts newest recordedAt first', () async {
      final repository = LocalHealthRecordRepository(box: box);
      await box.put(
        'older',
        _record(
          id: 'older',
          dogId: 'dog-1',
          recordedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await box.put(
        'newer',
        _record(
          id: 'newer',
          dogId: 'dog-1',
          recordedAt: DateTime.utc(2026, 6, 1),
        ),
      );
      await box.put(
        'other-dog',
        _record(id: 'other-dog', dogId: 'dog-2'),
      );

      expect(
        repository.listByDogId('dog-1').map((record) => record.id),
        <String>['newer', 'older'],
      );
    });

    test('listByDogId uses deterministic tie breakers', () async {
      final repository = LocalHealthRecordRepository(box: box);
      final recordedAt = DateTime.utc(2026, 6, 1);
      final olderCreatedAt = DateTime.utc(2026, 6, 2);
      final newerCreatedAt = DateTime.utc(2026, 6, 3);
      final records = <HealthRecord>[
        _record(
          id: 'z-id',
          recordedAt: recordedAt,
          createdAt: newerCreatedAt,
        ),
        _record(
          id: 'older-created',
          recordedAt: recordedAt,
          createdAt: olderCreatedAt,
        ),
        _record(
          id: 'a-id',
          recordedAt: recordedAt,
          createdAt: newerCreatedAt,
        ),
      ];
      for (final record in records.reversed) {
        await box.put(record.id, record);
      }

      expect(
        repository.listByDogId('dog-1').map((record) => record.id),
        <String>['a-id', 'z-id', 'older-created'],
      );
    });

    test('softDelete updates timestamps and hides the record by default',
        () async {
      final deletedAt = DateTime.utc(2026, 7, 19, 11);
      final repository = LocalHealthRecordRepository(
        box: box,
        now: () => deletedAt,
      );
      final record = _record(id: 'delete-me');
      await box.put(record.id, record);

      final deleted = await repository.softDelete(record.id);

      expect(deleted, isNotNull);
      expect(deleted!.deletedAt, deletedAt);
      expect(deleted.updatedAt, deletedAt);
      expect(deleted.isDeleted, isTrue);
      expect(deleted.id, record.id);
      expect(deleted.dogId, record.dogId);
      expect(deleted.type, record.type);
      expect(deleted.title, record.title);
      expect(deleted.recordedAt, record.recordedAt);
      expect(deleted.createdAt, record.createdAt);
      expect(box.containsKey(record.id), isTrue);
      expect(repository.listByDogId(record.dogId), isEmpty);
      expect(
        repository.listByDogId(record.dogId, includeDeleted: true),
        hasLength(1),
      );
      expect(repository.getById(record.id)?.deletedAt, deletedAt);
    });

    test('softDelete returns null for an unknown id', () async {
      final repository = LocalHealthRecordRepository(box: box);

      expect(await repository.softDelete('missing'), isNull);
      expect(box, isEmpty);
    });

    test('create, edits and soft delete deduplicate to one pending task',
        () async {
      final outbox = SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      );
      final repository = LocalHealthRecordRepository(
        box: box,
        syncOutboxService: outbox,
      );

      final created = await repository.create(
        dogId: 'dog-1',
        type: HealthRecordType.medication,
        title: 'Medicine',
        recordedAt: DateTime.utc(2026, 1, 1),
      );
      await repository.upsert(created.copyWith(title: 'Updated'));
      await repository.upsert(created.copyWith(title: 'Updated again'));
      await repository.softDelete(created.id);

      expect(outboxBox.length, 1);
      expect(
        outboxBox.values.map((task) => task.entityType),
        everyElement('health_record_upsert'),
      );
      expect(
        outboxBox.values.map((task) => task.entityId),
        everyElement(created.id),
      );
      expect(
        outboxBox.values.every((task) => task.payload.length == 3),
        isTrue,
      );
      expect(repository.getById(created.id)?.isDeleted, isTrue);
    });

    test('upsert rejects moving an existing record to another dog', () async {
      final repository = LocalHealthRecordRepository(box: box);
      final record = _record(id: 'record-1', dogId: 'dog-1');
      await box.put(record.id, record);

      expect(
        () => repository.upsert(record.copyWith(dogId: 'dog-2')),
        throwsArgumentError,
      );
      expect(box.get(record.id)?.dogId, 'dog-1');
    });

    test('outbox save failure is observable after local save', () async {
      final outbox = SyncOutboxService(
        box: outboxBox,
        enableAutoSync: false,
      );
      final repository = LocalHealthRecordRepository(
        box: box,
        syncOutboxService: outbox,
      );
      await outboxBox.close();

      await expectLater(
        repository.create(
          dogId: 'dog-1',
          type: HealthRecordType.other,
          title: 'Local survives',
          recordedAt: DateTime(2026, 7, 20),
        ),
        throwsA(isA<SyncOutboxEnqueueException>()),
      );
      expect(box.values.single.title, 'Local survives');
      outboxBox = await Hive.openBox<SyncTask>('health_records_outbox_test');
      expect(outboxBox, isEmpty);
    });
  });
}

HealthRecord _record({
  required String id,
  String dogId = 'dog-1',
  String? dogKey,
  HealthRecordType type = HealthRecordType.other,
  String? description,
  String? productName,
  String? dose,
  DateTime? recordedAt,
  DateTime? nextDueAt,
  HealthRepeatInterval? repeatInterval,
  String? createdByUserId,
  DateTime? createdAt,
  DateTime? deletedAt,
}) {
  return HealthRecord(
    id: id,
    dogId: dogId,
    dogKey: dogKey,
    type: type,
    title: 'Health record',
    description: description,
    productName: productName,
    dose: dose,
    recordedAt: recordedAt ?? DateTime.utc(2026, 2, 3, 10),
    nextDueAt: nextDueAt,
    repeatInterval: repeatInterval,
    createdByUserId: createdByUserId,
    createdAt: createdAt ?? DateTime.utc(2026, 2, 3, 11),
    updatedAt: DateTime.utc(2026, 2, 4, 12),
    deletedAt: deletedAt,
  );
}

Map<int, dynamic> _requiredAdapterFields() {
  return <int, dynamic>{
    0: 'record-1',
    1: 'dog-1',
    3: HealthRecordType.medication.name,
    4: 'Medicine',
    8: DateTime.utc(2026, 1, 2),
  };
}

HealthRecord _readAdapterFields(Map<int, dynamic> fields) {
  final values = <dynamic>[fields.length];
  for (final entry in fields.entries) {
    values
      ..add(entry.key)
      ..add(entry.value);
  }
  return HealthRecordAdapter().read(_FieldsBinaryReader(values));
}

class _FieldsBinaryReader implements BinaryReader {
  _FieldsBinaryReader(this._values);

  final List<dynamic> _values;
  int _index = 0;

  dynamic _next() => _values[_index++];

  @override
  int readByte() => _next() as int;

  @override
  dynamic read([int? typeId]) => _next();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
