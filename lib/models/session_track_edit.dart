import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 51)
class SessionTrackEdit {
  static const int currentSchemaVersion = 1;

  @HiveField(0)
  final String sessionId;
  @HiveField(1)
  final String sourceTrackId;
  @HiveField(2)
  final int startIndexInclusive;
  @HiveField(3)
  final int endIndexExclusive;
  @HiveField(4)
  final DateTime startTimeAnchor;
  @HiveField(5)
  final DateTime endTimeAnchor;
  @HiveField(6)
  final int sourcePointCount;
  @HiveField(7)
  final String sourceFingerprint;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final DateTime updatedAt;
  @HiveField(10)
  final String? updatedByUserId;
  @HiveField(11)
  final int schemaVersion;

  const SessionTrackEdit({
    required this.sessionId,
    required this.sourceTrackId,
    required this.startIndexInclusive,
    required this.endIndexExclusive,
    required this.startTimeAnchor,
    required this.endTimeAnchor,
    required this.sourcePointCount,
    required this.sourceFingerprint,
    required this.createdAt,
    required this.updatedAt,
    this.updatedByUserId,
    this.schemaVersion = currentSchemaVersion,
  });

  Map<String, dynamic> toCloudMap() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'sourceTrackId': sourceTrackId,
        'startIndexInclusive': startIndexInclusive,
        'endIndexExclusive': endIndexExclusive,
        'startTimeAnchor': Timestamp.fromDate(startTimeAnchor.toUtc()),
        'endTimeAnchor': Timestamp.fromDate(endTimeAnchor.toUtc()),
        'sourcePointCount': sourcePointCount,
        'sourceFingerprint': sourceFingerprint,
        'createdAt': Timestamp.fromDate(createdAt.toUtc()),
        'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
        if (updatedByUserId != null && updatedByUserId!.trim().isNotEmpty)
          'updatedByUserId': updatedByUserId!.trim(),
      };

  static SessionTrackEdit? fromCloudMap({
    required String sessionId,
    required Object? value,
  }) {
    if (value is! Map) return null;
    final data = Map<String, dynamic>.from(value);
    final sourceTrackId = data['sourceTrackId'];
    final start = data['startIndexInclusive'];
    final end = data['endIndexExclusive'];
    final count = data['sourcePointCount'];
    final fingerprint = data['sourceFingerprint'];
    final startTime = _dateTime(data['startTimeAnchor']);
    final endTime = _dateTime(data['endTimeAnchor']);
    final updatedAt = _dateTime(data['updatedAt']);
    if (sourceTrackId is! String ||
        sourceTrackId.trim().isEmpty ||
        start is! int ||
        end is! int ||
        count is! int ||
        fingerprint is! String ||
        fingerprint.isEmpty ||
        startTime == null ||
        endTime == null ||
        updatedAt == null) {
      return null;
    }
    return SessionTrackEdit(
      sessionId: sessionId,
      sourceTrackId: sourceTrackId,
      startIndexInclusive: start,
      endIndexExclusive: end,
      startTimeAnchor: startTime,
      endTimeAnchor: endTime,
      sourcePointCount: count,
      sourceFingerprint: fingerprint,
      createdAt: _dateTime(data['createdAt']) ?? updatedAt,
      updatedAt: updatedAt,
      updatedByUserId: data['updatedByUserId'] is String
          ? data['updatedByUserId'] as String
          : null,
      schemaVersion: data['schemaVersion'] is int
          ? data['schemaVersion'] as int
          : currentSchemaVersion,
    );
  }

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}

class SessionTrackEditAdapter extends TypeAdapter<SessionTrackEdit> {
  @override
  final int typeId = 51;

  @override
  SessionTrackEdit read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < count; index++)
        reader.readByte(): reader.read(),
    };
    return SessionTrackEdit(
      sessionId: fields[0] as String,
      sourceTrackId: fields[1] as String,
      startIndexInclusive: fields[2] as int,
      endIndexExclusive: fields[3] as int,
      startTimeAnchor: fields[4] as DateTime,
      endTimeAnchor: fields[5] as DateTime,
      sourcePointCount: fields[6] as int,
      sourceFingerprint: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      updatedByUserId: fields[10] as String?,
      schemaVersion:
          fields[11] as int? ?? SessionTrackEdit.currentSchemaVersion,
    );
  }

  @override
  void write(BinaryWriter writer, SessionTrackEdit value) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(value.sessionId)
      ..writeByte(1)
      ..write(value.sourceTrackId)
      ..writeByte(2)
      ..write(value.startIndexInclusive)
      ..writeByte(3)
      ..write(value.endIndexExclusive)
      ..writeByte(4)
      ..write(value.startTimeAnchor)
      ..writeByte(5)
      ..write(value.endTimeAnchor)
      ..writeByte(6)
      ..write(value.sourcePointCount)
      ..writeByte(7)
      ..write(value.sourceFingerprint)
      ..writeByte(8)
      ..write(value.createdAt)
      ..writeByte(9)
      ..write(value.updatedAt)
      ..writeByte(10)
      ..write(value.updatedByUserId)
      ..writeByte(11)
      ..write(value.schemaVersion);
  }
}
