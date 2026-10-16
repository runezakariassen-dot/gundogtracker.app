import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';

void main() {
  test('json roundtrip keeps enums statuses and nullable fields', () {
    final asset = DogMediaAsset(
      mediaId: 'media-1',
      dogCloudId: 'dog-cloud-1',
      dogKey: 'NO123-45',
      sessionId: 'session-1',
      kind: DogMediaKind.sessionVideo,
      storagePath: 'dogs/dog-cloud-1/sessions/session-1/media/media-1/original',
      thumbnailStoragePath:
          'dogs/dog-cloud-1/sessions/session-1/media/media-1/thumb.jpg',
      localPath: 'dog_media/dog-cloud-1/sessions/session-1/media-1.mp4',
      thumbnailLocalPath:
          'dog_media/dog-cloud-1/sessions/session-1/media-1_thumb.jpg',
      contentType: 'video/mp4',
      sizeBytes: 123456,
      status: DogMediaStatus.active,
      syncStatus: DogMediaSyncStatus.uploaded,
      createdByUid: 'user-1',
      createdAt: DateTime.utc(2026, 6, 18, 10),
      updatedAt: DateTime.utc(2026, 6, 18, 11),
      createdByHuntEventId: 'event-1',
    );

    final restored = DogMediaAsset.fromJson(asset.toJson());

    expect(restored.mediaId, asset.mediaId);
    expect(restored.dogCloudId, asset.dogCloudId);
    expect(restored.dogKey, asset.dogKey);
    expect(restored.sessionId, asset.sessionId);
    expect(restored.kind, DogMediaKind.sessionVideo);
    expect(restored.status, DogMediaStatus.active);
    expect(restored.syncStatus, DogMediaSyncStatus.uploaded);
    expect(restored.storagePath, asset.storagePath);
    expect(restored.thumbnailStoragePath, asset.thumbnailStoragePath);
    expect(restored.localPath, asset.localPath);
    expect(restored.thumbnailLocalPath, asset.thumbnailLocalPath);
    expect(restored.contentType, 'video/mp4');
    expect(restored.sizeBytes, 123456);
    expect(restored.createdByUid, 'user-1');
    expect(restored.createdAt, DateTime.utc(2026, 6, 18, 10));
    expect(restored.updatedAt, DateTime.utc(2026, 6, 18, 11));
    expect(restored.deletedAt, isNull);
    expect(restored.createdByHuntEventId, 'event-1');
  });

  test('copyWith can mark asset deleted', () {
    final asset = DogMediaAsset(
      mediaId: 'media-1',
      dogCloudId: 'dog-cloud-1',
      dogKey: 'NO123-45',
      kind: DogMediaKind.profileImage,
      status: DogMediaStatus.active,
      syncStatus: DogMediaSyncStatus.downloaded,
      createdAt: DateTime.utc(2026, 6, 18),
    );
    final deletedAt = DateTime.utc(2026, 6, 19);

    final deleted = asset.copyWith(
      status: DogMediaStatus.deleted,
      syncStatus: DogMediaSyncStatus.deleted,
      deletedAt: deletedAt,
    );

    expect(deleted.status, DogMediaStatus.deleted);
    expect(deleted.syncStatus, DogMediaSyncStatus.deleted);
    expect(deleted.deletedAt, deletedAt);
    expect(deleted.mediaId, asset.mediaId);
  });

  test('Hive adapter decodes legacy 17-field record without provenance', () {
    final createdAt = DateTime.utc(2025, 12, 1, 12);
    final reader = _LegacyBinaryReader(<dynamic>[
      17,
      0,
      'legacy-media',
      1,
      'dog-cloud',
      2,
      'DOG-1',
      3,
      'session-1',
      4,
      DogMediaKind.sessionImage.name,
      5,
      null,
      6,
      null,
      7,
      'media/dogs/dog-cloud/sessions/session-1/legacy.jpg',
      8,
      null,
      9,
      'image/jpeg',
      10,
      42,
      11,
      DogMediaStatus.active.name,
      12,
      DogMediaSyncStatus.localOnly.name,
      13,
      'owner',
      14,
      createdAt,
      15,
      null,
      16,
      null,
    ]);

    final restored = DogMediaAssetAdapter().read(reader);

    expect(restored.mediaId, 'legacy-media');
    expect(restored.sessionId, 'session-1');
    expect(restored.kind, DogMediaKind.sessionImage);
    expect(restored.localPath, endsWith('legacy.jpg'));
    expect(restored.sizeBytes, 42);
    expect(restored.createdAt, createdAt);
    expect(restored.createdByHuntEventId, isNull);
  });
}

class _LegacyBinaryReader implements BinaryReader {
  _LegacyBinaryReader(this._values);

  final List<dynamic> _values;
  var _index = 0;

  @override
  int readByte() => _values[_index++] as int;

  @override
  dynamic read([int? typeId]) => _values[_index++];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
