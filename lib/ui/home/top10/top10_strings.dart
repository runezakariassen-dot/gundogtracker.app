import 'package:jakthund_app/l10n/app_localizations.dart';

class Top10Strings {
  const Top10Strings._();

  static String ageLabel({
    required AppLocalizations l10n,
    required int years,
    required int months,
    required int days,
  }) {
    final parts = <String>[];

    if (years > 0) {
      parts.add(l10n.age_years_short(years));
    }
    if (months > 0) {
      parts.add(l10n.age_months_short(months));
    }
    if (days > 0) {
      parts.add(l10n.age_days(days));
    }

    if (parts.isEmpty) {
      return l10n.age_zero_days;
    }
    return parts.join(' ${l10n.age_and} ');
  }

  static String standsLabel({
    required AppLocalizations l10n,
    required int count,
  }) {
    final unit = l10n.top10_points_unit(count);
    return '$count $unit';
  }
}
