import '../../models/dog.dart';
import '../../models/hunt_session.dart';
import 'advanced_statistics_models.dart';

/// Tjeneste for beregning av avanserte statistikker
class AdvancedStatisticsService {
  /// Beregn avanserte statistikker for en enkelt hund
  static AdvancedDogStats calculateDogStats(
    String dogId,
    String dogName,
    List<HuntSession> sessions,
  ) {
    final visibleSessions =
        sessions.where((session) => !session.isDeleted).toList(growable: false);
    if (visibleSessions.isEmpty) {
      return AdvancedDogStats(
        dogId: dogId,
        dogName: dogName,
        totalSessions: 0,
        totalActiveTime: Duration.zero,
        totalPoints: 0,
        totalFlushes: 0,
        totalBirdContacts: 0,
        totalBirdsShot: 0,
        averagePointsPerHour: 0.0,
        averageBirdContactsPerSession: 0.0,
        averageFlushesPerSession: 0.0,
        successRate: 0.0,
        monthlyPoints: const {},
        seasonalData: const {},
        progressOverTime: const [],
      );
    }

    final totalSessions = visibleSessions.length;
    final totalActiveTime = Duration(
      minutes:
          visibleSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes),
    );
    final totalPoints = visibleSessions.fold<int>(
      0,
      (sum, s) => sum + s.points + s.secondaryPoints,
    );
    final totalFlushes =
        visibleSessions.fold<int>(0, (sum, s) => sum + s.flushes);
    final totalBirdContacts =
        visibleSessions.fold<int>(0, (sum, s) => sum + s.birdsSeen);
    final totalBirdsShot =
        visibleSessions.fold<int>(0, (sum, s) => sum + s.birdsShotCount);

    final totalHours = totalActiveTime.inMinutes / 60.0;
    final averagePointsPerHour =
        totalHours > 0 ? totalPoints / totalHours : 0.0;
    final averageBirdContactsPerSession =
        totalSessions > 0 ? totalBirdContacts / totalSessions : 0.0;
    final averageFlushesPerSession =
        totalSessions > 0 ? totalFlushes / totalSessions : 0.0;
    final successRate =
        totalBirdContacts > 0 ? totalPoints / totalBirdContacts : 0.0;

    final monthlyPoints = _calculateMonthlyPoints(visibleSessions);
    final seasonalData = _calculateSeasonalData(visibleSessions);
    final progressOverTime = _calculateProgressOverTime(visibleSessions);

    return AdvancedDogStats(
      dogId: dogId,
      dogName: dogName,
      totalSessions: totalSessions,
      totalActiveTime: totalActiveTime,
      totalPoints: totalPoints,
      totalFlushes: totalFlushes,
      totalBirdContacts: totalBirdContacts,
      totalBirdsShot: totalBirdsShot,
      averagePointsPerHour: averagePointsPerHour,
      averageBirdContactsPerSession: averageBirdContactsPerSession,
      averageFlushesPerSession: averageFlushesPerSession,
      successRate: successRate,
      monthlyPoints: monthlyPoints,
      seasonalData: seasonalData,
      progressOverTime: progressOverTime,
    );
  }

  /// Beregn månedlige poengsummeringer
  static Map<String, int> _calculateMonthlyPoints(List<HuntSession> sessions) {
    final monthlyPoints = <String, int>{};

    for (final session in sessions) {
      final monthKey =
          '${session.dateTime.year}-${session.dateTime.month.toString().padLeft(2, '0')}';
      monthlyPoints[monthKey] = (monthlyPoints[monthKey] ?? 0) +
          session.points +
          session.secondaryPoints;
    }

    return monthlyPoints;
  }

  /// Beregn sesongdata
  static Map<String, int> _calculateSeasonalData(List<HuntSession> sessions) {
    final seasonalData = <String, int>{};

    for (final session in sessions) {
      final season = _getSeason(session.dateTime);
      seasonalData[season] = (seasonalData[season] ?? 0) +
          session.points +
          session.secondaryPoints;
    }

    return seasonalData;
  }

  /// Beregn progresjon over tid
  static List<ProgressPoint> _calculateProgressOverTime(
      List<HuntSession> sessions) {
    if (sessions.isEmpty) return [];

    // Sorter sesjoner etter dato
    final sortedSessions = List<HuntSession>.from(sessions)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final progressPoints = <ProgressPoint>[];
    var cumulativePoints = 0;
    var cumulativeSessions = 0;

    for (final session in sortedSessions) {
      cumulativeSessions++;
      cumulativePoints += session.points + session.secondaryPoints;

      final averagePoints =
          cumulativeSessions > 0 ? cumulativePoints / cumulativeSessions : 0.0;

      progressPoints.add(ProgressPoint(
        date: session.dateTime,
        value: averagePoints,
        label: '${session.dateTime.day}/${session.dateTime.month}',
      ));
    }

    return progressPoints;
  }

  /// Beregn sammenligning mellom hunder
  static DogComparisonStats calculateDogComparison(
    List<Dog> dogs,
    List<HuntSession> allSessions,
  ) {
    final dogStats = <AdvancedDogStats>[];
    final averagePointsPerHour = <String, double>{};
    final averageBirdContactsPerSession = <String, double>{};
    final successRates = <String, double>{};

    for (final dog in dogs) {
      if (dog.isDeleted) {
        continue;
      }
      final dogSessions =
          allSessions.where((s) => s.dogId == dog.id && !s.isDeleted).toList();
      final stats = calculateDogStats(dog.id, dog.name, dogSessions);

      dogStats.add(stats);
      averagePointsPerHour[dog.name] = stats.averagePointsPerHour;
      averageBirdContactsPerSession[dog.name] =
          stats.averageBirdContactsPerSession;
      successRates[dog.name] = stats.successRate;
    }

    return DogComparisonStats(
      dogStats: dogStats,
      averagePointsPerHour: averagePointsPerHour,
      averageBirdContactsPerSession: averageBirdContactsPerSession,
      successRates: successRates,
    );
  }

  /// Beregn sesongstatistikker
  static List<SeasonalStats> calculateSeasonalStats(
    List<HuntSession> sessions,
    String dogId,
  ) {
    final dogSessions =
        sessions.where((s) => s.dogId == dogId && !s.isDeleted).toList();
    final seasonalMap = <String, List<HuntSession>>{};

    for (final session in dogSessions) {
      final season = _getSeason(session.dateTime);
      seasonalMap.putIfAbsent(season, () => []).add(session);
    }

    final seasonalStats = <SeasonalStats>[];

    for (final entry in seasonalMap.entries) {
      final seasonSessions = entry.value;
      final sessionsCount = seasonSessions.length;
      final activeTime = Duration(
        minutes:
            seasonSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes),
      );
      final points = seasonSessions.fold<int>(
          0, (sum, s) => sum + s.points + s.secondaryPoints);
      final flushes = seasonSessions.fold<int>(0, (sum, s) => sum + s.flushes);
      final birdContacts =
          seasonSessions.fold<int>(0, (sum, s) => sum + s.birdsSeen);

      final totalHours = activeTime.inMinutes / 60.0;
      final averagePointsPerHour = totalHours > 0 ? points / totalHours : 0.0;

      seasonalStats.add(SeasonalStats(
        season: entry.key,
        sessions: sessionsCount,
        activeTime: activeTime,
        points: points,
        flushes: flushes,
        birdContacts: birdContacts,
        averagePointsPerHour: averagePointsPerHour,
      ));
    }

    // Sorter etter sesong
    seasonalStats.sort((a, b) => a.season.compareTo(b.season));

    return seasonalStats;
  }

  /// Hjelpemetode for å bestemme sesong basert på dato
  static String _getSeason(DateTime date) {
    final year = date.year;
    final month = date.month;

    if (month >= 12 || month <= 2) {
      return month <= 2 ? 'Vinter $year' : 'Vinter ${year + 1}';
    } else if (month >= 3 && month <= 5) {
      return 'Vår $year';
    } else if (month >= 6 && month <= 8) {
      return 'Sommer $year';
    } else {
      return 'Høst $year';
    }
  }
}
