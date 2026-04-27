import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/ui/auth/signup_screen.dart';

void main() {
  Future<void> pumpSignUpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SignUpScreen(),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders localized signup content', (tester) async {
    await pumpSignUpScreen(tester);

    expect(find.text('Opprett konto'), findsNWidgets(2));
    expect(
      find.text('Opprett konto med e-post og passord for å komme i gang.'),
      findsOneWidget,
    );
    expect(find.text('E-post'), findsOneWidget);
    expect(find.text('Passord'), findsOneWidget);
    expect(find.text('Gjenta passord'), findsOneWidget);
  });

  testWidgets('shows friendly validation when submitting empty form',
      (tester) async {
    await pumpSignUpScreen(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Skriv inn e-post.'), findsOneWidget);
    expect(find.text('Skriv inn passord.'), findsOneWidget);
    expect(find.text('Gjenta passordet.'), findsOneWidget);
  });
}
