import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/dog_media_asset.dart';

class DogMediaCacheService {
  DogMediaCacheService({String? documentsPath})
      : _documentsPath = documentsPath;

  final String? _documentsPath;

  static const String rootDirectory = 'dog_media';

  Future<String> profileImagePath({
    required String dogCloudId,
    required String mediaId,
    String extension = '.jpg',
  }) {
    return absolutePathForRelative(
      profileImageRelativePath(
        dogCloudId: dogCloudId,
        mediaId: mediaId,
        extension: extension,
      ),
    );
  }

  String profileImageRelativePath({
    required String dogCloudId,
    required String mediaId,
    String extension = '.jpg',
  }) {
    return p.posix.join(
      rootDirectory,
      _sanitizeSegment(dogCloudId),
      'profile',
      '${_sanitizeSegment(mediaId)}${_normalizeExtension(extension)}',
    );
  }

  Future<String> sessionMediaPath({
    required String dogCloudId,
    required String sessionId,
    required String mediaId,
    required DogMediaKind kind,
    String? extension,
  }) {
    return absolutePathForRelative(
      sessionMediaRelativePath(
        dogCloudId: dogCloudId,
        sessionId: sessionId,
        mediaId: mediaId,
        kind: kind,
        extension: extension,
      ),
    );
  }

  String sessionMediaRelativePath({
    required String dogCloudId,
    required String sessionId,
    required String mediaId,
    required DogMediaKind kind,
    String? extension,
  }) {
    final normalizedExtension =
        _normalizeExtension(extension ?? _defaultExtension(kind));
    return p.posix.join(
      rootDirectory,
      _sanitizeSegment(dogCloudId),
      'sessions',
      _sanitizeSegment(sessionId),
      '${_sanitizeSegment(mediaId)}$normalizedExtension',
    );
  }

  Future<String> thumbnailPath({
    required String dogCloudId,
    required String mediaId,
    String? sessionId,
  }) {
    return absolutePathForRelative(
      thumbnailRelativePath(
        dogCloudId: dogCloudId,
        mediaId: mediaId,
        sessionId: sessionId,
      ),
    );
  }

  String thumbnailRelativePath({
    required String dogCloudId,
    required String mediaId,
    String? sessionId,
  }) {
    final normalizedSessionId = sessionId?.trim();
    if (normalizedSessionId == null || normalizedSessionId.isEmpty) {
      return p.posix.join(
        rootDirectory,
        _sanitizeSegment(dogCloudId),
        'profile',
        '${_sanitizeSegment(mediaId)}_thumb.jpg',
      );
    }
    return p.posix.join(
      rootDirectory,
      _sanitizeSegment(dogCloudId),
      'sessions',
      _sanitizeSegment(normalizedSessionId),
      '${_sanitizeSegment(mediaId)}_thumb.jpg',
    );
  }

  Future<String> absolutePathForRelative(String relativePath) async {
    final docsPath = await _resolveDocumentsPath();
    final segments = relativePath
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    return p.joinAll(<String>[docsPath, ...segments]);
  }

  Future<Directory> ensureParentDirectory(String absolutePath) async {
    final directory = Directory(p.dirname(absolutePath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> _resolveDocumentsPath() async {
    final documentsPath = _documentsPath;
    if (documentsPath != null && documentsPath.trim().isNotEmpty) {
      return documentsPath;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  String _defaultExtension(DogMediaKind kind) {
    return switch (kind) {
      DogMediaKind.profileImage => '.jpg',
      DogMediaKind.sessionImage => '.jpg',
      DogMediaKind.sessionVideo => '.mp4',
    };
  }

  String _normalizeExtension(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('.') ? trimmed : '.$trimmed';
  }

  String _sanitizeSegment(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return sanitized.isEmpty ? 'unknown' : sanitized;
  }
}
