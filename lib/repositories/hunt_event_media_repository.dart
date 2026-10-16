import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import '../models/dog_media_asset.dart';
import '../models/hunt_event_media_link.dart';
import '../models/hunt_session.dart';
import '../services/media_storage.dart';

class HuntEventMediaRepository {
  HuntEventMediaRepository({
    Box<HuntEventMediaLink>? linkBox,
    Box<DogMediaAsset>? mediaBox,
    Box<HuntSession>? sessionBox,
  })  : _linkBox = linkBox,
        _mediaBox = mediaBox,
        _sessionBox = sessionBox;

  final Box<HuntEventMediaLink>? _linkBox;
  final Box<DogMediaAsset>? _mediaBox;
  final Box<HuntSession>? _sessionBox;

  Box<HuntEventMediaLink> get _links => _linkBox ?? huntEventMediaLinksBox();
  Box<DogMediaAsset> get _media => _mediaBox ?? dogMediaAssetsBox();
  Box<HuntSession> get _sessions => _sessionBox ?? sessionsBox();

  List<HuntEventMediaLink> linksForEvent(String eventId) {
    final links = _links.values
        .where((link) => link.huntEventId == eventId)
        .toList(growable: false);
    links.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      final created = a.createdAt.compareTo(b.createdAt);
      return created != 0 ? created : a.id.compareTo(b.id);
    });
    return links;
  }

  /// Ordered, active canonical media. Missing/deleted references are skipped.
  List<DogMediaAsset> mediaForEvent(String eventId) {
    return linksForEvent(eventId)
        .map((link) => _media.get(link.mediaId))
        .whereType<DogMediaAsset>()
        .where((asset) => asset.status == DogMediaStatus.active)
        .toList(growable: false);
  }

  Future<HuntEventMediaLink> link({
    required String huntEventId,
    required String mediaId,
    int? sortOrder,
    DateTime? createdAt,
  }) async {
    HuntEventMediaLink? existing;
    for (final candidate in linksForEvent(huntEventId)) {
      if (candidate.mediaId == mediaId) {
        existing = candidate;
        break;
      }
    }
    if (existing != null) return existing;
    final link = HuntEventMediaLink(
      id: const Uuid().v4(),
      huntEventId: huntEventId,
      mediaId: mediaId,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
      sortOrder: sortOrder ?? linksForEvent(huntEventId).length,
    );
    await _links.put(link.id, link);
    return link;
  }

  Future<void> replaceLinks(
    String huntEventId,
    Iterable<String> orderedMediaIds,
  ) async {
    final seenMediaIds = <String>{};
    final ids = orderedMediaIds
        .where((mediaId) => seenMediaIds.add(mediaId))
        .toList(growable: false);
    final existingByMediaId = <String, HuntEventMediaLink>{
      for (final existing in linksForEvent(huntEventId))
        existing.mediaId: existing,
    };

    final retainedMediaIds = ids.toSet();
    final removedLinks = existingByMediaId.values
        .where((link) => !retainedMediaIds.contains(link.mediaId))
        .toList(growable: false);
    final removedLinkIds = removedLinks.map((link) => link.id).toList();
    await _links.deleteAll(removedLinkIds);

    for (final removedLink in removedLinks) {
      await deleteEventCreatedMediaIfUnreferenced(
        removedLink.mediaId,
        huntEventId: huntEventId,
        removedLinkIds: removedLinkIds,
      );
    }

    for (var index = 0; index < ids.length; index++) {
      final existing = existingByMediaId[ids[index]];
      if (existing != null) {
        if (existing.sortOrder != index) {
          await _links.put(
            existing.id,
            HuntEventMediaLink(
              id: existing.id,
              huntEventId: existing.huntEventId,
              mediaId: existing.mediaId,
              createdAt: existing.createdAt,
              sortOrder: index,
            ),
          );
        }
        continue;
      }
      await link(
        huntEventId: huntEventId,
        mediaId: ids[index],
        sortOrder: index,
      );
    }
  }

  Future<void> unlink(String huntEventId, String mediaId) async {
    final keys = _links
        .toMap()
        .entries
        .where((entry) =>
            entry.value.huntEventId == huntEventId &&
            entry.value.mediaId == mediaId)
        .map((entry) => entry.key)
        .toList(growable: false);
    await _links.deleteAll(keys);
  }

  bool isReferenced(String mediaId) =>
      _links.values.any((link) => link.mediaId == mediaId);

  /// Removes local media created through a HuntEvent after its final event
  /// link is gone. Existing session media, profile media, and cloud-backed
  /// assets are deliberately retained.
  Future<bool> deleteEventCreatedMediaIfUnreferenced(
    String mediaId, {
    String? huntEventId,
    Iterable<dynamic> removedLinkIds = const [],
  }) async {
    final remainingReferenceCount =
        _links.values.where((link) => link.mediaId == mediaId).length;
    final asset = _media.get(mediaId);
    final storedPath = asset?.localPath;
    final normalizedPath = storedPath == null
        ? null
        : (await MediaStorage.normalizeMediaPaths([storedPath])).single;
    if (kDebugMode) {
      debugPrint(
        '[HUNT_EVENT_MEDIA][cleanup] eventId=${huntEventId ?? ''} '
        'mediaId=$mediaId removedLinkIds=${removedLinkIds.toList()} '
        'remainingReferences=$remainingReferenceCount '
        'createdByHuntEventId=${asset?.createdByHuntEventId} '
        'sessionId=${asset?.sessionId} path=$storedPath '
        'normalizedPath=$normalizedPath',
      );
    }
    if (remainingReferenceCount != 0) {
      _logRetain(mediaId, 'remaining_event_reference');
      return false;
    }
    if (asset == null) {
      _logRetain(mediaId, 'asset_not_found');
      return false;
    }
    if (asset.createdByHuntEventId == null ||
        asset.createdByHuntEventId!.isEmpty) {
      _logRetain(mediaId, 'no_hunt_event_provenance');
      return false;
    }
    if (asset.kind == DogMediaKind.profileImage) {
      _logRetain(mediaId, 'profile_media');
      return false;
    }
    if (asset.storagePath != null) {
      _logRetain(mediaId, 'cloud_backed');
      return false;
    }
    if (asset.syncStatus != DogMediaSyncStatus.localOnly) {
      _logRetain(mediaId, 'not_local_only');
      return false;
    }
    if (asset.sessionId == null || asset.sessionId!.isEmpty) {
      _logRetain(mediaId, 'session_not_found');
      return false;
    }
    if (normalizedPath == null || !normalizedPath.startsWith('media/')) {
      _logRetain(mediaId, 'unsafe_local_path');
      return false;
    }

    for (final candidate in _media.values) {
      if (candidate.mediaId == mediaId ||
          candidate.status != DogMediaStatus.active ||
          candidate.localPath == null) {
        continue;
      }
      final candidatePath =
          (await MediaStorage.normalizeMediaPaths([candidate.localPath!]))
              .single;
      if (candidatePath == normalizedPath) {
        _logRetain(mediaId, 'other_asset_reference');
        return false;
      }
    }

    final matchingSessions = <MapEntry<dynamic, HuntSession>>[];
    var sessionFound = false;
    for (final entry in _sessions.toMap().entries) {
      final session = entry.value;
      if (session.sessionId != asset.sessionId &&
          entry.key.toString() != asset.sessionId) {
        continue;
      }
      sessionFound = true;
      final normalizedSessionPaths =
          await MediaStorage.normalizeMediaPaths(session.mediaPaths);
      if (normalizedSessionPaths.contains(normalizedPath)) {
        matchingSessions.add(entry);
      }
    }
    if (!sessionFound) {
      _logRetain(mediaId, 'session_not_found');
      return false;
    }
    if (matchingSessions.isEmpty) {
      _logRetain(mediaId, 'session_path_not_found');
      return false;
    }
    for (final entry in matchingSessions) {
      final before = entry.value.mediaPaths;
      final normalizedBefore = await MediaStorage.normalizeMediaPaths(before);
      final after = <String>[
        for (var index = 0; index < before.length; index++)
          if (normalizedBefore[index] != normalizedPath) before[index],
      ];
      await _sessions.put(
        entry.key,
        entry.value.copyWith(mediaPaths: after),
      );
      final persistedAfter = _sessions.get(entry.key)?.mediaPaths;
      if (kDebugMode) {
        debugPrint(
          '[HUNT_EVENT_MEDIA][cleanup-session] mediaId=$mediaId '
          'sessionId=${entry.value.sessionId} hiveKey=${entry.key} '
          'mediaPathsBefore=$before mediaPathsAfter=$persistedAfter',
        );
      }
    }

    await _media.delete(mediaId);

    var pathStillReferencedBySession = false;
    for (final session in _sessions.values) {
      final paths = await MediaStorage.normalizeMediaPaths(session.mediaPaths);
      if (paths.contains(normalizedPath)) {
        pathStillReferencedBySession = true;
        break;
      }
    }
    var pathStillReferencedByAsset = false;
    for (final candidate in _media.values) {
      if (candidate.status != DogMediaStatus.active ||
          candidate.localPath == null) {
        continue;
      }
      final candidatePath =
          (await MediaStorage.normalizeMediaPaths([candidate.localPath!]))
              .single;
      if (candidatePath == normalizedPath) {
        pathStillReferencedByAsset = true;
        break;
      }
    }
    var fileRemoved = false;
    if (!pathStillReferencedBySession && !pathStillReferencedByAsset) {
      await MediaStorage.deletePersistedMedia(normalizedPath);
      final validation = await MediaStorage.validatePersistedMedia(
        normalizedPath,
      );
      fileRemoved = validation?.exists != true;
    }
    if (kDebugMode) {
      debugPrint(
        '[HUNT_EVENT_MEDIA][cleanup-result] eventId=${huntEventId ?? ''} '
        'mediaId=$mediaId assetRemoved=${_media.get(mediaId) == null} '
        'fileRemoved=$fileRemoved decision=delete',
      );
    }
    return true;
  }

  void _logRetain(String mediaId, String reason) {
    if (kDebugMode) {
      debugPrint(
        '[HUNT_EVENT_MEDIA][cleanup-result] mediaId=$mediaId '
        'decision=retain retain_reason=$reason',
      );
    }
  }

  Future<void> deleteLinksForEvent(String huntEventId) async {
    final keys = _links
        .toMap()
        .entries
        .where((entry) => entry.value.huntEventId == huntEventId)
        .map((entry) => entry.key)
        .toList(growable: false);
    await _links.deleteAll(keys);
  }
}
