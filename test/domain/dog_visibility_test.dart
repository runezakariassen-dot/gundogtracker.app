import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/config/subscription_products.dart';
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

  test('foreign local dogs are hidden for the current account', () {
    final userADog = _buildDog(
      id: 'dog-a',
      dogKey: 'DOG-A',
      name: 'Løgnas',
      ownerUserId: 'user-a',
    );
    final userBDog = _buildDog(
      id: 'dog-b',
      dogKey: 'DOG-B',
      name: 'Birk',
      ownerUserId: 'user-b',
    );

    final visibleDogs = filterVisibleDogs(
      dogs: <Dog>[userADog, userBDog],
      memberships: const <DogMembership>[],
      currentUserId: 'user-b',
    );

    expect(visibleDogs.map((dog) => dog.id), <String>['dog-b']);
  });

  test('quota count ignores previous account dogs', () {
    final staleDogs = List<Dog>.generate(
      5,
      (index) => _buildDog(
        id: 'dog-a-$index',
        dogKey: 'DOG-A-$index',
        ownerUserId: 'user-a',
      ),
    );

    final snapshot = buildDogLimitCountSnapshot(
      dogs: staleDogs,
      memberships: const <DogMembership>[],
      currentUserId: 'user-b',
    );

    expect(snapshot.countedDogs, isEmpty);
    expect(snapshot.countedDogs.length, lessThan(freeDogLimit));
  });

  test('quota count ignores deleted dogs', () {
    final deletedDog = _buildDog(
      id: 'dog-1',
      dogKey: 'DOG-1',
      ownerUserId: 'user-1',
      deletedAt: DateTime.utc(2024, 1, 2, 10),
    );

    final snapshot = buildDogLimitCountSnapshot(
      dogs: <Dog>[deletedDog],
      memberships: const <DogMembership>[],
      currentUserId: 'user-1',
    );

    expect(snapshot.countedDogs, isEmpty);
  });

  test('revoked shared dogs are hidden and do not count toward quota', () {
    final sharedDog = _buildDog(
      id: 'dog-1',
      dogKey: 'DOG-1',
      ownerUserId: 'owner-user',
    );

    final snapshot = buildDogLimitCountSnapshot(
      dogs: <Dog>[sharedDog],
      memberships: <DogMembership>[
        _membership(
          dogKey: 'DOG-1',
          userId: 'viewer-user',
          role: Role.viewer,
          status: Status.revoked,
        ),
      ],
      currentUserId: 'viewer-user',
    );

    expect(snapshot.visibleDogs, isEmpty);
    expect(snapshot.countedDogs, isEmpty);
  });
}

Dog _buildDog({
  required String id,
  required String dogKey,
  String name = 'Birk',
  String ownerUserId = 'user-1',
  DateTime? deletedAt,
}) {
  return Dog(
    id: id,
    name: name,
    dogKey: dogKey,
    regNrDisplay: 'NO123/45',
    ownerUserId: ownerUserId,
    updatedAt: DateTime.utc(2024, 1, 1, 12),
    deletedAt: deletedAt,
  );
}

DogMembership _membership({
  required String dogKey,
  String userId = 'user-1',
  Role role = Role.owner,
  Status status = Status.active,
}) {
  return DogMembership(
    dogKey: dogKey,
    userId: userId,
    role: role,
    status: status,
    addedAt: DateTime.utc(2024, 1, 1, 12),
    addedByUserId: 'user-1',
  );
}
