import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../models/sync_state.dart';

class SyncStateStore {
  SyncStateStore({Box<SyncState>? box}) : _box = box ?? syncStateBox();

  final Box<SyncState> _box;

  SyncState getOrCreate(String dogId) {
    final existing = _box.get(dogId);
    if (existing != null) {
      return existing;
    }
    final created = SyncState(dogId: dogId);
    _box.put(dogId, created);
    return created;
  }

  Future<void> setLastPulledAt(String dogId, DateTime t) async {
    final state = getOrCreate(dogId).copyWith(lastPulledAt: t);
    await _box.put(dogId, state);
  }

  Future<void> setLastPushedAt(String dogId, DateTime t) async {
    final state = getOrCreate(dogId).copyWith(lastPushedAt: t);
    await _box.put(dogId, state);
  }

  Future<void> setLastServerTime(String dogId, DateTime t) async {
    final state = getOrCreate(dogId).copyWith(lastServerTime: t);
    await _box.put(dogId, state);
  }
}
