import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Smoke: kan bygge et enkelt widget-tre',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('ok')),
          ),
        ),
      );

      expect(find.text('ok'), findsOneWidget);
    },
    tags: ['ci'],
  );
}
