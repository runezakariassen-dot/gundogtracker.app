import 'package:jakthund_app/l10n/app_localizations.dart';

String pluralize(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

String standText(int count) => pluralize(count, 'stand', 'stander');

String sessionText(int count) => pluralize(count, 'økt', 'økter');

String birdText(int count, {AppLocalizations? l10n}) {
  if (l10n != null) {
    return '$count ${l10n.session_label_birds}';
  }
  return pluralize(count, 'fugl', 'fugler');
}

String flushText(int count) => '$count støkk';

String formatDurationBetween(
  DateTime start,
  DateTime end, {
  AppLocalizations? l10n,
}) {
  final normalizedStart = DateTime(start.year, start.month, start.day);
  final normalizedEnd = DateTime(end.year, end.month, end.day);

  var years = normalizedEnd.year - normalizedStart.year;
  var months = normalizedEnd.month - normalizedStart.month;
  var days = normalizedEnd.day - normalizedStart.day;

  var borrowCount = 1;
  while (days < 0) {
    months--;
    final previousMonth = DateTime(
      normalizedEnd.year,
      normalizedEnd.month - borrowCount + 1,
      0,
    );
    days += previousMonth.day;
    borrowCount++;
  }

  if (months < 0) {
    years--;
    months += 12;
  }

  if (l10n != null) {
    final localizedParts = <String>[];
    if (years > 0) localizedParts.add(l10n.age_years(years));
    if (months > 0) localizedParts.add(l10n.age_months(months));
    if (days > 0) localizedParts.add(l10n.age_days(days));

    if (localizedParts.isEmpty) {
      return l10n.age_zero_days;
    }
    return localizedParts.join(' ${l10n.age_and} ');
  }

  final parts = <String>[];
  if (years > 0) parts.add('$years ${_yearLabel(years)}');
  if (months > 0) parts.add('$months ${_monthWord(months)}');
  if (days > 0) parts.add('$days ${_dayLabel(days)}');

  final joinWord = _conjunction();
  return parts.isEmpty ? _zeroDaysLabel() : parts.join(' $joinWord ');
}

String _yearLabel(int count) => count == 1 ? 'year' : 'years';

String _monthWord(int count) => count == 1 ? 'month' : 'months';

String _dayLabel(int count) => count == 1 ? 'day' : 'days';

String _conjunction() => 'and';

String _zeroDaysLabel() => '0 days';

String standsCountTextL10n(int count, AppLocalizations l10n) =>
    l10n.stats_stands_count(count);

String sessionsCountTextL10n(int count, AppLocalizations l10n) =>
    l10n.stats_sessions_count(count);

String birdsCountTextL10n(int count, AppLocalizations l10n) =>
    l10n.stats_birds_count(count);

String flushesCountTextL10n(int count, AppLocalizations l10n) =>
    l10n.stats_flushes_count(count);

String yearsTextL10n(int count, AppLocalizations l10n) =>
    l10n.common_years(count);

String monthsTextL10n(int count, AppLocalizations l10n) =>
    l10n.common_months(count);

String daysTextL10n(int count, AppLocalizations l10n) =>
    l10n.common_days(count);

String monthsShortL10n(AppLocalizations l10n) => l10n.common_months_short;

String conjunctionAndL10n(AppLocalizations l10n) => l10n.common_conjunction_and;
