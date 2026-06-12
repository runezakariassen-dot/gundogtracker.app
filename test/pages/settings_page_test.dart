import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/pages/settings_page.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/data/hive_path_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String tempDirPath;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('settings_page_');
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

  Future<void> pumpSettingsPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> scrollToDiagnostics(WidgetTester tester) async {
    await tester.dragUntilVisible(
      find.text('Diagnostikk'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pump();
  }

  Future<void> dragUntilTextVisible(
    WidgetTester tester,
    String text,
  ) async {
    await tester.dragUntilVisible(
      find.text(text),
      find.byType(ListView).first,
      const Offset(0, -250),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('debug section renders collapsed', (tester) async {
    await pumpSettingsPage(tester);
    await scrollToDiagnostics(tester);

    expect(find.text('Diagnostikk'), findsOneWidget);
    expect(find.text('Avansert diagnostikk'), findsOneWidget);
    expect(find.text('Kjør synkkø nå'), findsNothing);
  });

  testWidgets('debug tools are still available when diagnostics expands',
      (tester) async {
    await pumpSettingsPage(tester);
    await scrollToDiagnostics(tester);

    await tester.tap(find.text('Avansert diagnostikk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Hent hunder på nytt'), findsOneWidget);
    expect(find.text('Sjekk økter i skyen'), findsOneWidget);
    expect(find.text('Legg tilbake økter lokalt'), findsOneWidget);
    expect(find.text('Kjør synkkø nå'), findsOneWidget);
    expect(find.text('Nullstill feilede synkoppgaver'), findsOneWidget);
    expect(find.text('Outbox'), findsOneWidget);
  });

  testWidgets('normal settings content still renders', (tester) async {
    await pumpSettingsPage(tester);

    expect(find.text('Innlogget som'), findsOneWidget);
    await dragUntilTextVisible(tester, 'Utseende');
    expect(find.text('Utseende'), findsOneWidget);
    await dragUntilTextVisible(tester, 'Logg ut');
    expect(find.text('Logg ut'), findsOneWidget);
  });
}
