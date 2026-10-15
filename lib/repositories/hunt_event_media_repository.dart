import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import '../models/dog_media_asset.dart';
import '../models/hunt_event_media_link.dart';

class HuntEventMediaRepository {
  HuntEventMediaRepository({
    Box<HuntEventMediaLink>? linkBox,
    Box<DogMediaAsset>? mediaBox,
  })  : _linkBox = linkBox,
        _mediaBox = mediaBox;

  final Box<HuntEventMediaLink>? _linkBox;
  final Box<DogMediaAsset>? _mediaBox;

  Box<HuntEventMediaLink> get _links => _linkBox ?? huntEventMediaLinksBox();
  Box<DogMediaAsset> get _media => _mediaBox ?? dogMediaAssetsBox();

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
