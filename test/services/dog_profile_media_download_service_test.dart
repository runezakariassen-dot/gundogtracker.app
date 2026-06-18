import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/local_dog_media_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';
import 'package:jakthund_app/services/cloud/dog_media_cloud_service.dart';
import 'package:jakthund_app/services/dog_media_cache_service.dart';
import 'package:jakthund_app/services/dog_profile_media_download_service.dart';

void main() {
  late Directory tempDir;
  late Box<DogMediaAsset> box;
  late LocalDogMediaRepository repository;
  late DogMediaCacheService cacheService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dog_profile_download_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(49)) {
      Hive.registerAdapter(DogMediaAssetAdapter());
    }
    box = await Hive.openBox<DogMediaAsset>('dog_media_assets_test');
    repository = LocalDogMediaRepository(box: box);
    cacheService = DogMediaCacheService(documentsPath: tempDir.path);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('happy path fetches metadata downloads and stores downloaded asset',
      () async {
    String? fetchedDogId;
    String? fetchedMediaId;
    String? downloadedStoragePath;
    String? downloadedLocalPath;
    var tick = 0;
    final service = DogProfileMediaDownloadService(
      localRepository: repository,
      cacheService: cacheService,
      clock: () => DateTime.utc(2026, 6, 18, 10, tick++),
      fetchMetadata: ({
        required String dogId,
        required String mediaId,
      }) async {
        fetchedDogId = dogId;
        fetchedMediaId = mediaId;
        return _profileMetadata(
          dogId: dogId,
          dogKey: 'DOG-1',
          mediaId: mediaId,
          contentType: 'image/png',
        );
      },
      downloadFile: ({
        required String storagePath,
        required String localPath,
      }) async {
        downloadedStoragePath = storagePath;
        downloadedLocalPath = localPath;
        await File(localPath).writeAsBytes(<int>[1, 2, 3]);
      },
    );

    final asset = await service.downloadProfileImage(
      dogCloudId: ' dog-cloud-1 ',
      dogKey: ' DOG-1 ',
      profileMediaId: ' profile-media-1 ',
    );

    expect(fetchedDogId, 'dog-cloud-1');
    expect(fetchedMediaId, 'profile-media-1');
    expect(downloadedStoragePath,
        'dogs/dog-cloud-1/profile/profile-media-1/original');
    expect(downloadedLocalPath,
        '${tempDir.path}/dog_media/dog-cloud-1/profile/profile-media-1.png');
    expect(await File(downloadedLocalPath!).exists(), isTrue);
    expect(asset, isNotNull);
    expect(asset!.mediaId, 'profile-media-1');
    expect(asset.dogCloudId, 'dog-cloud-1');
    expect(asset.dogKey, 'DOG-1');
    expect(asset.localPath, downloadedLocalPath);
    expect(asset.storagePath, downloadedStoragePath);
    expect(asset.contentType, 'image/png');
    expect(asset.syncStatus, DogMediaSyncStatus.downloaded);
    expect(repository.get('profile-media-1')?.syncStatus,
        DogMediaSyncStatus.downloaded);
  });

  test(
      'existing downloaded cache is returned without metadata fetch or download',
      () async {
    final localPath =
        '${tempDir.path}/dog_media/dog-cloud-1/profile/profile-media-1.jpg';
    await File(localPath).create(recursive: true);
    final cached = DogMediaAsset(
      mediaId: 'profile-media-1',
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      kind: DogMediaKind.profileImage,
      localPath: localPath,
      status: DogMediaStatus.active,
      syncStatus: DogMediaSyncStatus.downloaded,
      createdAt: DateTime.utc(2026, 6, 18, 9),
    );
    await repository.put(cached);
    final service = DogProfileMediaDownloadService(
      localRepository: repository,
      cacheService: cacheService,
      fetchMetadata: ({
        required String dogId,
        required String mediaId,
      }) async {
        fail('metadata should not be fetched for usable downloaded cache');
      },
      downloadFile: ({
        required String storagePath,
        required String localPath,
      }) async {
        fail('file should not be downloaded for usable downloaded cache');
      },
    );

    final asset = await service.downloadProfileImage(
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      profileMediaId: 'profile-media-1',
    );

    expect(asset, same(cached));
  });

  test('missing profileMediaId does nothing', () async {
    var fetchCalled = false;
    final service = DogProfileMediaDownloadService(
      localRepository: repository,
      cacheService: cacheService,
      fetchMetadata: ({
        required String dogId,
        required String mediaId,
      }) async {
        fetchCalled = true;
        return null;
      },
      downloadFile: ({
        required String storagePath,
        required String localPath,
      }) async {},
    );

    final asset = await service.downloadProfileImageForDog(
      Dog(
        name: 'Birk',
        dogKey: 'DOG-1',
        regNrDisplay: 'NO123/45',
        cloudId: 'dog-cloud-1',
      ),
    );

    expect(asset, isNull);
    expect(fetchCalled, isFalse);
    expect(box.values, isEmpty);
  });

  test('missing metadata does not crash or create asset', () async {
    final service = DogProfileMediaDownloadService(
      localRepository: repository,
      cacheService: cacheService,
      fetchMetadata: ({
        required String dogId,
        required String mediaId,
      }) async {
        return null;
      },
      downloadFile: ({
        required String storagePath,
        required String localPath,
      }) async {
        fail('missing metadata should not trigger download');
      },
    );

    final asset = await service.downloadProfileImage(
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      profileMediaId: 'profile-media-1',
    );

    expect(asset, isNull);
    expect(box.values, isEmpty);
  });

  test('metadata with wrong kind or status is rejected without download',
      () async {
    var fetchCount = 0;
    final service = DogProfileMediaDownloadService(
      localRepository: repository,
      cacheService: cacheService,
      fetchMetadata: ({
        required String dogId,
        required String mediaId,
      }) async {
        fetchCount += 1;
        if (fetchCount == 1) {
          return _profileMetadata(
            dogId: dogId,
            dogKey: 'DOG-1',
            mediaId: mediaId,
            kind: DogMediaKind.sessionImage.name,
          );
        }
        return _profileMetadata(
          dogId: dogId,
          dogKey: 'DOG-1',
          mediaId: mediaId,
          status: DogMediaStatus.deleted.name,
        );
      },
      downloadFile: ({
        required String storagePath,
        required String localPath,
      }) async {
        fail('invalid metadata should not trigger download');
      },
    );

    final wrongKind = await service.downloadProfileImage(
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      profileMediaId: 'profile-media-1',
    );
    final wrongStatus = await service.downloadProfileImage(
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      profileMediaId: 'profile-media-2',
    );

    expect(wrongKind, isNull);
    expect(wrongStatus, isNull);
    expect(box.values, isEmpty);
  });

  test('download failure marks failed asset and keeps metadata', () async {
    final service = DogProfileMediaDownloadService(
      localRepository: repository,
      cacheService: cacheService,
      clock: () => DateTime.utc(2026, 6, 18, 10),
      fetchMetadata: ({
        required String dogId,
        required String mediaId,
      }) async {
        return _profileMetadata(
          dogId: dogId,
          dogKey: 'DOG-1',
          mediaId: mediaId,
          contentType: 'image/jpeg',
        );
      },
      downloadFile: ({
        required String storagePath,
        required String localPath,
      }) async {
        throw StateError('download failed');
      },
    );

    await expectLater(
      service.downloadProfileImage(
        dogCloudId: 'dog-cloud-1',
        dogKey: 'DOG-1',
        profileMediaId: 'profile-media-1',
      ),
      throwsA(isA<StateError>()),
    );

    final stored = repository.get('profile-media-1');
    expect(stored, isNotNull);
    expect(stored!.dogCloudId, 'dog-cloud-1');
    expect(stored.dogKey, 'DOG-1');
    expect(stored.storagePath,
        'dogs/dog-cloud-1/profile/profile-media-1/original');
    expect(stored.localPath,
        '${tempDir.path}/dog_media/dog-cloud-1/profile/profile-media-1.jpg');
    expect(stored.contentType, 'image/jpeg');
    expect(stored.syncStatus, DogMediaSyncStatus.failed);
    expect(stored.status, DogMediaStatus.active);
  });
}

Map<String, dynamic> _profileMetadata({
  required String dogId,
  required String dogKey,
  required String mediaId,
  String kind = 'profileImage',
  String status = 'active',
  String contentType = 'image/jpeg',
}) {
  return <String, dynamic>{
    'mediaId': mediaId,
    'dogId': dogId,
    'dogKey': dogKey,
    'kind': kind,
    'storagePath': DogMediaCloudService.profileOriginalStoragePath(
      dogId: dogId,
      mediaId: mediaId,
    ),
    'thumbnailStoragePath': DogMediaCloudService.profileThumbnailStoragePath(
      dogId: dogId,
      mediaId: mediaId,
    ),
    'contentType': contentType,
    'sizeBytes': 1234,
    'status': status,
    'createdByUid': 'owner-uid',
    'createdAt': DateTime.utc(2026, 6, 18, 9),
    'updatedAt': DateTime.utc(2026, 6, 18, 9),
    'source': 'mobile',
  };
}
