import 'dart:io';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaStorage {
  MediaStorage._();

  static final _random = math.Random();
  static String? _documentsDir;

  static Future<void> ensureDocumentDirectoryReady() async {
    await _ensureDocumentsDirectory();
  }

  static Future<String> persistPickedMedia({
    required String dogId,
    required String sessionId,
    required String sourcePath,
    String? hiveKey,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Media source file not found', sourcePath);
    }

    final docsDir = await _ensureDocumentsDirectory();
    final fileName = _generateFileName(sourceFile.path);
    final relativeSegments = [
      'media',
      'dogs',
      dogId,
      'sessions',
      sessionId,
      fileName,
    ];
    final relativePath = p.posix.joinAll(relativeSegments);
    final targetPath = p.joinAll([docsDir.path, ...relativeSegments]);
    final targetFile = File(targetPath);

    final existsBefore = await targetFile.exists();
    if (existsBefore) {
      final bytes = await targetFile.length();
      _logPersist(relativePath, targetPath, sessionId, hiveKey, bytes, true);
      return relativePath;
    }

    await targetFile.create(recursive: true);
    await sourceFile.copy(targetPath);
    final exists = await targetFile.exists();
    final bytes = exists ? await targetFile.length() : 0;
    _logPersist(relativePath, targetPath, sessionId, hiveKey, bytes, exists);

    return relativePath;
  }

  static Future<List<String>> normalizeMediaPaths(List<String> storedPaths) async {
    final docsDir = await _ensureDocumentsDirectory();
    final normalized = <String>[];
    for (final stored in storedPaths) {
      final sanitized = _sanitizeStoredPath(stored);
      if (sanitized.isEmpty) {
        normalized.add(sanitized);
        continue;
      }
      if (sanitized.startsWith('media/')) {
        normalized.add(sanitized);
        continue;
      }
      if (p.isAbsolute(sanitized)) {
        final relative =
            _relativeFromDocuments(sanitized, docsDir.path);
        if (relative != null) {
          normalized.add(relative);
          continue;
        }
      }
      normalized.add(sanitized);
    }
    return normalized;
  }

  static Future<void> deletePersistedMedia(String path) async {
    final resolved = await resolveMediaPath(path);
    if (resolved == null) return;
    if (!resolved.contains(p.join('media', 'dogs'))) return;
    final file = File(resolved);
    if (!await file.exists()) {
      if (kDebugMode) {
        debugPrint('[MEDIA] deleted file: $resolved (not found)');
      }
      return;
    }

    try {
      await file.delete();
      if (kDebugMode) {
        debugPrint('[MEDIA] deleted file: $resolved');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[MEDIA] deleted file failed: $resolved ($error)');
      }
    }
  }

  static Future<void> _logPersist(
    String relativePath,
    String absolutePath,
    String sessionId,
    String? hiveKey,
    int bytes,
    bool exists,
  ) async {
    if (!kDebugMode) return;
    debugPrint(
      '[MEDIA] persisted relative=$relativePath absolute=$absolutePath sessionIdUsed=$sessionId hiveKey=${hiveKey ?? ''} exists=$exists size=$bytes',
    );
  }

  static Future<Directory> _ensureDocumentsDirectory() async {
    if (_documentsDir != null) {
      return Directory(_documentsDir!);
    }
    final directory = await getApplicationDocumentsDirectory();
    _documentsDir = directory.path;
    return directory;
  }

  static Future<String?> resolveMediaPath(String storedPath) async {
    final sanitized = _sanitizeStoredPath(storedPath);
    if (sanitized.isEmpty) return null;
    final docsDir = await _ensureDocumentsDirectory();
    if (sanitized.startsWith('media/')) {
      return _absoluteFromRelativePath(sanitized, docsDir.path);
    }
    if (p.isAbsolute(sanitized)) {
      final relative = _relativeFromDocuments(sanitized, docsDir.path);
      if (relative != null) {
        return _absoluteFromRelativePath(relative, docsDir.path);
      }
      return sanitized;
    }
    return _absoluteFromRelativePath(sanitized, docsDir.path);
  }

  static Future<MediaStorageValidation?> validatePersistedMedia(
    String storedPath,
  ) async {
    final resolved = await resolveMediaPath(storedPath);
    if (resolved == null) return null;
    final file = File(resolved);
    final exists = await file.exists();
    final length = exists ? await file.length() : 0;
    return MediaStorageValidation(
      resolvedPath: resolved,
      exists: exists,
      length: length,
    );
  }

  static MediaStorageValidation? resolveAndValidateMedia(String storedPath) {
    final resolved = _resolveMediaPathSync(storedPath);
    if (resolved == null) return null;
    final file = File(resolved);
    final exists = file.existsSync();
    final length = exists ? file.lengthSync() : 0;
    if (kDebugMode) {
      debugPrint(
        '[MEDIA] resolve stored=$storedPath resolved=$resolved exists=$exists size=$length',
      );
    }
    return MediaStorageValidation(
      resolvedPath: resolved,
      exists: exists,
      length: length,
    );
  }

  static String _generateFileName(String sourcePath) {
    final extension = p.extension(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSegment = _random.nextInt(100000);
    return '${timestamp}_$randomSegment$extension';
  }

  static String _sanitizeStoredPath(String storedPath) {
    return storedPath.trim().replaceAll('\\', '/');
  }

  static String? _relativeFromDocuments(String absolutePath, String docsPath) {
    final normalizedAbs = p.normalize(absolutePath);
    final normalizedDocs = p.normalize(docsPath);
    if (!normalizedAbs.startsWith('$normalizedDocs${p.separator}')) {
      return null;
    }
    final relative = p.relative(normalizedAbs, from: normalizedDocs);
    if (relative.startsWith('..')) return null;
    return relative.replaceAll('\\', '/');
  }

  static String _absoluteFromRelativePath(String relativePath, String docsPath) {
    final segments =
        relativePath.split('/').where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return docsPath;
    return p.joinAll([docsPath, ...segments]);
  }

  static String? extractSessionIdFromPath(String storedPath) {
    final sanitized = _sanitizeStoredPath(storedPath);
    final segments =
        sanitized.split('/').where((segment) => segment.isNotEmpty).toList();
    final index = segments.indexWhere((segment) => segment == 'sessions');
    if (index != -1 && index + 1 < segments.length) {
      return segments[index + 1];
    }
    return null;
  }

  static String? sessionIdFromPaths(List<String>? storedPaths) {
    if (storedPaths == null) return null;
    for (final stored in storedPaths) {
      final sessionId = extractSessionIdFromPath(stored);
      if (sessionId != null && sessionId.isNotEmpty) {
        return sessionId;
      }
    }
    return null;
  }

  static String? _resolveMediaPathSync(String storedPath) {
    if (_documentsDir == null) return null;
    final sanitized = _sanitizeStoredPath(storedPath);
    if (sanitized.isEmpty) return null;
    if (sanitized.startsWith('media/')) {
      return _absoluteFromRelativePath(sanitized, _documentsDir!);
    }
    if (p.isAbsolute(sanitized)) {
      final relative = _relativeFromDocuments(sanitized, _documentsDir!);
      if (relative != null) {
        return _absoluteFromRelativePath(relative, _documentsDir!);
      }
      return sanitized;
    }
    return _absoluteFromRelativePath(sanitized, _documentsDir!);
  }
}

class MediaStorageValidation {
  MediaStorageValidation({
    required this.resolvedPath,
    required this.exists,
    required this.length,
  });

  final String resolvedPath;
  final bool exists;
  final int length;
}
