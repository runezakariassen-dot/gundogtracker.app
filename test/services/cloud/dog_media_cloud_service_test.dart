import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';
import 'package:jakthund_app/services/cloud/dog_media_cloud_service.dart';

void main() {
  test('builds profile image storage paths', () {
    expect(
      DogMediaCloudService.profileOriginalStoragePath(
        dogId: 'dog-cloud-1',
        mediaId: 'media-1',
      ),
      'dogs/dog-cloud-1/profile/media-1/original',
    );
    expect(
      DogMediaCloudService.profileThumbnailStoragePath(
        dogId: 'dog-cloud-1',
        mediaId: 'media-1',
      ),
      'dogs/dog-cloud-1/profile/media-1/thumb.jpg',
    );
  });

  test('builds session image and video storage paths', () {
    expect(
      DogMediaCloudService.sessionMediaOriginalStoragePath(
        dogId: 'dog-cloud-1',
        sessionId: 'session-1',
        mediaId: 'image-1',
      ),
      'dogs/dog-cloud-1/sessions/session-1/media/image-1/original',
    );
    expect(
      DogMediaCloudService.sessionMediaThumbnailStoragePath(
        dogId: 'dog-cloud-1',
        sessionId: 'session-1',
        mediaId: 'video-1',
      ),
      'dogs/dog-cloud-1/sessions/session-1/media/video-1/thumb.jpg',
    );
  });

  test('builds Firestore media document path', () {
    expect(
      DogMediaCloudService.firestoreMediaDocumentPath(
        dogId: 'dog-cloud-1',
        mediaId: 'media-1',
      ),
      'dogs/dog-cloud-1/media/media-1',
    );
  });

  test('builds profile metadata payload without local paths', () {
    final createdAt = DateTime.utc(2026, 6, 18, 10);
    final payload = DogMediaCloudService.profileImageMetadataPayload(
      dogId: 'dog-cloud-1',
      dogKey: 'NO123-45',
      mediaId: 'profile-1',
      thumbnailStoragePath: DogMediaCloudService.profileThumbnailStoragePath(
        dogId: 'dog-cloud-1',
        mediaId: 'profile-1',
      ),
      contentType: 'image/jpeg',
      sizeBytes: 12345,
      createdByUid: 'owner-uid',
      createdAt: createdAt,
    );

    expect(payload['mediaId'], 'profile-1');
    expect(payload['dogId'], 'dog-cloud-1');
    expect(payload['dogKey'], 'NO123-45');
    expect(payload.containsKey('sessionId'), isFalse);
    expect(payload['kind'], DogMediaKind.profileImage.name);
    expect(
      payload['storagePath'],
      'dogs/dog-cloud-1/profile/profile-1/original',
    );
    expect(
      payload['thumbnailStoragePath'],
      'dogs/dog-cloud-1/profile/profile-1/thumb.jpg',
    );
    expect(payload['contentType'], 'image/jpeg');
    expect(payload['sizeBytes'], 12345);
    expect(payload['status'], DogMediaStatus.active.name);
    expect(payload['createdByUid'], 'owner-uid');
    expect(payload['createdAt'], isA<Timestamp>());
    expect(payload['updatedAt'], isA<Timestamp>());
    expect(payload['deletedAt'], isNull);
    expect(payload['source'], 'mobile');
    expect(payload.containsKey('localPath'), isFalse);
    expect(payload.containsKey('thumbnailLocalPath'), isFalse);
    expect(payload.containsKey('imagePath'), isFalse);
  });

  test('builds session media metadata payload without local paths', () {
    final createdAt = DateTime.utc(2026, 6, 18, 10);
    final updatedAt = DateTime.utc(2026, 6, 18, 11);
    final payload = DogMediaCloudService.sessionMediaMetadataPayload(
      dogId: 'dog-cloud-1',
      dogKey: 'NO123-45',
      sessionId: 'session-1',
      mediaId: 'video-1',
      kind: DogMediaKind.sessionVideo,
      thumbnailStoragePath:
          DogMediaCloudService.sessionMediaThumbnailStoragePath(
        dogId: 'dog-cloud-1',
        sessionId: 'session-1',
        mediaId: 'video-1',
      ),
      contentType: 'video/mp4',
      sizeBytes: 98765,
      createdByUid: 'member-uid',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    expect(payload['mediaId'], 'video-1');
    expect(payload['dogId'], 'dog-cloud-1');
    expect(payload['dogKey'], 'NO123-45');
    expect(payload['sessionId'], 'session-1');
    expect(payload['kind'], DogMediaKind.sessionVideo.name);
    expect(
      payload['storagePath'],
      'dogs/dog-cloud-1/sessions/session-1/media/video-1/original',
    );
    expect(
      payload['thumbnailStoragePath'],
      'dogs/dog-cloud-1/sessions/session-1/media/video-1/thumb.jpg',
    );
    expect(payload['contentType'], 'video/mp4');
    expect(payload['sizeBytes'], 98765);
    expect(payload['status'], DogMediaStatus.active.name);
    expect(payload['createdByUid'], 'member-uid');
    expect(payload['createdAt'], isA<Timestamp>());
    expect(payload['updatedAt'], isA<Timestamp>());
    expect(payload['deletedAt'], isNull);
    expect(payload['source'], 'mobile');
    expect(payload.containsKey('localPath'), isFalse);
    expect(payload.containsKey('thumbnailLocalPath'), isFalse);
    expect(payload.containsKey('imagePath'), isFalse);
  });

  test('rejects profile image kind for session media payload', () {
    expect(
      () => DogMediaCloudService.sessionMediaMetadataPayload(
        dogId: 'dog-cloud-1',
        dogKey: 'NO123-45',
        sessionId: 'session-1',
        mediaId: 'profile-1',
        kind: DogMediaKind.profileImage,
        createdAt: DateTime.utc(2026, 6, 18),
      ),
      throwsArgumentError,
    );
  });
}
