// ignore_for_file: deprecated_member_use_from_same_package
// lib/domain/domain_bootstrap.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/hive_boxes.dart';
import '../domain/repositories/dog_milestone_state_repository.dart';
import '../domain/milestones/milestone_id.dart';
import '../models/achieved_milestone.dart';
import '../models/dog.dart';
import '../models/dog_media_asset.dart';
import '../models/dog_milestone_state.dart';
import '../models/dog_membership.dart';
import '../models/dog_sex.dart';
import '../models/hunt_session.dart';
import '../models/outbox_entry.dart';
import '../models/ownership_transfer.dart';
import '../models/share_invitation.dart';
import '../models/sync_task.dart';
import '../models/sync_state.dart';
import '../models/track_adapter_v2.dart';
import '../models/session_type_adapter.dart';
import '../services/hive_lifecycle_service.dart';
import '../services/user_identity_service.dart';
import 'models/active_session_draft.dart';
import '../utils/reg_nr.dart';
import 'domain_constants.dart';
import 'dog_milestone_backfill_bootstrap.dart';
export 'dog_milestone_backfill_bootstrap.dart';

Future<void> initDomainLayer() async {
  registerDomainAdapters();
  if (!HiveLifecycleService.isReady) {
    await HiveLifecycleService.init();
  }
  await runDomainBootstrapTasks();
}

void registerDomainAdapters() {
  _registerAdapterIfNeeded(DogAdapter());
  _registerAdapterIfNeeded(DogMediaAssetAdapter());
  _registerAdapterIfNeeded(AchievedMilestoneAdapter());
  _registerAdapterIfNeeded(DogMilestoneStateAdapter());
  _registerAdapterIfNeeded(DogMembershipAdapter());
  _registerAdapterIfNeeded(DogSexAdapter());
  _registerAdapterIfNeeded(ActiveSessionDraftAdapter());
  _registerAdapterIfNeeded(HuntSessionAdapter());
  _registerAdapterIfNeeded(SessionTypeAdapter());
  _registerAdapterIfNeeded(ShareInvitationAdapter());
  _registerAdapterIfNeeded(OwnershipTransferAdapter());
  _registerAdapterIfNeeded(SyncTaskAdapter());
  _registerAdapterIfNeeded(OutboxEntryAdapter());
  _registerAdapterIfNeeded(RoleAdapter());
  _registerAdapterIfNeeded(StatusAdapter());
  _registerAdapterIfNeeded(SyncStatusAdapter());
  _registerAdapterIfNeeded(SyncStateAdapter());

  // ✅ Test forventer typeId=16, og du har den i track_adapter_v2.dart
  _registerAdapterIfNeeded(TrackAdapterV2());
}

bool _domainTasksCompleted = false;

/// Test-hook: gjør at tester kan kjøre initDomainLayer() flere ganger og få
/// bootstrap tasks kjørt på nytt.
@visibleForTesting
void resetDomainBootstrapForTesting() {
  _domainTasksCompleted = false;
}

Future<void> runDomainBootstrapTasks() async {
  if (_domainTasksCompleted) return;
  _domainTasksCompleted = true;
  await migrateDogMilestonesToStateIfNeeded();
  await ensureDogMilestonesBackfilled(
    dogs: dogsBox().values,
    settingsBox: Hive.box<dynamic>(appSettingsBoxName),
    stateRepository: DogMilestoneStateRepository(),
  );
  await _migrateDomainSchemaIfNeeded();
  await _backfillDogKeysIfNeeded();
  await _backfillDogKeyOwnershipIfNeeded();
}

void _registerAdapterIfNeeded<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

Future<void> migrateDogMilestonesToStateIfNeeded() async {
  final settingsBox = Hive.box<dynamic>(appSettingsBoxName);
  final migrated =
      settingsBox.get(dogMilestoneStateMigrationKey) as bool? ?? false;
  if (migrated) {
    return;
  }
  final repository = DogMilestoneStateRepository();
  for (final entry in dogsBox().toMap().entries) {
    final dog = entry.value;
    if (dog.achievedMilestones.isEmpty) {
      continue;
    }
    final state = await repository.getOrCreate(dog.id);
    if (state.achievedIds.isNotEmpty) {
      continue;
    }
    final normalized = <String>{};
    final achievedAt = <String, DateTime>{};
    for (final milestone in dog.achievedMilestones) {
      final id = _normalizeMilestoneId(milestone.id);
      if (id == null) {
        continue;
      }
      normalized.add(id);
      achievedAt[id] = milestone.achievedAt;
    }
    if (normalized.isEmpty) {
      continue;
    }
    await repository.save(
      state.copyWith(
        achievedIds: normalized.toList(growable: false),
        achievedAt: achievedAt,
      ),
    );
  }
  await settingsBox.put(dogMilestoneStateMigrationKey, true);
}

String? _normalizeMilestoneId(String id) {
  if (id == 'first_point') {
    return MilestoneId.stands1;
  }
  return id;
}

Future<void> _migrateDomainSchemaIfNeeded() async {
  final settingsBox = Hive.box<dynamic>(appSettingsBoxName);
  final version = _readSchemaVersion(settingsBox.get(domainSchemaVersionKey));
  if (version >= domainSchemaVersion) {
    return;
  }

  await shareInvitesBox().clear();
  await ownershipTransfersBox().clear();

  await settingsBox.put(domainSchemaVersionKey, domainSchemaVersion);
}

int _readSchemaVersion(dynamic raw) {
  if (raw is int) {
    return raw;
  }
  if (raw is String) {
    return int.tryParse(raw) ?? 0;
  }
  return 0;
}

Future<void> _backfillDogKeysIfNeeded() async {
  final box = dogsBox();
  final entries = box.toMap().entries.toList();
  for (final entry in entries) {
    final dog = entry.value;
    final display = dog.regNrDisplay.trim();
    if (display.isEmpty) {
      continue;
    }
    final normalized = normalizeRegNr(display);
    if (normalized.isEmpty || dog.dogKey == normalized) {
      continue;
    }
    final updated = dog.copyWith(dogKey: normalized);
    await box.put(entry.key, updated);
  }
}

Future<void> _backfillDogKeyOwnershipIfNeeded() async {
  final settingsBox = Hive.box<dynamic>(appSettingsBoxName);
  final alreadyBackfilled =
      settingsBox.get(dogKeyBackfillDoneKey) as bool? ?? false;
  if (alreadyBackfilled) {
    debugPrint('[BACKFILL] Skipping ownership backfill (already complete)');
    return;
  }

  final identity = UserIdentityService();
  final currentUserId = identity.getCurrentUserId().trim();
  if (currentUserId.isEmpty) {
    debugPrint('[BACKFILL] Skipping ownership backfill (no current user)');
    return;
  }

  final box = dogsBox();
  final membershipBox = dogMembershipsBox();
  final dogEntries = box.toMap().entries.toList();
  if (dogEntries.isEmpty) {
    debugPrint('[BACKFILL] No dogs to process for ownership backfill');
    await settingsBox.put(dogKeyBackfillDoneKey, true);
    return;
  }

  final membershipEntries = membershipBox.toMap().entries.toList();
  var dogsUpdated = 0;
  var deletedDogsSkipped = 0;
  var membershipsCreated = 0;
  var membershipsUpdated = 0;
  var membershipsAlreadyValid = 0;

  for (final entry in dogEntries) {
    final dog = entry.value;
    if (dog.isDeleted) {
      deletedDogsSkipped++;
      continue;
    }

    var effectiveDogKey = dog.dogKey.trim();
    final hadEmptyKey = effectiveDogKey.isEmpty;
    var updatedDog = dog;

    if (hadEmptyKey) {
      effectiveDogKey = dog.id;
      updatedDog = dog.copyWith(
        dogKey: effectiveDogKey,
        updatedAt: DateTime.now(),
      );
      await box.put(entry.key, updatedDog);
      dogsUpdated++;
    }

    MapEntry<dynamic, DogMembership>? membershipEntry;
    for (final membershipRecord in membershipEntries) {
      final membership = membershipRecord.value;
      if (membership.dogKey == effectiveDogKey &&
          membership.userId.trim() == currentUserId) {
        membershipEntry = membershipRecord;
        break;
      }
    }

    if (membershipEntry != null) {
      final membership = membershipEntry.value;
      if (membership.role != Role.owner || membership.status != Status.active) {
        final updatedMembership = membership.copyWith(
          role: Role.owner,
          status: Status.active,
        );
        await membershipBox.put(membershipEntry.key, updatedMembership);
        membershipsUpdated++;
      } else {
        membershipsAlreadyValid++;
      }
      continue;
    }

    final newMembership = DogMembership(
      dogKey: effectiveDogKey,
      userId: currentUserId,
      role: Role.owner,
      status: Status.active,
      addedAt: DateTime.now(),
      addedByUserId: currentUserId,
    );
    await membershipBox.add(newMembership);
    membershipsCreated++;
  }

  await settingsBox.put(dogKeyBackfillDoneKey, true);
  debugPrint(
    '[BACKFILL] Dog key/ownership backfill complete '
    '(alreadyBackfilled=$alreadyBackfilled, dogsUpdated=$dogsUpdated, '
    'deletedDogsSkipped=$deletedDogsSkipped, '
    'membershipsCreated=$membershipsCreated, '
    'membershipsUpdated=$membershipsUpdated, '
    'membershipsAlreadyValid=$membershipsAlreadyValid)',
  );
}
