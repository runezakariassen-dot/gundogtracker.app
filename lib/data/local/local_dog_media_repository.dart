import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../models/dog_media_asset.dart';

class LocalDogMediaRepository {
  LocalDogMediaRepository({Box<DogMediaAsset>? box})
      : _box = box ?? dogMediaAssetsBox();

  final Box<DogMediaAsset> _box;

  Future<void> put(DogMediaAsset asset) {
    return _box.put(asset.mediaId, asset);
  }

  DogMediaAsset? get(String mediaId) {
    return _box.get(mediaId);
  }

  List<DogMediaAsset> listForDog({
    String? dogCloudId,
    String? dogKey,
    bool includeDeleted = false,
  }) {
    return _box.values
        .where((asset) =>
            _matchesDog(asset, dogCloudId: dogCloudId, dogKey: dogKey) &&
            (includeDeleted || asset.status != DogMediaStatus.deleted))
        .toList(growable: false);
  }

  List<DogMediaAsset> listForSession({
    String? dogCloudId,
    String? dogKey,
    required String sessionId,
    bool includeDeleted = false,
  }) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) return const <DogMediaAsset>[];
    return listForDog(
      dogCloudId: dogCloudId,
      dogKey: dogKey,
      includeDeleted: includeDeleted,
    )
        .where((asset) => asset.sessionId?.trim() == normalizedSessionId)
        .toList(growable: false);
  }

  DogMediaAsset? getProfileImageForDog({
    String? dogCloudId,
    String? dogKey,
    bool includeDeleted = false,
  }) {
    final candidates = listForDog(
      dogCloudId: dogCloudId,
      dogKey: dogKey,
      includeDeleted: includeDeleted,
    )
        .where((asset) => asset.kind == DogMediaKind.profileImage)
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final aUpdated = a.updatedAt ?? a.createdAt;
      final bUpdated = b.updatedAt ?? b.createdAt;
      return bUpdated.compareTo(aUpdated);
    });
    return candidates.first;
  }

  Future<void> markDeleted(String mediaId, {DateTime? deletedAt}) async {
    final asset = get(mediaId);
    if (asset == null) return;
    final timestamp = deletedAt ?? DateTime.now();
    await put(
      asset.copyWith(
        status: DogMediaStatus.deleted,
        syncStatus: DogMediaSyncStatus.deleted,
        updatedAt: timestamp,
        deletedAt: timestamp,
      ),
    );
  }

  bool _matchesDog(
    DogMediaAsset asset, {
    String? dogCloudId,
    String? dogKey,
  }) {
    final normalizedCloudId = dogCloudId?.trim();
    final normalizedDogKey = dogKey?.trim();
    final hasCloudId =
        normalizedCloudId != null && normalizedCloudId.isNotEmpty;
    final hasDogKey = normalizedDogKey != null && normalizedDogKey.isNotEmpty;
    if (!hasCloudId && !hasDogKey) return false;
    if (hasCloudId && asset.dogCloudId.trim() == normalizedCloudId) return true;
    if (hasDogKey && asset.dogKey.trim() == normalizedDogKey) return true;
    return false;
  }
}
