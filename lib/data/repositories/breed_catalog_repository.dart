import 'package:hive/hive.dart';

import '../hive_boxes.dart';
import '../../services/hive_lifecycle_service.dart';

class BreedCatalogRepository {
  static const String _breedsKey = 'breeds';

  Box<dynamic> _box() =>
      HiveLifecycleService.getBox<dynamic>(breedCatalogBoxName);

  List<String> readBreeds() {
    final value = _box().get(_breedsKey);
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  Future<void> writeBreeds(List<String> breeds) async {
    await _box().put(_breedsKey, breeds);
  }
}
