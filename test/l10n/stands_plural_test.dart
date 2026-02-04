import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

Future<AppLocalizations> _loadNbLocalizations() async {
  final delegate = AppLocalizations.delegate;
  const locale = Locale('nb');
  final localizations = await delegate.load(locale);
  return localizations;
}

void main() {
  testWidgets('standsCount pluralizes correctly', (tester) async {
    final l10n = await _loadNbLocalizations();
    expect(l10n.standsCount(0), '0 stander');
    expect(l10n.standsCount(1), '1 stand');
    expect(l10n.standsCount(2), '2 stander');
    expect(l10n.standsCount(10), '10 stander');
    expect(l10n.standsCount(100), '100 stander');
    expect(l10n.standsCount(200), '200 stander');
  });
}
