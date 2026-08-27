import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/local_health_record_repository.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/health_record.dart';
import 'package:jakthund_app/pages/dog_health_journal_page.dart';
import 'package:jakthund_app/pages/health_record_form_page.dart';

void main() {
  late Directory tempDir;
  late Box<HealthRecord> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('health_journal_page_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(HealthRecordAdapter());
    }
    box = await Hive.openBox<HealthRecord>('health_journal_page_test');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets('shows the localized empty state', (tester) async {
    final dog = Dog(
      id: 'dog-1',
      name: 'Luna',
      dogKey: 'DOG-1',
      regNrDisplay: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogHealthJournalPage(
          dog: dog,
          repository: LocalHealthRecordRepository(box: box),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ingen helseoppføringer ennå'), findsOneWidget);
    expect(find.text('Legg til oppføring'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
  });

  testWidgets('reloads only when the form returns true', (tester) async {
    final repository = _CountingRepository(box);
    final dog = Dog(
      id: 'dog-1',
      name: 'Luna',
      dogKey: 'DOG-1',
      regNrDisplay: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogHealthJournalPage(dog: dog, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.listCalls, 1);

    await tester.tap(find.text('Legg til oppføring'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(HealthRecordFormPage))).pop(true);
    await tester.pumpAndSettle();
    expect(repository.listCalls, 2);

    await tester.tap(find.text('Legg til oppføring'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(HealthRecordFormPage))).pop(false);
    await tester.pumpAndSettle();
    expect(repository.listCalls, 2);

    await tester.tap(find.text('Legg til oppføring'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(HealthRecordFormPage))).pop();
    await tester.pumpAndSettle();
    expect(repository.listCalls, 2);
  });
}

class _CountingRepository extends LocalHealthRecordRepository {
  _CountingRepository(Box<HealthRecord> box) : super(box: box);

  int listCalls = 0;

  @override
  List<HealthRecord> listByDogId(
    String dogId, {
    bool includeDeleted = false,
  }) {
    listCalls++;
    return super.listByDogId(dogId, includeDeleted: includeDeleted);
  }
}
