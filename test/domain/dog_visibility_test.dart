import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/dogs/dog_visibility.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';

void main() {
  test('visible dogs filters out deleted dogs', () {
    final visibleDog = _buildDog(
      id: 'dog-1',
      dogKey: 'DOG-1',
    );
    final deletedDog = _buildDog(
      id: 'dog-2',
      dogKey: 'DOG-2',
      deletedAt: DateTime.utc(2024, 1, 2, 10),
    );

    final visibleDogs = filterVisibleDogs(
      dogs: <Dog>[visibleDog, deletedDog],
      memberships: <DogMembership>[
        _membership(dogKey: 'DOG-1'),
        _membership(dogKey: 'DOG-2'),
      ],
      currentUserId: 'user-1',
    );

    expect(visibleDogs.map((dog) => dog.id), <String>['dog-1']);
  });

  test('memberships do not make deleted dog visible', () {
    final deletedDog = _buildDog(
      id: 'dog-1',
      dogKey: 'DOG-1',
      deletedAt: DateTime.utc(2024, 1, 2, 10),
    );

    final visibleDogs = filterVisibleDogs(
      dogs: <Dog>[deletedDog],
      memberships: <DogMembership>[_membership(dogKey: 'DOG-1')],
      currentUserId: 'user-1',
    );

    expect(visibleDogs, isEmpty);
  });

  test('findVisibleDogById does not return deleted dog', () {
    final deletedDog = _buildDog(
      id: 'dog-1',
      dogKey: 'DOG-1',
      deletedAt: DateTime.utc(2024, 1, 2, 10),
    );

    final result = findVisibleDogById(
      dogs: <Dog>[deletedDog],
      memberships: <DogMembership>[_membership(dogKey: 'DOG-1')],
      currentUserId: 'user-1',
      dogId: 'dog-1',
    );

    expect(result, isNull);
  });

  test('detail visibility helper hides deleted dog and keeps active dog', () {
    final activeDog = _buildDog(
      id: 'dog-1',
      dogKey: 'DOG-1',
    );
    final deletedDog = _buildDog(
      id: 'dog-2',
      dogKey: 'DOG-2',
      deletedAt: DateTime.utc(2024, 1, 2, 10),
    );

    expect(isDogVisibleInUi(activeDog), isTrue);
    expect(isDogVisibleInUi(deletedDog), isFalse);
    expect(isDogVisibleInUi(null), isFalse);
  });

  test('deleted dog stays hidden even if related data still exists locally',
      () {
    final deletedDog = _buildDog(
      id: 'dog-1',
      dogKey: 'DOG-1',
      deletedAt: DateTime.utc(2024, 1, 2, 10),
    );

    final visibleDogs = filterVisibleDogs(
      dogs: <Dog>[deletedDog],
      memberships: <DogMembership>[_membership(dogKey: 'DOG-1')],
      currentUserId: 'user-1',
    );

    expect(visibleDogs, isEmpty);
  });
}

Dog _buildDog({
  required String id,
  required String dogKey,
  DateTime? deletedAt,
}) {
  return Dog(
    id: id,
    name: 'Birk',
    dogKey: dogKey,
    regNrDisplay: 'NO123/45',
    ownerUserId: 'user-1',
    updatedAt: DateTime.utc(2024, 1, 1, 12),
    deletedAt: deletedAt,
  );
}

DogMembership _membership({
  required String dogKey,
}) {
  return DogMembership(
    dogKey: dogKey,
    userId: 'user-1',
    role: Role.owner,
    status: Status.active,
    addedAt: DateTime.utc(2024, 1, 1, 12),
    addedByUserId: 'user-1',
  );
}
