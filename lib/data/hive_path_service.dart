import 'dart:io';

import 'package:path/path.dart' as p;

// Conditional import:
// - In Flutter (dart.library.ui == true) use path_provider.
// - In pure Dart VM tests use systemTemp.
import 'support_dir_resolver.dart'
    if (dart.library.ui) 'support_dir_resolver_flutter.dart';

class HivePathService {
  HivePathService._();

  static String? _overridePathForTesting;
  static String? _initializedPath;

  static void setOverridePathForTesting(String? path) {
    _overridePathForTesting = path;
    _log('[HIVE_PATH] overridePathForTesting=$path');
  }

  static String? get overridePathForTesting => _overridePathForTesting;

  static String? get initializedPath => _initializedPath;

  static Future<Directory> init({String? subdirName}) async {
    final subdir = subdirName ?? 'jakthund_hive';

    // 1) Test override: always preferred (no plugins, no flutter needed)
    final override = _overridePathForTesting;
    if (override != null && override.isNotEmpty) {
      final dir = Directory(p.join(override, subdir));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _initializedPath = dir.path;
      return dir;
    }

    // 2) Resolve app support directory (Flutter runtime) OR systemTemp (pure Dart)
    try {
      final baseDir = await resolveBaseSupportDir();
      final dir = Directory(p.join(baseDir.path, subdir));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _initializedPath = dir.path;
      return dir;
    } catch (e) {
      // Defensive fallback for any unexpected resolver issues.
      final dir =
          Directory(p.join(Directory.systemTemp.path, 'jakthund', subdir));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _initializedPath = dir.path;
      _log(
          '[HIVE_PATH] resolver failed ($e). Falling back to systemTemp: ${dir.path}');
      return dir;
    }
  }

  static Future<String> resolveHiveDirPath({String? subdirName}) async {
    // If a test override is active, always compute from it (may change per test).
    final override = _overridePathForTesting;
    if (override != null && override.isNotEmpty) {
      final dir = await init(subdirName: subdirName);
      return dir.path;
    }

    // Reuse cached initialization path in-process.
    if (_initializedPath != null && _initializedPath!.isNotEmpty) {
      _log(
          '[HIVE_PATH] init skipped (already initialized) path=$_initializedPath');
      return _initializedPath!;
    }

    final dir = await init(subdirName: subdirName);
    return dir.path;
  }

  static void resetForTesting() {
    _initializedPath = null;
    _overridePathForTesting = null;
    _log('[HIVE_PATH] resetForTesting');
  }

  static void _log(String message) {
    // Keep logging lightweight and pure-Dart (no flutter foundation).
    // Use environment flag to avoid spam in release-like runs.
    const isProduct = bool.fromEnvironment('dart.vm.product');
    if (!isProduct) {
      // ignore: avoid_print
      print(message);
    }
  }
}
