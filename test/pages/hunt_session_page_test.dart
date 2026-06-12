// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/hunt_session_page.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('session page visible dogs are scoped to current user', () {
    final visibleDogs = visibleDogsForSessionPage(
      dogs: <Dog>[
        Dog(
          id: 'old-dog',
          name: 'Gammel Testhund',
          dogKey: 'DOG-OLD',
          regNrDisplay: 'NO111/11',
          ownerUserId: 'user-old',
        ),
        Dog(
          id: 'new-dog',
          name: 'Ny Brukerhund',
          dogKey: 'DOG-NEW',
          regNrDisplay: 'NO222/22',
          ownerUserId: 'user-new',
        ),
      ],
      memberships: <DogMembership>[
        DogMembership(
          dogKey: 'DOG-OLD',
          userId: 'user-old',
          role: Role.owner,
          status: Status.active,
          addedAt: DateTime.utc(2024, 1, 1),
          addedByUserId: 'user-old',
        ),
        DogMembership(
          dogKey: 'DOG-NEW',
          userId: 'user-new',
          role: Role.owner,
          status: Status.active,
          addedAt: DateTime.utc(2024, 1, 1),
          addedByUserId: 'user-new',
        ),
      ],
      currentUserId: 'user-new',
      currentUserIds: const <String>{'user-new'},
    );

    expect(visibleDogs.map((dog) => dog.id), ['new-dog']);
  });

  test('session dog visibility matches current user access', () {
    final visibleDogs = visibleDogsForSessionPage(
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
      currentUserIds: const <String>{'user-b'},
    );

    expect(visibleDogs.map((dog) => dog.id), <String>['dog-b']);
  });

  test('session dog visibility hides revoked shared access', () {
    final visibleDogs = visibleDogsForSessionPage(
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
      currentUserIds: const <String>{'viewer-user'},
    );

    expect(visibleDogs, isEmpty);
  });

  group('HuntSessionPage', () {
    late String tempDirPath;

    setUp(() async {
      PackageInfo.setMockInitialValues(
        appName: 'Jakthund',
        packageName: 'jakthund_app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: 'test',
      );
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

    test('session page has no visible dogs when local cache is empty', () {
      final visibleDogs = visibleDogsForSessionPage(
        dogs: const <Dog>[],
        memberships: const <DogMembership>[],
        currentUserId: 'user-1',
        currentUserIds: const <String>{'user-1'},
      );

      expect(visibleDogs, isEmpty);
    });

    // TODO: Move to hunt_session_page_datetime_test.dart after verification
    // testWidgets('new session form shows default date and time controls',
    //     (tester) async {
    //   final dogsBox = Hive.box<Dog>('dogsBox_v2');
    //   await dogsBox.put(
    //     'dog-1',
    //     Dog(
    //       id: 'dog-1',
    //       name: 'Luna',
    //       dogKey: 'DOG-1',
    //       regNrDisplay: 'NO100/01',
    //     ),
    //   );
    //
    //   await tester.pumpWidget(
    //     const MaterialApp(
    //       locale: Locale('nb'),
    //       localizationsDelegates: AppLocalizations.localizationsDelegates,
    //       supportedLocales: AppLocalizations.supportedLocales,
    //       home: HuntSessionPage(
    //         showSessionList: false,
    //         autoStartNow: true,
    //       ),
    //     ),
    //   );
    //   await _pumpUi(tester);
    //
    //   expect(find.byKey(const Key('sessionDateButton')), findsOneWidget);
    //   expect(find.byKey(const Key('sessionTimeButton')), findsOneWidget);
    //
    //   final now = DateTime.now();
    //   final expectedDate = DateFormat.yMd('nb').format(now);
    //   expect(find.text(expectedDate), findsOneWidget);
    //   expect(find.textContaining(RegExp(r'\d{1,2}:\d{2}')), findsWidgets);
    // });
    //
    // testWidgets('new session saves default dateTime near now', (tester) async {
    //   final dogsBox = Hive.box<Dog>('dogsBox_v2');
    //   final sessionsBox = Hive.box<HuntSession>('sessionsBox_v2');
    //   await dogsBox.put(
    //     'dog-1',
    //     Dog(
    //       id: 'dog-1',
    //       name: 'Luna',
    //       dogKey: 'DOG-1',
    //       regNrDisplay: 'NO100/01',
    //     ),
    //   );
    //
    //   await tester.pumpWidget(
    //     const MaterialApp(
    //       locale: Locale('nb'),
    //       localizationsDelegates: AppLocalizations.localizationsDelegates,
    //       supportedLocales: AppLocalizations.supportedLocales,
    //       home: HuntSessionPage(
    //         showSessionList: false,
    //         autoStartNow: true,
    //       ),
    //     ),
    //   );
    //   await _pumpUi(tester);
    //
    //   final beforeSave = DateTime.now();
    //   final context = tester.element(find.byType(HuntSessionPage));
    //   final l10n = AppLocalizations.of(context)!;
    //   await tester.tap(find.text(l10n.session_save_button));
    //   await _pumpUi(tester);
    //
    //   expect(sessionsBox.values.length, 1);
    //   final saved = sessionsBox.values.single;
    //   final diff = saved.dateTime.difference(beforeSave).inMinutes.abs();
    //   expect(diff <= 2, isTrue);
    // });
    //
    // testWidgets('user can change session date and time in edit form',
    //     (tester) async {
    //   final dogsBox = Hive.box<Dog>('dogsBox_v2');
    //   final sessionsBox = Hive.box<HuntSession>('sessionsBox_v2');
    //   await dogsBox.put(
    //     'dog-1',
    //     Dog(
    //       id: 'dog-1',
    //       name: 'Luna',
    //       dogKey: 'DOG-1',
    //       regNrDisplay: 'NO100/01',
    //     ),
    //   );
    //   final sessionKey = await sessionsBox.add(
    //     HuntSession(
    //       dogId: 'dog-1',
    //       dateTime: DateTime(2024, 1, 10, 8, 0),
    //       location: 'Fjell',
    //       durationMinutes: 30,
    //       birdsSeen: 1,
    //       points: 1,
    //       flushes: 0,
    //       notes: '',
    //     ),
    //   );
    //
    //   await tester.pumpWidget(
    //     MaterialApp(
    //       locale: const Locale('nb'),
    //       localizationsDelegates: AppLocalizations.localizationsDelegates,
    //       supportedLocales: AppLocalizations.supportedLocales,
    //       home: HuntSessionPage(
    //         showSessionList: false,
    //         showNewSessionSection: false,
    //         editSessionKey: sessionKey,
    //       ),
    //     ),
    //   );
    //   await _pumpUi(tester);
    //
    //   await tester.tap(find.byKey(const Key('sessionDateButton')));
    //   await _pumpUi(tester);
    //   await tester.tap(find.text('15').last);
    //   await _pumpUi(tester);
    //   await tester.tap(find.text('OK').last);
    //   await _pumpUi(tester);
    //
    //   await tester.tap(find.byKey(const Key('sessionTimeButton')));
    //   await _pumpUi(tester);
    //   await tester.tap(find.text('11').last);
    //   await _pumpUi(tester);
    //   await tester.tap(find.text('OK').last);
    //   await _pumpUi(tester);
    //
    //   final context = tester.element(find.byType(HuntSessionPage));
    //   final l10n = AppLocalizations.of(context)!;
    //   await tester.tap(find.text(l10n.session_detail_action_save_changes));
    //   await _pumpUi(tester);
    //
    //   final saved = sessionsBox.get(sessionKey);
    //   expect(saved, isNotNull);
    //   expect(saved!.dateTime.day, 15);
    //   expect(saved.dateTime.hour, 11);
    // });
  });

  // TODO: Move to hunt_session_page_datetime_test.dart after verification
  // testWidgets('session list displays date and time in dd.MM.yyyy HH:mm format',
  //     (tester) async {
  //   final sessionDate = DateTime(2025, 9, 28, 10, 45);
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: _SessionDateListTestView(
  //           sessions: <_SessionDateRow>[
  //             _SessionDateRow(
  //               dateTime: sessionDate,
  //               durationMinutes: 90,
  //               birdsSeen: 3,
  //               points: 5,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 100));
  //
  //   final expectedDateText = DateFormat('dd.MM.yyyy HH:mm').format(sessionDate);
  //   expect(find.text(expectedDateText), findsOneWidget);
  //   expect(find.text('90'), findsOneWidget);
  //   expect(find.text('3'), findsOneWidget);
  //   expect(find.text('5'), findsOneWidget);
  // });
  //
  // testWidgets('session list displays multiple sessions with correct date-times',
  //     (tester) async {
  //   final date1 = DateTime(2025, 9, 25, 7, 30);
  //   final date2 = DateTime(2025, 9, 28, 18, 5);
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: _SessionDateListTestView(
  //           sessions: <_SessionDateRow>[
  //             _SessionDateRow(
  //               dateTime: date1,
  //               durationMinutes: 60,
  //               birdsSeen: 2,
  //               points: 4,
  //             ),
  //             _SessionDateRow(
  //               dateTime: date2,
  //               durationMinutes: 90,
  //               birdsSeen: 3,
  //               points: 5,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 100));
  //
  //   final expectedDate1 = DateFormat('dd.MM.yyyy HH:mm').format(date1);
  //   final expectedDate2 = DateFormat('dd.MM.yyyy HH:mm').format(date2);
  //
  //   expect(find.text(expectedDate1), findsOneWidget);
  //   expect(find.text(expectedDate2), findsOneWidget);
  // });
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
