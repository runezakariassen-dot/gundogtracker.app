import 'dart:io';

import '../data/local/local_dog_media_repository.dart';
import '../models/dog.dart';
import '../models/dog_media_asset.dart';
import '../utils/dog_image_path_resolver.dart';

class DogProfileImageResolver {
  DogProfileImageResolver({LocalDogMediaRepository? mediaRepository})
      : _mediaRepository = mediaRepository ?? LocalDogMediaRepository();

  final LocalDogMediaRepository _mediaRepository;

  String? resolve(Dog dog) {
    final profileMediaId = dog.profileMediaId?.trim();
    if (profileMediaId != null && profileMediaId.isNotEmpty) {
      final cloudCachePath = _resolveDownloadedCloudCache(profileMediaId);
      if (cloudCachePath != null) return cloudCachePath;
    }
    return DogImagePathResolver.toAbsolute(dog.imagePath);
  }

  String? _resolveDownloadedCloudCache(String profileMediaId) {
    final asset = _mediaRepository.get(profileMediaId);
    if (asset == null ||
        asset.kind != DogMediaKind.profileImage ||
        asset.status != DogMediaStatus.active ||
        asset.syncStatus != DogMediaSyncStatus.downloaded) {
      return null;
    }
    final localPath = asset.localPath?.trim();
    if (localPath == null || localPath.isEmpty) return null;
    return File(localPath).existsSync() ? localPath : null;
  }
}
