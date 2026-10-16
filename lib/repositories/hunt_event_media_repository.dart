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
    final removedLinkIds = existingByMediaId.values
        .where((link) => !retainedMediaIds.contains(link.mediaId))
        .map((link) => link.id)
        .toList(growable: false);
    await _links.deleteAll(removedLinkIds);

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
  Future<bool> deleteEventCreatedMediaIfUnreferenced(String mediaId) async {
    if (isReferenced(mediaId)) return false;
    final asset = _media.get(mediaId);
    final path = asset?.localPath;
    final safeLocalAsset = asset != null &&
        asset.createdByHuntEventId != null &&
        asset.createdByHuntEventId!.isNotEmpty &&
        asset.sessionId != null &&
        asset.kind != DogMediaKind.profileImage &&
        asset.syncStatus == DogMediaSyncStatus.localOnly &&
        asset.storagePath == null &&
        path != null &&
        path.startsWith('media/');
    if (!safeLocalAsset) return false;

    final matchingSessions = _sessions.toMap().entries.where((entry) {
      final session = entry.value;
      return (session.sessionId == asset.sessionId ||
              entry.key.toString() == asset.sessionId) &&
          session.mediaPaths.contains(path);
    }).toList(growable: false);
    for (final entry in matchingSessions) {
      await _sessions.put(
        entry.key,
        entry.value.copyWith(
          mediaPaths: entry.value.mediaPaths
              .where((candidate) => candidate != path)
              .toList(growable: false),
        ),
      );
    }

    await _media.delete(mediaId);

    final pathStillReferencedBySession =
        _sessions.values.any((session) => session.mediaPaths.contains(path));
    final pathStillReferencedByAsset = _media.values.any(
      (candidate) =>
          candidate.status == DogMediaStatus.active &&
          candidate.localPath == path,
    );
    if (!pathStillReferencedBySession && !pathStillReferencedByAsset) {
      await MediaStorage.deletePersistedMedia(path);
    }
    return true;
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
