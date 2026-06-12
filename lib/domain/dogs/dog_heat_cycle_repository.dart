import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../models/dog_heat_cycle_log.dart';
import '../../services/hive_lifecycle_service.dart';

class DogHeatCycleRepository {
  DogHeatCycleRepository({Box<dynamic>? box})
      : _box = box ?? HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);

  final Box<dynamic> _box;

  static String storageKeyForDog(String dogId) => 'dogHeatCycles::$dogId';

  Future<List<DogHeatCycleLog>> listForDog(String dogId) async {
    final raw = _box.get(storageKeyForDog(dogId));
    final entries = <DogHeatCycleLog>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final map = <String, dynamic>{};
          item.forEach((key, value) {
            map[key.toString()] = value;
          });
          final parsed = DogHeatCycleLog.fromJson(map);
          if (parsed != null && parsed.dogId == dogId) {
            entries.add(parsed);
          }
        }
      }
    }

    entries.sort((a, b) => b.startDate.compareTo(a.startDate));
    return entries;
  }

  Future<void> saveForDog(DogHeatCycleLog entry) async {
    final current = await listForDog(entry.dogId);
    final index = current.indexWhere(
      (existing) => existing.createdAt.toUtc() == entry.createdAt.toUtc(),
    );
    if (index >= 0) {
      current[index] = entry;
    } else {
      current.add(entry);
    }

    current.sort((a, b) => b.startDate.compareTo(a.startDate));

    await _box.put(
      storageKeyForDog(entry.dogId),
      current.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<void> deleteForDog({
    required String dogId,
    required DateTime createdAt,
  }) async {
    final current = await listForDog(dogId);
    current.removeWhere(
      (entry) => entry.createdAt.toUtc() == createdAt.toUtc(),
    );
    await _box.put(
      storageKeyForDog(dogId),
      current.map((item) => item.toJson()).toList(growable: false),
    );
  }
}
