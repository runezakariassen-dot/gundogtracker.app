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

  testWidgets(
    'milestone presenter shows snackbar with scope',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestHost(),
          ),
        ),
      );

      _TestHost.showSnack();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Milestone!'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
    },
    tags: ['slow'],
  );
}

class _TestHost extends StatefulWidget {
  const _TestHost();

  static late void Function() showSnack;

  @override
  State<_TestHost> createState() => _TestHostState();
}

class _TestHostState extends State<_TestHost> {
  @override
  void initState() {
    super.initState();

    _TestHost.showSnack = () {
      MilestoneCelebrationPresenter.showSnackBar(
        context: context,
        text: 'Milestone!',
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
