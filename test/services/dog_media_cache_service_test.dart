import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';
import 'package:jakthund_app/services/dog_media_cache_service.dart';

void main() {
  test('generates stable profile image paths under dog media cache root',
      () async {
    final service = DogMediaCacheService(documentsPath: '/tmp/jakthund_docs');

    final relative = service.profileImageRelativePath(
      dogCloudId: 'dog/cloud 1',
      mediaId: 'profile/media 1',
    );
    final absolute = await service.profileImagePath(
      dogCloudId: 'dog/cloud 1',
      mediaId: 'profile/media 1',
    );

    expect(relative, 'dog_media/dog_cloud_1/profile/profile_media_1.jpg');
    expect(
      absolute,
      '/tmp/jakthund_docs/dog_media/dog_cloud_1/profile/profile_media_1.jpg',
    );
  });

  test('generates session image and video cache paths without owner imagePath',
      () async {
    final service = DogMediaCacheService(documentsPath: '/tmp/jakthund_docs');

    final image = service.sessionMediaRelativePath(
      dogCloudId: 'dog-cloud-1',
      sessionId: 'session-1',
      mediaId: 'image-1',
      kind: DogMediaKind.sessionImage,
    );
    final video = service.sessionMediaRelativePath(
      dogCloudId: 'dog-cloud-1',
      sessionId: 'session-1',
      mediaId: 'video-1',
      kind: DogMediaKind.sessionVideo,
    );
    final thumbnail = service.thumbnailRelativePath(
      dogCloudId: 'dog-cloud-1',
      sessionId: 'session-1',
      mediaId: 'video-1',
    );

    expect(
      image,
      'dog_media/dog-cloud-1/sessions/session-1/image-1.jpg',
    );
    expect(
      video,
      'dog_media/dog-cloud-1/sessions/session-1/video-1.mp4',
    );
    expect(
      thumbnail,
      'dog_media/dog-cloud-1/sessions/session-1/video-1_thumb.jpg',
    );
    expect(image, isNot(contains('dogs/photos')));
    expect(video, isNot(contains('dogs/photos')));
  });
}
