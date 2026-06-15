class DogHeatCycleLog {
  const DogHeatCycleLog({
    required this.dogId,
    required this.startDate,
    this.endDate,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String dogId;
  final DateTime startDate;
  final DateTime? endDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogHeatCycleLog copyWith({
    DateTime? startDate,
    Object? endDate = _noValue,
    Object? note = _noValue,
    DateTime? updatedAt,
  }) {
    return DogHeatCycleLog(
      dogId: dogId,
      startDate: startDate ?? this.startDate,
      endDate:
          identical(endDate, _noValue) ? this.endDate : endDate as DateTime?,
      note: identical(note, _noValue) ? this.note : note as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dogId': dogId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DogHeatCycleLog? fromJson(Map<String, dynamic> json) {
    final dogId = _readString(json['dogId']);
    final startDate = _readDate(json['startDate']);
    final createdAt = _readDate(json['createdAt']);
    final updatedAt = _readDate(json['updatedAt']);

    if (dogId == null ||
        startDate == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }

    final note = _readString(json['note']);

    return DogHeatCycleLog(
      dogId: dogId,
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: _readDate(json['endDate']),
      note: note == null || note.trim().isEmpty ? null : note.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static DateTime? _readDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

const Object _noValue = Object();
