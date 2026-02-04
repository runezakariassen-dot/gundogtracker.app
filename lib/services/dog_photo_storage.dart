import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DogPhotoStorage {
  DogPhotoStorage._();

  static String? _documentsDir;

  static Future<String> _ensureDocumentsDir() async {
    if (_documentsDir != null) return _documentsDir!;
    final directory = await getApplicationDocumentsDirectory();
    _documentsDir = directory.path;
    return _documentsDir!;
  }

  static Future<void> ensureDocumentDirectory() async {
    await _ensureDocumentsDir();
  }

  static Future<String> saveDogPhoto({
    required String dogId,
    required String sourcePath,
  }) async {
    final dirPath = await _ensureDocumentsDir();
    final photosDir = Directory(p.join(dirPath, 'dogs', 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    const extension = '.jpg';
    final normalized = 'dog_$dogId$extension';
    final destination = p.join(photosDir.path, normalized);
    final destFile = File(destination);
    if (await destFile.exists()) {
      await destFile.delete();
    }
    await File(sourcePath).copy(destination);
    return p.relative(destination, from: dirPath);
  }

  static String? resolveAbsolutePath(String? storedPath) {
    if (storedPath == null || storedPath.isEmpty) return null;
    if (storedPath.startsWith('/')) return storedPath;
    if (_documentsDir == null) return null;
    return p.join(_documentsDir!, storedPath);
  }

  static File? imageFileFromPath(String? storedPath) {
    final absolute = resolveAbsolutePath(storedPath);
    if (absolute == null) return null;
    final file = File(absolute);
    return file.existsSync() ? file : null;
  }

  static Future<String?> migrateLegacyPath(String storedPath) async {
    final dirPath = await _ensureDocumentsDir();
    final normalized = storedPath.trim();
    if (normalized.startsWith('/')) {
      if (normalized.startsWith(dirPath)) {
        return p.relative(normalized, from: dirPath);
      }
      final file = File(normalized);
      if (file.existsSync()) {
        final photosDir = Directory(p.join(dirPath, 'dogs', 'photos'));
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }
        final destPath = p.join(photosDir.path, p.basename(normalized));
        await file.copy(destPath);
        return p.relative(destPath, from: dirPath);
      }
      final filename = p.basename(normalized);
      final candidate = File(p.join(dirPath, 'dogs', 'photos', filename));
      if (candidate.existsSync()) {
        return p.relative(candidate.path, from: dirPath);
      }
    }
    return null;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    final absolute = resolveAbsolutePath(path);
    if (absolute == null) return;
    final file = File(absolute);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // ignore
      }
    }
  }
}
