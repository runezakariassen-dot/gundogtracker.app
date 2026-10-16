import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/hive_boxes.dart';
import '../models/dog_media_asset.dart';
import '../models/hunt_session.dart';
import '../services/media_storage.dart';

class SessionMediaRemovalResult {
  const SessionMediaRemovalResult({
    required this.sessionFound,
    required this.pathFound,
    required this.sessionKey,
    required this.pathsBefore,
    required this.pathsAfter,
    required this.assetExistsAfter,
    required this.fileExistsAfter,
  });

  final bool sessionFound;
  final bool pathFound;
  final dynamic sessionKey;
  final List<String> pathsBefore;
  final List<String> pathsAfter;
  final bool assetExistsAfter;
  final bool fileExistsAfter;
}

/// Canonical persisted removal for media owned by a hunt session.
class SessionMediaRepository {
  SessionMediaRepository({
    Box<HuntSession>? sessionBox,
    Box<DogMediaAsset>? mediaBox,
  })  : _sessionBox = sessionBox,
        _mediaBox = mediaBox;

  final Box<HuntSession>? _sessionBox;
  final Box<DogMediaAsset>? _mediaBox;

  Box<HuntSession> get _sessions => _sessionBox ?? sessionsBox();
  Box<DogMediaAsset> get _media => _mediaBox ?? dogMediaAssetsBox();

  Future<SessionMediaRemovalResult> removeSessionMedia({
    required String path,
    Object? sessionKey,
    String? sessionId,
    String? mediaId,
    bool deleteAsset = false,
  }) async {
    final normalizedTarget =
        (await MediaStorage.normalizeMediaPaths([path])).single;
    MapEntry<dynamic, HuntSession>? match;
    if (sessionKey != null) {
      final session = _sessions.get(sessionKey);
      if (session != null) match = MapEntry(sessionKey, session);
    }
    if (match == null && sessionId != null) {
      for (final entry in _sessions.toMap().entries) {
        if (entry.value.sessionId == sessionId ||
            entry.key.toString() == sessionId) {
          match = entry;
          break;
        }
      }
    }

    final before = match?.value.mediaPaths ?? const <String>[];
    var after = List<String>.from(before);
    var pathFound = false;
    if (match != null) {
      final normalizedBefore = await MediaStorage.normalizeMediaPaths(before);
      pathFound = normalizedBefore.contains(normalizedTarget);
      after = <String>[
        for (var index = 0; index < before.length; index++)
          if (normalizedBefore[index] != normalizedTarget) before[index],
      ];
      if (pathFound) {
        await _sessions.put(
          match.key,
          match.value.copyWith(mediaPaths: after),
        );
        after = List<String>.from(
          _sessions.get(match.key)?.mediaPaths ?? const <String>[],
        );
      }
    }

    var referencedByAnotherSession = false;
    for (final session in _sessions.values) {
      final paths = await MediaStorage.normalizeMediaPaths(session.mediaPaths);
      if (paths.contains(normalizedTarget)) {
        referencedByAnotherSession = true;
        break;
      }
    }
    var referencedByAnotherAsset = false;
    for (final candidate in _media.values) {
      if (candidate.mediaId == mediaId ||
          candidate.status != DogMediaStatus.active ||
          candidate.localPath == null) {
        continue;
      }
      final candidatePath =
          (await MediaStorage.normalizeMediaPaths([candidate.localPath!]))
              .single;
      if (candidatePath == normalizedTarget) {
        referencedByAnotherAsset = true;
        break;
      }
    }
    final safeToDelete =
        pathFound && !referencedByAnotherSession && !referencedByAnotherAsset;
    if (safeToDelete && deleteAsset && mediaId != null) {
      final asset = _media.get(mediaId);
      final safeAsset = asset != null &&
          asset.kind != DogMediaKind.profileImage &&
          asset.storagePath == null &&
          asset.syncStatus == DogMediaSyncStatus.localOnly;
      if (safeAsset) await _media.delete(mediaId);
    }
    if (safeToDelete && (!deleteAsset || _media.get(mediaId) == null)) {
      await MediaStorage.deletePersistedMedia(normalizedTarget);
    }
    final validation =
        await MediaStorage.validatePersistedMedia(normalizedTarget);
    final result = SessionMediaRemovalResult(
      sessionFound: match != null,
      pathFound: pathFound,
      sessionKey: match?.key,
      pathsBefore: List<String>.from(before),
      pathsAfter: after,
      assetExistsAfter: mediaId != null && _media.get(mediaId) != null,
      fileExistsAfter: validation?.exists == true,
    );
    if (kDebugMode) {
      debugPrint(
        '[SESSION_MEDIA][remove-result] sessionId=$sessionId '
        'sessionHiveKey=${result.sessionKey} mediaId=$mediaId '
        'sessionPathsBefore=${result.pathsBefore} '
        'targetNormalizedPath=$normalizedTarget '
        'sessionPathsAfter=${result.pathsAfter} '
        'assetExistsAfter=${result.assetExistsAfter} '
        'fileExistsAfter=${result.fileExistsAfter}',
      );
    }
    return result;
  }
}
