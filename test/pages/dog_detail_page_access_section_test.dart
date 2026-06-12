import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_constants.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/gps_track.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/map_settings.dart';
import 'package:jakthund_app/models/outbox_entry.dart';
import 'package:jakthund_app/models/ownership_transfer.dart';
import 'package:jakthund_app/pages/dog_detail_page.dart';
import 'package:jakthund_app/models/share_invitation.dart';
import 'package:jakthund_app/models/sync_state.dart';
import 'package:jakthund_app/models/sync_task.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

Future<void> _closeOpenBoxes() async {
  Future<void> closeTypedBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) return;
    await Hive.box<T>(name)
        .close()
        .timeout(const Duration(seconds: 2), onTimeout: () {});
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
    final tempDir = await Directory.systemTemp.createTemp(
      'dog_detail_access_',
    );
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
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpDogDetailPage(
    WidgetTester tester, {
    required Dog dog,
    required String currentUserId,
    required List<DogMembership> memberships,
  }) async {
    final dogs = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    final membershipBox = HiveLifecycleService.getBox<DogMembership>(
      dogMembershipsBoxName,
    );
    final settingsBox = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);

    await tester.runAsync(() async {
      await dogs.put(dog.id, dog);
      for (final membership in memberships) {
        await membershipBox.put(
          '${membership.dogKey}::${membership.userId}',
          membership,
        );
      }
      await settingsBox.put(currentUserIdKey, currentUserId);
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogDetailPage(dog: dog),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> disposeDogDetailPage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('owner sees access section at top with change role action',
      (tester) async {
    final dog = Dog(
      id: 'dog-owner',
      name: 'Luna',
      dogKey: 'DOG-OWNER',
      regNrDisplay: 'NO100/01',
      ownerUserId: 'owner-user',
    );

    await pumpDogDetailPage(
      tester,
      dog: dog,
      currentUserId: 'owner-user',
      memberships: <DogMembership>[
        DogMembership(
          dogKey: dog.dogKey,
          userId: 'member-user',
          role: Role.viewer,
          status: Status.active,
          addedAt: DateTime(2024, 1, 1),
          addedByUserId: 'owner-user',
        ),
      ],
    );

    expect(find.text('Tilgang og roller'), findsOneWidget);
    expect(find.text('Access section v2'), findsOneWidget);
    expect(find.text('Endre rolle'), findsWidgets);

    await disposeDogDetailPage(tester);
  });

  testWidgets('admin sees access section at top with change role action',
      (tester) async {
    final dog = Dog(
      id: 'dog-admin',
      name: 'Birk',
      dogKey: 'DOG-ADMIN',
      regNrDisplay: 'NO100/02',
      ownerUserId: 'owner-user',
    );

    await pumpDogDetailPage(
      tester,
      dog: dog,
      currentUserId: 'admin-user',
      memberships: <DogMembership>[
        DogMembership(
          dogKey: dog.dogKey,
          userId: 'admin-user',
          role: Role.admin,
          status: Status.active,
          addedAt: DateTime(2024, 1, 1),
          addedByUserId: 'owner-user',
        ),
        DogMembership(
          dogKey: dog.dogKey,
          userId: 'member-user',
          role: Role.viewer,
          status: Status.active,
          addedAt: DateTime(2024, 1, 2),
          addedByUserId: 'owner-user',
        ),
      ],
    );

    expect(find.text('Tilgang og roller'), findsOneWidget);
    expect(find.text('Access section v2'), findsOneWidget);
    expect(find.text('Endre rolle'), findsWidgets);

    await disposeDogDetailPage(tester);
  });

  testWidgets('viewer sees access section as read-only', (tester) async {
    final dog = Dog(
      id: 'dog-viewer',
      name: 'Tara',
      dogKey: 'DOG-VIEWER',
      regNrDisplay: 'NO100/03',
      ownerUserId: 'owner-user',
    );

    await pumpDogDetailPage(
      tester,
      dog: dog,
      currentUserId: 'viewer-user',
      memberships: <DogMembership>[
        DogMembership(
          dogKey: dog.dogKey,
          userId: 'viewer-user',
          role: Role.viewer,
          status: Status.active,
          addedAt: DateTime(2024, 1, 1),
          addedByUserId: 'owner-user',
        ),
      ],
    );

    expect(find.text('Tilgang og roller'), findsOneWidget);
    expect(find.text('Access section v2'), findsOneWidget);
    expect(find.text('Endre rolle'), findsNothing);

    await disposeDogDetailPage(tester);
  });
}
