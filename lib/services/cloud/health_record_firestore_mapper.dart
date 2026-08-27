import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/health_record.dart';

const int healthRecordSchemaVersion = 1;

Map<String, dynamic> healthRecordToFirestore({
  required HealthRecord record,
  required String cloudDogId,
  String? createdByUserId,
}) {
  final repeat = record.repeatInterval ?? const HealthRepeatInterval.none();
  return <String, dynamic>{
    'id': record.id,
    'cloudDogId': cloudDogId,
    'dogKey': record.dogKey,
    'type': record.type.name,
    'title': record.title,
    'description': record.description,
    'productName': record.productName,
    'dose': record.dose,
    'recordedDate': formatHealthCalendarDate(record.recordedAt),
    'nextDueDate': record.nextDueAt == null
        ? null
        : formatHealthCalendarDate(record.nextDueAt!),
    'repeatKind': repeat.kind.name,
    'customDays': repeat.customDays,
    'createdByUserId': record.createdByUserId ?? createdByUserId,
    'createdAt': Timestamp.fromDate(record.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(record.updatedAt.toUtc()),
    'deletedAt': record.deletedAt == null
        ? null
        : Timestamp.fromDate(record.deletedAt!.toUtc()),
    'schemaVersion': healthRecordSchemaVersion,
  };
}

HealthRecord healthRecordFromFirestore({
  required Map<String, dynamic> data,
  required String documentId,
  required String localDogId,
  String? localDogKey,
}) {
  final id = _requiredString(data['id'], 'id');
  if (id != documentId) {
    throw const FormatException('Health record id does not match document id.');
  }

  final recordedAt = _requiredCalendarDate(
    data.containsKey('recordedDate')
        ? data['recordedDate']
        : data['recordedAt'],
    'recordedDate',
  );
  final createdAt = _dateTime(data['createdAt']);
  final updatedAt = _dateTime(data['updatedAt']) ?? createdAt;
  if (updatedAt == null) {
    throw const FormatException(
      'Missing or invalid health record fields "updatedAt" and "createdAt".',
    );
  }
  final repeatKind = _enumByName(
    data['repeatKind'],
    HealthRepeatKind.values,
    HealthRepeatKind.none,
  );
  final customDays =
      data['customDays'] is int ? data['customDays'] as int : null;

  return HealthRecord(
    id: id,
    dogId: localDogId,
    dogKey: localDogKey,
    type: _enumByName(
      data['type'],
      HealthRecordType.values,
      HealthRecordType.other,
    ),
    title: _requiredString(data['title'], 'title', allowEmpty: true),
    description: _string(data['description']),
    productName: _string(data['productName']),
    dose: _string(data['dose']),
    recordedAt: recordedAt,
    nextDueAt: _optionalCalendarDate(
      data,
      'nextDueDate',
      legacyFieldName: 'nextDueAt',
    ),
    repeatInterval: _repeatInterval(repeatKind, customDays),
    createdByUserId:
        _string(data['createdByUserId']) ?? _string(data['createdBy']),
    createdAt: createdAt ?? updatedAt,
    updatedAt: updatedAt,
    deletedAt: _dateTime(data['deletedAt']),
  );
}

HealthRepeatInterval _repeatInterval(HealthRepeatKind kind, int? customDays) {
  switch (kind) {
    case HealthRepeatKind.none:
      return const HealthRepeatInterval.none();
    case HealthRepeatKind.monthly:
      return const HealthRepeatInterval.monthly();
    case HealthRepeatKind.everyThreeMonths:
      return const HealthRepeatInterval.everyThreeMonths();
    case HealthRepeatKind.everySixMonths:
      return const HealthRepeatInterval.everySixMonths();
    case HealthRepeatKind.yearly:
      return const HealthRepeatInterval.yearly();
    case HealthRepeatKind.customDays:
      return customDays != null && customDays > 0
          ? HealthRepeatInterval.customDays(customDays)
          : const HealthRepeatInterval.none();
  }
}

T _enumByName<T extends Enum>(dynamic raw, List<T> values, T fallback) {
  if (raw is! String) return fallback;
  return values.firstWhere(
    (value) => value.name == raw,
    orElse: () => fallback,
  );
}

String _requiredString(dynamic raw, String field, {bool allowEmpty = false}) {
  if (raw is String && (allowEmpty || raw.trim().isNotEmpty)) return raw;
  throw FormatException('Missing or invalid health record field "$field".');
}

String? _string(dynamic raw) => raw is String ? raw : null;

DateTime? _dateTime(dynamic raw) {
  if (raw is Timestamp) return raw.toDate().toUtc();
  if (raw is DateTime) return raw.toUtc();
  if (raw is String) return DateTime.tryParse(raw)?.toUtc();
  return null;
}

String formatHealthCalendarDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime _requiredCalendarDate(dynamic raw, String field) {
  final value = _calendarDate(raw);
  if (value != null) return value;
  throw FormatException('Missing or invalid health record field "$field".');
}

DateTime? _calendarDate(dynamic raw) {
  if (raw is String) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }
    return value;
  }
  if (raw is Timestamp) {
    // Legacy timestamps represented a local calendar date as an instant.
    // Recovering the current device's local calendar components best preserves
    // those documents; the new string format is timezone-independent.
    final local = raw.toDate().toLocal();
    return DateTime(local.year, local.month, local.day);
  }
  if (raw is DateTime) {
    final local = raw.isUtc ? raw.toLocal() : raw;
    return DateTime(local.year, local.month, local.day);
  }
  return null;
}

DateTime? _optionalCalendarDate(
  Map<String, dynamic> data,
  String fieldName, {
  String? legacyFieldName,
}) {
  final selectedField = data.containsKey(fieldName)
      ? fieldName
      : legacyFieldName != null && data.containsKey(legacyFieldName)
          ? legacyFieldName
          : null;
  if (selectedField == null) return null;
  final raw = data[selectedField];
  if (raw == null) return null;
  final value = _calendarDate(raw);
  if (value != null) return value;
  throw FormatException(
    'Invalid health record calendar date field "$selectedField".',
  );
}
