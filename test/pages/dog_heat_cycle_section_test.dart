import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/local_health_record_repository.dart';
import 'package:jakthund_app/domain/dogs/dog_heat_cycle_repository.dart';
import 'package:jakthund_app/domain/domain_constants.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_heat_cycle_log.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/dog_sex.dart';
import 'package:jakthund_app/models/health_record.dart';
import 'package:jakthund_app/pages/dog_health_journal_page.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late Box<HealthRecord> healthBox;
  late Box<DogMembership> membershipBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('heat_cycle_widget_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(HealthRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(RoleAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(StatusAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(DogMembershipAdapter());
    }
    settingsBox = await Hive.openBox<dynamic>('settings');
    healthBox = await Hive.openBox<HealthRecord>('health');
    membershipBox = await Hive.openBox<DogMembership>(dogMembershipsBoxName);
  });

  tearDown(() async {
    await membershipBox.close();
    await healthBox.close();
    await settingsBox.close();
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Dog dog(DogSex sex) => Dog(
        id: 'dog-1',
        name: 'Luna',
        dogKey: 'DOG-1',
        regNrDisplay: '',
        sex: sex,
      );

  Future<void> pumpJournal(
    WidgetTester tester,
    Dog selectedDog, {
    DogHeatCycleRepository? heatCycleRepository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogHealthJournalPage(
          dog: selectedDog,
          repository: LocalHealthRecordRepository(box: healthBox),
          heatCycleRepository:
              heatCycleRepository ?? _MemoryHeatCycleRepository(settingsBox),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> disposeJournal(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('female journal shows heat cycles above empty health records',
      (tester) async {
    await pumpJournal(tester, dog(DogSex.female));

    expect(find.byKey(const Key('dog_heat_cycle_section')), findsOneWidget);
    expect(find.text('Ingen helseoppføringer ennå'), findsOneWidget);

    await disposeJournal(tester);
  });

  testWidgets('male journal does not show heat cycles', (tester) async {
    await pumpJournal(tester, dog(DogSex.male));

    expect(find.byKey(const Key('dog_heat_cycle_section')), findsNothing);
    expect(find.text('Ingen helseoppføringer ennå'), findsOneWidget);

    await disposeJournal(tester);
  });

  testWidgets('existing heat cycle remains visible and supports CRUD',
      (tester) async {
    final repository = _MemoryHeatCycleRepository(settingsBox);
    final existing = DogHeatCycleLog(
      dogId: 'dog-1',
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 1, 25),
      note: 'Opprinnelig notat',
      createdAt: DateTime.utc(2026, 1, 10, 8),
      updatedAt: DateTime.utc(2026, 1, 10, 8),
    );
    await repository.saveForDog(existing);
    await pumpJournal(
      tester,
      dog(DogSex.female),
      heatCycleRepository: repository,
    );

    expect(find.text('10.01.2026 - 25.01.2026'), findsOneWidget);
    expect(find.text('Opprinnelig notat'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dog_heat_cycle_add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Lagre'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await repository.listForDog('dog-1'), hasLength(2));

    await tester.tap(find.text('Rediger').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'Oppdatert notat');
    await tester.tap(find.text('Lagre'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    var entries = await repository.listForDog('dog-1');
    expect(
      entries
          .singleWhere((entry) => entry.createdAt == existing.createdAt)
          .note,
      'Oppdatert notat',
    );

    await tester.tap(find.text('Slett').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Slett').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    entries = await repository.listForDog('dog-1');
    expect(entries, hasLength(1));
    expect(
      entries.where((entry) => entry.createdAt == existing.createdAt),
      isEmpty,
    );

    await disposeJournal(tester);
  });

  testWidgets('shared viewer can read history but cannot write',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox.put(currentUserIdKey, 'viewer-user');
      await membershipBox.put(
        'DOG-1::viewer-user',
        DogMembership(
          dogKey: 'DOG-1',
          userId: 'viewer-user',
          role: Role.viewer,
          status: Status.active,
          addedAt: DateTime.utc(2026, 1, 1),
          addedByUserId: 'owner-user',
        ),
      );
    });

    final repository = _MemoryHeatCycleRepository(settingsBox);
    await repository.saveForDog(
      DogHeatCycleLog(
        id: 'heat-viewer',
        dogId: 'dog-1',
        startDate: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 1, 25),
        note: 'Synlig for viewer',
        createdAt: DateTime.utc(2026, 1, 10, 8),
        updatedAt: DateTime.utc(2026, 1, 10, 8),
      ),
    );
    await pumpJournal(
      tester,
      dog(DogSex.female).copyWith(ownerUserId: 'owner-user'),
      heatCycleRepository: repository,
    );

    expect(find.text('10.01.2026 - 25.01.2026'), findsOneWidget);
    expect(find.text('Synlig for viewer'), findsOneWidget);

    final addButton = tester
        .widget<FilledButton>(find.byKey(const Key('dog_heat_cycle_add')));
    expect(addButton.onPressed, isNull);
    final editButton =
        tester.widget<OutlinedButton>(find.byType(OutlinedButton).first);
    expect(editButton.onPressed, isNull);

    await disposeJournal(tester);
  });
}

class _MemoryHeatCycleRepository extends DogHeatCycleRepository {
  _MemoryHeatCycleRepository(Box<dynamic> box) : super(box: box);

  final List<DogHeatCycleLog> _entries = [];

  @override
  Future<List<DogHeatCycleLog>> listForDog(
    String dogId, {
    bool includeDeleted = false,
  }) async {
    final entries = _entries
        .where((entry) =>
            entry.dogId == dogId && (includeDeleted || !entry.isDeleted))
        .toList();
    entries.sort((a, b) => b.startDate.compareTo(a.startDate));
    return entries;
  }

  @override
  Future<void> saveForDog(
    DogHeatCycleLog entry, {
    bool enqueueSync = true,
  }) async {
    final index = _entries.indexWhere(
      (existing) =>
          (existing.id != null &&
              entry.id != null &&
              existing.id == entry.id) ||
          existing.createdAt.toUtc() == entry.createdAt.toUtc(),
    );
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
  }

  @override
  Future<void> deleteForDog({
    required String dogId,
    required DateTime createdAt,
    bool enqueueSync = true,
  }) async {
    final index = _entries.indexWhere(
      (entry) =>
          entry.dogId == dogId && entry.createdAt.toUtc() == createdAt.toUtc(),
    );
    if (index >= 0) {
      final now = DateTime.now().toUtc();
      _entries[index] =
          _entries[index].copyWith(updatedAt: now, deletedAt: now);
    }
  }
}
