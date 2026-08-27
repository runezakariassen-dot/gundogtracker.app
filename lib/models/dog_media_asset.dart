import 'package:hive/hive.dart';

enum DogMediaKind {
  profileImage,
  sessionImage,
  sessionVideo,
}

enum DogMediaStatus {
  active,
  deleted,
}

enum DogMediaSyncStatus {
  localOnly,
  pendingUpload,
  uploading,
  uploaded,
  pendingDownload,
  downloading,
  downloaded,
  failed,
  deleted,
}

class DogMediaAsset {
  DogMediaAsset({
    required this.mediaId,
    required this.dogCloudId,
    required this.dogKey,
    required this.kind,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    this.sessionId,
    this.storagePath,
    this.thumbnailStoragePath,
    this.localPath,
    this.thumbnailLocalPath,
    this.contentType,
    this.sizeBytes,
    this.createdByUid,
    this.updatedAt,
    this.deletedAt,
  });

  final String mediaId;
  final String dogCloudId;
  final String dogKey;
  final String? sessionId;
  final DogMediaKind kind;
  final String? storagePath;
  final String? thumbnailStoragePath;
  final String? localPath;
  final String? thumbnailLocalPath;
  final String? contentType;
  final int? sizeBytes;
  final DogMediaStatus status;
  final DogMediaSyncStatus syncStatus;
  final String? createdByUid;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  DogMediaAsset copyWith({
    String? mediaId,
    String? dogCloudId,
    String? dogKey,
    Object? sessionId = _noValue,
    DogMediaKind? kind,
    Object? storagePath = _noValue,
    Object? thumbnailStoragePath = _noValue,
    Object? localPath = _noValue,
    Object? thumbnailLocalPath = _noValue,
    Object? contentType = _noValue,
    Object? sizeBytes = _noValue,
    DogMediaStatus? status,
    DogMediaSyncStatus? syncStatus,
    Object? createdByUid = _noValue,
    DateTime? createdAt,
    Object? updatedAt = _noValue,
    Object? deletedAt = _noValue,
  }) {
    return DogMediaAsset(
      mediaId: mediaId ?? this.mediaId,
      dogCloudId: dogCloudId ?? this.dogCloudId,
      dogKey: dogKey ?? this.dogKey,
      sessionId: identical(sessionId, _noValue)
          ? this.sessionId
          : sessionId as String?,
      kind: kind ?? this.kind,
      storagePath: identical(storagePath, _noValue)
          ? this.storagePath
          : storagePath as String?,
      thumbnailStoragePath: identical(thumbnailStoragePath, _noValue)
          ? this.thumbnailStoragePath
          : thumbnailStoragePath as String?,
      localPath: identical(localPath, _noValue)
          ? this.localPath
          : localPath as String?,
      thumbnailLocalPath: identical(thumbnailLocalPath, _noValue)
          ? this.thumbnailLocalPath
          : thumbnailLocalPath as String?,
      contentType: identical(contentType, _noValue)
          ? this.contentType
          : contentType as String?,
      sizeBytes:
          identical(sizeBytes, _noValue) ? this.sizeBytes : sizeBytes as int?,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdByUid: identical(createdByUid, _noValue)
          ? this.createdByUid
          : createdByUid as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: identical(updatedAt, _noValue)
          ? this.updatedAt
          : updatedAt as DateTime?,
      deletedAt: identical(deletedAt, _noValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mediaId': mediaId,
      'dogCloudId': dogCloudId,
      'dogKey': dogKey,
      'sessionId': sessionId,
      'kind': kind.name,
      'storagePath': storagePath,
      'thumbnailStoragePath': thumbnailStoragePath,
      'localPath': localPath,
      'thumbnailLocalPath': thumbnailLocalPath,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'status': status.name,
      'syncStatus': syncStatus.name,
      'createdByUid': createdByUid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DogMediaAsset.fromJson(Map<String, dynamic> json) {
    return DogMediaAsset(
      mediaId: _readString(json['mediaId']) ?? '',
      dogCloudId: _readString(json['dogCloudId']) ?? '',
      dogKey: _readString(json['dogKey']) ?? '',
      sessionId: _readString(json['sessionId']),
      kind: _readEnum(
        json['kind'],
        DogMediaKind.values,
        fallback: DogMediaKind.sessionImage,
      ),
      storagePath: _readString(json['storagePath']),
      thumbnailStoragePath: _readString(json['thumbnailStoragePath']),
      localPath: _readString(json['localPath']),
      thumbnailLocalPath: _readString(json['thumbnailLocalPath']),
      contentType: _readString(json['contentType']),
      sizeBytes: _readInt(json['sizeBytes']),
      status: _readEnum(
        json['status'],
        DogMediaStatus.values,
        fallback: DogMediaStatus.active,
      ),
      syncStatus: _readEnum(
        json['syncStatus'],
        DogMediaSyncStatus.values,
        fallback: DogMediaSyncStatus.localOnly,
      ),
      createdByUid: _readString(json['createdByUid']),
      createdAt: _readDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _readDateTime(json['updatedAt']),
      deletedAt: _readDateTime(json['deletedAt']),
    );
  }

  static const Object _noValue = Object();
}

class DogMediaAssetAdapter extends TypeAdapter<DogMediaAsset> {
  @override
  final int typeId = 49;

  @override
  DogMediaAsset read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return DogMediaAsset(
      mediaId: fields[0] as String,
      dogCloudId: fields[1] as String,
      dogKey: fields[2] as String,
      sessionId: fields[3] as String?,
      kind: _enumFromName(
        fields[4] as String?,
        DogMediaKind.values,
        DogMediaKind.sessionImage,
      ),
      storagePath: fields[5] as String?,
      thumbnailStoragePath: fields[6] as String?,
      localPath: fields[7] as String?,
      thumbnailLocalPath: fields[8] as String?,
      contentType: fields[9] as String?,
      sizeBytes: fields[10] as int?,
      status: _enumFromName(
        fields[11] as String?,
        DogMediaStatus.values,
        DogMediaStatus.active,
      ),
      syncStatus: _enumFromName(
        fields[12] as String?,
        DogMediaSyncStatus.values,
        DogMediaSyncStatus.localOnly,
      ),
      createdByUid: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime?,
      deletedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DogMediaAsset obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.mediaId)
      ..writeByte(1)
      ..write(obj.dogCloudId)
      ..writeByte(2)
      ..write(obj.dogKey)
      ..writeByte(3)
      ..write(obj.sessionId)
      ..writeByte(4)
      ..write(obj.kind.name)
      ..writeByte(5)
      ..write(obj.storagePath)
      ..writeByte(6)
      ..write(obj.thumbnailStoragePath)
      ..writeByte(7)
      ..write(obj.localPath)
      ..writeByte(8)
      ..write(obj.thumbnailLocalPath)
      ..writeByte(9)
      ..write(obj.contentType)
      ..writeByte(10)
      ..write(obj.sizeBytes)
      ..writeByte(11)
      ..write(obj.status.name)
      ..writeByte(12)
      ..write(obj.syncStatus.name)
      ..writeByte(13)
      ..write(obj.createdByUid)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.deletedAt);
  }
}

String? _readString(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

T _readEnum<T extends Enum>(
  dynamic value,
  List<T> values, {
  required T fallback,
}) {
  return _enumFromName(_readString(value), values, fallback);
}

T _enumFromName<T extends Enum>(String? value, List<T> values, T fallback) {
  if (value == null || value.isEmpty) return fallback;
  return values.firstWhere(
    (entry) => entry.name == value,
    orElse: () => fallback,
  );
}
