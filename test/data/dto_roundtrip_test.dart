import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/data/dto/dog_dto.dart';
import 'package:jakthund_app/data/dto/membership_dto.dart';
import 'package:jakthund_app/data/dto/ownership_transfer_dto.dart';
import 'package:jakthund_app/data/dto/share_invitation_dto.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/ownership_transfer.dart';
import 'package:jakthund_app/models/share_invitation.dart';

void main() {
  test('dog dto roundtrip preserves key fields', () {
    final dog = Dog(
      id: 'dog-1',
      name: 'Birk',
      dogKey: 'NO123-45',
      regNrDisplay: 'NO123/45',
      imagePath: '/tmp/dog.png',
      birthDate: DateTime(2020, 5, 1),
      pedigreeUrl: 'https://example.com',
      breed: 'Elghund',
      ownerUserId: 'owner',
      updatedAt: DateTime(2024, 1, 1),
      deletedAt: DateTime(2024, 1, 2),
    );

    final json = dogToJson(dog);
    final restored = dogFromJson(json);

    expect(restored.id, dog.id);
    expect(restored.name, dog.name);
    expect(restored.dogKey, dog.dogKey);
    expect(restored.regNrDisplay, dog.regNrDisplay);
    expect(restored.imagePath, dog.imagePath);
    expect(restored.birthDate, dog.birthDate);
    expect(restored.pedigreeUrl, dog.pedigreeUrl);
    expect(restored.breed, dog.breed);
    expect(restored.ownerUserId, dog.ownerUserId);
    expect(restored.updatedAt, dog.updatedAt);
    expect(restored.deletedAt, dog.deletedAt);
  });

  test('membership dto roundtrip preserves key fields', () {
    final membership = DogMembership(
      dogKey: 'NO123-45',
      userId: 'member',
      role: Role.editor,
      status: Status.active,
      addedAt: DateTime(2024, 1, 2),
      addedByUserId: 'owner',
    );

    final json = membershipToJson(membership);
    final restored = membershipFromJson(json);

    expect(restored.dogKey, membership.dogKey);
    expect(restored.userId, membership.userId);
    expect(restored.role, membership.role);
    expect(restored.status, membership.status);
    expect(restored.addedAt, membership.addedAt);
    expect(restored.addedByUserId, membership.addedByUserId);
  });

  test('share invitation dto roundtrip preserves key fields', () {
    final invite = ShareInvitation(
      inviteId: 'invite-1',
      dogKey: 'NO123-45',
      role: Role.viewer,
      token: 'ABC123DEF4',
      createdAt: DateTime(2024, 1, 1),
      expiresAt: DateTime(2024, 1, 8),
      status: Status.pending,
      recipientEmail: 'pending@example.com',
      recipientUserId: null,
      createdByUserId: 'owner',
    );

    final json = shareInvitationToJson(invite);
    final restored = shareInvitationFromJson(json);

    expect(restored.inviteId, invite.inviteId);
    expect(restored.dogKey, invite.dogKey);
    expect(restored.role, invite.role);
    expect(restored.token, invite.token);
    expect(restored.createdAt, invite.createdAt);
    expect(restored.expiresAt, invite.expiresAt);
    expect(restored.status, invite.status);
  });

  test('ownership transfer dto roundtrip preserves key fields', () {
    final transfer = OwnershipTransfer(
      transferId: 'transfer-1',
      dogKey: 'NO123-45',
      fromUserId: 'owner',
      toUserId: 'new-owner',
      status: Status.pending,
      createdAt: DateTime(2024, 1, 1),
      expiresAt: DateTime(2024, 1, 8),
    );

    final json = ownershipTransferToJson(transfer);
    final restored = ownershipTransferFromJson(json);

    expect(restored.transferId, transfer.transferId);
    expect(restored.dogKey, transfer.dogKey);
    expect(restored.fromUserId, transfer.fromUserId);
    expect(restored.toUserId, transfer.toUserId);
    expect(restored.status, transfer.status);
    expect(restored.createdAt, transfer.createdAt);
    expect(restored.expiresAt, transfer.expiresAt);
  });
}
