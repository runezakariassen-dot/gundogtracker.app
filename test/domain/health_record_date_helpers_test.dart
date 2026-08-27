import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/health/health_record_date_helpers.dart';
import 'package:jakthund_app/domain/health/health_record_form_helpers.dart';
import 'package:jakthund_app/l10n/app_localizations_en.dart';
import 'package:jakthund_app/l10n/app_localizations_nb.dart';
import 'package:jakthund_app/models/health_record.dart';

void main() {
  group('calculateHealthNextDueAt', () {
    test('clamps January 31 to the last valid day in February', () {
      expect(
        calculateHealthNextDueAt(
          DateTime(2025, 1, 31),
          const HealthRepeatInterval.monthly(),
        ),
        DateTime(2025, 2, 28),
      );
    });

    test('adds three calendar months across a year boundary', () {
      expect(
        calculateHealthNextDueAt(
          DateTime(2025, 11, 30),
          const HealthRepeatInterval.everyThreeMonths(),
        ),
        DateTime(2026, 2, 28),
      );
    });

    test('adds six calendar months', () {
      expect(
        calculateHealthNextDueAt(
          DateTime(2026, 3, 31),
          const HealthRepeatInterval.everySixMonths(),
        ),
        DateTime(2026, 9, 30),
      );
    });

    test('clamps a leap day when adding one year', () {
      expect(
        calculateHealthNextDueAt(
          DateTime(2024, 2, 29),
          const HealthRepeatInterval.yearly(),
        ),
        DateTime(2025, 2, 28),
      );
    });

    test('adds custom days and returns null for no repetition', () {
      expect(
        calculateHealthNextDueAt(
          DateTime(2026, 1, 1),
          HealthRepeatInterval.customDays(10),
        ),
        DateTime(2026, 1, 11),
      );
      expect(
        calculateHealthNextDueAt(
          DateTime(2026, 1, 1),
          const HealthRepeatInterval.none(),
        ),
        isNull,
      );
    });

    test('custom days preserve calendar date and local or UTC semantics', () {
      final local = DateTime(2026, 10, 25, 12);
      final localResult = calculateHealthNextDueAt(
        local,
        HealthRepeatInterval.customDays(1),
      )!;
      expect(localResult, DateTime(2026, 10, 26, 12));
      expect(localResult.isUtc, isFalse);

      final utc = DateTime.utc(2026, 10, 25, 12);
      final utcResult = calculateHealthNextDueAt(
        utc,
        HealthRepeatInterval.customDays(1),
      )!;
      expect(utcResult, DateTime.utc(2026, 10, 26, 12));
      expect(utcResult.isUtc, isTrue);
    });

    test('calendar months preserve UTC semantics', () {
      final result = calculateHealthNextDueAt(
        DateTime.utc(2026, 1, 31, 10),
        const HealthRepeatInterval.monthly(),
      )!;
      expect(result, DateTime.utc(2026, 2, 28, 10));
      expect(result.isUtc, isTrue);
    });
  });

  group('healthDueStatus', () {
    test('distinguishes overdue, today, and future by calendar date', () {
      final now = DateTime(2026, 7, 19, 23, 59);
      expect(
        healthDueStatus(DateTime(2026, 7, 18, 23), now).kind,
        HealthDueStatusKind.overdue,
      );
      expect(
        healthDueStatus(DateTime(2026, 7, 19), now).kind,
        HealthDueStatusKind.today,
      );
      final future = healthDueStatus(DateTime(2026, 7, 22, 1), now);
      expect(future.kind, HealthDueStatusKind.future);
      expect(future.days, 3);
    });
  });

  group('form validation', () {
    test('rejects empty and whitespace-only titles', () {
      expect(validateHealthTitle(''), isFalse);
      expect(validateHealthTitle('   '), isFalse);
      expect(validateHealthTitle('Vaccine'), isTrue);
    });

    test('rejects invalid custom repeat days', () {
      expect(
        validateCustomRepeatDays(HealthRepeatKind.customDays, '0'),
        isFalse,
      );
      expect(
        validateCustomRepeatDays(HealthRepeatKind.customDays, 'abc'),
        isFalse,
      );
      expect(
        validateCustomRepeatDays(HealthRepeatKind.customDays, '30'),
        isTrue,
      );
    });
  });

  group('NextDueDateState', () {
    const monthly = HealthRepeatInterval.monthly();
    final recordedAt = DateTime(2026, 1, 31);

    test('unchanged edit preserves existing null and manual values', () {
      final nullState = NextDueDateState.forEdit(null);
      expect(
        nullState.valueForSave(
          recordedAt: recordedAt,
          repeatInterval: monthly,
        ),
        isNull,
      );

      final manualDate = DateTime(2026, 5, 20);
      final manualState = NextDueDateState.forEdit(manualDate);
      expect(
        manualState.valueForSave(
          recordedAt: recordedAt,
          repeatInterval: monthly,
        ),
        manualDate,
      );
    });

    test('automatic mode recalculates for relevant changes', () {
      final state = const NextDueDateState.forCreate().relevantInputChanged(
        recordedAt: recordedAt,
        repeatInterval: monthly,
      );
      expect(state.mode, NextDueDateMode.automatic);
      expect(state.value, DateTime(2026, 2, 28));

      final changed = state.relevantInputChanged(
        recordedAt: DateTime(2026, 2, 10),
        repeatInterval: HealthRepeatInterval.customDays(10),
      );
      expect(changed.value, DateTime(2026, 2, 20));
    });

    test('manual and removed modes ignore relevant input changes', () {
      final manualDate = DateTime(2026, 8, 1);
      final manual = const NextDueDateState.forCreate()
          .selectManually(manualDate)
          .relevantInputChanged(
            recordedAt: DateTime(2027),
            repeatInterval: monthly,
          );
      expect(manual.mode, NextDueDateMode.manual);
      expect(manual.value, manualDate);

      final removed = manual.removeManually().relevantInputChanged(
            recordedAt: DateTime(2027),
            repeatInterval: monthly,
          );
      expect(removed.mode, NextDueDateMode.removed);
      expect(
          removed.valueForSave(
            recordedAt: recordedAt,
            repeatInterval: monthly,
          ),
          isNull);
    });
  });

  test('Norwegian and English day labels use singular and plural', () {
    final nb = AppLocalizationsNb();
    final en = AppLocalizationsEn();
    expect(nb.healthJournalInDays(1), 'Om 1 dag');
    expect(nb.healthJournalInDays(2), 'Om 2 dager');
    expect(en.healthJournalOverdueDays(1), 'Overdue by 1 day');
    expect(en.healthJournalOverdueDays(2), 'Overdue by 2 days');
  });
}
