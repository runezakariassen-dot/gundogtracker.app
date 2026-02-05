import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../services/hive_lifecycle_service.dart';

abstract class DogTitleCatalogRepository {
  List<String> readTitles();
  Future<void> writeTitles(List<String> titles);
}

class HiveDogTitleCatalogRepository implements DogTitleCatalogRepository {
  static const String _titlesKey = 'titles';

  Box<dynamic> _box() =>
      HiveLifecycleService.getBox<dynamic>(breedCatalogBoxName);

  @override
  List<String> readTitles() {
    final value = _box().get(_titlesKey);
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  @override
  Future<void> writeTitles(List<String> titles) async {
    await _box().put(_titlesKey, titles);
  }
}

class DogTitleCatalogService {
  DogTitleCatalogService({DogTitleCatalogRepository? repository})
      : _repository = repository ?? HiveDogTitleCatalogRepository();

  final DogTitleCatalogRepository _repository;

  List<String> getTitles() {
    return _sorted(_repository.readTitles());
  }

  Future<void> addTitle(String value) async {
    final display = _displayValue(value);
    if (display.isEmpty) {
      return;
    }
    final normalized = _normalize(display);
    final current = _repository.readTitles();
    final normalizedSet = current.map(_normalize).toSet();
    if (normalizedSet.contains(normalized)) {
      return;
    }
    final updated = [...current, display];
    await _repository.writeTitles(_sorted(updated));
  }
}

String _displayValue(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _normalize(String value) {
  return _displayValue(value).toLowerCase();
}

List<String> _sorted(List<String> values) {
  final list = values.toList();
  list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}
