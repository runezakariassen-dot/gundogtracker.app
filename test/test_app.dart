import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

/// Pumps a minimal MaterialApp for widget tests with NB locale as default.
///
/// IMPORTANT:
/// - This is test-only.
/// - No app logic changes.
/// - Keeps UI tests stable/predictable by forcing Locale('nb').
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  NavigatorObserver? navigatorObserver,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('nb'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      navigatorObservers: <NavigatorObserver>[
        if (navigatorObserver != null) navigatorObserver,
      ],
      home: Material(
        child: child,
      ),
    ),
  );

  // Let localization + initial frames settle.
  await tester.pumpAndSettle();
}
