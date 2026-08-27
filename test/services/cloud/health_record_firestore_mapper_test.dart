import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/health_record.dart';
import 'package:jakthund_app/services/cloud/health_record_firestore_mapper.dart';
import 'package:jakthund_app/services/cloud/firestore_health_record_sync_service.dart';

void main() {
  test('maps all health record fields to stable Firestore values', () {
    final record = _record();

    final data = healthRecordToFirestore(
      record: record,
      cloudDogId: 'cloud-dog-1',
    );

    expect(data['id'], record.id);
    expect(data['cloudDogId'], 'cloud-dog-1');
    expect(data, isNot(contains('dogId')));
    expect(data['recordedDate'], '2026-01-01');
    expect(data['nextDueDate'], '2027-01-01');
    expect(data['type'], HealthRecordType.vaccination.name);
    expect(data['repeatKind'], HealthRepeatKind.customDays.name);
    expect(data['customDays'], 42);
    expect(data['schemaVersion'], healthRecordSchemaVersion);
    expect(data['updatedAt'], isA<Timestamp>());
  });

  test('round-trip remaps cloud dog reference to local dog identity', () {
    final original = _record();
    final payload = healthRecordToFirestore(
      record: original,
      cloudDogId: 'cloud-dog-1',
    );
    final mapped = healthRecordFromFirestore(
      data: payload,
      documentId: original.id,
      localDogId: 'local-dog-2',
      localDogKey: 'LOCAL-KEY',
    );

    expect(mapped.id, original.id);
    expect(mapped.dogId, 'local-dog-2');
    expect(mapped.dogKey, 'LOCAL-KEY');
    expect(mapped.type, original.type);
    expect(mapped.title, original.title);
    expect(mapped.description, original.description);
    expect(mapped.productName, original.productName);
    expect(mapped.dose, original.dose);
    expect(mapped.repeatInterval, original.repeatInterval);
    expect(
        mapped.repeatInterval?.customDays, original.repeatInterval?.customDays);
    expect(mapped.deletedAt, original.deletedAt);
    expect(mapped.recordedAt.year, original.recordedAt.year);
    expect(mapped.recordedAt.month, original.recordedAt.month);
    expect(mapped.recordedAt.day, original.recordedAt.day);
    expect(mapped.nextDueAt?.year, original.nextDueAt?.year);
    expect(mapped.nextDueAt?.month, original.nextDueAt?.month);
    expect(mapped.nextDueAt?.day, original.nextDueAt?.day);
    expect(mapped.createdByUserId, original.createdByUserId);
    expect(mapped.createdAt.toUtc(), original.createdAt.toUtc());
    expect(mapped.updatedAt.toUtc(), original.updatedAt.toUtc());
    expect(mapped.deletedAt?.toUtc(), original.deletedAt?.toUtc());
    expect(payload['cloudDogId'], 'cloud-dog-1');
    expect(payload['schemaVersion'], healthRecordSchemaVersion);
    expect(payload['recordedDate'], '2026-01-01');
    expect(payload['nextDueDate'], '2027-01-01');
  });

  test('unknown enums fall back and invalid custom repeat becomes none', () {
    final data = healthRecordToFirestore(
      record: _record(),
      cloudDogId: 'cloud-dog-1',
    )
      ..['type'] = 'futureType'
      ..['repeatKind'] = 'customDays'
      ..['customDays'] = -1;

    final mapped = healthRecordFromFirestore(
      data: data,
      documentId: 'record-1',
      localDogId: 'dog-1',
    );

    expect(mapped.type, HealthRecordType.other);
    expect(mapped.repeatInterval, const HealthRepeatInterval.none());
  });

  test('unknown repeat kind falls back to none', () {
    final data = healthRecordToFirestore(
      record: _record(),
      cloudDogId: 'cloud-dog-1',
    )..['repeatKind'] = 'futureInterval';

    final mapped = healthRecordFromFirestore(
      data: data,
      documentId: 'record-1',
      localDogId: 'dog-1',
    );

    expect(mapped.repeatInterval, const HealthRepeatInterval.none());
  });

  test('corrupt required fields throw instead of creating invalid objects', () {
    final data = healthRecordToFirestore(
      record: _record(),
      cloudDogId: 'cloud-dog-1',
    )..remove('recordedDate');

    expect(
      () => healthRecordFromFirestore(
        data: data,
        documentId: 'record-1',
        localDogId: 'dog-1',
      ),
      throwsFormatException,
    );
  });

  test('summer and winter local dates serialize without timezone conversion',
      () {
    expect(formatHealthCalendarDate(DateTime(2026, 7, 20)), '2026-07-20');
    expect(formatHealthCalendarDate(DateTime(2026, 1, 20)), '2026-01-20');
    expect(
      formatHealthCalendarDate(DateTime.utc(2026, 7, 20)),
      '2026-07-20',
    );
  });

  test('nullable calendar date round-trips as null', () {
    final record = _record().copyWith(nextDueAt: null);
    final data = healthRecordToFirestore(
      record: record,
      cloudDogId: 'cloud-dog-1',
    );
    final mapped = healthRecordFromFirestore(
      data: data,
      documentId: record.id,
      localDogId: 'dog-1',
    );

    expect(data['nextDueDate'], isNull);
    expect(mapped.nextDueAt, isNull);
  });

  test('recordedDate rejects impossible, malformed and non-string values', () {
    for (final invalid in <dynamic>[
      '2026-02-31',
      '2026-7-20',
      '2026-07-2',
      '20.07.2026',
      123,
      true,
    ]) {
      final data = healthRecordToFirestore(
        record: _record(),
        cloudDogId: 'cloud-dog-1',
      )..['recordedDate'] = invalid;

      expect(
        () => healthRecordFromFirestore(
          data: data,
          documentId: 'record-1',
          localDogId: 'dog-1',
        ),
        throwsFormatException,
        reason: 'invalid recordedDate: $invalid',
      );
    }
  });

  test('nextDueDate distinguishes missing, null, valid and invalid values', () {
    final base = healthRecordToFirestore(
      record: _record(),
      cloudDogId: 'cloud-dog-1',
    );

    final missing = Map<String, dynamic>.from(base)..remove('nextDueDate');
    expect(_map(missing).nextDueAt, isNull);

    final explicitNull = <String, dynamic>{...base, 'nextDueDate': null};
    expect(_map(explicitNull).nextDueAt, isNull);

    final valid = <String, dynamic>{...base, 'nextDueDate': '2026-07-20'};
    expect(formatHealthCalendarDate(_map(valid).nextDueAt!), '2026-07-20');

    for (final invalid in <dynamic>[
      '2026-02-31',
      '2026-7-20',
      '20.07.2026',
      123,
      true,
    ]) {
      expect(
        () => _map(<String, dynamic>{...base, 'nextDueDate': invalid}),
        throwsFormatException,
        reason: 'invalid nextDueDate: $invalid',
      );
    }
  });

  test('legacy nextDueAt DateTime is read defensively', () {
    final data = healthRecordToFirestore(
      record: _record(),
      cloudDogId: 'cloud-dog-1',
    )
      ..remove('nextDueDate')
      ..['nextDueAt'] = DateTime(2026, 7, 20);

    expect(formatHealthCalendarDate(_map(data).nextDueAt!), '2026-07-20');
  });

  test('legacy Timestamp calendar date is read using local components', () {
    final data = healthRecordToFirestore(
      record: _record(),
      cloudDogId: 'cloud-dog-1',
    )
      ..remove('recordedDate')
      ..['recordedAt'] = Timestamp.fromDate(DateTime(2026, 7, 20));

    final mapped = healthRecordFromFirestore(
      data: data,
      documentId: 'record-1',
      localDogId: 'dog-1',
    );

    expect(formatHealthCalendarDate(mapped.recordedAt), '2026-07-20');
  });

  test('document id mismatch and wrong required field type are rejected', () {
    final data = healthRecordToFirestore(
      record: _record(),
      cloudDogId: 'cloud-dog-1',
    );
    expect(
      () => healthRecordFromFirestore(
        data: data,
        documentId: 'different-id',
        localDogId: 'dog-1',
      ),
      throwsFormatException,
    );
    expect(
      () => healthRecordFromFirestore(
        data: <String, dynamic>{...data, 'title': 42},
        documentId: 'record-1',
        localDogId: 'dog-1',
      ),
      throwsFormatException,
    );
  });

  test('updatedAt falls back only to createdAt and rejects when both absent',
      () {
    final data = healthRecordToFirestore(
      record: _record(),
      cloudDogId: 'cloud-dog-1',
    )..remove('updatedAt');
    final mapped = healthRecordFromFirestore(
      data: data,
      documentId: 'record-1',
      localDogId: 'dog-1',
    );
    expect(mapped.updatedAt, mapped.createdAt);

    data.remove('createdAt');
    expect(
      () => healthRecordFromFirestore(
        data: data,
        documentId: 'record-1',
        localDogId: 'dog-1',
      ),
      throwsFormatException,
    );
  });

  test('atomic write decision handles insert, newer, older and equal', () {
    final cloudTime = DateTime.utc(2026, 1, 2);
    final existing = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(cloudTime),
    };
    expect(
      healthRecordCloudWriteDecision(
        existingData: null,
        incomingUpdatedAt: cloudTime,
      ),
      HealthRecordCloudWriteDecision.written,
    );
    expect(
      healthRecordCloudWriteDecision(
        existingData: existing,
        incomingUpdatedAt: cloudTime.add(const Duration(seconds: 1)),
      ),
      HealthRecordCloudWriteDecision.written,
    );
    expect(
      healthRecordCloudWriteDecision(
        existingData: existing,
        incomingUpdatedAt: cloudTime,
      ),
      HealthRecordCloudWriteDecision.alreadyCurrent,
    );
    expect(
      healthRecordCloudWriteDecision(
        existingData: existing,
        incomingUpdatedAt: cloudTime.subtract(const Duration(seconds: 1)),
      ),
      HealthRecordCloudWriteDecision.cloudNewer,
    );
  });

  test('atomic decision applies equally to tombstones', () {
    final cloudTime = DateTime.utc(2026, 1, 2);
    final existing = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(cloudTime),
      'deletedAt': null,
    };
    expect(
      healthRecordCloudWriteDecision(
        existingData: existing,
        incomingUpdatedAt: cloudTime.add(const Duration(seconds: 1)),
      ),
      HealthRecordCloudWriteDecision.written,
    );
    expect(
      healthRecordCloudWriteDecision(
        existingData: existing,
        incomingUpdatedAt: cloudTime.subtract(const Duration(seconds: 1)),
      ),
      HealthRecordCloudWriteDecision.cloudNewer,
    );
  });

  test('transaction payload clears nullable fields and preserves metadata', () {
    final incoming = healthRecordToFirestore(
      record: _record().copyWith(description: null, nextDueAt: null),
      cloudDogId: 'cloud-dog-1',
    );
    final originalCreatedAt = Timestamp.fromDate(DateTime.utc(2025));
    final payload = healthRecordTransactionPayload(
      incomingPayload: incoming,
      existingData: <String, dynamic>{
        'createdAt': originalCreatedAt,
        'createdByUserId': 'original-user',
        'dogKey': 'DOG-KEY',
      },
    );

    expect(payload['description'], isNull);
    expect(payload['nextDueDate'], isNull);
    expect(payload['createdAt'], originalCreatedAt);
    expect(payload['createdByUserId'], 'original-user');
    expect(payload['dogKey'], 'DOG-KEY');
  });

  test('transaction payload migrates and preserves legacy createdBy', () {
    final incoming = healthRecordToFirestore(
      record: _record().copyWith(createdByUserId: null),
      cloudDogId: 'cloud-dog-1',
      createdByUserId: 'current-editor',
    );
    final payload = healthRecordTransactionPayload(
      incomingPayload: incoming,
      existingData: <String, dynamic>{
        'createdAt': Timestamp.fromDate(DateTime.utc(2025)),
        'createdBy': 'original-user',
        'dogKey': 'DOG-KEY',
      },
    );

    expect(payload['createdByUserId'], 'original-user');
  });
}

HealthRecord _record() {
  return HealthRecord(
    id: 'record-1',
    dogId: 'dog-1',
    dogKey: 'DOG-KEY',
    type: HealthRecordType.vaccination,
    title: 'Rabies',
    description: 'Annual vaccination',
    productName: 'Vaccine',
    dose: '1 ml',
    recordedAt: DateTime.utc(2026, 1, 1),
    nextDueAt: DateTime.utc(2027, 1, 1),
    repeatInterval: HealthRepeatInterval.customDays(42),
    createdByUserId: 'user-1',
    createdAt: DateTime.utc(2026, 1, 1, 9),
    updatedAt: DateTime.utc(2026, 1, 2, 9),
    deletedAt: DateTime.utc(2026, 2, 1),
  );
}

HealthRecord _map(Map<String, dynamic> data) {
  return healthRecordFromFirestore(
    data: data,
    documentId: 'record-1',
    localDogId: 'dog-1',
  );
}
