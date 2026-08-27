import '../../models/health_record.dart';

enum HealthDueStatusKind { overdue, today, future }

class HealthDueStatus {
  const HealthDueStatus(this.kind, this.days);

  final HealthDueStatusKind kind;
  final int days;
}

DateTime? calculateHealthNextDueAt(
  DateTime recordedAt,
  HealthRepeatInterval? interval,
) {
  if (interval == null || interval.kind == HealthRepeatKind.none) return null;
  switch (interval.kind) {
    case HealthRepeatKind.none:
      return null;
    case HealthRepeatKind.monthly:
      return _addCalendarMonths(recordedAt, 1);
    case HealthRepeatKind.everyThreeMonths:
      return _addCalendarMonths(recordedAt, 3);
    case HealthRepeatKind.everySixMonths:
      return _addCalendarMonths(recordedAt, 6);
    case HealthRepeatKind.yearly:
      return _addCalendarMonths(recordedAt, 12);
    case HealthRepeatKind.customDays:
      return _addCalendarDays(recordedAt, interval.customDays!);
  }
}

HealthDueStatus healthDueStatus(DateTime dueAt, DateTime now) {
  final dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final difference = dueDate.difference(today).inDays;
  if (difference < 0) {
    return HealthDueStatus(HealthDueStatusKind.overdue, -difference);
  }
  if (difference == 0) {
    return const HealthDueStatus(HealthDueStatusKind.today, 0);
  }
  return HealthDueStatus(HealthDueStatusKind.future, difference);
}

DateTime _addCalendarMonths(DateTime source, int months) {
  final zeroBasedMonth = source.month - 1 + months;
  final year = source.year + zeroBasedMonth ~/ 12;
  final month = zeroBasedMonth % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = source.day > lastDay ? lastDay : source.day;
  return _dateTimeLike(source, year, month, day);
}

DateTime _addCalendarDays(DateTime source, int days) {
  return _dateTimeLike(source, source.year, source.month, source.day + days);
}

DateTime _dateTimeLike(DateTime source, int year, int month, int day) {
  if (source.isUtc) {
    return DateTime.utc(
      year,
      month,
      day,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }
  return DateTime(
    year,
    month,
    day,
    source.hour,
    source.minute,
    source.second,
    source.millisecond,
    source.microsecond,
  );
}
