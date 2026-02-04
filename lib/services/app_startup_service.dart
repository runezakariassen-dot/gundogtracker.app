// lib/services/app_startup_service.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../data/hive_boxes.dart';
import '../data/hive_path_service.dart';
import '../domain/domain_bootstrap.dart';
import '../domain/settings/settings_repository.dart';
import '../services/dog_photo_storage.dart';
import '../services/media_storage.dart';
import '../services/hive_lifecycle_service.dart';
import '../ui/locale/locale_controller.dart';

/// Starter opp "app core" på en kontrollert måte.
class AppStartupService {
  AppStartupService._();

  static Future<LocaleController>? _initialization;
  static const Duration _timeout = Duration(seconds: 25);

  /// Kall denne tidlig (f.eks. før `runApp`) for å sikre at Hive og locale er klare.
  ///
  /// `hiveSubdirName` kan brukes i tester for å separere data (valgfritt).
  static Future<LocaleController> ensureInitialized({String? hiveSubdirName}) {
    return _initialization ??=
        _initialize(hiveSubdirName: hiveSubdirName).timeout(_timeout);
  }

  static Future<LocaleController> _initialize({String? hiveSubdirName}) async {
    debugPrint('[BOOT] init start');

    final Directory hiveDir =
        await HivePathService.init(subdirName: hiveSubdirName);
    debugPrint('[BOOT] hive dir: ${hiveDir.path}');

    await DogPhotoStorage.ensureDocumentDirectory();
    await MediaStorage.ensureDocumentDirectoryReady();

    await _initTileCaching();

    registerDomainAdapters();

    await HiveLifecycleService.init();

    await runDomainBootstrapTasks();

    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    final pendingRestart =
        settingsBox.get('pendingRestartAfterRestore') == true;
    if (pendingRestart) {
      debugPrint('[RESTORE] restarted_after_restore=true');
      await settingsBox.put('pendingRestartAfterRestore', false);
    }

    final localeController = LocaleController(SettingsRepository(settingsBox));
    debugPrint('[BOOT] before localeController.init');
    await localeController.init();

    debugPrint('[BOOT] after localeController.init');
    debugPrint('[BOOT] init complete');
    return localeController;
  }

  static Future<void> _initTileCaching() async {
    try {
      await FMTCObjectBoxBackend().initialise();
    } on RootAlreadyInitialised {
      // Ignore: already running (e.g. hot restart or previous init).
    } catch (e, st) {
      debugPrint('[BOOT] Tile cache init error: $e');
      debugPrint(st.toString());
    }
  }
}
