import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/services/session_track_edit_permission_service.dart';

void main() {
  final dog = Dog(
    id: 'local-dog',
    name: 'Zoe',
    dogKey: 'dog-key',
    regNrDisplay: '',
    ownerUserId: 'owner',
    cloudOwnerUid: 'cloud-owner',
  );

  DogMembership member(String userId, Role role,
          {Status status = Status.active}) =>
      DogMembership(
        dogKey: dog.dogKey,
        userId: userId,
        role: role,
        status: status,
        addedAt: DateTime.utc(2026),
        addedByUserId: 'owner',
      );

  bool can(String userId, Iterable<DogMembership> memberships) =>
      SessionTrackEditPermissionService.canEditFor(
        dogId: dog.id,
        userIds: [userId],
        dogs: [dog],
        memberships: memberships,
      );

  test('owner, admin, and editor can edit', () {
    expect(can('owner', const []), isTrue);
    expect(can('cloud-owner', const []), isTrue);
    expect(can('admin', [member('admin', Role.admin)]), isTrue);
    expect(can('editor', [member('editor', Role.editor)]), isTrue);
  });

  test('viewer and inactive memberships cannot edit', () {
    expect(can('viewer', [member('viewer', Role.viewer)]), isFalse);
    expect(
      can('pending', [member('pending', Role.editor, status: Status.pending)]),
      isFalse,
    );
    expect(
      can('revoked', [member('revoked', Role.owner, status: Status.revoked)]),
      isFalse,
    );
    expect(can('non-member', const []), isFalse);
  });
}
