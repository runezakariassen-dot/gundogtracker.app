import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/local_dog_media_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';
import 'package:jakthund_app/services/dog_profile_image_resolver.dart';

void main() {
  late Directory tempDir;
  late Box<DogMediaAsset> box;
  late LocalDogMediaRepository repository;
  late DogProfileImageResolver resolver;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dog_profile_resolver_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(49)) {
      Hive.registerAdapter(DogMediaAssetAdapter());
    }
    box = await Hive.openBox<DogMediaAsset>('dog_media_assets_test');
    repository = LocalDogMediaRepository(box: box);
    resolver = DogProfileImageResolver(mediaRepository: repository);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('downloaded cloud asset with existing file wins over imagePath',
      () async {
    final cloudFile = File('${tempDir.path}/cloud/profile.jpg');
    await cloudFile.create(recursive: true);
    await repository.put(
      _asset(
        mediaId: 'profile-media-1',
        localPath: cloudFile.path,
        syncStatus: DogMediaSyncStatus.downloaded,
      ),
    );
    final dog = _dog(
      imagePath: '/local/fallback.jpg',
      profileMediaId: 'profile-media-1',
    );

    expect(resolver.resolve(dog), cloudFile.path);
  });

  test('missing profileMediaId or asset falls back to imagePath', () {
    expect(
      resolver.resolve(_dog(imagePath: '/local/fallback.jpg')),
      '/local/fallback.jpg',
    );
    expect(
      resolver.resolve(
        _dog(
          imagePath: '/local/fallback.jpg',
          profileMediaId: 'missing-media',
        ),
      ),
      '/local/fallback.jpg',
    );
  });

  test('not downloaded cloud asset falls back to imagePath', () async {
    final cloudFile = File('${tempDir.path}/cloud/profile.jpg');
    await cloudFile.create(recursive: true);
    await repository.put(
      _asset(
        mediaId: 'profile-media-1',
        localPath: cloudFile.path,
        syncStatus: DogMediaSyncStatus.pendingDownload,
      ),
    );

    expect(
      resolver.resolve(
        _dog(
          imagePath: '/local/fallback.jpg',
          profileMediaId: 'profile-media-1',
        ),
      ),
      '/local/fallback.jpg',
    );
  });

  test('downloaded cloud asset with missing local file falls back to imagePath',
      () async {
    await repository.put(
      _asset(
        mediaId: 'profile-media-1',
        localPath: '${tempDir.path}/cloud/missing.jpg',
        syncStatus: DogMediaSyncStatus.downloaded,
      ),
    );

    expect(
      resolver.resolve(
        _dog(
          imagePath: '/local/fallback.jpg',
          profileMediaId: 'profile-media-1',
        ),
      ),
      '/local/fallback.jpg',
    );
  });

  test('no cloud cache and no imagePath returns null', () {
    expect(resolver.resolve(_dog()), isNull);
  });
}

Dog _dog({
  String? imagePath,
  String? profileMediaId,
}) {
  return Dog(
    name: 'Birk',
    dogKey: 'DOG-1',
    regNrDisplay: 'NO123/45',
    imagePath: imagePath,
    profileMediaId: profileMediaId,
  );
}

DogMediaAsset _asset({
  required String mediaId,
  required String localPath,
  required DogMediaSyncStatus syncStatus,
}) {
  return DogMediaAsset(
    mediaId: mediaId,
    dogCloudId: 'dog-cloud-1',
    dogKey: 'DOG-1',
    kind: DogMediaKind.profileImage,
    localPath: localPath,
    status: DogMediaStatus.active,
    syncStatus: syncStatus,
    createdAt: DateTime.utc(2026, 6, 18),
  );
}
