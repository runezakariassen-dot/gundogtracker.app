import 'package:hive/hive.dart';

import '../../../data/hive_boxes.dart';
import '../../../models/offline_region_metadata.dart';

class OfflineRegionService {
  static const String _offlineRegionsKey = 'offlineRegions_v1';

  Box<dynamic> _settingsBox() => Hive.box<dynamic>(appSettingsBoxName);

  List<OfflineRegionMetadata> loadAll() {
    final raw = _settingsBox().get(_offlineRegionsKey);
    if (raw is List) {
      return raw.whereType<OfflineRegionMetadata>().toList(growable: false);
    }
    return const [];
  }

  Future<void> add(OfflineRegionMetadata region) async {
    final current = loadAll().toList(growable: true);
    current.add(region);
    await _settingsBox().put(_offlineRegionsKey, current);
  }

  Future<void> removeById(String id) async {
    final filtered =
        loadAll().where((region) => region.id != id).toList(growable: false);
    await _settingsBox().put(_offlineRegionsKey, filtered);
  }

  Future<void> replaceAll(List<OfflineRegionMetadata> regions) async {
    await _settingsBox().put(_offlineRegionsKey, regions);
  }

  Future<void> clear({String? tileSourceKey}) async {
    if (tileSourceKey == null) {
      await _settingsBox().put(_offlineRegionsKey, <OfflineRegionMetadata>[]);
      return;
    }
    final filtered = loadAll()
        .where((region) => region.tileSourceKey != tileSourceKey)
        .toList(growable: false);
    await _settingsBox().put(_offlineRegionsKey, filtered);
  }
}
