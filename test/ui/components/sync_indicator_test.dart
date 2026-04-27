import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/services/cloud/sync_status_service.dart';
import 'package:jakthund_app/ui/components/sync_indicator.dart';

void main() {
  Future<void> pumpIndicator(
    WidgetTester tester,
    SyncStatus status,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SyncIndicator(status: status),
          ),
        ),
      ),
    );
  }

  testWidgets('renders synced indicator', (tester) async {
    await pumpIndicator(tester, SyncStatus.synced);

    final icon = tester.widget<Icon>(find.byIcon(Icons.cloud_done));
    expect(icon.color, Colors.green);
  });

  testWidgets('renders pending indicator', (tester) async {
    await pumpIndicator(tester, SyncStatus.pending);

    final icon = tester.widget<Icon>(find.byIcon(Icons.cloud_queue));
    expect(icon.color, Colors.grey);
  });

  testWidgets('renders in-progress indicator', (tester) async {
    await pumpIndicator(tester, SyncStatus.inProgress);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders failed indicator', (tester) async {
    await pumpIndicator(tester, SyncStatus.failed);

    final icon = tester.widget<Icon>(find.byIcon(Icons.error));
    expect(icon.color, Colors.red);
  });
}
