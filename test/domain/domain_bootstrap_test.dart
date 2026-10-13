import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_constants.dart' as dc;
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/ownership_transfer.dart';
import 'package:jakthund_app/models/share_invitation.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/repositories/session_repository.dart';
import 'package:jakthund_app/repositories/track_repository.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_domain_');
    HivePathService.setOverridePathForTesting(tempDir.path);
    HiveLifecycleService.resetForTesting();

    // ✅ Viktig: gjør at bootstrap kan kjøre i hver test.
    resetDomainBootstrapForTesting();
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    await tempDir.delete(recursive: true);
  });

  test('initDomainLayer registers adapters', () async {
    await initDomainLayer();

    expect(Hive.isAdapterRegistered(3), isTrue);
    expect(Hive.isAdapterRegistered(2), isTrue);
    expect(Hive.isAdapterRegistered(1), isTrue);
    expect(Hive.isAdapterRegistered(7), isTrue);
    expect(Hive.isAdapterRegistered(8), isTrue);
    expect(Hive.isAdapterRegistered(9), isTrue);
    expect(Hive.isAdapterRegistered(10), isTrue);
    expect(Hive.isAdapterRegistered(11), isTrue);
    expect(Hive.isAdapterRegistered(12), isTrue);
    expect(Hive.isAdapterRegistered(13), isTrue);
    expect(Hive.isAdapterRegistered(16), isTrue);
    expect(Hive.isAdapterRegistered(51), isTrue);
    expect(Hive.isAdapterRegistered(220), isTrue);
    expect(Hive.isAdapterRegistered(221), isTrue);
  });

  test('production bootstrap persists Track with GpsPoint round-trip',
      () async {
    await initDomainLayer();

    final points = [
      GpsPoint(
        lat: 58.4546,
        lon: 5.9749,
        time: DateTime.utc(2025, 10, 13, 12, 18, 38),
      ),
      GpsPoint(
        lat: 58.4550,
        lon: 5.9753,
        time: DateTime.utc(2025, 10, 13, 12, 19, 38),
      ),
    ];
    final track = Track(
      id: 'track-round-trip',
      createdAt: DateTime.utc(2025, 10, 13),
      source: 'gpx_import',
      points: points,
    );

    final repository = TrackRepository();
    await repository.upsertTrack(track);
    final stored = await repository.getTrack(track.id);

    expect(stored, isNotNull);
    expect(stored!.points, hasLength(2));
    expect(stored.points.first.lat, points.first.lat);
    expect(stored.points.first.lon, points.first.lon);
    expect(stored.points.first.time, points.first.time);
  });

  test('replaceTrackForSession persists points for int and string Hive keys',
      () async {
    await initDomainLayer();

    final points = [
      GpsPoint(
        lat: 60.1,
        lon: 10.1,
        time: DateTime.utc(2025, 1, 1, 10),
      ),
      GpsPoint(
        lat: 60.2,
        lon: 10.2,
        time: DateTime.utc(2025, 1, 1, 10, 1),
      ),
    ];
    final repository = SessionRepository();

    for (final dynamic key in <dynamic>[42, 'session-uuid']) {
      final sessionId = key.toString();
      await sessionsBox().put(
        key,
        HuntSession(
          sessionId: sessionId,
          dogId: 'dog-1',
          dateTime: DateTime.utc(2025, 1, 1),
          location: '',
          durationMinutes: 0,
          birdsSeen: 0,
          points: 0,
          flushes: 0,
          notes: '',
        ),
      );

      await repository.replaceTrackForSession(
        sessionId,
        points,
        source: 'gpx_import',
      );

      final updatedSession = sessionsBox().get(key);
      expect(updatedSession?.trackId, isNotNull);
      final storedTrack = tracksBox().get(updatedSession!.trackId);
      expect(storedTrack, isNotNull);
      expect(storedTrack!.points, hasLength(2));
      expect(storedTrack.points.last.lat, points.last.lat);
      expect(storedTrack.points.last.lon, points.last.lon);
      expect(storedTrack.points.last.time, points.last.time);
    }
  });

  test('initDomainLayer bumps schema version and clears share boxes', () async {
    await initDomainLayer();

    final invitesBox = shareInvitesBox();
    final transfersBox = ownershipTransfersBox();

    await invitesBox.put(
      'invite-1',
      ShareInvitation(
        inviteId: 'invite-1',
        dogKey: 'NO123-45',
        role: Role.viewer,
        token: 'TOKEN12345',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        status: Status.pending,
        recipientEmail: 'invite@example.com',
        recipientUserId: null,
        createdByUserId: 'owner',
      ),
    );
    await transfersBox.put(
      'transfer-1',
      OwnershipTransfer(
        transferId: 'transfer-1',
        dogKey: 'NO123-45',
        fromUserId: 'user-a',
        toUserId: 'user-b',
        status: Status.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    final settingsBox = Hive.box<dynamic>(appSettingsBoxName);
    await settingsBox.put(dc.domainSchemaVersionKey, 0);

    // ✅ Kritisk: vi må la bootstrap tasks kjøre igjen i samme test
    resetDomainBootstrapForTesting();

    await initDomainLayer();

    expect(invitesBox.isEmpty, isTrue);
    expect(transfersBox.isEmpty, isTrue);
    expect(settingsBox.get(dc.domainSchemaVersionKey), dc.domainSchemaVersion);
  });

  test('ownership backfill does not grant new user access after completion',
      () async {
    await initDomainLayer();

    final settingsBox = Hive.box<dynamic>(appSettingsBoxName);
    final dogs = dogsBox();
    final memberships = dogMembershipsBox();

    await settingsBox.put(dc.currentUserIdKey, 'user-b');
    await settingsBox.put(dc.dogKeyBackfillDoneKey, true);
    await dogs.add(
      Dog(
        id: 'dog-a',
        name: 'Dog A',
        dogKey: 'NO123-45',
        regNrDisplay: 'NO12345/20',
        ownerUserId: 'user-a',
      ),
    );
    await memberships.add(
      DogMembership(
        dogKey: 'NO123-45',
        userId: 'user-a',
        role: Role.owner,
        status: Status.active,
        addedAt: DateTime(2024),
        addedByUserId: 'user-a',
      ),
    );

    resetDomainBootstrapForTesting();
    await initDomainLayer();

    final userBMemberships = memberships.values.where(
      (membership) =>
          membership.dogKey == 'NO123-45' && membership.userId == 'user-b',
    );
    expect(userBMemberships, isEmpty);
  });
}
