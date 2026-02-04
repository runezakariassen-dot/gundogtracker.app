import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/ui/home/widgets/top10_points_card.dart';

import '../test_hive_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await initHiveForTests(prefix: 'jakthund_test_top10_');
  });

  tearDownAll(() async {
    await teardownHiveForTests(tempDir);
  });

  setUp(() async {
    await Hive.box<DogMilestoneState>(dogMilestoneStateBoxName).clear();
  });

  testWidgets('Top10 card shows localized label and long name', (tester) async {
    final dog = Dog(
      id: 'dog-long',
      name: 'Super Long Dog Name That Wraps',
      dogKey: 'dog-long',
      regNrDisplay: '123',
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('nb'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Material(
              child: Center(
                child: Top10PointsCard(
                  rank: 1,
                  dog: dog,
                  totalPoints: 1,
                  fieldLabel: l10n.standsLabel,
                  valueLabel: l10n.standsCount(1),
                  onTap: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final localizations =
        await AppLocalizations.delegate.load(const Locale('nb'));
    expect(find.text(localizations.standsLabel), findsOneWidget);
    expect(find.text(localizations.standsCount(1)), findsOneWidget);

    final nameFinder = find.text('Super Long Dog Name That Wraps');
    expect(nameFinder, findsOneWidget);
  });
}
