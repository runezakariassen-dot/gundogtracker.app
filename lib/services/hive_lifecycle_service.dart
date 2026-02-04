import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import '../data/hive_boxes.dart';
import '../data/hive_path_service.dart';
import '../domain/models/active_session_draft.dart';
import '../models/dog.dart';
import '../models/dog_milestone_state.dart';
import '../models/dog_membership.dart';
import '../models/gps_track.dart';
import '../models/hunt_session.dart';
import '../models/map_settings.dart';
import '../models/ownership_transfer.dart';
import '../models/outbox_entry.dart';
import '../models/share_invitation.dart';
import '../models/sync_state.dart';
import '../models/sync_task.dart';
import '../models/track.dart';

class HiveLifecycleService {
  HiveLifecycleService._();

  static bool _ready = false;
  static bool get isReady => _ready;

  static final Duration _initTimeout = const Duration(seconds: 20);
  static final Duration _boxTimeout = const Duration(seconds: 5);

  static Directory? _hiveDir;

  // Standard subdir for app-lagring (brukes når overridePath ikke er satt)
  static const String _defaultSubdirName = 'jakthund_hive';

  static final List<_BoxDescriptor<dynamic>> _boxDescriptors = [
    _BoxDescriptor<Dog>(
      name: dogsBoxName,
      open: (attempts) => _openBoxOnce<Dog>(dogsBoxName, attempts),
    ),
    _BoxDescriptor<HuntSession>(
      name: sessionsBoxName,
      open: (attempts) => _openBoxOnce<HuntSession>(sessionsBoxName, attempts),
    ),
    _BoxDescriptor<Track>(
      name: tracksBoxName,
      open: (attempts) => _openBoxOnce<Track>(tracksBoxName, attempts),
    ),
    _BoxDescriptor<GpsTrack>(
      name: gpsTracksBoxName,
      open: (attempts) => _openBoxOnce<GpsTrack>(gpsTracksBoxName, attempts),
    ),
    _BoxDescriptor<MapSettings>(
      name: mapSettingsBoxName,
      open: (attempts) =>
          _openBoxOnce<MapSettings>(mapSettingsBoxName, attempts),
    ),
    _BoxDescriptor<String>(
      name: birdSpeciesBoxName,
      open: (attempts) => _openBoxOnce<String>(birdSpeciesBoxName, attempts),
    ),
    _BoxDescriptor<dynamic>(
      name: breedCatalogBoxName,
      open: (attempts) => _openBoxOnce<dynamic>(breedCatalogBoxName, attempts),
    ),
    _BoxDescriptor<dynamic>(
      name: appSettingsBoxName,
      open: (attempts) => _openBoxOnce<dynamic>(appSettingsBoxName, attempts),
    ),
    _BoxDescriptor<DogMembership>(
      name: dogMembershipsBoxName,
      open: (attempts) =>
          _openBoxOnce<DogMembership>(dogMembershipsBoxName, attempts),
    ),
    _BoxDescriptor<ShareInvitation>(
      name: shareInvitesBoxName,
      open: (attempts) =>
          _openBoxOnce<ShareInvitation>(shareInvitesBoxName, attempts),
    ),
    _BoxDescriptor<OwnershipTransfer>(
      name: ownershipTransfersBoxName,
      open: (attempts) =>
          _openBoxOnce<OwnershipTransfer>(ownershipTransfersBoxName, attempts),
    ),
    _BoxDescriptor<SyncTask>(
      name: syncTasksBoxName,
      open: (attempts) => _openBoxOnce<SyncTask>(syncTasksBoxName, attempts),
    ),
    _BoxDescriptor<OutboxEntry>(
      name: syncOutboxBoxName,
      open: (attempts) =>
          _openBoxOnce<OutboxEntry>(syncOutboxBoxName, attempts),
    ),
    _BoxDescriptor<SyncState>(
      name: syncStateBoxName,
      open: (attempts) => _openBoxOnce<SyncState>(syncStateBoxName, attempts),
    ),
    _BoxDescriptor<DateTime>(
      name: milestoneSeenBoxName,
      open: (attempts) =>
          _openBoxOnce<DateTime>(milestoneSeenBoxName, attempts),
    ),
    _BoxDescriptor<DogMilestoneState>(
      name: dogMilestoneStateBoxName,
      open: (attempts) =>
          _openBoxOnce<DogMilestoneState>(dogMilestoneStateBoxName, attempts),
    ),
    _BoxDescriptor<ActiveSessionDraft>(
      name: activeSessionDraftBoxName,
      open: (attempts) =>
          _openBoxOnce<ActiveSessionDraft>(activeSessionDraftBoxName, attempts),
    ),
  ];

  static Future<void> init({String? overridePath}) async {
    // Viktig for tests: _ready kan være true selv om Hive er lukket (tearDown kaller Hive.close()).
    // Da må vi ikke returnere tidlig.
    if (_ready && _allBoxesOpen()) {
      return;
    }
    if (_ready && !_allBoxesOpen()) {
      debugPrint(
        '[HIVE_LIFECYCLE] init called but boxes are not open. Forcing re-init.',
      );
      _ready = false;
    }

    debugPrint('[HIVE_LIFECYCLE] init start');

    try {
      await _withTimeout(() => _initCore(overridePath), _initTimeout);
    } on TimeoutException {
      debugPrint(
          '[HIVE_LIFECYCLE][TIMEOUT] init exceeded ${_initTimeout.inSeconds}s');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[HIVE_LIFECYCLE][FAIL] init error: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    }

    _ready = true;
    debugPrint('[HIVE_LIFECYCLE] init done');
  }

  static bool _allBoxesOpen() {
    for (final d in _boxDescriptors) {
      if (!Hive.isBoxOpen(d.name)) return false;
    }
    return true;
  }

  static Future<void> _initCore(String? overridePath) async {
    final hiveDir = await _resolveHiveDir(overridePath);
    _hiveDir = hiveDir;

    // Init Hive i denne prosessen
    // (Hive.init kan kaste hvis allerede init, vi tåler det)
    try {
      Hive.init(hiveDir.path);
      debugPrint('[HIVE_LIFECYCLE] Hive.init("${hiveDir.path}")');
    } catch (error) {
      debugPrint(
          '[HIVE_LIFECYCLE] Hive.init skipped/failed (already init?): $error');
    }

    await _migrateLegacyBoxes();
    final reopenAttempts = <String, int>{};

    for (final descriptor in _boxDescriptors) {
      debugPrint('[HIVE_LIFECYCLE] opening ${descriptor.name}');
      await _openBox(descriptor, reopenAttempts);
      debugPrint('[HIVE_LIFECYCLE] opened ${descriptor.name}');
    }

    debugPrint('[HIVE_LIFECYCLE] all boxes opened');
  }

  static Future<Directory> _resolveHiveDir(String? overridePath) async {
    if (overridePath != null && overridePath.trim().isNotEmpty) {
      final trimmed = overridePath.trim();

      // Hvis overridePath ser ut som en "ekte path" (absolutt/relativ med / eller ~),
      // bruker vi den direkte.
      final looksLikePath = trimmed.contains('/') ||
          trimmed.startsWith('~') ||
          trimmed.contains(r'\');

      if (looksLikePath) {
        final expanded = trimmed.startsWith('~')
            ? p.join(Platform.environment['HOME'] ?? '', trimmed.substring(1))
            : trimmed;

        final dir = Directory(expanded);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        debugPrint('[HIVE_LIFECYCLE] using overridePath hiveDir="${dir.path}"');
        return dir;
      }

      // Ellers tolker vi overridePath som subdirName til HivePathService
      final dir = await HivePathService.init(subdirName: trimmed);
      debugPrint(
          '[HIVE_LIFECYCLE] using override subdirName="$trimmed" -> "${dir.path}"');
      return dir;
    }

    final dir = await HivePathService.init(subdirName: _defaultSubdirName);
    debugPrint('[HIVE_LIFECYCLE] HivePathService.init -> "${dir.path}"');
    return dir;
  }

  static Future<void> closeAll({String? reason}) async {
    final note = reason != null ? ' reason=$reason' : '';
    debugPrint('[HIVE][LIFECYCLE] closeAll called.$note');
    try {
      await Hive.close();
      _ready = false;
      debugPrint('[HIVE][LIFECYCLE] closed.$note');
    } catch (error, stack) {
      debugPrint('[HIVE][LIFECYCLE] close failed$error');
      debugPrint(stack.toString());
    }
  }

  static Future<void> reopenAll() async {
    _ready = false;
    await init();
  }

  static void resetForTesting() {
    _ready = false;
  }

  static Future<void> _openBox<T>(
    _BoxDescriptor<T> descriptor,
    Map<String, int> reopenAttempts,
  ) async {
    final recoveryKey = '${descriptor.name}#quarantine';

    debugPrint('[HIVE][OPEN] ${descriptor.name} start');

    try {
      await _withTimeout(() => descriptor.open(reopenAttempts), _boxTimeout);
      debugPrint('[HIVE][OPEN] ${descriptor.name} success');
      return;
    } on TimeoutException {
      debugPrint('[HIVE_LIFECYCLE][TIMEOUT] box=${descriptor.name}');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[HIVE_LIFECYCLE][FAIL] box=${descriptor.name} error=$error');
      debugPrint(stackTrace.toString());

      if (_shouldQuarantine(error)) {
        await _closeBoxIfOpen(descriptor.name);
        await _quarantineBoxFiles(descriptor.name);

        final recoveryAttempts = reopenAttempts[recoveryKey] ?? 0;
        if (recoveryAttempts >= 1) {
          debugPrint(
              '[HIVE_LIFECYCLE][SKIP] box=${descriptor.name} already recovered once');
          return;
        }

        reopenAttempts[recoveryKey] = recoveryAttempts + 1;

        try {
          await _withTimeout(
              () => descriptor.open(reopenAttempts), _boxTimeout);
          debugPrint('[HIVE_LIFECYCLE][RECOVERED] box=${descriptor.name}');
          return;
        } catch (retryError, retryStack) {
          debugPrint(
              '[HIVE_LIFECYCLE][SKIP] box=${descriptor.name} retry error=$retryError');
          debugPrint(retryStack.toString());
          return;
        }
      }

      rethrow;
    }
  }

  static Future<Box<T>> _openBoxOnce<T>(
    String name,
    Map<String, int> reopenAttempts,
  ) async {
    if (Hive.isBoxOpen(name)) {
      try {
        return Hive.box<T>(name);
      } catch (_) {
        // Fall through til mismatch-håndtering.
      }

      final existing = Hive.box(name);
      debugPrint(
        '[HIVE][OPEN][TYPE_MISMATCH] name=$name existing=${existing.runtimeType} expected=Box<$T>',
      );

      final attempts = reopenAttempts[name] ?? 0;
      if (attempts > 0) {
        debugPrint('[HIVE_LIFECYCLE][FAIL] $name reopen already attempted');
        throw StateError('Box $name has unexpected runtime type.');
      }
      reopenAttempts[name] = 1;

      try {
        await existing.close();
      } catch (error, stackTrace) {
        debugPrint('[HIVE][OPEN][TYPE_MISMATCH] failed closing $name: $error');
        debugPrint(stackTrace.toString());
      }
    }

    return Hive.openBox<T>(name);
  }

  static Box<T> getBox<T>(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw StateError('Hive box "$name" is not open yet.');
    }

    try {
      return Hive.box<T>(name);
    } catch (_) {
      final box = Hive.box(name);
      throw StateError(
        'Hive box "$name" is opened with unexpected type ${box.runtimeType}.',
      );
    }
  }

  static Future<T> _withTimeout<T>(
    Future<T> Function() action,
    Duration timeout,
  ) {
    return action().timeout(timeout);
  }

  static Future<void> _migrateLegacyBoxes() async {
    for (final descriptor in _boxDescriptors) {
      final name = descriptor.name;
      final lower = name.toLowerCase();
      if (name == lower) continue;

      final existsName = await Hive.boxExists(name);
      final existsLower = await Hive.boxExists(lower);
      if (existsName || !existsLower) continue;

      await _migrateBox(lower, name);
    }
  }

  static bool _isActiveSessionDraftBoxName(String name) {
    return name.toLowerCase() == activeSessionDraftBoxName;
  }

  static Future<Box<dynamic>> _openDynamicBoxForMigration(String name) async {
    // Hvis active_session_draft åpnes som dynamic her, kan Hive låse runtime-typen
    // og senere getBox<ActiveSessionDraft>() feiler i tester.
    if (_isActiveSessionDraftBoxName(name)) {
      await Hive.openBox<ActiveSessionDraft>(name);
      return Hive.box(name); // dynamic view
    }
    return Hive.openBox<dynamic>(name);
  }

  static Future<void> _migrateBox(String source, String target) async {
    debugPrint('[HIVE_MIGRATE] migrating $source -> $target');

    final sourceBox = await _openDynamicBoxForMigration(source);
    final targetBox = await _openDynamicBoxForMigration(target);

    var count = 0;
    for (final entry in sourceBox.toMap().entries) {
      await targetBox.put(entry.key, entry.value);
      count++;
    }

    await targetBox.flush();
    await sourceBox.close();
    await targetBox.close();

    try {
      await Hive.deleteBoxFromDisk(source);
    } catch (error, stackTrace) {
      debugPrint('[HIVE_MIGRATE] failed to delete $source: $error');
      debugPrint(stackTrace.toString());
    }

    debugPrint('[HIVE_MIGRATE] migrated $source -> $target count=$count');
  }

  static bool _shouldQuarantine(Object error) {
    final message = error.toString().toLowerCase();
    return error is HiveError || message.contains('unknown typeid');
  }

  static Future<void> _closeBoxIfOpen(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) return;

    try {
      await Hive.box(boxName).close();
      debugPrint('[HIVE][LIFECYCLE] closed box $boxName before quarantining');
    } catch (error, stackTrace) {
      debugPrint('[HIVE][LIFECYCLE] failed closing box $boxName: $error');
      debugPrint(stackTrace.toString());
    }
  }

  static Future<void> _quarantineBoxFiles(String boxName) async {
    final hiveDir = _hiveDir;
    if (hiveDir == null) {
      debugPrint(
          '[HIVE][QUARANTINE] hiveDir is null (init not completed), skipping');
      return;
    }

    debugPrint(
        '[HIVE][QUARANTINE] requested boxName=$boxName hiveDir=${hiveDir.path}');

    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-');
    final destDir = Directory(p.join(hiveDir.path, 'quarantine', timestamp));
    await destDir.create(recursive: true);

    for (final suffix in ['.hive', '.lock']) {
      final file = File(p.join(hiveDir.path, '$boxName$suffix'));
      if (!await file.exists()) {
        debugPrint('[HIVE][QUARANTINE] not found: ${file.path}');
        continue;
      }

      final destination = File(p.join(destDir.path, '$boxName$suffix'));
      try {
        final oldPath = file.path;
        await file.rename(destination.path);
        debugPrint('[HIVE][QUARANTINE] moved $oldPath -> ${destination.path}');
      } catch (error, stackTrace) {
        debugPrint('[HIVE][QUARANTINE] failed moving $boxName$suffix: $error');
        debugPrint(stackTrace.toString());
      }
    }
  }
}

class _BoxDescriptor<T> {
  const _BoxDescriptor({
    required this.name,
    required this.open,
  });

  final String name;
  final Future<Box<T>> Function(Map<String, int> reopenAttempts) open;
}
