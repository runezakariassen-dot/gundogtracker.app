import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
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
import 'package:jakthund_app/pages/dog_page.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';

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

  Future<void> disposePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('dog_page_');
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

  testWidgets('dog page renders polished empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogPage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Start reisen med jakthunden din'), findsOneWidget);
    expect(
      find.text(
        'Du kan bruke appen helt offline. All data lagres lokalt på telefonen din.',
      ),
      findsOneWidget,
    );
    expect(find.text('Legg til hund'), findsWidgets);

    await disposePage(tester);
  });
}
