// File: lib/remote/dto/services/dog_save_and_sync_service.dart
//
// Offline-first:
// 1) Save dog to Hive (your existing code should do this)
// 2) Then sync to Firestore (best effort)
//
// This service is intentionally tiny and non-invasive.
// You call it instead of calling Hive save directly in UI.

import 'package:jakthund_app/remote/services/dog_sync_service.dart';

class DogSaveAndSyncService {
  DogSaveAndSyncService._();

  /// Save locally first (caller provides the local save function),
  /// then sync to Firestore.
  ///
  /// Why this shape?
  /// - We avoid guessing your Hive box / repository APIs.
  /// - You keep your existing save logic untouched, just wrap it.
  ///
  /// Usage:
  /// await DogSaveAndSyncService.saveAndSync(
  ///   dog: dog,
  ///   saveLocal: () async { await dogsBox.put(dog.id, dog); },
  /// );
  static Future<void> saveAndSync({
    required dynamic dog,
    required Future<void> Function() saveLocal,
  }) async {
    // 1) Always persist locally first (offline-first)
    await saveLocal();

    // 2) Best-effort sync (never break local save)
    try {
      await DogSyncService.syncDog(dog: dog);
    } catch (_) {
      // Intentionally swallow for now.
      // Later we add a retry queue + status indicator in UI.
    }
  }
}
