import 'package:hive/hive.dart';

enum HealthRecordType {
  tickTreatment,
  deworming,
  vaccination,
  medication,
  veterinaryVisit,
  allergy,
  injury,
  surgery,
  weight,
  hipElbowXray,
  eyeExamination,
  dnaTest,
  insurance,
  other,
}

enum HealthRepeatKind {
  none,
  monthly,
  everyThreeMonths,
  everySixMonths,
  yearly,
  customDays,
}

class HealthRepeatInterval {
  const HealthRepeatInterval._(this.kind, this.customDays);

  const HealthRepeatInterval.none() : this._(HealthRepeatKind.none, null);
  const HealthRepeatInterval.monthly() : this._(HealthRepeatKind.monthly, null);
  const HealthRepeatInterval.everyThreeMonths()
      : this._(HealthRepeatKind.everyThreeMonths, null);
  const HealthRepeatInterval.everySixMonths()
      : this._(HealthRepeatKind.everySixMonths, null);
  const HealthRepeatInterval.yearly() : this._(HealthRepeatKind.yearly, null);

  HealthRepeatInterval.customDays(int days)
      : kind = HealthRepeatKind.customDays,
        customDays = _validateCustomDays(days);

  final HealthRepeatKind kind;
  final int? customDays;

  static int _validateCustomDays(int days) {
    if (days <= 0) {
      throw ArgumentError.value(
        days,
        'days',
        'Custom repeat interval must be greater than zero.',
      );
    }
    return days;
  }

  @override
  bool operator ==(Object other) {
    return other is HealthRepeatInterval &&
        other.kind == kind &&
        other.customDays == customDays;
  }

  @override
  int get hashCode => Object.hash(kind, customDays);
}

class HealthRecord {
  static const Object _noValue = Object();

  const HealthRecord({
    required this.id,
    required this.dogId,
    this.dogKey,
    required this.type,
    required this.title,
    this.description,
    this.productName,
    this.dose,
    required this.recordedAt,
    this.nextDueAt,
    this.repeatInterval,
    this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String dogId;
  final String? dogKey;
  final HealthRecordType type;
  final String title;
  final String? description;
  final String? productName;
  final String? dose;
  final DateTime recordedAt;
  final DateTime? nextDueAt;
  final HealthRepeatInterval? repeatInterval;
  final String? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  HealthRecord copyWith({
    String? id,
    String? dogId,
    Object? dogKey = _noValue,
    HealthRecordType? type,
    String? title,
    Object? description = _noValue,
    Object? productName = _noValue,
    Object? dose = _noValue,
    DateTime? recordedAt,
    Object? nextDueAt = _noValue,
    Object? repeatInterval = _noValue,
    Object? createdByUserId = _noValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _noValue,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      dogId: dogId ?? this.dogId,
      dogKey: identical(dogKey, _noValue) ? this.dogKey : dogKey as String?,
      type: type ?? this.type,
      title: title ?? this.title,
      description: identical(description, _noValue)
          ? this.description
          : description as String?,
      productName: identical(productName, _noValue)
          ? this.productName
          : productName as String?,
      dose: identical(dose, _noValue) ? this.dose : dose as String?,
      recordedAt: recordedAt ?? this.recordedAt,
      nextDueAt: identical(nextDueAt, _noValue)
          ? this.nextDueAt
          : nextDueAt as DateTime?,
      repeatInterval: identical(repeatInterval, _noValue)
          ? this.repeatInterval
          : repeatInterval as HealthRepeatInterval?,
      createdByUserId: identical(createdByUserId, _noValue)
          ? this.createdByUserId
          : createdByUserId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _noValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }
}

class HealthRecordAdapter extends TypeAdapter<HealthRecord> {
  @override
  final int typeId = 50;

  @override
  HealthRecord read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    final id = _readRequiredString(fields[0], 'id');
    final dogId = _readRequiredString(fields[1], 'dogId');
    final title = _readRequiredString(fields[4], 'title', allowEmpty: true);
    final recordedAt = _readRequiredDateTime(fields[8], 'recordedAt');
    final createdAt = _readNullableDateTime(fields[12]) ?? recordedAt;
    final repeatKind = _enumFromName(
      _readNullableString(fields[10]),
      HealthRepeatKind.values,
      HealthRepeatKind.none,
    );
    final customDays = _readInt(fields[11]);

    return HealthRecord(
      id: id,
      dogId: dogId,
      dogKey: _readNullableString(fields[2]),
      type: _enumFromName(
        _readNullableString(fields[3]),
        HealthRecordType.values,
        HealthRecordType.other,
      ),
      title: title,
      description: _readNullableString(fields[5]),
      productName: _readNullableString(fields[6]),
      dose: _readNullableString(fields[7]),
      recordedAt: recordedAt,
      nextDueAt: _readNullableDateTime(fields[9]),
      repeatInterval: fields.containsKey(10)
          ? _repeatIntervalFromStorage(repeatKind, customDays)
          : null,
      createdByUserId: _readNullableString(fields[15]),
      createdAt: createdAt,
      updatedAt: _readNullableDateTime(fields[13]) ?? createdAt,
      deletedAt: _readNullableDateTime(fields[14]),
    );
  }

  @override
  void write(BinaryWriter writer, HealthRecord obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.dogKey)
      ..writeByte(3)
      ..write(obj.type.name)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.productName)
      ..writeByte(7)
      ..write(obj.dose)
      ..writeByte(8)
      ..write(obj.recordedAt)
      ..writeByte(9)
      ..write(obj.nextDueAt)
      ..writeByte(10)
      ..write(obj.repeatInterval?.kind.name)
      ..writeByte(11)
      ..write(obj.repeatInterval?.customDays)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.deletedAt)
      ..writeByte(15)
      ..write(obj.createdByUserId);
  }
}

HealthRepeatInterval _repeatIntervalFromStorage(
  HealthRepeatKind kind,
  int? customDays,
) {
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

T _enumFromName<T extends Enum>(String? name, List<T> values, T fallback) {
  if (name == null || name.isEmpty) return fallback;
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => fallback,
  );
}

String _readRequiredString(
  dynamic value,
  String fieldName, {
  bool allowEmpty = false,
}) {
  if (value is String && (allowEmpty || value.trim().isNotEmpty)) {
    return value;
  }
  throw HiveError('Invalid or missing required field "$fieldName".');
}

String? _readNullableString(dynamic value) {
  return value is String ? value : null;
}

DateTime _readRequiredDateTime(dynamic value, String fieldName) {
  if (value is DateTime) return value;
  throw HiveError('Invalid or missing required field "$fieldName".');
}

DateTime? _readNullableDateTime(dynamic value) {
  return value is DateTime ? value : null;
}

int? _readInt(dynamic value) {
  return value is int ? value : null;
}
