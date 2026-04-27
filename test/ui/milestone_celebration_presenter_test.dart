import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/ui/milestones/milestone_celebration_presenter.dart';

import '../test_hive_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const closeButtonKey = Key('milestone_info_close_button');

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await initHiveForTests(prefix: 'jakthund_test_milestone_');
  });

  tearDownAll(() async {
    await teardownHiveForTests(tempDir);
  });

  setUp(() async {
    await Hive.box<dynamic>(appSettingsBoxName).clear();
    await Hive.box<DateTime>(milestoneSeenBoxName).clear();
    await Hive.box<DogMilestoneState>(dogMilestoneStateBoxName).clear();
  });

  testWidgets('milestone info auto-dismisses after 5 seconds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _TestHost(),
        ),
      ),
    );

    _TestHost.showInfo();

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Ny milepæl!'), findsOneWidget);
    expect(find.text('Birk: Første økt'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4800));
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual dismiss before timeout gives no double dismiss',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _TestHost(),
        ),
      ),
    );

    _TestHost.showInfo();

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(find.byKey(closeButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(seconds: 6));
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated show and dismiss works without crash', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _TestHost(),
        ),
      ),
    );

    _TestHost.showInfo();
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(closeButtonKey));
    await tester.pumpAndSettle();

    _TestHost.showInfo();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(closeButtonKey));
    await tester.pumpAndSettle();
  });
}

class _TestHost extends StatefulWidget {
  const _TestHost();

  static late void Function() showInfo;

  @override
  State<_TestHost> createState() => _TestHostState();
}

class _TestHostState extends State<_TestHost> {
  @override
  void initState() {
    super.initState();

    _TestHost.showInfo = () {
      MilestoneCelebrationPresenter.showMilestoneInfoSnackBar(
        context: context,
        leading: const Icon(Icons.emoji_events),
        title: 'Ny milepæl!',
        summary: 'Birk: Første økt',
        actionLabel: 'Se milepæler',
        onAction: () {},
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
