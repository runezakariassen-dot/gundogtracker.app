import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/local/local_dog_media_repository.dart';
import '../models/dog.dart';
import '../models/dog_media_asset.dart';
import 'cloud/dog_media_cloud_service.dart';
import 'dog_media_cache_service.dart';

typedef DogProfileMediaFetchMetadata = Future<Map<String, dynamic>?> Function({
  required String dogId,
  required String mediaId,
});

typedef DogProfileMediaDownloadFile = Future<void> Function({
  required String storagePath,
  required String localPath,
});

typedef DogProfileMediaDownloadClock = DateTime Function();

class DogProfileMediaDownloadService {
  DogProfileMediaDownloadService({
    LocalDogMediaRepository? localRepository,
    DogMediaCacheService? cacheService,
    DogMediaCloudService? cloudService,
    DogProfileMediaFetchMetadata? fetchMetadata,
    DogProfileMediaDownloadFile? downloadFile,
    DogProfileMediaDownloadClock? clock,
  })  : _localRepository = localRepository ?? LocalDogMediaRepository(),
        _cacheService = cacheService ?? DogMediaCacheService(),
        _fetchMetadata = fetchMetadata ??
            _defaultFetchMetadata(cloudService ?? DogMediaCloudService()),
        _downloadFile = downloadFile ??
            _defaultDownloadFile(cloudService ?? DogMediaCloudService()),
        _clock = clock ?? DateTime.now;

  final LocalDogMediaRepository _localRepository;
  final DogMediaCacheService _cacheService;
  final DogProfileMediaFetchMetadata _fetchMetadata;
  final DogProfileMediaDownloadFile _downloadFile;
  final DogProfileMediaDownloadClock _clock;

  Future<DogMediaAsset?> downloadProfileImageForDog(Dog dog) {
    return downloadProfileImage(
      dogCloudId: dog.cloudId,
      dogKey: dog.dogKey,
      profileMediaId: dog.profileMediaId,
    );
  }

  Future<DogMediaAsset?> downloadProfileImage({
    required String? dogCloudId,
    required String? dogKey,
    required String? profileMediaId,
  }) async {
    final normalizedDogCloudId = _optionalTrimmed(dogCloudId);
    final normalizedDogKey = _optionalTrimmed(dogKey);
    final normalizedMediaId = _optionalTrimmed(profileMediaId);
    if (normalizedDogCloudId == null ||
        normalizedDogKey == null ||
        normalizedMediaId == null) {
      return null;
    }

    final cachedAsset = _localRepository.get(normalizedMediaId);
    if (_isUsableDownloadedCache(cachedAsset)) {
      return cachedAsset;
    }

    final metadata = await _fetchMetadata(
      dogId: normalizedDogCloudId,
      mediaId: normalizedMediaId,
    );
    if (metadata == null) return null;

    final metadataAsset = await _assetFromMetadata(
      metadata,
      fallbackDogCloudId: normalizedDogCloudId,
      fallbackDogKey: normalizedDogKey,
      fallbackMediaId: normalizedMediaId,
    );
    if (metadataAsset == null) return null;

    var asset = metadataAsset.copyWith(
      syncStatus: DogMediaSyncStatus.pendingDownload,
      updatedAt: _clock().toUtc(),
    );
    await _localRepository.put(asset);

    try {
      asset = asset.copyWith(
        syncStatus: DogMediaSyncStatus.downloading,
        updatedAt: _clock().toUtc(),
      );
      await _localRepository.put(asset);
      await _cacheService.ensureParentDirectory(asset.localPath!);
      await _downloadFile(
        storagePath: asset.storagePath!,
        localPath: asset.localPath!,
      );
      asset = asset.copyWith(
        syncStatus: DogMediaSyncStatus.downloaded,
        updatedAt: _clock().toUtc(),
      );
      await _localRepository.put(asset);
      return asset;
    } catch (_) {
      final failedAsset = asset.copyWith(
        syncStatus: DogMediaSyncStatus.failed,
        updatedAt: _clock().toUtc(),
      );
      await _localRepository.put(failedAsset);
      rethrow;
    }
  }

  Future<DogMediaAsset?> _assetFromMetadata(
    Map<String, dynamic> metadata, {
    required String fallbackDogCloudId,
    required String fallbackDogKey,
    required String fallbackMediaId,
  }) async {
    final kind = _readString(metadata['kind']);
    final status = _readString(metadata['status']);
    final storagePath = _readString(metadata['storagePath']);
    if (kind != DogMediaKind.profileImage.name ||
        status != DogMediaStatus.active.name ||
        storagePath == null) {
      return null;
    }

    final dogCloudId = _readString(metadata['dogId']) ?? fallbackDogCloudId;
    final dogKey = _readString(metadata['dogKey']) ?? fallbackDogKey;
    final mediaId = _readString(metadata['mediaId']) ?? fallbackMediaId;
    final contentType = _readString(metadata['contentType']);
    final localPath = await _cacheService.profileImagePath(
      dogCloudId: dogCloudId,
      mediaId: mediaId,
      extension: _extensionForContentType(contentType),
    );

    return DogMediaAsset(
      mediaId: mediaId,
      dogCloudId: dogCloudId,
      dogKey: dogKey,
      kind: DogMediaKind.profileImage,
      storagePath: storagePath,
      thumbnailStoragePath: _readString(metadata['thumbnailStoragePath']),
      localPath: localPath,
      contentType: contentType,
      sizeBytes: _readInt(metadata['sizeBytes']),
      status: DogMediaStatus.active,
      syncStatus: DogMediaSyncStatus.pendingDownload,
      createdByUid: _readString(metadata['createdByUid']),
      createdAt: _readDateTime(metadata['createdAt']) ?? _clock().toUtc(),
      updatedAt: _readDateTime(metadata['updatedAt']),
      deletedAt: _readDateTime(metadata['deletedAt']),
    );
  }

  bool _isUsableDownloadedCache(DogMediaAsset? asset) {
    if (asset == null ||
        asset.kind != DogMediaKind.profileImage ||
        asset.status != DogMediaStatus.active ||
        asset.syncStatus != DogMediaSyncStatus.downloaded) {
      return false;
    }
    final localPath = _optionalTrimmed(asset.localPath);
    return localPath != null && File(localPath).existsSync();
  }

  static DogProfileMediaFetchMetadata _defaultFetchMetadata(
    DogMediaCloudService cloudService,
  ) {
    return ({
      required String dogId,
      required String mediaId,
    }) {
      return cloudService.readMediaMetadata(dogId: dogId, mediaId: mediaId);
    };
  }

  static DogProfileMediaDownloadFile _defaultDownloadFile(
    DogMediaCloudService cloudService,
  ) {
    return ({
      required String storagePath,
      required String localPath,
    }) {
      return cloudService.downloadFileToPath(
        storagePath: storagePath,
        localPath: localPath,
      );
    };
  }

  static String? _optionalTrimmed(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static String? _readString(dynamic value) {
    if (value is String) return _optionalTrimmed(value);
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _extensionForContentType(String? contentType) {
    switch (contentType?.toLowerCase()) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/heic':
        return '.heic';
      case 'image/heif':
        return '.heif';
      case 'image/jpeg':
      case 'image/jpg':
      default:
        return '.jpg';
    }
  }
}
