// ignore_for_file: use_super_parameters

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/hive_boxes.dart';
import '../../data/hive_path_service.dart';
import '../../domain/restore/restore_guard.dart';
import '../../services/hive_lifecycle_service.dart';
import 'restore_state.dart';

class BackupRestoreService {
  const BackupRestoreService();

  static final ValueNotifier<bool> isRestoring = ValueNotifier<bool>(false);

  Future<BackupRestoreResult> restoreFromZip({
    required List<String> expectedBoxNames,
  }) async {
    debugPrint(
        '[RESTORE][SIGNATURE] backup_restore_service.dart v2 LOGGING ENABLED');
    debugPrint('[RESTORE][CONFIG] expectedBoxes=$expectedBoxNames');

    RestoreState.start('restoreFromZip');
    isRestoring.value = true;
    try {
      await HiveLifecycleService.closeAll(reason: 'restoreFromZip');

      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        withData: false,
      );
      if (picked == null || picked.files.isEmpty) {
        debugPrint('[RESTORE] no file picked');
        return const BackupRestoreResult.cancelled();
      }

      final originalPath = picked.files.single.path;
      if (originalPath == null) {
        debugPrint('[RESTORE] picked file has no path');
        return const BackupRestoreResult.failed('Valgt ZIP mangler sti.');
      }

      final pickedFile = File(originalPath);
      final pickedExists = pickedFile.existsSync();
      final pickedBytes = pickedExists ? pickedFile.lengthSync() : -1;
      debugPrint('[RESTORE][START] pickedZipPath=$originalPath');
      debugPrint(
          '[RESTORE][VALIDATION] pickedZipBytes=$pickedBytes pickedZipExists=$pickedExists');

      if (!pickedExists || pickedBytes <= 0 || pickedBytes < 50 * 1024) {
        return const BackupRestoreResult.failed(
          'Backup-filen er for liten eller ikke tilgjengelig.',
        );
      }

      final copiedZip = await _copyZipToAppTemp(originalPath);
      final copiedExists = copiedZip.existsSync();
      final copiedBytes = copiedExists ? copiedZip.lengthSync() : -1;
      debugPrint(
        '[RESTORE][COPY_ZIP] source=$originalPath dest=${copiedZip.path} exists=$copiedExists size=$copiedBytes',
      );

      if (!copiedExists || copiedBytes <= 0) {
        return const BackupRestoreResult.failed(
          'Kunne ikke kopiere ZIP til app-mappe.',
        );
      }

      final extractDir = await _extractZip(copiedZip);
      final extractFiles = _listFilesRecursive(extractDir);
      _logExtractedFiles(extractDir, extractFiles);
      _logInventory('[RESTORE][INVENTORY][EXTRACTED]', extractDir);

      final restoredPhotos = await _restorePhotoFiles(extractDir);
      debugPrint('[RESTORE] restored photo files=$restoredPhotos');

      final hiveFiles = _collectHiveFiles(extractFiles);
      if (hiveFiles.isEmpty) {
        debugPrint(
            '[RESTORE][WARNING] No Hive files found in extracted backup');
        return const BackupRestoreResult.failed(
            'Backup inneholder ingen Hive-filer.');
      }

      final hiveDir = await HivePathService.init();
      hiveDir.createSync(recursive: true);
      final copiedCount = await _copyHiveFilesToTarget(hiveDir, hiveFiles);
      _logInventory('[RESTORE][TARGET after]', hiveDir);

      await HiveLifecycleService.init();
      final settingsBox =
          HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
      await settingsBox.put('pendingRestartAfterRestore', true);
      debugPrint('[RESTORE] flagged pendingRestartAfterRestore=true');
      isRestoring.value = false;

      debugPrint('[RESTORE] restore complete - restart app to apply changes');

      // Signaliser restart til UI (BootWrapper håndterer dette kontrollert)
      RestoreGuard.requestRestart(reason: 'restoreFromZip complete');

      return BackupRestoreResult.success(
        restoredBoxFiles: copiedCount,
        restoredMediaFiles: restoredPhotos,
        extractedTo: extractDir.path,
        requiresRestart: true,
      );
    } catch (error, stack) {
      debugPrint('[RESTORE][ERROR] $error');
      debugPrint(stack.toString());
      return BackupRestoreResult.failed(error.toString());
    } finally {
      if (isRestoring.value) {
        isRestoring.value = false;
      }
      RestoreState.stop('restoreFromZip');
    }
  }
}

Future<File> _copyZipToAppTemp(String pickedPath) async {
  final appSupport = await getApplicationSupportDirectory();
  final incoming = Directory(p.join(appSupport.path, 'restore_incoming'));
  incoming.createSync(recursive: true);
  final destination = File(
    p.join(incoming.path,
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(pickedPath)}'),
  );
  return await File(pickedPath).copy(destination.path);
}

Future<Directory> _extractZip(File zipFile) async {
  final appSupport = await getApplicationSupportDirectory();
  final extractBase = Directory(p.join(appSupport.path, 'restore_extract'));
  final extractDir = Directory(
    p.join(extractBase.path, DateTime.now().millisecondsSinceEpoch.toString()),
  );
  extractDir.createSync(recursive: true);

  final bytes = await zipFile.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final entry in archive) {
    final outPath = p.join(extractDir.path, entry.name);
    if (entry.isFile) {
      final outFile = File(outPath);
      outFile.parent.createSync(recursive: true);
      await outFile.writeAsBytes(entry.content as List<int>, flush: true);
    } else {
      Directory(outPath).createSync(recursive: true);
    }
  }

  return extractDir;
}

const _hiveExtensions = ['.hive', '.lock', '.hive-wal', '.hive-shm'];

List<File> _collectHiveFiles(List<File> files) {
  return files.where((file) {
    final name = file.path.toLowerCase();
    return _hiveExtensions.any(name.endsWith);
  }).toList();
}

List<File> _listFilesRecursive(Directory base) {
  if (!base.existsSync()) return const [];
  return base.listSync(recursive: true).whereType<File>().toList();
}

void _logExtractedFiles(Directory dir, List<File> files) {
  debugPrint('[RESTORE][EXTRACT] dir=${dir.path}');
  if (files.isEmpty) {
    debugPrint('[RESTORE][EXTRACT] no files extracted');
    return;
  }
  for (final file in files) {
    final bytes = file.lengthSync();
    debugPrint('[RESTORE][EXTRACT] ${file.path} | bytes=$bytes');
  }
}

void _logInventory(String label, Directory base) {
  final files = _listFilesRecursive(base);
  debugPrint('$label dir=${base.path} contains ${files.length} files');
  for (final file in files) {
    final bytes = file.lengthSync();
    debugPrint('$label file=${p.basename(file.path)} bytes=$bytes');
  }
}

Future<int> _copyHiveFilesToTarget(Directory hiveDir, List<File> files) async {
  var counter = 0;
  for (final src in files) {
    final dest = File(p.join(hiveDir.path, p.basename(src.path)));
    final existsBefore = dest.existsSync();
    debugPrint(
        '[RESTORE][COPY_TO_HIVE] src=${src.path} target=${dest.path} existsBefore=$existsBefore');
    if (existsBefore) {
      dest.deleteSync();
    }
    final copied = await src.copy(dest.path);
    final existsAfter = copied.existsSync();
    final bytes = copied.lengthSync();
    debugPrint(
        '[RESTORE][COPY_TO_HIVE] after exists=$existsAfter bytes=$bytes');
    if (!existsAfter || bytes <= 0) {
      throw StateError('Kunne ikke kopiere ${src.path}.');
    }
    counter++;
  }
  return counter;
}

Future<int> _restorePhotoFiles(Directory extractDir) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final destDir = Directory(p.join(docsDir.path, 'dogs', 'photos'));
  destDir.createSync(recursive: true);
  int counter = 0;

  for (final file in _listFilesRecursive(extractDir)) {
    final relative = p.relative(file.path, from: extractDir.path);
    if (!relative.startsWith('photos${p.separator}') &&
        !relative.startsWith('photos/')) {
      continue;
    }
    final dest = File(p.join(destDir.path, p.basename(file.path)));
    await file.copy(dest.path);
    counter++;
  }

  return counter;
}

class BackupRestoreResult {
  final bool ok;
  final bool cancelled;
  final String? errorMessage;
  final int restoredBoxFiles;
  final int restoredMediaFiles;
  final String? extractedTo;
  final bool requiresRestart;

  const BackupRestoreResult._({
    required this.ok,
    required this.cancelled,
    this.errorMessage,
    this.restoredBoxFiles = 0,
    this.restoredMediaFiles = 0,
    this.extractedTo,
    this.requiresRestart = false,
  });

  const BackupRestoreResult.cancelled() : this._(ok: false, cancelled: true);

  const factory BackupRestoreResult.failed(String message) = _BackupFailed;

  const factory BackupRestoreResult.success({
    required int restoredBoxFiles,
    required int restoredMediaFiles,
    required String extractedTo,
    required bool requiresRestart,
  }) = _BackupSuccess;
}

class _BackupFailed extends BackupRestoreResult {
  const _BackupFailed(String message)
      : super._(
          ok: false,
          cancelled: false,
          errorMessage: message,
        );
}

class _BackupSuccess extends BackupRestoreResult {
  const _BackupSuccess({
    required int restoredBoxFiles,
    required int restoredMediaFiles,
    required String extractedTo,
    required bool requiresRestart,
  }) : super._(
          ok: true,
          cancelled: false,
          restoredBoxFiles: restoredBoxFiles,
          restoredMediaFiles: restoredMediaFiles,
          extractedTo: extractedTo,
          requiresRestart: requiresRestart,
        );
}
