import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/milestones/milestone_catalog.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/milestones/milestone_models.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/ui/milestones/milestone_celebration_overlay.dart';
import 'package:jakthund_app/widgets/flying_birds_widget.dart';

import '../test_app.dart';
import '../test_hive_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await initHiveForTests(prefix: 'jakthund_test_overlay_');
  });

  tearDownAll(() async {
    await teardownHiveForTests(tempDir);
  });

  setUp(() async {
    debugResetMilestoneCelebrationState();
    await Hive.box<dynamic>(appSettingsBoxName).clear();
    await Hive.box<DateTime>(milestoneSeenBoxName).clear();
    await Hive.box<DogMilestoneState>(dogMilestoneStateBoxName).clear();
    await Hive.box<dynamic>(appSettingsBoxName).put(hapticsEnabledKey, false);
    await Hive.box<dynamic>(appSettingsBoxName).put(soundOnMilestoneKey, false);
  });

  tearDown(() {
    debugResetMilestoneCelebrationState();
  });

  testWidgets('celebration can trigger without crash', (tester) async {
    await _pumpHost(tester);

    final future = _OverlayHost.openCelebration();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(MilestoneCelebrationOverlay), findsOneWidget);
    expect(debugIsMilestoneCelebrationRunning(), isTrue);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await future;
  });

  testWidgets(
    'repeated trigger while celebration is running does not create another overlay',
    (tester) async {
      await _pumpHost(tester);

      final first = _OverlayHost.openCelebration();
      final second = _OverlayHost.openCelebration();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(second, same(first));
      expect(find.byType(MilestoneCelebrationOverlay), findsOneWidget);
      expect(find.byType(FlyingBirdsWidget), findsNWidgets(5));
      expect(debugIsMilestoneCelebrationRunning(), isTrue);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await first;
    },
  );

  testWidgets('widget dispose rydder opp controllers og timer', (tester) async {
    await _pumpHost(tester);

    final future = _OverlayHost.openCelebration();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await future;

    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(MilestoneCelebrationOverlay), findsNothing);
    expect(debugIsMilestoneCelebrationRunning(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new celebration after previous completion works',
      (tester) async {
    await _pumpHost(tester);

    final first = _OverlayHost.openCelebration();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();
    await first;

    expect(debugIsMilestoneCelebrationRunning(), isFalse);

    final second = _OverlayHost.openCelebration();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(MilestoneCelebrationOverlay), findsOneWidget);
    expect(debugIsMilestoneCelebrationRunning(), isTrue);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await second;
  });

  testWidgets('celebration rendering remains intact with upward birds',
      (tester) async {
    await _pumpHost(tester, size: const Size(1024, 768));

    final future = _OverlayHost.openCelebration();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final birdWidgets =
        tester.widgetList<FlyingBirdsWidget>(find.byType(FlyingBirdsWidget));

    expect(find.textContaining('Birk'), findsOneWidget);
    expect(find.text('01.01.2024 12:00'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(birdWidgets.length, 5);
    expect(
      birdWidgets.every((widget) => widget.origin.y > 0.8),
      isTrue,
    );
    expect(
      birdWidgets.every((widget) => widget.blastDirection < 0),
      isTrue,
    );
    expect(
      birdWidgets.any((widget) => widget.blastDirection == -math.pi / 2),
      isTrue,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await future;
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpApp(
    tester,
    child: const Scaffold(
      body: _OverlayHost(),
    ),
  );
}

class _OverlayHost extends StatefulWidget {
  const _OverlayHost();

  static late Future<void> Function() openCelebration;

  @override
  State<_OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<_OverlayHost> {
  @override
  void initState() {
    super.initState();
    _OverlayHost.openCelebration = () {
      return showMilestoneCelebrationOverlay(
        context: context,
        def: _milestoneDef(),
        dog: _dog(),
        achievedAt: DateTime(2024, 1, 1, 12, 0),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

MilestoneDef _milestoneDef() {
  return milestoneCatalog
      .firstWhere((config) => config.def.id == MilestoneId.sessions1)
      .def;
}

Dog _dog() {
  return Dog(
    id: 'dog-1',
    name: 'Birk',
    dogKey: 'dog-key-1',
    regNrDisplay: 'NO12345/24',
  );
}
