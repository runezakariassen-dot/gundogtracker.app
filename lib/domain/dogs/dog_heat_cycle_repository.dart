import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../data/hive_boxes.dart';
import '../../data/local/sync_outbox_service.dart';
import '../../models/dog_heat_cycle_log.dart';
import '../../services/hive_lifecycle_service.dart';

class DogHeatCycleRepository {
  DogHeatCycleRepository({
    Box<dynamic>? box,
    SyncOutboxService? syncOutboxService,
    DateTime Function()? now,
    String? Function()? createdByUserIdProvider,
    Uuid? uuid,
  })  : _box = box ?? HiveLifecycleService.getBox<dynamic>(appSettingsBoxName),
        _syncOutboxService = syncOutboxService,
        _now = now ?? DateTime.now,
        _createdByUserIdProvider = createdByUserIdProvider,
        _uuid = uuid ?? const Uuid();

  final Box<dynamic> _box;
  final SyncOutboxService? _syncOutboxService;
  final DateTime Function() _now;
  final String? Function()? _createdByUserIdProvider;
  final Uuid _uuid;

  static String storageKeyForDog(String dogId) => 'dogHeatCycles::$dogId';

  Future<List<DogHeatCycleLog>> listForDog(
    String dogId, {
    bool includeDeleted = false,
  }) async {
    final raw = _box.get(storageKeyForDog(dogId));
    final entries = <DogHeatCycleLog>[];
    var changed = false;

    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = <String, dynamic>{};
        item.forEach((key, value) {
          map[key.toString()] = value;
        });
        final parsed = DogHeatCycleLog.fromJson(map);
        if (parsed == null || parsed.dogId != dogId) continue;
        final normalized = _normalizeLegacyIdentity(parsed);
        if (!_sameLogIdentityAndFields(parsed, normalized)) {
          changed = true;
        }
        entries.add(normalized);
      }
    }

    if (changed) {
      await _persistEntries(dogId, entries);
    }

    final visible = includeDeleted
        ? entries
        : entries.where((entry) => !entry.isDeleted).toList(growable: false);
    visible.sort((a, b) => b.startDate.compareTo(a.startDate));
    return visible;
  }

  Future<DogHeatCycleLog?> getById({
    required String dogId,
    required String heatCycleId,
    bool includeDeleted = true,
  }) async {
    final entries = await listForDog(dogId, includeDeleted: includeDeleted);
    for (final entry in entries) {
      if (entry.id == heatCycleId) {
        return entry;
      }
    }
    return null;
  }

  Future<void> saveForDog(
    DogHeatCycleLog entry, {
    bool enqueueSync = true,
  }) async {
    final current = await listForDog(entry.dogId, includeDeleted: true);
    final index = current.indexWhere(
      (existing) => _matchesEntryIdentity(existing, entry),
    );

    final resolvedCreator = _resolveCreatedBy(
      incoming: entry.createdByUserId,
      existing: index >= 0 ? current[index].createdByUserId : null,
    );
    final normalized = _normalizeLegacyIdentity(
      entry.copyWith(createdByUserId: resolvedCreator),
    );

    if (index >= 0) {
      final existing = current[index];
      current[index] = normalized.copyWith(
        id: existing.id,
        createdAt: existing.createdAt,
        createdByUserId: existing.createdByUserId ?? normalized.createdByUserId,
      );
    } else {
      final generatedId = normalized.id ?? _uuid.v4();
      current.add(
        normalized.copyWith(
          id: generatedId,
          createdByUserId: normalized.createdByUserId,
        ),
      );
    }

    await _persistEntries(entry.dogId, current);

    if (enqueueSync) {
      final saved = current.firstWhere(
        (item) => _matchesEntryIdentity(item, normalized),
      );
      await _enqueueUpsert(saved);
    }
  }

  Future<void> deleteForDog({
    required String dogId,
    required DateTime createdAt,
    bool enqueueSync = true,
  }) async {
    final current = await listForDog(dogId, includeDeleted: true);
    final index = current.indexWhere(
      (entry) => entry.createdAt.toUtc() == createdAt.toUtc(),
    );
    if (index < 0) return;

    final deletedAt = _now().toUtc();
    final entry = current[index].copyWith(
      updatedAt: deletedAt,
      deletedAt: deletedAt,
    );
    current[index] = _normalizeLegacyIdentity(entry);

    await _persistEntries(dogId, current);
    if (enqueueSync) {
      await _enqueueDelete(current[index]);
    }
  }

  Future<void> mergePulledForDog(
    String dogId,
    List<DogHeatCycleLog> remoteEntries,
  ) async {
    final localEntries = await listForDog(dogId, includeDeleted: true);
    final merged = <String, DogHeatCycleLog>{};

    for (final entry in localEntries) {
      final normalized = _normalizeLegacyIdentity(entry);
      if (normalized.id == null) continue;
      merged[normalized.id!] = normalized;
    }

    for (final remoteEntry in remoteEntries) {
      if (remoteEntry.dogId != dogId) continue;
      final normalizedRemote = _normalizeLegacyIdentity(remoteEntry);
      final remoteId = normalizedRemote.id;
      if (remoteId == null) continue;
      final local = merged[remoteId];
      if (local == null ||
          normalizedRemote.updatedAt.toUtc().isAfter(local.updatedAt.toUtc())) {
        merged[remoteId] = normalizedRemote;
      }
    }

    final values = merged.values.toList(growable: false)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    await _persistEntries(dogId, values);
  }

  DogHeatCycleLog _normalizeLegacyIdentity(DogHeatCycleLog entry) {
    final normalizedId = entry.id?.trim().isNotEmpty == true
        ? entry.id!.trim()
        : _legacyIdFor(entry);
    return entry.copyWith(id: normalizedId);
  }

  String _legacyIdFor(DogHeatCycleLog entry) {
    return _uuid.v5(
      Namespace.url.value,
      '${entry.dogId}|${entry.createdAt.toUtc().toIso8601String()}',
    );
  }

  bool _matchesEntryIdentity(
    DogHeatCycleLog existing,
    DogHeatCycleLog candidate,
  ) {
    final existingId = existing.id?.trim();
    final candidateId = candidate.id?.trim();
    if (existingId != null &&
        existingId.isNotEmpty &&
        candidateId != null &&
        candidateId.isNotEmpty) {
      return existingId == candidateId;
    }
    return existing.createdAt.toUtc() == candidate.createdAt.toUtc();
  }

  bool _sameLogIdentityAndFields(
    DogHeatCycleLog before,
    DogHeatCycleLog after,
  ) {
    return before.id == after.id &&
        before.dogId == after.dogId &&
        before.startDate == after.startDate &&
        before.endDate == after.endDate &&
        before.note == after.note &&
        before.createdByUserId == after.createdByUserId &&
        before.createdAt == after.createdAt &&
        before.updatedAt == after.updatedAt &&
        before.deletedAt == after.deletedAt;
  }

  String? _resolveCreatedBy({
    required String? incoming,
    required String? existing,
  }) {
    final incomingTrimmed = incoming?.trim();
    if (incomingTrimmed != null && incomingTrimmed.isNotEmpty) {
      return incomingTrimmed;
    }
    final existingTrimmed = existing?.trim();
    if (existingTrimmed != null && existingTrimmed.isNotEmpty) {
      return existingTrimmed;
    }
    final provided = _createdByUserIdProvider?.call()?.trim();
    if (provided != null && provided.isNotEmpty) {
      return provided;
    }
    return null;
  }

  Future<void> _persistEntries(String dogId, List<DogHeatCycleLog> entries) {
    entries.sort((a, b) => b.startDate.compareTo(a.startDate));
    return _box.put(
      storageKeyForDog(dogId),
      entries.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<void> _enqueueUpsert(DogHeatCycleLog entry) async {
    final service = _resolveOutboxService();
    if (service == null || entry.id == null || entry.id!.trim().isEmpty) {
      return;
    }
    await service.enqueueUpsertHeatCycle(
      heatCycleId: entry.id!,
      dogId: entry.dogId,
    );
  }

  Future<void> _enqueueDelete(DogHeatCycleLog entry) async {
    final service = _resolveOutboxService();
    if (service == null || entry.id == null || entry.id!.trim().isEmpty) {
      return;
    }
    await service.enqueueDeleteHeatCycle(
      heatCycleId: entry.id!,
      dogId: entry.dogId,
      deletedAt: entry.deletedAt ?? entry.updatedAt,
    );
  }

  SyncOutboxService? _resolveOutboxService() {
    if (_syncOutboxService != null) {
      return _syncOutboxService;
    }
    if (!Hive.isBoxOpen(syncTasksBoxName)) {
      return null;
    }
    return SyncOutboxService();
  }
}
