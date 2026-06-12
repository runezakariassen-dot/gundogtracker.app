import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/pages/dog_detail_page.dart';

void main() {
  group('DogDetailPage - Role Management Visibility', () {
    test('editableRolesForMembership allows owner to set admin role', () {
      final editableRoles = editableRolesForMembership(
        actorRole: Role.owner,
        targetRole: Role.editor,
      );
      expect(editableRoles, contains(Role.admin));
    });

    test('editableRolesForMembership allows admin to set editor role', () {
      final editableRoles = editableRolesForMembership(
        actorRole: Role.admin,
        targetRole: Role.viewer,
      );
      expect(editableRoles, contains(Role.editor));
    });

    test('editableRolesForMembership prevents admin from setting admin role', () {
      final editableRoles = editableRolesForMembership(
        actorRole: Role.admin,
        targetRole: Role.admin,
      );
      expect(editableRoles, isEmpty);
    });

    test('editableRolesForMembership prevents owner role modification', () {
      final editableRoles = editableRolesForMembership(
        actorRole: Role.owner,
        targetRole: Role.owner,
      );
      expect(editableRoles, isEmpty);
    });

    test('heat cycle section shows for female dogs only', () {
      final femaleDog = Dog(
        id: 'dog-female',
        name: 'Luna',
        dogKey: 'DOG-F',
        regNrDisplay: 'NO200/01',
        sex: DogSex.female,
      );
      final maleDog = Dog(
        id: 'dog-male',
        name: 'Birk',
        dogKey: 'DOG-M',
        regNrDisplay: 'NO200/02',
        sex: DogSex.male,
      );

      expect(shouldShowHeatCycleSection(femaleDog), isTrue);
      expect(shouldShowHeatCycleSection(maleDog), isFalse);
    });
  });

  group('DogDetailPage - Membership UI Tests', () {
    test('resolveHighestActiveRoleForUserIds returns highest priority role', () {
      final memberships = <DogMembership>[
        DogMembership(
          dogKey: 'dog-1',
          userId: 'user-1',
          role: Role.editor,
          status: Status.active,
          addedAt: DateTime(2024, 1, 1),
          addedByUserId: 'owner',
        ),
        DogMembership(
          dogKey: 'dog-1',
          userId: 'user-1',
          role: Role.admin,
          status: Status.active,
          addedAt: DateTime(2024, 1, 2),
          addedByUserId: 'owner',
        ),
      ];

      final role = resolveHighestActiveRoleForUserIds(
        memberships: memberships,
        dogKey: 'dog-1',
        userIds: const ['user-1'],
      );

      expect(role, Role.admin);
    });

    test('resolveHighestActiveRoleForUserIds ignores revoked memberships', () {
      final memberships = <DogMembership>[
        DogMembership(
          dogKey: 'dog-1',
          userId: 'user-1',
          role: Role.admin,
          status: Status.revoked,
          addedAt: DateTime(2024, 1, 1),
          addedByUserId: 'owner',
        ),
        DogMembership(
          dogKey: 'dog-1',
          userId: 'user-1',
          role: Role.viewer,
          status: Status.active,
          addedAt: DateTime(2024, 1, 2),
          addedByUserId: 'owner',
        ),
      ];

      final role = resolveHighestActiveRoleForUserIds(
        memberships: memberships,
        dogKey: 'dog-1',
        userIds: const ['user-1'],
      );

      expect(role, Role.viewer);
    });

    test('resolveHighestActiveRoleForUserIds returns null when no active memberships',
        () {
      final memberships = <DogMembership>[
        DogMembership(
          dogKey: 'dog-1',
          userId: 'user-1',
          role: Role.viewer,
          status: Status.revoked,
          addedAt: DateTime(2024, 1, 1),
          addedByUserId: 'owner',
        ),
      ];

      final role = resolveHighestActiveRoleForUserIds(
        memberships: memberships,
        dogKey: 'dog-1',
        userIds: const ['user-1'],
      );

      expect(role, isNull);
    });

    test(
        'resolveHighestActiveRoleForUserIds returns null when no matching user ids',
        () {
      final memberships = <DogMembership>[
        DogMembership(
          dogKey: 'dog-1',
          userId: 'other-user',
          role: Role.admin,
          status: Status.active,
          addedAt: DateTime(2024, 1, 1),
          addedByUserId: 'owner',
        ),
      ];

      final role = resolveHighestActiveRoleForUserIds(
        memberships: memberships,
        dogKey: 'dog-1',
        userIds: const ['user-1'],
      );

      expect(role, isNull);
    });
  });
}
