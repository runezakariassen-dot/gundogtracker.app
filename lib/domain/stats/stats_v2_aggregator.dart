import 'package:jakthund_app/models/hunt_session.dart';

enum StatsV2PeriodType { year, season, custom }

enum StatsV2Season { winter, spring, summer, autumn }

class StatsV2Query {
  final StatsV2PeriodType periodType;
  final int? year;
  final StatsV2Season? season;
  final DateTime? from;
  final DateTime? to;
  final String? dogId;

  const StatsV2Query({
    required this.periodType,
    this.year,
    this.season,
    this.from,
    this.to,
    this.dogId,
  });
}

class StatsV2YearSummary {
  final int year;
  final int sessionsCount;
  final int activeMinutes;
  final int points;
  final int secondaryPoints;
  final int flushes;
  final int birdContacts;
  final int birdsDown;

  const StatsV2YearSummary({
    required this.year,
    required this.sessionsCount,
    required this.activeMinutes,
    required this.points,
    required this.secondaryPoints,
    required this.flushes,
    required this.birdContacts,
    required this.birdsDown,
  });
}

class StatsV2Result {
  final StatsV2Query query;
  final int sessionsCount;
  final int activeMinutes;
  final int points;
  final int secondaryPoints;
  final int flushes;
  final int birdContacts;
  final int birdsDown;
  final List<StatsV2YearSummary> byYear;

  const StatsV2Result({
    required this.query,
    required this.sessionsCount,
    required this.activeMinutes,
    required this.points,
    required this.secondaryPoints,
    required this.flushes,
    required this.birdContacts,
    required this.birdsDown,
    required this.byYear,
  });
}

class StatsV2Aggregator {
  static StatsV2Result aggregate({
    required List<HuntSession> sessions,
    required StatsV2Query query,
    DateTime Function() nowProvider = _defaultNow,
  }) {
    final range = _buildDateRange(query);

    final totals = _Totals();
    final perYear = <int, _Totals>{};

    for (final session in sessions) {
      if (session.isDeleted) {
        continue;
      }
      if (query.dogId != null && session.dogId != query.dogId) {
        continue;
      }

      if (!_isWithinRange(session.dateTime, range)) {
        continue;
      }

      totals.add(session);
      final year = session.dateTime.year;
      perYear.putIfAbsent(year, () => _Totals()).add(session);
    }

    final byYear = perYear.entries
        .map((entry) => StatsV2YearSummary(
              year: entry.key,
              sessionsCount: entry.value.sessions,
              activeMinutes: entry.value.activeMinutes,
              points: entry.value.points,
              secondaryPoints: entry.value.secondaryPoints,
              flushes: entry.value.flushes,
              birdContacts: entry.value.birdContacts,
              birdsDown: entry.value.birdsDown,
            ))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));

    return StatsV2Result(
      query: query,
      sessionsCount: totals.sessions,
      activeMinutes: totals.activeMinutes,
      points: totals.points,
      secondaryPoints: totals.secondaryPoints,
      flushes: totals.flushes,
      birdContacts: totals.birdContacts,
      birdsDown: totals.birdsDown,
      byYear: List.unmodifiable(byYear),
    );
  }
}

class _Totals {
  int sessions = 0;
  int activeMinutes = 0;
  int points = 0;
  int secondaryPoints = 0;
  int flushes = 0;
  int birdContacts = 0;
  int birdsDown = 0;

  void add(HuntSession session) {
    sessions += 1;
    activeMinutes += session.durationMinutes;
    points += session.points;
    secondaryPoints += session.secondaryPoints;
    flushes += session.flushes;
    birdContacts += session.birdsSeen;
    birdsDown += session.birdsShotCount;
  }
}

bool _isWithinRange(DateTime value, _DateRange range) {
  return !value.isBefore(range.from) && !value.isAfter(range.to);
}

_DateRange _buildDateRange(StatsV2Query query) {
  switch (query.periodType) {
    case StatsV2PeriodType.year:
      final year = query.year;
      if (year == null) {
        throw ArgumentError(
            'StatsV2Query.year is required for periodType=year');
      }

      return _DateRange(
        from: DateTime(year, 1, 1),
        to: DateTime(year + 1, 1, 1).subtract(_oneMicrosecond),
      );
    case StatsV2PeriodType.season:
      final year = query.year;
      final season = query.season;
      if (year == null || season == null) {
        throw ArgumentError(
            'StatsV2Query.year and season are required for periodType=season');
      }

      return _seasonRange(year, season);
    case StatsV2PeriodType.custom:
      final from = query.from;
      final to = query.to;
      if (from == null || to == null) {
        throw ArgumentError(
            'StatsV2Query.from and to are required for periodType=custom');
      }

      final start = DateTime(from.year, from.month, from.day);
      final end = _endOfDay(to);
      if (start.isAfter(end)) {
        throw ArgumentError('custom range must have from <= to');
      }

      return _DateRange(from: start, to: end);
  }
}

const _oneMicrosecond = Duration(microseconds: 1);

_DateRange _seasonRange(int year, StatsV2Season season) {
  switch (season) {
    case StatsV2Season.winter:
      final start = DateTime(year - 1, 12, 1);
      final end = DateTime(year, 3, 1).subtract(_oneMicrosecond);
      return _DateRange(from: start, to: end);
    case StatsV2Season.spring:
      final start = DateTime(year, 3, 1);
      final end = DateTime(year, 6, 1).subtract(_oneMicrosecond);
      return _DateRange(from: start, to: end);
    case StatsV2Season.summer:
      final start = DateTime(year, 6, 1);
      final end = DateTime(year, 9, 1).subtract(_oneMicrosecond);
      return _DateRange(from: start, to: end);
    case StatsV2Season.autumn:
      final start = DateTime(year, 9, 1);
      final end = DateTime(year, 12, 1).subtract(_oneMicrosecond);
      return _DateRange(from: start, to: end);
  }
}

DateTime _endOfDay(DateTime value) {
  final nextDay =
      DateTime(value.year, value.month, value.day).add(const Duration(days: 1));
  return nextDay.subtract(_oneMicrosecond);
}

class _DateRange {
  final DateTime from;
  final DateTime to;

  const _DateRange({required this.from, required this.to});
}

DateTime _defaultNow() => DateTime.now();
