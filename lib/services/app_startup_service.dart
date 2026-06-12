import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../data/hive_boxes.dart';
import '../data/hive_path_service.dart';
import '../domain/domain_bootstrap.dart';
import '../domain/settings/settings_repository.dart';
import '../services/cloud/auto_sync_coordinator.dart';
import '../services/cloud/firestore_dog_sync_service.dart';
import '../services/dog_photo_storage.dart';
import '../services/hive_lifecycle_service.dart';
import '../services/media_storage.dart';
import '../services/notification_service.dart';
import '../ui/locale/locale_controller.dart';

class AppStartupService {
  AppStartupService._();

  static Future<LocaleController>? _initialization;
  static const Duration _timeout = Duration(seconds: 25);

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
    await NotificationService.instance.init();

    await _initTileCaching();

    registerDomainAdapters();

    await HiveLifecycleService.init();

    await runDomainBootstrapTasks();
    await _ensureFirebaseSignedIn();
    try {
      debugPrint('[CLOUD][DOG] fetch hook reached');
      await FirestoreDogSyncService.instance.fetchAccessibleDogs();
      debugPrint('[CLOUD][DOG] fetch hook completed');
    } catch (_) {
      // Best-effort: ignore cloud fetch failures so startup can proceed.
    }

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
    await AutoSyncCoordinator.instance.runOnStartup();
    return localeController;
  }

  static Future<void> _ensureFirebaseSignedIn() async {
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      await _ensureUserDocument(currentUser.uid);
      return;
    }

    final cred = await auth.signInAnonymously();
    final uid = cred.user?.uid;
    if (uid != null) {
      await _ensureUserDocument(uid);
    }
  }

  static Future<void> _ensureUserDocument(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      }, SetOptions(merge: true));

      debugPrint('[FIRESTORE] wrote users/$uid');
    } catch (e, st) {
      debugPrint('[FIRESTORE] write failed: $e');
      debugPrint(st.toString());
      rethrow;
    }
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
