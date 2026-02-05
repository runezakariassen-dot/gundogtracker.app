import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/services/dog_title_catalog_service.dart';

class _TestRepo implements DogTitleCatalogRepository {
  List<String> _stored = [];

  @override
  List<String> readTitles() => List<String>.from(_stored);

  @override
  Future<void> writeTitles(List<String> titles) async {
    _stored = List<String>.from(titles);
  }
}

void main() {
  group('DogTitleCatalogService', () {
    late _TestRepo repo;
    late DogTitleCatalogService service;

    setUp(() {
      repo = _TestRepo();
      service = DogTitleCatalogService(repository: repo);
    });

    test('adds trimmed title and ignores case duplicates', () async {
      await service.addTitle('  NUCH  ');
      expect(repo._stored, ['NUCH']);

      await service.addTitle('nuch');
      expect(repo._stored, ['NUCH']);
    });

    test('getTitles returns sorted set and preserves writes', () async {
      repo._stored = ['zeta', 'Alpha'];
      expect(service.getTitles(), ['Alpha', 'zeta']);

      await service.addTitle('bravo');
      expect(repo._stored, ['Alpha', 'bravo', 'zeta']);
    });
  });
}
