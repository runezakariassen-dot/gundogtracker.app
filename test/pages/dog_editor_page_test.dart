import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
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
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    final tempDir = Directory(tempDirPath);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
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
