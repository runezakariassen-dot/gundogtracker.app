import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/local_dog_media_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';
import 'package:jakthund_app/services/dog_profile_media_upload_service.dart';

void main() {
  late Directory tempDir;
  late Box<DogMediaAsset> box;
  late LocalDogMediaRepository repository;
  late File imageFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dog_profile_upload_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(49)) {
      Hive.registerAdapter(DogMediaAssetAdapter());
    }
    box = await Hive.openBox<DogMediaAsset>('dog_media_assets_test');
    repository = LocalDogMediaRepository(box: box);
    imageFile = File('${tempDir.path}/profile.jpg');
    await imageFile.writeAsBytes(<int>[1, 2, 3, 4]);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('happy path creates asset uploads writes metadata and returns media id',
      () async {
    String? uploadedPath;
    String? uploadedContentType;
    String? metadataDogId;
    String? metadataMediaId;
    Map<String, dynamic>? metadataPayload;
    var tick = 0;
    final service = DogProfileMediaUploadService(
      localRepository: repository,
      mediaIdFactory: () => 'profile-media-1',
      clock: () => DateTime.utc(2026, 6, 18, 10, tick++),
      uploadFile: ({
        required File file,
        required String storagePath,
        String? contentType,
      }) async {
        expect(file.path, imageFile.path);
        uploadedPath = storagePath;
        uploadedContentType = contentType;
      },
      writeMetadata: ({
        required String dogId,
        required String mediaId,
        required Map<String, dynamic> payload,
      }) async {
        metadataDogId = dogId;
        metadataMediaId = mediaId;
        metadataPayload = payload;
      },
    );

    final result = await service.uploadProfileImage(
      dogCloudId: ' dog-cloud-1 ',
      dogKey: ' DOG-1 ',
      localImagePath: imageFile.path,
      currentUserUid: ' owner-uid ',
      contentType: ' image/jpeg ',
      sizeBytes: 4,
    );

    expect(result.mediaId, 'profile-media-1');
    expect(result.profileMediaId, 'profile-media-1');
    expect(uploadedPath, 'dogs/dog-cloud-1/profile/profile-media-1/original');
    expect(uploadedContentType, 'image/jpeg');
    expect(metadataDogId, 'dog-cloud-1');
    expect(metadataMediaId, 'profile-media-1');
    expect(metadataPayload?['mediaId'], 'profile-media-1');
    expect(metadataPayload?['dogId'], 'dog-cloud-1');
    expect(metadataPayload?['dogKey'], 'DOG-1');
    expect(metadataPayload?['kind'], DogMediaKind.profileImage.name);
    expect(
      metadataPayload?['storagePath'],
      'dogs/dog-cloud-1/profile/profile-media-1/original',
    );
    expect(
      metadataPayload?['thumbnailStoragePath'],
      'dogs/dog-cloud-1/profile/profile-media-1/thumb.jpg',
    );
    expect(metadataPayload?['contentType'], 'image/jpeg');
    expect(metadataPayload?['sizeBytes'], 4);
    expect(metadataPayload?['createdByUid'], 'owner-uid');
    expect(metadataPayload?['source'], 'mobile');

    final stored = repository.get('profile-media-1');
    expect(stored, isNotNull);
    expect(stored!.dogCloudId, 'dog-cloud-1');
    expect(stored.dogKey, 'DOG-1');
    expect(stored.localPath, imageFile.path);
    expect(stored.storagePath, uploadedPath);
    expect(stored.thumbnailStoragePath,
        'dogs/dog-cloud-1/profile/profile-media-1/thumb.jpg');
    expect(stored.syncStatus, DogMediaSyncStatus.uploaded);
    expect(stored.status, DogMediaStatus.active);
    expect(stored.createdByUid, 'owner-uid');
  });

  test('upload failure marks asset failed and keeps local path', () async {
    final service = DogProfileMediaUploadService(
      localRepository: repository,
      mediaIdFactory: () => 'profile-media-1',
      clock: () => DateTime.utc(2026, 6, 18, 10),
      uploadFile: ({
        required File file,
        required String storagePath,
        String? contentType,
      }) async {
        throw StateError('upload failed');
      },
      writeMetadata: ({
        required String dogId,
        required String mediaId,
        required Map<String, dynamic> payload,
      }) async {
        fail('metadata should not be written when upload fails');
      },
    );

    await expectLater(
      service.uploadProfileImage(
        dogCloudId: 'dog-cloud-1',
        dogKey: 'DOG-1',
        localImagePath: imageFile.path,
        currentUserUid: 'owner-uid',
        contentType: 'image/jpeg',
        sizeBytes: 4,
      ),
      throwsA(isA<StateError>()),
    );

    final stored = repository.get('profile-media-1');
    expect(stored, isNotNull);
    expect(stored!.localPath, imageFile.path);
    expect(stored.storagePath,
        'dogs/dog-cloud-1/profile/profile-media-1/original');
    expect(stored.syncStatus, DogMediaSyncStatus.failed);
    expect(stored.status, DogMediaStatus.active);
  });

  test('metadata payload does not contain localPath or imagePath', () async {
    Map<String, dynamic>? metadataPayload;
    final service = DogProfileMediaUploadService(
      localRepository: repository,
      mediaIdFactory: () => 'profile-media-1',
      clock: () => DateTime.utc(2026, 6, 18, 10),
      uploadFile: ({
        required File file,
        required String storagePath,
        String? contentType,
      }) async {},
      writeMetadata: ({
        required String dogId,
        required String mediaId,
        required Map<String, dynamic> payload,
      }) async {
        metadataPayload = payload;
      },
    );

    await service.uploadProfileImage(
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      localImagePath: imageFile.path,
      currentUserUid: 'owner-uid',
      contentType: 'image/jpeg',
      sizeBytes: 4,
    );

    expect(metadataPayload, isNotNull);
    expect(metadataPayload!.containsKey('localPath'), isFalse);
    expect(metadataPayload!.containsKey('thumbnailLocalPath'), isFalse);
    expect(metadataPayload!.containsKey('imagePath'), isFalse);
  });

  test('missing dogCloudId or dogKey is rejected before local asset is created',
      () async {
    final service = DogProfileMediaUploadService(
      localRepository: repository,
      mediaIdFactory: () => 'profile-media-1',
      clock: () => DateTime.utc(2026, 6, 18, 10),
      uploadFile: ({
        required File file,
        required String storagePath,
        String? contentType,
      }) async {},
      writeMetadata: ({
        required String dogId,
        required String mediaId,
        required Map<String, dynamic> payload,
      }) async {},
    );

    await expectLater(
      service.uploadProfileImage(
        dogCloudId: ' ',
        dogKey: 'DOG-1',
        localImagePath: imageFile.path,
        currentUserUid: 'owner-uid',
      ),
      throwsArgumentError,
    );
    await expectLater(
      service.uploadProfileImage(
        dogCloudId: 'dog-cloud-1',
        dogKey: '',
        localImagePath: imageFile.path,
        currentUserUid: 'owner-uid',
      ),
      throwsArgumentError,
    );

    expect(box.values, isEmpty);
  });

  test('Dog input uses dog cloud id and dog key', () async {
    String? uploadedPath;
    final dog = Dog(
      name: 'Birk',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO123/45',
      cloudId: 'dog-cloud-1',
    );
    final service = DogProfileMediaUploadService(
      localRepository: repository,
      mediaIdFactory: () => 'profile-media-1',
      clock: () => DateTime.utc(2026, 6, 18, 10),
      uploadFile: ({
        required File file,
        required String storagePath,
        String? contentType,
      }) async {
        uploadedPath = storagePath;
      },
      writeMetadata: ({
        required String dogId,
        required String mediaId,
        required Map<String, dynamic> payload,
      }) async {},
    );

    final result = await service.uploadProfileImageForDog(
      dog: dog,
      localImagePath: imageFile.path,
      currentUserUid: 'owner-uid',
    );

    expect(result.profileMediaId, 'profile-media-1');
    expect(uploadedPath, 'dogs/dog-cloud-1/profile/profile-media-1/original');
  });
}
