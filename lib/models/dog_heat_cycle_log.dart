class DogHeatCycleLog {
  const DogHeatCycleLog({
    this.id,
    required this.dogId,
    required this.startDate,
    this.endDate,
    this.note,
    this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String? id;
  final String dogId;
  final DateTime startDate;
  final DateTime? endDate;
  final String? note;
  final String? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  DogHeatCycleLog copyWith({
    Object? id = _noValue,
    DateTime? startDate,
    Object? endDate = _noValue,
    Object? note = _noValue,
    Object? createdByUserId = _noValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _noValue,
  }) {
    return DogHeatCycleLog(
      id: identical(id, _noValue) ? this.id : id as String?,
      dogId: dogId,
      startDate: startDate ?? this.startDate,
      endDate:
          identical(endDate, _noValue) ? this.endDate : endDate as DateTime?,
      note: identical(note, _noValue) ? this.note : note as String?,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'note': note,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static DogHeatCycleLog? fromJson(Map<String, dynamic> json) {
    final id = _readString(json['id']) ?? _readString(json['heatCycleId']);
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
    final createdByUserId = _readString(json['createdByUserId']);

    return DogHeatCycleLog(
      id: id,
      dogId: dogId,
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: _readDate(json['endDate']),
      note: note == null || note.trim().isEmpty ? null : note.trim(),
      createdByUserId: createdByUserId == null || createdByUserId.trim().isEmpty
          ? null
          : createdByUserId.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: _readDate(json['deletedAt']),
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
