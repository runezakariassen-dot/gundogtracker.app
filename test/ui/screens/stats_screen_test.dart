import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type.dart';
import 'package:jakthund_app/ui/screens/stats_screen.dart';
import 'package:jakthund_app/ui/screens/stats_trend_calculator.dart';
import 'package:jakthund_app/data/hive_boxes.dart';

import '../../test_hive_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await initHiveForTests(prefix: 'stats_screen_');
  });

  tearDownAll(() async {
    await teardownHiveForTests(tempDir);
  });

  setUp(() async {
    await Hive.box<HuntSession>(sessionsBoxName).clear();
  });

  Future<void> pumpStats(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('shows empty state with icon and body when no sessions',
      (tester) async {
    await pumpStats(tester);

    expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
    expect(find.text('Ingen økter registrert enda'), findsOneWidget);
    expect(
      find.text(
        'Registrer din første økt for å se trender og statistikk over tid.',
      ),
      findsOneWidget,
    );
  });

  test('calculates trend result from in-memory sessions without Hive', () {
    final result = StatsTrendCalculator.calculate(
      [
        HuntSession(
          dogId: 'dog-1',
          dateTime: DateTime(2025, 9, 15),
          location: 'Marka',
          durationMinutes: 90,
          birdsSeen: 3,
          points: 5,
          flushes: 2,
          notes: '',
          sessionType: SessionType.hunting,
        ),
        HuntSession(
          dogId: 'dog-2',
          dateTime: DateTime(2025, 9, 18),
          location: 'Fjellet',
          durationMinutes: 60,
          birdsSeen: 1,
          points: 2,
          flushes: 0,
          notes: '',
          sessionType: SessionType.training,
        ),
      ],
      now: () => DateTime(2025, 9, 20),
    );

    expect(result, isNotNull);
    expect(result!.bucket, StatsTrendBucket.daily);
    expect(result.start, DateTime(2025, 9, 15));
    expect(result.points, hasLength(6));
    expect(result.points[0].count, 1);
    expect(result.points[3].count, 1);
    expect(result.points.fold<int>(0, (sum, point) => sum + point.count), 2);
  });
}
