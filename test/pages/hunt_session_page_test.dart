import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/hunt_session_page.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String tempDirPath;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('hunt_session_');
    tempDirPath = tempDir.path;
    HivePathService.setOverridePathForTesting(tempDirPath);
    HiveLifecycleService.resetForTesting();
    await HivePathService.init();
    registerDomainAdapters();
    await HiveLifecycleService.init();
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    final tempDir = Directory(tempDirPath);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('session page guides user to add a dog before first session',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HuntSessionPage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text(
        'Legg til en hund først, så kan du starte den første økten.',
      ),
      findsOneWidget,
    );
    expect(find.text('Legg til hund'), findsOneWidget);
  });

  test('session dog visibility matches current user access', () {
    final visibleDogs = visibleSessionDogsForUser(
      dogs: <Dog>[
        _buildDog(
            id: 'dog-a',
            dogKey: 'DOG-A',
            name: 'Løgnas',
            ownerUserId: 'user-a'),
        _buildDog(
            id: 'dog-b', dogKey: 'DOG-B', name: 'Birk', ownerUserId: 'user-b'),
      ],
      memberships: const <DogMembership>[],
      currentUserId: 'user-b',
    );

    expect(visibleDogs.map((dog) => dog.id), <String>['dog-b']);
  });

  test('session dog visibility hides revoked shared access', () {
    final visibleDogs = visibleSessionDogsForUser(
      dogs: <Dog>[
        _buildDog(
          id: 'shared-dog',
          dogKey: 'SHARED-DOG',
          name: 'Shared',
          ownerUserId: 'owner-user',
        ),
      ],
      memberships: <DogMembership>[
        _membership(
          dogKey: 'SHARED-DOG',
          userId: 'viewer-user',
          role: Role.viewer,
          status: Status.revoked,
        ),
      ],
      currentUserId: 'viewer-user',
    );

    expect(visibleDogs, isEmpty);
  });
}

Dog _buildDog({
  required String id,
  required String dogKey,
  required String name,
  required String ownerUserId,
  DateTime? deletedAt,
}) {
  return Dog(
    id: id,
    name: name,
    dogKey: dogKey,
    regNrDisplay: 'NO123/45',
    ownerUserId: ownerUserId,
    updatedAt: DateTime.utc(2024, 1, 1, 12),
    deletedAt: deletedAt,
  );
}

DogMembership _membership({
  required String dogKey,
  required String userId,
  required Role role,
  required Status status,
}) {
  return DogMembership(
    dogKey: dogKey,
    userId: userId,
    role: role,
    status: status,
    addedAt: DateTime.utc(2024, 1, 1, 12),
    addedByUserId: 'owner-user',
  );
}
