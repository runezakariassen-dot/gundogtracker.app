import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/utils/json_encodable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupExportService {
  const BackupExportService();

  /// Eksporterer:
  /// - Raw Hive DB-filer (primært .hive + evt wal/shm) under mappen hive_db/
  /// - Valgfritt: JSON-snapshot av boksene under hive_json/
  /// - Media-filer under media/
  /// - manifest.json i root
  Future<File> exportAll({
    required List<Box> boxes,
    required List<String> filePaths,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile =
        File(p.join(backupDir.path, 'fuglehund_backup_$timestamp.zip'));

    final archive = Archive();

    // 0) Sørg for at HivePathService er init og bruk den faktiske hiveDirectory som source of truth.
    final hiveDir = await HivePathService.init();
    if (!hiveDir.existsSync()) {
      hiveDir.createSync(recursive: true);
    }

    // 0a) Flush alle bokser før vi kopierer filer fra disk
    for (final box in boxes) {
      try {
        await box.flush();
      } catch (e) {
        debugPrint('[BACKUP][WARN] flush failed for box=${box.name}: $e');
      }
    }

    // 1) Raw Hive DB files (det viktigste for restore!)
    final hiveDbFiles = _collectHiveDbFiles(hiveDir);

    if (hiveDbFiles.isEmpty) {
      throw StateError(
        'No Hive DB files (.hive/.hive-wal/.hive-shm) found in ${hiveDir.path}; backup aborted.',
      );
    }

    int totalHiveBytes = 0;
    bool hasHive = false;

    for (final file in hiveDbFiles) {
      final name = p.basename(file.path);
      final bytes = await file.readAsBytes();
      totalHiveBytes += bytes.length;
      if (name.toLowerCase().endsWith('.hive')) hasHive = true;

      debugPrint(
        '[BACKUP][HIVE_DB] include=$name bytes=${bytes.length} path=${file.path}',
      );

      archive.addFile(
        ArchiveFile(
          'hive_db/$name',
          bytes.length,
          bytes,
        ),
      );
    }

    if (!hasHive) {
      throw StateError(
        'Backup aborted: no .hive files found (only wal/shm?). hiveDir=${hiveDir.path}',
      );
    }

    // Ekstra sanity: hvis totalen er ekstremt lav, varsle (typisk symptom på feil mappe/feil data).
    if (totalHiveBytes < 8 * 1024) {
      debugPrint(
        '[BACKUP][WARN] Total hive bytes is very small ($totalHiveBytes). '
        'This usually indicates empty DB or wrong directory.',
      );
    }

    // 2) (Valgfritt) Hive boxes -> JSON snapshot (debug/forensics). Kan beholdes.
    for (final box in boxes) {
      final name = box.name;
      final content = <String, dynamic>{};

      try {
        for (final entry in box.toMap().entries) {
          final key = entry.key?.toString() ?? '';
          content[key] = _serializeValue(entry.value);
        }
      } catch (e) {
        debugPrint('[BACKUP][WARN] failed serializing box=$name: $e');
      }

      final jsonStr = jsonEncode(content);
      final jsonBytes = utf8.encode(jsonStr);

      archive.addFile(
        ArchiveFile(
          'hive_json/$name.json',
          jsonBytes.length,
          jsonBytes,
        ),
      );
    }

    // 3) Media files (dedup + exists) under media/
    final uniquePaths = <String>{...filePaths};
    int includedMedia = 0;

    final photosDir = Directory(p.join(docsDir.path, 'dogs', 'photos'));
    int includedPhotos = 0;
    if (photosDir.existsSync()) {
      final photoFiles = photosDir.listSync().whereType<File>();
      for (final file in photoFiles) {
        final fileName = p.basename(file.path);
        final bytes = await file.readAsBytes();
        archive.addFile(
          ArchiveFile(
            'photos/$fileName',
            bytes.length,
            bytes,
          ),
        );
        includedPhotos++;
      }
    }

    for (final path in uniquePaths) {
      try {
        final file = File(path);
        if (!file.existsSync()) continue;

        final bytes = await file.readAsBytes();
        final fileName = p.basename(path);

        archive.addFile(
          ArchiveFile(
            'media/$fileName',
            bytes.length,
            bytes,
          ),
        );

        includedMedia += 1;
      } catch (_) {
        // Skip unreadable files
      }
    }

    // 4) Manifest
    final info = await PackageInfo.fromPlatform();
    final manifest = {
      'app': 'Fuglehund',
      'version': info.version,
      'build': info.buildNumber,
      'createdAt': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'boxes': boxes.map((b) => b.name).toList(),
      'mediaFilesIncluded': includedMedia,
      'photoFilesIncluded': includedPhotos,
      'hiveDir': hiveDir.path,
      'hiveDbFiles': hiveDbFiles.map((f) => p.basename(f.path)).toList(),
      'totalHiveBytes': totalHiveBytes,
    };

    final manifestStr = jsonEncode(manifest);
    final manifestBytes = utf8.encode(manifestStr);

    archive.addFile(
      ArchiveFile(
        'manifest.json',
        manifestBytes.length,
        manifestBytes,
      ),
    );

    // 5) Write ZIP
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('Failed to write ZIP archive.');
    }

    await zipFile.writeAsBytes(zipBytes, flush: true);

    if (kDebugMode) {
      debugPrint(
          '[BACKUP] ZIP written: ${zipFile.path} bytes=${zipFile.lengthSync()}');
    }

    return zipFile;
  }
}

dynamic _serializeValue(Object? value) {
  if (value == null) return null;
  if (value is String || value is num || value is bool) return value;
  if (value is DateTime) return value.toIso8601String();
  if (value is Duration) return value.inMilliseconds;
  if (value is Uint8List) return base64Encode(value);
  if (value is List) {
    return value.map(_serializeValue).toList();
  }
  if (value is Map) {
    return value.map(
      (key, entry) => MapEntry(key?.toString() ?? '', _serializeValue(entry)),
    );
  }
  if (value is JsonEncodable) {
    final map = value.toJson();
    return map.map((key, entry) => MapEntry(key, _serializeValue(entry)));
  }
  try {
    final dynamicJson = (value as dynamic).toJson();
    return _serializeValue(dynamicJson);
  } catch (_) {
    // Fall through
  }
  return value.toString();
}

/// Vi tar med bare DB-filer som faktisk trengs for restore.
/// - .hive (hovedfil)
/// - .hive-wal / .hive-shm (kan forekomme)
///
/// Vi tar IKKE med .lock (unødvendig og ofte “smått” som kan maskere feil).
const _dbExtensions = ['.hive', '.hive-wal', '.hive-shm'];

List<File> _collectHiveDbFiles(Directory hiveDir) {
  if (!hiveDir.existsSync()) return const [];

  return hiveDir.listSync(recursive: true).whereType<File>().where((file) {
    final lowerPath = file.path.toLowerCase();

    // Ekskluder egne systemmapper
    if (lowerPath.contains('${p.separator}quarantine${p.separator}')) {
      return false;
    }
    if (lowerPath.contains('${p.separator}backups${p.separator}')) {
      return false;
    }

    final name = p.basename(lowerPath);
    return _dbExtensions.any((ext) => name.endsWith(ext));
  }).toList();
}
