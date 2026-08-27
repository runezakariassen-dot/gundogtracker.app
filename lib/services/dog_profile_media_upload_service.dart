import 'dart:io';

import 'package:uuid/uuid.dart';

import '../data/local/local_dog_media_repository.dart';
import '../models/dog.dart';
import '../models/dog_media_asset.dart';
import 'cloud/dog_media_cloud_service.dart';

typedef DogProfileMediaUploadFile = Future<void> Function({
  required File file,
  required String storagePath,
  String? contentType,
});

typedef DogProfileMediaWriteMetadata = Future<void> Function({
  required String dogId,
  required String mediaId,
  required Map<String, dynamic> payload,
});

typedef DogProfileMediaIdFactory = String Function();
typedef DogProfileMediaClock = DateTime Function();

class DogProfileMediaUploadResult {
  const DogProfileMediaUploadResult({
    required this.mediaId,
    required this.profileMediaId,
    required this.asset,
  });

  final String mediaId;
  final String profileMediaId;
  final DogMediaAsset asset;
}

class DogProfileMediaUploadService {
  DogProfileMediaUploadService({
    LocalDogMediaRepository? localRepository,
    DogMediaCloudService? cloudService,
    DogProfileMediaUploadFile? uploadFile,
    DogProfileMediaWriteMetadata? writeMetadata,
    DogProfileMediaIdFactory? mediaIdFactory,
    DogProfileMediaClock? clock,
  })  : _localRepository = localRepository ?? LocalDogMediaRepository(),
        _mediaIdFactory = mediaIdFactory ?? const Uuid().v4,
        _clock = clock ?? DateTime.now,
        _uploadFile = uploadFile ??
            _defaultUploadFile(cloudService ?? DogMediaCloudService()),
        _writeMetadata = writeMetadata ??
            _defaultWriteMetadata(cloudService ?? DogMediaCloudService());

  final LocalDogMediaRepository _localRepository;
  final DogProfileMediaUploadFile _uploadFile;
  final DogProfileMediaWriteMetadata _writeMetadata;
  final DogProfileMediaIdFactory _mediaIdFactory;
  final DogProfileMediaClock _clock;

  Future<DogProfileMediaUploadResult> uploadProfileImageForDog({
    required Dog dog,
    required String localImagePath,
    required String currentUserUid,
    String? contentType,
    int? sizeBytes,
  }) {
    return uploadProfileImage(
      dogCloudId: dog.cloudId,
      dogKey: dog.dogKey,
      localImagePath: localImagePath,
      currentUserUid: currentUserUid,
      contentType: contentType,
      sizeBytes: sizeBytes,
    );
  }

  Future<DogProfileMediaUploadResult> uploadProfileImage({
    required String? dogCloudId,
    required String? dogKey,
    required String localImagePath,
    required String currentUserUid,
    String? contentType,
    int? sizeBytes,
  }) async {
    final normalizedDogCloudId = _requiredTrimmed(
      dogCloudId,
      'dogCloudId',
    );
    final normalizedDogKey = _requiredTrimmed(dogKey, 'dogKey');
    final normalizedLocalPath = _requiredTrimmed(
      localImagePath,
      'localImagePath',
    );
    final normalizedUserUid = _requiredTrimmed(
      currentUserUid,
      'currentUserUid',
    );
    final normalizedContentType = _optionalTrimmed(contentType);
    final mediaId = _requiredTrimmed(_mediaIdFactory(), 'mediaId');
    final createdAt = _clock().toUtc();
    final storagePath = DogMediaCloudService.profileOriginalStoragePath(
      dogId: normalizedDogCloudId,
      mediaId: mediaId,
    );
    final thumbnailStoragePath =
        DogMediaCloudService.profileThumbnailStoragePath(
      dogId: normalizedDogCloudId,
      mediaId: mediaId,
    );

    var asset = DogMediaAsset(
      mediaId: mediaId,
      dogCloudId: normalizedDogCloudId,
      dogKey: normalizedDogKey,
      kind: DogMediaKind.profileImage,
      storagePath: storagePath,
      thumbnailStoragePath: thumbnailStoragePath,
      localPath: normalizedLocalPath,
      contentType: normalizedContentType,
      sizeBytes: sizeBytes,
      status: DogMediaStatus.active,
      syncStatus: DogMediaSyncStatus.pendingUpload,
      createdByUid: normalizedUserUid,
      createdAt: createdAt,
    );
    await _localRepository.put(asset);

    try {
      asset = asset.copyWith(
        syncStatus: DogMediaSyncStatus.uploading,
        updatedAt: _clock().toUtc(),
      );
      await _localRepository.put(asset);

      await _uploadFile(
        file: File(normalizedLocalPath),
        storagePath: storagePath,
        contentType: normalizedContentType,
      );

      final metadata = DogMediaCloudService.profileImageMetadataPayload(
        dogId: normalizedDogCloudId,
        dogKey: normalizedDogKey,
        mediaId: mediaId,
        thumbnailStoragePath: thumbnailStoragePath,
        contentType: normalizedContentType,
        sizeBytes: sizeBytes,
        createdByUid: normalizedUserUid,
        createdAt: createdAt,
        updatedAt: _clock().toUtc(),
      );
      await _writeMetadata(
        dogId: normalizedDogCloudId,
        mediaId: mediaId,
        payload: metadata,
      );

      asset = asset.copyWith(
        syncStatus: DogMediaSyncStatus.uploaded,
        updatedAt: _clock().toUtc(),
      );
      await _localRepository.put(asset);

      return DogProfileMediaUploadResult(
        mediaId: mediaId,
        profileMediaId: mediaId,
        asset: asset,
      );
    } catch (_) {
      final failedAsset = asset.copyWith(
        syncStatus: DogMediaSyncStatus.failed,
        updatedAt: _clock().toUtc(),
      );
      await _localRepository.put(failedAsset);
      rethrow;
    }
  }

  static DogProfileMediaUploadFile _defaultUploadFile(
    DogMediaCloudService cloudService,
  ) {
    return ({
      required File file,
      required String storagePath,
      String? contentType,
    }) async {
      final task = await cloudService.uploadFileToStorage(
        file: file,
        storagePath: storagePath,
        contentType: contentType,
      );
      await task;
    };
  }

  static DogProfileMediaWriteMetadata _defaultWriteMetadata(
    DogMediaCloudService cloudService,
  ) {
    return ({
      required String dogId,
      required String mediaId,
      required Map<String, dynamic> payload,
    }) {
      return cloudService.writeMediaMetadata(
        dogId: dogId,
        mediaId: mediaId,
        payload: payload,
      );
    };
  }

  static String _requiredTrimmed(String? value, String fieldName) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'Must not be empty.');
    }
    return normalized;
  }

  static String? _optionalTrimmed(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
