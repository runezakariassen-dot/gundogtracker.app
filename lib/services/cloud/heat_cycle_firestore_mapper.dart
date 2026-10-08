import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/dog_heat_cycle_log.dart';

const int heatCycleSchemaVersion = 1;

Map<String, dynamic> heatCycleToFirestore({
  required DogHeatCycleLog entry,
  required String cloudDogId,
  String? createdByUserId,
}) {
  return <String, dynamic>{
    'id': entry.id,
    'cloudDogId': cloudDogId,
    'startDate': _formatCalendarDate(entry.startDate),
    'endDate':
        entry.endDate == null ? null : _formatCalendarDate(entry.endDate!),
    'note': entry.note,
    'createdByUserId': entry.createdByUserId ?? createdByUserId,
    'createdAt': Timestamp.fromDate(entry.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(entry.updatedAt.toUtc()),
    'deletedAt': entry.deletedAt == null
        ? null
        : Timestamp.fromDate(entry.deletedAt!.toUtc()),
    'schemaVersion': heatCycleSchemaVersion,
  };
}

DogHeatCycleLog heatCycleFromFirestore({
  required Map<String, dynamic> data,
  required String documentId,
  required String localDogId,
}) {
  final id = _requiredString(data['id'], 'id');
  if (id != documentId) {
    throw const FormatException('Heat cycle id does not match document id.');
  }

  final startDate = _requiredCalendarDate(data['startDate'], 'startDate');
  final endDate = _optionalCalendarDate(data['endDate']);
  final createdAt = _dateTime(data['createdAt']);
  final updatedAt = _dateTime(data['updatedAt']) ?? createdAt;
  if (updatedAt == null) {
    throw const FormatException(
      'Missing or invalid heat cycle fields "updatedAt" and "createdAt".',
    );
  }

  return DogHeatCycleLog(
    id: id,
    dogId: localDogId,
    startDate: startDate,
    endDate: endDate,
    note: _string(data['note'])?.trim().isEmpty == true
        ? null
        : _string(data['note']),
    createdByUserId: _string(data['createdByUserId']),
    createdAt: createdAt ?? updatedAt,
    updatedAt: updatedAt,
    deletedAt: _dateTime(data['deletedAt']),
  );
}

String _requiredString(dynamic raw, String field) {
  if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  throw FormatException('Missing or invalid heat cycle field "$field".');
}

String? _string(dynamic raw) => raw is String ? raw : null;

DateTime? _dateTime(dynamic raw) {
  if (raw is Timestamp) return raw.toDate().toUtc();
  if (raw is DateTime) return raw.toUtc();
  if (raw is String) return DateTime.tryParse(raw)?.toUtc();
  return null;
}

String _formatCalendarDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime _requiredCalendarDate(dynamic raw, String field) {
  final value = _optionalCalendarDate(raw);
  if (value != null) return value;
  throw FormatException('Missing or invalid heat cycle field "$field".');
}

DateTime? _optionalCalendarDate(dynamic raw) {
  if (raw == null) return null;
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
    final local = raw.toDate().toLocal();
    return DateTime(local.year, local.month, local.day);
  }
  if (raw is DateTime) {
    final local = raw.isUtc ? raw.toLocal() : raw;
    return DateTime(local.year, local.month, local.day);
  }
  return null;
}
