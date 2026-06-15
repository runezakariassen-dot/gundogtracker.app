import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_constants.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/domain/settings/settings_repository.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/models/gps_track.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/map_settings.dart';
import 'package:jakthund_app/models/outbox_entry.dart';
import 'package:jakthund_app/models/ownership_transfer.dart';
import 'package:jakthund_app/models/share_invitation.dart';
import 'package:jakthund_app/models/sync_state.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/ui/screens/home_screen.dart';

Future<void> _closeOpenBoxes() async {
  Future<void> closeTypedBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) return;
    try {
      await Hive.box<T>(name)
          .close()
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (_) {
      // Ignore cleanup failures in widget tests to avoid hanging teardown.
    }
  }

  await closeTypedBox<Dog>(dogsBoxName);
  await closeTypedBox<HuntSession>(sessionsBoxName);
  await closeTypedBox<Track>(tracksBoxName);
  await closeTypedBox<GpsTrack>(gpsTracksBoxName);
  await closeTypedBox<MapSettings>(mapSettingsBoxName);
  await closeTypedBox<String>(birdSpeciesBoxName);
  await closeTypedBox<dynamic>(breedCatalogBoxName);
  await closeTypedBox<dynamic>(appSettingsBoxName);
  await closeTypedBox<DogMembership>(dogMembershipsBoxName);
  await closeTypedBox<ShareInvitation>(shareInvitesBoxName);
  await closeTypedBox<OwnershipTransfer>(ownershipTransfersBoxName);
  await closeTypedBox<SyncTask>(syncTasksBoxName);
  await closeTypedBox<OutboxEntry>(syncOutboxBoxName);
  await closeTypedBox<SyncState>(syncStateBoxName);
  await closeTypedBox<DateTime>(milestoneSeenBoxName);
  await closeTypedBox<DogMilestoneState>(dogMilestoneStateBoxName);
  await closeTypedBox<ActiveSessionDraft>(activeSessionDraftBoxName);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String tempDirPath;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('home_screen_');
    tempDirPath = tempDir.path;
    HivePathService.setOverridePathForTesting(tempDirPath);
    HiveLifecycleService.resetForTesting();
    await HivePathService.init();
    registerDomainAdapters();
    await HiveLifecycleService.init();
  });

  tearDown(() async {
    await _closeOpenBoxes();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    final tempDir = Directory(tempDirPath);
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup failures in widget tests to avoid hanging teardown.
    }
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    String? currentUserIdOverride,
    String? currentUserEmailOverride,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(
          currentUserIdOverride: currentUserIdOverride,
          currentUserEmailOverride: currentUserEmailOverride,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> disposeHome(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('home empty state guides user to add the first dog',
      (tester) async {
    await pumpHome(tester);
    await tester.scrollUntilVisible(
      find.text('Start reisen med jakthunden din'),
      300,
    );
    await tester.pumpAndSettle();

    expect(find.text('Start reisen med jakthunden din'), findsOneWidget);
    expect(
      find.text(
        'Begynn med å legge til hunden din. Deretter kan du logge første økt når dere er klare.',
      ),
      findsOneWidget,
    );
    expect(find.text('Legg til hund'), findsOneWidget);

    await disposeHome(tester);
  });

  testWidgets('home does not show personal goal prompt', (tester) async {
    await pumpHome(tester);

    expect(find.text('Personlig mål'), findsNothing);
    expect(find.textContaining('standprogresjonen din'), findsNothing);

    await disposeHome(tester);
  });

  testWidgets('home shows pending dog invitation banner and opens invitations',
      (tester) async {
    final shareInvitesBox =
        HiveLifecycleService.getBox<ShareInvitation>(shareInvitesBoxName);

    await tester.runAsync(() async {
      await shareInvitesBox.put(
        'invite-1',
        ShareInvitation(
          inviteId: 'invite-1',
          dogKey: 'DOG-1',
          role: Role.editor,
          token: 'TOKEN123',
          createdAt: DateTime(2026, 5, 1),
          expiresAt: DateTime(2026, 5, 8),
          status: Status.pending,
          recipientEmail: 'member@example.com',
          recipientUserId: 'user-b',
          createdByUserId: 'owner-a',
          senderDisplayName: 'Rune Zakariassen',
          dogName: 'Kompis',
        ),
      );
    });

    await pumpHome(tester, currentUserIdOverride: 'user-b');

    expect(find.text('Du har en hundeinvitasjon'), findsOneWidget);
    expect(find.text('Se invitasjon'), findsOneWidget);

    await tester.tap(find.text('Se invitasjon'));
    await tester.pumpAndSettle();

    expect(find.text('Invitasjoner'), findsOneWidget);

    await disposeHome(tester);
  });

  testWidgets('home shows pending invitation that matches recipient email',
      (tester) async {
    final shareInvitesBox =
        HiveLifecycleService.getBox<ShareInvitation>(shareInvitesBoxName);

    await tester.runAsync(() async {
      await shareInvitesBox.put(
        'invite-email',
        ShareInvitation(
          inviteId: 'invite-email',
          dogKey: 'DOG-EMAIL',
          role: Role.editor,
          token: 'TOKENEMAIL',
          createdAt: DateTime(2026, 5, 1),
          expiresAt: DateTime(2026, 5, 8),
          status: Status.pending,
          recipientEmail: 'member@example.com',
          recipientUserId: null,
          createdByUserId: 'owner-a',
          dogName: 'Kompis',
        ),
      );
    });

    await pumpHome(
      tester,
      currentUserIdOverride: 'different-user',
      currentUserEmailOverride: 'member@example.com',
    );

    expect(find.text('Du har en hundeinvitasjon'), findsOneWidget);
    expect(find.text('Se invitasjon'), findsOneWidget);

    await disposeHome(tester);
  });

  testWidgets('home shows pending invitation that matches recipient uid',
      (tester) async {
    final shareInvitesBox =
        HiveLifecycleService.getBox<ShareInvitation>(shareInvitesBoxName);

    await tester.runAsync(() async {
      await shareInvitesBox.put(
        'invite-uid',
        ShareInvitation(
          inviteId: 'invite-uid',
          dogKey: 'DOG-UID',
          role: Role.editor,
          token: 'TOKENUID',
          createdAt: DateTime(2026, 5, 1),
          expiresAt: DateTime(2026, 5, 8),
          status: Status.pending,
          recipientEmail: 'other@example.com',
          recipientUserId: 'user-b',
          createdByUserId: 'owner-a',
          dogName: 'Kompis',
        ),
      );
    });

    await pumpHome(
      tester,
      currentUserIdOverride: 'user-b',
      currentUserEmailOverride: 'member@example.com',
    );

    expect(find.text('Du har en hundeinvitasjon'), findsOneWidget);
    expect(find.text('Se invitasjon'), findsOneWidget);

    await disposeHome(tester);
  });

  testWidgets('home invitation banner uses plural and hides when not pending',
      (tester) async {
    final shareInvitesBox =
        HiveLifecycleService.getBox<ShareInvitation>(shareInvitesBoxName);

    ShareInvitation invite(String id, Status status) {
      return ShareInvitation(
        inviteId: id,
        dogKey: 'DOG-$id',
        role: Role.editor,
        token: 'TOKEN$id',
        createdAt: DateTime(2026, 5, 1),
        expiresAt: DateTime(2026, 5, 8),
        status: status,
        recipientEmail: 'member@example.com',
        recipientUserId: 'user-b',
        createdByUserId: 'owner-a',
        dogName: 'Kompis',
      );
    }

    await tester.runAsync(() async {
      await shareInvitesBox.put('invite-1', invite('1', Status.pending));
      await shareInvitesBox.put('invite-2', invite('2', Status.pending));
    });

    await pumpHome(tester, currentUserIdOverride: 'user-b');

    expect(find.text('Du har 2 hundeinvitasjoner'), findsOneWidget);

    await tester.runAsync(() async {
      await shareInvitesBox.put('invite-1', invite('1', Status.accepted));
      await shareInvitesBox.put('invite-2', invite('2', Status.revoked));
    });
    await tester.pump();

    expect(find.text('Du har 2 hundeinvitasjoner'), findsNothing);
    expect(find.text('Du har en hundeinvitasjon'), findsNothing);
    expect(find.text('Se invitasjon'), findsNothing);

    await disposeHome(tester);
  });

  testWidgets('home does not show personal goal progress when goal exists',
      (tester) async {
    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    final repo = SettingsRepository(settingsBox);

    await tester.runAsync(() async {
      await repo.setUserProfile(
        const UserProfileSettings(personalStandGoal: 100),
      );
    });

    await pumpHome(tester, currentUserIdOverride: 'owner-1');

    expect(find.text('Personlig mål'), findsNothing);
    expect(find.text('42 / 100 stander'), findsNothing);
    expect(find.text('42% fullført'), findsNothing);

    await disposeHome(tester);
  });

  testWidgets('dashboard shows latest session when one exists', (tester) async {
    final dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    final sessionsBox =
        HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    final dog = Dog(
      id: 'dog-1',
      name: 'Bella',
      dogKey: 'NO-1',
      regNrDisplay: 'NO-1',
      ownerUserId: 'owner-1',
    );

    await tester.runAsync(() async {
      await dogsBox.put(dog.id, dog);
      await sessionsBox.add(
        HuntSession(
          dogId: dog.id,
          dateTime: DateTime(2026, 4, 24, 8, 30),
          location: 'Snasa',
          durationMinutes: 75,
          birdsSeen: 2,
          points: 7,
          flushes: 1,
          notes: 'Fin medvind og god kontakt.',
        ),
      );
    });

    await pumpHome(tester, currentUserIdOverride: 'owner-1');

    expect(find.text('Siste økt'), findsOneWidget);
    expect(find.text('Bella'), findsWidgets);
    expect(find.text('Fin medvind og god kontakt.'), findsOneWidget);
    expect(find.text('7 stander'), findsOneWidget);
    expect(find.text('2 fuglkontakter'), findsOneWidget);

    await disposeHome(tester);
  });

  testWidgets('dashboard shows latest session empty state when none exists',
      (tester) async {
    final dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    await tester.runAsync(() async {
      await dogsBox.put(
        'dog-1',
        Dog(
          id: 'dog-1',
          name: 'Bella',
          dogKey: 'NO-1',
          regNrDisplay: 'NO-1',
          ownerUserId: 'owner-1',
        ),
      );
    });

    await pumpHome(tester, currentUserIdOverride: 'owner-1');

    expect(find.text('Siste økt'), findsOneWidget);
    expect(find.text('Ingen økter registrert ennå.'), findsOneWidget);

    await disposeHome(tester);
  });

  testWidgets('home does not show start session quick action', (tester) async {
    final dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    await tester.runAsync(() async {
      await dogsBox.put(
        'dog-1',
        Dog(
          id: 'dog-1',
          name: 'Bella',
          dogKey: 'NO-1',
          regNrDisplay: 'NO-1',
          ownerUserId: 'owner-1',
        ),
      );
    });

    await pumpHome(tester, currentUserIdOverride: 'owner-1');

    expect(find.text('Siste økt'), findsOneWidget);
    expect(find.text('Ingen økter registrert ennå.'), findsOneWidget);
    expect(find.text('Start ny økt'), findsNothing);

    await disposeHome(tester);
  });

  testWidgets(
      'home shows locally owned dogs after restart without Firebase auth',
      (tester) async {
    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    final dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);

    await tester.runAsync(() async {
      await settingsBox.put(currentUserIdKey, 'local-user-1');
      await dogsBox.add(
        Dog(
          id: 'dog-1',
          name: 'Birk',
          dogKey: 'DOG-1',
          regNrDisplay: 'NO100/10',
          ownerUserId: 'local-user-1',
        ),
      );
      await dogsBox.add(
        Dog(
          id: 'dog-2',
          name: 'Luna',
          dogKey: 'DOG-2',
          regNrDisplay: 'NO100/11',
          ownerUserId: 'local-user-1',
        ),
      );
      await _closeOpenBoxes();
      HiveLifecycleService.resetForTesting();
      await HiveLifecycleService.init();
    });

    await pumpHome(tester);

    expect(find.text('Birk'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);

    await disposeHome(tester);
  });
}
