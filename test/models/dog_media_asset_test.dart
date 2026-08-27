import 'package:flutter_test/flutter_test.dart';
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
}
