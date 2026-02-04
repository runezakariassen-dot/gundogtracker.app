import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/domain/milestones/milestone_catalog.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/services/dog_milestone_display_service.dart';
import 'package:jakthund_app/ui/milestones/milestone_list_section.dart';

import '../test_app.dart';

List<String> _allTextStrings(WidgetTester tester) {
  final out = <String>[];

  // Text widgets
  for (final widget in tester.widgetList(find.byType(Text))) {
    final text = widget as Text;

    final data = text.data;
    if (data != null && data.trim().isNotEmpty) out.add(data.trim());

    final span = text.textSpan;
    if (span != null) {
      final plain = span.toPlainText().trim();
      if (plain.isNotEmpty) out.add(plain);
    }
  }

  // RichText widgets
  for (final widget in tester.widgetList(find.byType(RichText))) {
    final rich = widget as RichText;
    final plain = rich.text.toPlainText().trim();
    if (plain.isNotEmpty) out.add(plain);
  }

  return out;
}

bool _anyTextMatches(WidgetTester tester, RegExp pattern) {
  return _allTextStrings(tester).any((t) => pattern.hasMatch(t));
}

bool _anyTextContains(WidgetTester tester, String needle) {
  return _allTextStrings(tester).any((t) => t.contains(needle));
}

void main() {
  testWidgets('renders milestone titles and dates (NB)', (tester) async {
    final displays = [
      DogMilestoneDisplay(
        id: MilestoneId.stands1,
        def: milestoneDefById(MilestoneId.stands1)!,
        achievedAt: DateTime(2024, 1, 1),
      ),
      DogMilestoneDisplay(
        id: MilestoneId.sessions10,
        def: milestoneDefById(MilestoneId.sessions10)!,
        achievedAt: DateTime(2024, 2, 1),
      ),
    ];

    await pumpApp(
      tester,
      child: MilestoneListSection(milestones: displays),
    );

    // Guardrail: Ikke engelsk i NB-test
    expect(
      _anyTextMatches(tester, RegExp(r'\byear\b', caseSensitive: false)),
      isFalse,
    );
    expect(
      _anyTextMatches(tester, RegExp(r'\bmonth\b', caseSensitive: false)),
      isFalse,
    );

    // Titler: bekreft NB-ish innhold.
    expect(
      _anyTextMatches(tester, RegExp(r'\bstand\b', caseSensitive: false)),
      isTrue,
    );
    expect(_anyTextMatches(tester, RegExp(r'\b10\b')), isTrue);
    expect(
      _anyTextMatches(tester, RegExp(r'økt', caseSensitive: false)),
      isTrue,
    );

    // Datoformat kan variere (01.01.2024 vs 1.1.2024 vs 1. jan. 2024 osv.)
    final jan1 = RegExp(
      r'(01\.01\.2024|1\.1\.2024|1\.\s*(jan\.?|januar)\s*2024)',
      caseSensitive: false,
    );
    final feb1 = RegExp(
      r'(01\.02\.2024|1\.2\.2024|1\.\s*(feb\.?|februar)\s*2024)',
      caseSensitive: false,
    );

    expect(_anyTextMatches(tester, jan1), isTrue);
    expect(_anyTextMatches(tester, feb1), isTrue);

    // Sikre at vi ikke tilfeldigvis viser EN-ord
    expect(_anyTextContains(tester, 'First'), isFalse);
    expect(_anyTextContains(tester, 'sessions'), isFalse);
  });

  testWidgets('renders age when birthDate provided (NB)', (tester) async {
    final displays = [
      DogMilestoneDisplay(
        id: MilestoneId.stands1,
        def: milestoneDefById(MilestoneId.stands1)!,
        achievedAt: DateTime(2024, 1, 1),
      ),
    ];

    await pumpApp(
      tester,
      child: MilestoneListSection(
        milestones: displays,
        dogBirthDate: DateTime(2023, 6, 1),
      ),
    );

    final rendered = _allTextStrings(tester);
    final renderedDump = rendered.isEmpty
        ? '(no Text/RichText strings found)'
        : rendered.join('\n');

    // Guardrails: Ikke engelsk alder-format her
    expect(
      _anyTextMatches(tester, RegExp(r'\byear\b', caseSensitive: false)),
      isFalse,
      reason: 'Rendered texts:\n$renderedDump',
    );
    expect(
      _anyTextMatches(tester, RegExp(r'\bmonth\b', caseSensitive: false)),
      isFalse,
      reason: 'Rendered texts:\n$renderedDump',
    );

    // Alder: vi forventer at noe alder-relatert vises (NB), men vi lar UI bestemme
    // eksakt formulering. Dette expectationen gir oss fasiten via "reason" hvis den feiler.
    final ageRelated = RegExp(
      r'\b(alder|gammel|mnd|mån|måned|måneder)\b',
      caseSensitive: false,
    );

    expect(
      _anyTextMatches(tester, ageRelated),
      isTrue,
      reason: 'Rendered texts:\n$renderedDump',
    );

    // Guardrails mot gamle/alternative formuleringer (disse må IKKE dukke opp)
    expect(find.text('Alder: 7 mnd'), findsNothing);
    expect(find.text('Oppnådd 7 mnd'), findsNothing);
  });
}
