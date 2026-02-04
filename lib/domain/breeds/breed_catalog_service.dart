import '../../data/repositories/breed_catalog_repository.dart';

class BreedCatalogService {
  BreedCatalogService({BreedCatalogRepository? repository})
      : _repository = repository ?? BreedCatalogRepository();

  final BreedCatalogRepository _repository;

  Future<List<String>> getBreeds() async {
    final breeds = _repository.readBreeds();
    return _sorted(breeds);
  }

  Future<void> addBreed(String breed) async {
    final display = _displayBreed(breed);
    if (display.isEmpty) {
      return;
    }
    final normalized = normalizeBreed(display);
    if (normalized.isEmpty) {
      return;
    }
    final current = _repository.readBreeds();
    final normalizedSet = current.map(normalizeBreed).toSet();
    if (normalizedSet.contains(normalized)) {
      return;
    }
    final updated = [...current, display];
    await _repository.writeBreeds(_sorted(updated));
  }

  String _displayBreed(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _sorted(List<String> breeds) {
    final list = breeds.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }
}

String normalizeBreed(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
