import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/ui/text/text_helpers.dart';

import '../test_app.dart';

void main() {
  testWidgets('formatDurationBetween returns NB formatted duration',
      (tester) async {
    late AppLocalizations l10n;

    await pumpApp(
      tester,
      child: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context)!;
          return const SizedBox.shrink();
        },
      ),
    );

    final start = DateTime(2023, 1, 1);
    final end = DateTime(2024, 4, 7);

    expect(
      formatDurationBetween(start, end, l10n: l10n),
      '1 år og 3 mnd og 6 dager',
    );
  });
}
