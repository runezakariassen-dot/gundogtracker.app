import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/data/local/local_membership_repository.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/dogs/dog_visibility.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/pages/dog_editor_page.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String tempDirPath;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('dog_editor_');
    tempDirPath = tempDir.path;
    HivePathService.setOverridePathForTesting(tempDirPath);
    HiveLifecycleService.resetForTesting();
    await HivePathService.init();
    registerDomainAdapters();
    await HiveLifecycleService.init();
  });

  tearDown(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Avoid hanging widget tests if Hive cleanup stalls.
    }
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    final tempDir = Directory(tempDirPath);
    if (await tempDir.exists()) {
      try {
        await tempDir
            .delete(recursive: true)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best-effort cleanup only.
      }
    }
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _DogEditorTestHost(),
      ),
    );
    await tester.pump();
  }

  testWidgets('dog editor asks before leaving with unsaved changes',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Åpne editor'));
    await tester.pumpAndSettle();

    expect(find.text('Legg til hunden din'), findsOneWidget);
    expect(
      find.text(
        'Du kan begynne enkelt nå. Navn er nok for å komme i gang, og flere detaljer kan legges inn senere.',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, 'Birk');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Forkast endringer?'), findsOneWidget);
    expect(find.text('Endringene er ikke lagret ennå.'), findsOneWidget);

    await tester.tap(find.text('Avbryt'));
    await tester.pumpAndSettle();

    expect(find.text('Legg til hund'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forkast'));
    await tester.pumpAndSettle();

    expect(find.text('Åpne editor'), findsOneWidget);
    expect(find.text('Legg til hund'), findsNothing);
  });

  testWidgets('dog editor closes directly when nothing changed',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Åpne editor'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Åpne editor'), findsOneWidget);
    expect(find.text('Forkast endringer?'), findsNothing);
  });

  testWidgets('memorial story field appears only when marked deceased',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Åpne editor'));
    await tester.pumpAndSettle();

    expect(find.text('Historie / minne'), findsNothing);

    final deceasedToggleFinder = find.byType(SwitchListTile);
    await tester.dragUntilVisible(
      deceasedToggleFinder,
      find.byType(Scrollable).first,
      const Offset(0, -250),
    );
    await tester.tap(deceasedToggleFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('Historie / minne'), findsOneWidget);

    await tester.tap(deceasedToggleFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('Historie / minne'), findsNothing);
  });

  test('global dog delete is allowed for owner membership only', () {
    final dog = _testDog();
    final memberships = _sharedDogMemberships(dog);

    expect(
      canGloballyDeleteDog(
        dog: dog,
        memberships: memberships,
        userIds: const <String>['owner-a'],
      ),
      isTrue,
    );
    expect(
      canGloballyDeleteDog(
        dog: dog,
        memberships: memberships,
        userIds: const <String>['member-b'],
      ),
      isFalse,
    );
    expect(
      canGloballyDeleteDog(
        dog: dog,
        memberships: memberships,
        userIds: const <String>['member-c'],
      ),
      isFalse,
    );
  });

  test('shared membership can be resolved without owner delete access', () {
    final dog = _testDog();
    final memberships = _sharedDogMemberships(dog);

    final sharedMembership = activeSharedMembershipForUser(
      dog: dog,
      memberships: memberships,
      userIds: const <String>['member-b'],
    );

    expect(sharedMembership?.userId, 'member-b');
    expect(sharedMembership?.role, Role.editor);
    expect(
      activeSharedMembershipForUser(
        dog: dog,
        memberships: memberships,
        userIds: const <String>['owner-a'],
      ),
      isNull,
    );
  });

  test('shared user local remove revokes only own membership', () async {
    final dog = await _seedSharedDogForUser('member-b');
    final membership = activeSharedMembershipForUser(
      dog: dog,
      memberships: dogMembershipsBox().values,
      userIds: const <String>['member-b'],
    );

    expect(membership, isNotNull);

    final membershipRepository = LocalDogMembershipRepository();
    await membershipRepository.upsertMembership(
      membership!.copyWith(status: Status.revoked),
    );

    final ownerMembership =
        await membershipRepository.getMembership(dog.dogKey, 'owner-a');
    final sharedMembership =
        await membershipRepository.getMembership(dog.dogKey, 'member-b');

    expect(ownerMembership?.status, Status.active);
    expect(sharedMembership?.status, Status.revoked);
    expect(dogsBox().values.single.deletedAt, isNull);
    expect(
      syncTasksBox()
          .values
          .where((task) => task.entityType == 'dog_delete')
          .toList(growable: false),
      isEmpty,
    );

    expect(
      filterVisibleDogs(
        dogs: dogsBox().values,
        memberships: dogMembershipsBox()
            .values
            .where((membership) => membership.userId == 'member-b'),
        currentUserId: 'member-b',
      ),
      isEmpty,
    );
    expect(
      filterVisibleDogs(
        dogs: dogsBox().values,
        memberships: dogMembershipsBox()
            .values
            .where((membership) => membership.userId == 'owner-a'),
        currentUserId: 'owner-a',
      ).single.id,
      dog.id,
    );
  });

  testWidgets(
      'shared remove still revokes locally when cloud revoke fails and does not enqueue dog_delete',
      (tester) async {
    final dog = (await tester.runAsync(() async {
      final seeded = await _seedSharedDogForUser('member-b');
      final updated =
          seeded.copyWith(cloudId: '333e8028-8184-4d47-95ab-0d602a6b961e');
      final dogHiveEntry = dogsBox().toMap().entries.firstWhere(
            (entry) => entry.value.id == updated.id,
          );
      await dogsBox().put(dogHiveEntry.key, updated);
      return updated;
    }))!;

    String? calledCanonicalPath;
    DogMembership? locallyRevokedMembership;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _SharedDogEditorTestHost(
          dog: dog,
          upsertMembershipOverride: (membership) async {
            locallyRevokedMembership = membership;
          },
          revokeSharedDogMembership: ({
            required dog,
            required membership,
          }) async {
            calledCanonicalPath =
                'dogs/${dog.cloudId ?? dog.id}/members/${membership.userId}';
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Åpne delt editor'));
    await tester.pumpAndSettle();
    await _tapRemoveSharedDog(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fjern'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      calledCanonicalPath,
      'dogs/333e8028-8184-4d47-95ab-0d602a6b961e/members/member-b',
    );
    expect(locallyRevokedMembership?.status, Status.revoked);
    expect(locallyRevokedMembership?.userId, 'member-b');
    expect(dogsBox().values.single.deletedAt, isNull);
    expect(
      syncTasksBox()
          .values
          .where((task) => task.entityType == 'dog_delete')
          .toList(growable: false),
      isEmpty,
    );
    expect(find.byType(DogEditorPage), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shared remove succeeds when cloud revoke succeeds',
      (tester) async {
    final dog = (await tester.runAsync(() async {
      final seeded = await _seedSharedDogForUser('member-b');
      final updated =
          seeded.copyWith(cloudId: '333e8028-8184-4d47-95ab-0d602a6b961e');
      final dogHiveEntry = dogsBox().toMap().entries.firstWhere(
            (entry) => entry.value.id == updated.id,
          );
      await dogsBox().put(dogHiveEntry.key, updated);
      return updated;
    }))!;

    DogMembership? locallyRevokedMembership;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogEditorPage(
          initialDog: dog,
          currentUserIdOverride: 'member-b',
          upsertMembershipOverride: (membership) async {
            locallyRevokedMembership = membership;
          },
          revokeSharedDogMembership: ({
            required dog,
            required membership,
          }) async =>
              true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapRemoveSharedDog(tester);
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('Fjern')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(locallyRevokedMembership?.status, Status.revoked);
    expect(locallyRevokedMembership?.userId, 'member-b');
    expect(
      syncTasksBox()
          .values
          .where((task) => task.entityType == 'dog_delete')
          .toList(growable: false),
      isEmpty,
    );
    expect(dogsBox().values.single.deletedAt, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'shared remove with missing cloudId still revokes locally and does not enqueue dog_delete',
      (tester) async {
    final dog = (await tester.runAsync(
      () => _seedSharedDogForUser('member-b'),
    ))!;

    DogMembership? locallyRevokedMembership;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogEditorPage(
          initialDog: dog,
          currentUserIdOverride: 'member-b',
          upsertMembershipOverride: (membership) async {
            locallyRevokedMembership = membership;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapRemoveSharedDog(tester);
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('Fjern')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(locallyRevokedMembership?.status, Status.revoked);
    expect(locallyRevokedMembership?.userId, 'member-b');
    expect(dogsBox().values.single.deletedAt, isNull);
    expect(
      syncTasksBox()
          .values
          .where((task) => task.entityType == 'dog_delete')
          .toList(growable: false),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shared remove still persists local revoke when cloud throws',
      (tester) async {
    final dog = (await tester.runAsync(() async {
      final seeded = await _seedSharedDogForUser('member-b');
      final updated =
          seeded.copyWith(cloudId: '333e8028-8184-4d47-95ab-0d602a6b961e');
      final dogHiveEntry = dogsBox().toMap().entries.firstWhere(
            (entry) => entry.value.id == updated.id,
          );
      await dogsBox().put(dogHiveEntry.key, updated);
      return updated;
    }))!;

    DogMembership? locallyRevokedMembership;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogEditorPage(
          initialDog: dog,
          currentUserIdOverride: 'member-b',
          upsertMembershipOverride: (membership) async {
            locallyRevokedMembership = membership;
          },
          revokeSharedDogMembership: ({
            required dog,
            required membership,
          }) async {
            throw StateError('cloud write failed');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapRemoveSharedDog(tester);
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('Fjern')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(locallyRevokedMembership?.status, Status.revoked);
    expect(locallyRevokedMembership?.userId, 'member-b');
    expect(dogsBox().values.single.deletedAt, isNull);
    expect(
      syncTasksBox()
          .values
          .where((task) => task.entityType == 'dog_delete')
          .toList(growable: false),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _DogEditorTestHost extends StatelessWidget {
  const _DogEditorTestHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DogEditorPage(),
              ),
            );
          },
          child: const Text('Åpne editor'),
        ),
      ),
    );
  }
}

class _SharedDogEditorTestHost extends StatelessWidget {
  const _SharedDogEditorTestHost({
    required this.dog,
    required this.upsertMembershipOverride,
    required this.revokeSharedDogMembership,
  });

  final Dog dog;
  final UpsertDogMembershipForTesting upsertMembershipOverride;
  final RevokeSharedDogMembership revokeSharedDogMembership;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DogEditorPage(
                  initialDog: dog,
                  currentUserIdOverride: 'member-b',
                  upsertMembershipOverride: upsertMembershipOverride,
                  revokeSharedDogMembership: revokeSharedDogMembership,
                ),
              ),
            );
          },
          child: const Text('Åpne delt editor'),
        ),
      ),
    );
  }
}

Future<void> _tapRemoveSharedDog(WidgetTester tester) async {
  final removeButton = find.text('Fjern fra mine hunder');
  await tester.dragUntilVisible(
    removeButton,
    find.byType(Scrollable).first,
    const Offset(0, -300),
  );
  await tester.tap(removeButton);
}

Future<Dog> _seedSharedDogForUser(String currentUserId) async {
  final dog = _testDog();
  await dogsBox().add(dog);
  final repository = LocalDogMembershipRepository();
  for (final membership in _sharedDogMemberships(dog)) {
    await repository.upsertMembership(membership);
  }
  return dog;
}

Dog _testDog() {
  return Dog(
    id: 'dog-1',
    name: 'Kompis',
    dogKey: 'DOG-1',
    regNrDisplay: 'NO12345/26',
    ownerUserId: 'owner-a',
  );
}

List<DogMembership> _sharedDogMemberships(Dog dog) {
  return <DogMembership>[
    DogMembership(
      dogKey: dog.dogKey,
      userId: 'owner-a',
      role: Role.owner,
      status: Status.active,
      addedAt: DateTime(2026, 5, 1),
      addedByUserId: 'owner-a',
    ),
    DogMembership(
      dogKey: dog.dogKey,
      userId: 'member-b',
      role: Role.editor,
      status: Status.active,
      addedAt: DateTime(2026, 5, 1),
      addedByUserId: 'owner-a',
    ),
    DogMembership(
      dogKey: dog.dogKey,
      userId: 'member-c',
      role: Role.viewer,
      status: Status.active,
      addedAt: DateTime(2026, 5, 1),
      addedByUserId: 'owner-a',
    ),
  ];
}
