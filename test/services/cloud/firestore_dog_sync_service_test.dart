import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/models/share_invitation.dart';
import 'package:jakthund_app/services/cloud/firestore_dog_sync_service.dart';

void main() {
  test('buildUpsertPayload includes persisted dog profile fields', () {
    final dog = Dog(
      id: 'dog-1',
      name: 'Birk',
      nickname: 'Basse',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO123/45',
      regNr: 'NO123/45',
      breed: 'Engelsk setter',
      pedigreeUrl: 'https://example.com/pedigree',
      ownerUserId: 'owner-1',
      ownerEmail: 'owner@example.com',
      title: 'JCH',
      updatedAt: DateTime.utc(2024, 3, 1, 12),
      birthDate: DateTime.utc(2020, 5, 1),
      sex: DogSex.female,
      deceasedAt: DateTime.utc(2025, 1, 10),
      memorialNote: 'Savnet hver dag',
      memorialStory: 'Hun jaktet med stor ro og presisjon.',
      profileHeroTextAnchor: 'topLeft',
      profileHeroTextScale: 1.2,
      watermarkShowTitle: false,
      watermarkShowName: false,
      watermarkShowOfficialName: true,
      watermarkShowNickname: true,
      watermarkUseDarkText: true,
      imagePath: 'dogs/photos/dog-1.jpg',
      profileMediaId: 'profile-media-1',
    );

    final payload = FirestoreDogSyncService.buildUpsertPayload(
      dog: dog,
      cloudDogId: 'cloud-dog-1',
      cloudOwnerUid: 'owner-1',
    );

    expect(payload['id'], 'cloud-dog-1');
    expect(payload['dogKey'], 'DOG-1');
    expect(payload['name'], 'Birk');
    expect(payload['nickname'], 'Basse');
    expect(payload['breed'], 'Engelsk setter');
    expect(payload['regNr'], 'NO123/45');
    expect(payload['regNrDisplay'], 'NO123/45');
    expect(payload['pedigreeUrl'], 'https://example.com/pedigree');
    expect(payload['ownerUserId'], 'owner-1');
    expect(payload['ownerEmail'], 'owner@example.com');
    expect(payload['title'], 'JCH');
    expect(payload['sex'], 'female');
    expect(payload['memorialNote'], 'Savnet hver dag');
    expect(payload['memorialStory'], 'Hun jaktet med stor ro og presisjon.');
    expect(payload['profileHeroTextAnchor'], 'topLeft');
    expect(payload['profileHeroTextScale'], 1.2);
    expect(payload['watermarkShowTitle'], isFalse);
    expect(payload['watermarkShowName'], isFalse);
    expect(payload['watermarkShowOfficialName'], isTrue);
    expect(payload['watermarkShowNickname'], isTrue);
    expect(payload['watermarkUseDarkText'], isTrue);
    expect(payload['profileMediaId'], 'profile-media-1');
    expect(payload['birthDate'], isA<Timestamp>());
    expect(payload['deceasedAt'], isA<Timestamp>());
    expect(payload['updatedAt'], isA<Timestamp>());
    expect(payload['deletedAt'], isA<FieldValue>());
    expect(payload.containsKey('imagePath'), isFalse);
  });

  test('buildUpsertPayload omits blank profileMediaId', () {
    final dog = Dog(
      id: 'dog-1',
      name: 'Birk',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO123/45',
      updatedAt: DateTime.utc(2024, 3, 1, 12),
      profileMediaId: '   ',
    );

    final payload = FirestoreDogSyncService.buildUpsertPayload(
      dog: dog,
      cloudDogId: 'cloud-dog-1',
      cloudOwnerUid: 'owner-1',
    );

    expect(payload.containsKey('profileMediaId'), isFalse);
  });

  test('isActiveMembershipStatus allows active and legacy owner memberships',
      () {
    expect(
      FirestoreDogSyncService.isActiveMembershipStatus(
        <String, dynamic>{'status': 'active'},
      ),
      isTrue,
    );
    expect(
      FirestoreDogSyncService.isActiveMembershipStatus(
        <String, dynamic>{'status': 'revoked'},
      ),
      isFalse,
    );
    expect(
      FirestoreDogSyncService.isActiveMembershipStatus(
        <String, dynamic>{'status': 'pending'},
      ),
      isFalse,
    );
    expect(
      FirestoreDogSyncService.isActiveMembershipStatus(
        <String, dynamic>{'status': null},
      ),
      isFalse,
    );
    expect(
      FirestoreDogSyncService.isActiveMembershipStatus(
        <String, dynamic>{'role': 'owner', 'status': null},
      ),
      isTrue,
    );
    expect(
      FirestoreDogSyncService.isActiveMembershipStatus(
        <String, dynamic>{'role': 'editor', 'status': null},
      ),
      isFalse,
    );
  });

  test('shouldIncludeDogForMembershipDocs rejects revoked non-owner membership',
      () {
    expect(
      FirestoreDogSyncService.shouldIncludeDogForMembershipDocs(
        <Map<String, dynamic>>[
          <String, dynamic>{'role': 'editor', 'status': 'revoked'},
        ],
      ),
      isFalse,
    );
  });

  test(
      'shouldIncludeDogForMembershipDocs keeps legacy owner null-status active',
      () {
    expect(
      FirestoreDogSyncService.shouldIncludeDogForMembershipDocs(
        <Map<String, dynamic>>[
          <String, dynamic>{'role': 'owner', 'status': null},
        ],
      ),
      isTrue,
    );
  });

  test(
      'shouldIncludeDogForMembershipDocs treats non-owner null-status as inactive',
      () {
    expect(
      FirestoreDogSyncService.shouldIncludeDogForMembershipDocs(
        <Map<String, dynamic>>[
          <String, dynamic>{'role': 'editor', 'status': null},
        ],
      ),
      isFalse,
    );
  });

  test(
      'shouldIncludeDogForMembershipDocs denies dog when active and revoked docs conflict',
      () {
    expect(
      FirestoreDogSyncService.shouldIncludeDogForMembershipDocs(
        <Map<String, dynamic>>[
          <String, dynamic>{'role': 'editor', 'status': 'active'},
          <String, dynamic>{'role': 'editor', 'status': 'revoked'},
        ],
      ),
      isFalse,
    );
  });

  test('accept membership payload reactivates revoked member as active', () {
    final invite = ShareInvitation(
      inviteId: 'invite-1',
      dogKey: 'DOG-1',
      role: Role.viewer,
      token: 'TOKEN123',
      createdAt: DateTime.utc(2026, 6),
      expiresAt: DateTime.utc(2026, 6, 8),
      status: Status.accepted,
      recipientEmail: 'member@example.com',
      recipientUserId: 'member-uid',
      createdByUserId: 'owner-uid',
      cloudDogId: 'cloud-dog-1',
    );
    final revokedMembership = DogMembership(
      dogKey: 'DOG-1',
      userId: 'member-uid',
      role: Role.viewer,
      status: Status.revoked,
      addedAt: DateTime.utc(2026, 6),
      addedByUserId: 'owner-uid',
    );

    final payload = FirestoreDogSyncService.buildShareInviteMembershipPayload(
      invite: invite,
      membership: revokedMembership,
      uid: 'member-uid',
      includeCreatedAt: true,
    );

    expect(payload['uid'], 'member-uid');
    expect(payload['role'], 'viewer');
    expect(payload['status'], 'active');
    expect(payload['dogKey'], 'DOG-1');
    expect(payload['acceptedInviteId'], 'invite-1');
    expect(payload['createdAt'], isA<FieldValue>());
    expect(payload['updatedAt'], isA<FieldValue>());
  });

  test('mapFirestoreDogToDog ignores local-only imagePath from cloud', () {
    final dog = FirestoreDogSyncService.instance.mapFirestoreDogToDog(
      <String, dynamic>{
        'id': 'cloud-dog-1',
        'dogKey': 'DOG-1',
        'name': 'Birk',
        'regNrDisplay': 'NO123/45',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 6)),
        'imagePath': 'dogs/photos/dog_owner_device.jpg',
        'profileMediaId': 'profile-media-1',
      },
      'cloud-dog-1',
    );

    expect(dog.imagePath, isNull);
    expect(dog.profileMediaId, 'profile-media-1');
  });

  test('mapFirestoreDogToDog handles missing profileMediaId', () {
    final dog = FirestoreDogSyncService.instance.mapFirestoreDogToDog(
      <String, dynamic>{
        'id': 'cloud-dog-1',
        'dogKey': 'DOG-1',
        'name': 'Birk',
        'regNrDisplay': 'NO123/45',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 6)),
      },
      'cloud-dog-1',
    );

    expect(dog.profileMediaId, isNull);
  });
}
