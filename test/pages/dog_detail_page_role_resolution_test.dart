import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/pages/dog_detail_page.dart';

void main() {
  test(
      'resolveHighestActiveRoleForUserIds keeps administrator over weaker duplicate role',
      () {
    final memberships = <DogMembership>[
      DogMembership(
        dogKey: 'dog-1',
        userId: 'local-user',
        role: Role.admin,
        status: Status.active,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
      DogMembership(
        dogKey: 'dog-1',
        userId: 'firebase-user',
        role: Role.viewer,
        status: Status.active,
        addedAt: DateTime(2024, 1, 2),
        addedByUserId: 'owner',
      ),
    ];

    final role = resolveHighestActiveRoleForUserIds(
      memberships: memberships,
      dogKey: 'dog-1',
      userIds: const ['local-user', 'firebase-user'],
    );

    expect(role, Role.admin);
  });

  test('resolveHighestActiveRoleForUserIds ignores revoked memberships', () {
    final memberships = <DogMembership>[
      DogMembership(
        dogKey: 'dog-1',
        userId: 'local-user',
        role: Role.admin,
        status: Status.revoked,
        addedAt: DateTime(2024, 1, 1),
        addedByUserId: 'owner',
      ),
      DogMembership(
        dogKey: 'dog-1',
        userId: 'firebase-user',
        role: Role.viewer,
        status: Status.active,
        addedAt: DateTime(2024, 1, 2),
        addedByUserId: 'owner',
      ),
    ];

    final role = resolveHighestActiveRoleForUserIds(
      memberships: memberships,
      dogKey: 'dog-1',
      userIds: const ['local-user', 'firebase-user'],
    );

    expect(role, Role.viewer);
  });
}
