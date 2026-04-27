import '../../models/hunt_session.dart';
import 'statistics_result.dart';

/// Statistikksummer (V1)
///
/// Beholder eksisterende:
/// - aggregate(sessions)
/// - aggregateForDog(sessions, dogId)
///
/// Legger til:
/// - perDogRows(): "Økter per hund" + aktiv tid per hund
/// - timeSeries(): tidsserie per uke eller måned (økter + aktiv tid)
/// - formatBucketLabel(): label-tekst for perioden (uke/måned)
class StatisticsAggregator {
  static StatisticsResult aggregate(List<HuntSession> sessions) {
    final visibleSessions =
        sessions.where((session) => !session.isDeleted).toList(growable: false);
    if (visibleSessions.isEmpty) return StatisticsResult.empty();

    var totalMinutes = 0;
    var totalBirds = 0;
    var totalPoints = 0;
    var totalFlushes = 0;

    DateTime? first;
    DateTime? last;

    for (final s in visibleSessions) {
      totalMinutes += s.durationMinutes;
      totalBirds += s.birdsSeen;
      totalPoints += s.points + s.secondaryPoints;
      totalFlushes += s.flushes;

      final dt = s.dateTime;
      if (first == null || dt.isBefore(first)) {
        first = dt;
      }
      if (last == null || dt.isAfter(last)) {
        last = dt;
      }
    }

    return StatisticsResult(
      totalSessions: visibleSessions.length,
      totalActiveTime: Duration(minutes: totalMinutes),
      totalBirdContacts: totalBirds,
      totalPoints: totalPoints,
      totalFlushes: totalFlushes,
      firstSessionDate: first,
      lastSessionDate: last,
    );
  }

  static StatisticsResult aggregateForDog(
    List<HuntSession> sessions,
    String dogId,
  ) {
    final filtered = sessions.where((s) => s.dogId == dogId).toList();
    return aggregate(filtered);
  }

  /// ---- V1: Økter per hund ----
  ///
  /// UI kan sende inn dogId -> navn map (fra dogsBox),
  /// hvis ikke vises "Ukjent hund".
  ///
  /// Sorteres: flest økter først, så mest aktiv tid.
  static List<DogStatsRow> perDogRows(
    List<HuntSession> sessions, {
    Map<String, String> dogIdToName = const {},
  }) {
    if (sessions.isEmpty) return const [];

    final byDog = <String, List<HuntSession>>{};
    for (final s in sessions) {
      if (s.isDeleted) continue;
      if (s.dogId.isEmpty) continue;
      byDog.putIfAbsent(s.dogId, () => <HuntSession>[]).add(s);
    }

    final rows = <DogStatsRow>[];
    for (final entry in byDog.entries) {
      final dogId = entry.key;
      final res = aggregate(entry.value);
      rows.add(
        DogStatsRow(
          dogId: dogId,
          dogName: dogIdToName[dogId] ?? 'Ukjent hund',
          result: res,
        ),
      );
    }

    rows.sort((a, b) {
      final s = b.result.totalSessions.compareTo(a.result.totalSessions);
      if (s != 0) return s;
      return b.result.totalActiveTime.compareTo(a.result.totalActiveTime);
    });

    return rows;
  }

  /// ---- V1: Tidsserie (uke/måned) ----
  ///
  /// Gir buckets med:
  /// - sessions (antall økter i perioden)
  /// - activeTime (sum aktiv tid i perioden)
  static List<TimeSeriesBucket> timeSeries(
    List<HuntSession> sessions, {
    required TimeSeriesGranularity granularity,
  }) {
    if (sessions.isEmpty) return const [];

    final buckets = <DateTime, _BucketAcc>{};

    for (final s in sessions) {
      if (s.isDeleted) continue;
      final dt = s.dateTime;

      final key = (granularity == TimeSeriesGranularity.month)
          ? DateTime(dt.year, dt.month, 1)
          : _startOfWeek(dt);

      final acc = buckets.putIfAbsent(key, () => _BucketAcc());
      acc.sessions += 1;
      acc.totalMinutes += s.durationMinutes;
    }

    final keys = buckets.keys.toList()..sort();
    return [
      for (final k in keys)
        TimeSeriesBucket(
          periodStart: k,
          sessions: buckets[k]!.sessions,
          activeTime: Duration(minutes: buckets[k]!.totalMinutes),
        ),
    ];
  }

  /// Label for periode:
  /// - måned: "Des 2025"
  /// - uke: "23.12–29.12"
  static String formatBucketLabel(
    TimeSeriesBucket b, {
    required TimeSeriesGranularity granularity,
  }) {
    final start = b.periodStart.toLocal();

    if (granularity == TimeSeriesGranularity.month) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mai',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final m = months[start.month - 1];
      return '$m ${start.year}';
    }

    final end = start.add(const Duration(days: 6));
    String fmt(DateTime d) => '${d.day}.${d.month}';
    return '${fmt(start)}–${fmt(end)}';
  }

  static DateTime _startOfWeek(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    final delta = (date.weekday - DateTime.monday) % 7;
    return date.subtract(Duration(days: delta));
  }
}

/// Rad for "Økter per hund"
class DogStatsRow {
  final String dogId;
  final String dogName;
  final StatisticsResult result;

  const DogStatsRow({
    required this.dogId,
    required this.dogName,
    required this.result,
  });
}

enum TimeSeriesGranularity { week, month }

class TimeSeriesBucket {
  final DateTime periodStart; // Monday (uke) eller 1. i måneden
  final int sessions;
  final Duration activeTime;

  const TimeSeriesBucket({
    required this.periodStart,
    required this.sessions,
    required this.activeTime,
  });
}

class _BucketAcc {
  int sessions = 0;
  int totalMinutes = 0;
}
