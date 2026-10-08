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

  test('owner sees all valid role options in dialog', () {
    expect(
      editableRolesForMembership(
        actorRole: Role.owner,
        targetRole: Role.admin,
      ),
      const <Role>[Role.owner, Role.admin, Role.editor, Role.viewer],
    );
  });

  test('administrator sees only lower role options', () {
    expect(
      editableRolesForMembership(
        actorRole: Role.admin,
        targetRole: Role.viewer,
      ),
      const <Role>[Role.editor, Role.viewer],
    );

    expect(
      editableRolesForMembership(
        actorRole: Role.admin,
        targetRole: Role.owner,
      ),
      isEmpty,
    );
    expect(
      editableRolesForMembership(
        actorRole: Role.admin,
        targetRole: Role.admin,
      ),
      isEmpty,
    );
  });

  test('viewer has no role editing options', () {
    expect(
      editableRolesForMembership(
        actorRole: Role.viewer,
        targetRole: Role.editor,
      ),
      isEmpty,
    );
  });

  test('owner cannot edit owner role entry (protects owner lock)', () {
    expect(
      editableRolesForMembership(
        actorRole: Role.owner,
        targetRole: Role.owner,
      ),
      isEmpty,
    );
  });
}
