import 'package:equatable/equatable.dart';

/// Avanserte statistikkresultater for en enkelt hund
class AdvancedDogStats extends Equatable {
  final String dogId;
  final String dogName;
  final int totalSessions;
  final Duration totalActiveTime;
  final int totalPoints;
  final int totalFlushes;
  final int totalBirdContacts;
  final int totalBirdsShot;
  final double averagePointsPerHour;
  final double averageBirdContactsPerSession;
  final double averageFlushesPerSession;
  final double successRate; // points / birdContacts
  final Map<String, int> monthlyPoints;
  final Map<String, int> seasonalData;
  final List<ProgressPoint> progressOverTime;

  const AdvancedDogStats({
    required this.dogId,
    required this.dogName,
    required this.totalSessions,
    required this.totalActiveTime,
    required this.totalPoints,
    required this.totalFlushes,
    required this.totalBirdContacts,
    required this.totalBirdsShot,
    required this.averagePointsPerHour,
    required this.averageBirdContactsPerSession,
    required this.averageFlushesPerSession,
    required this.successRate,
    required this.monthlyPoints,
    required this.seasonalData,
    required this.progressOverTime,
  });

  @override
  List<Object?> get props => [
        dogId,
        dogName,
        totalSessions,
        totalActiveTime,
        totalPoints,
        totalFlushes,
        totalBirdContacts,
        totalBirdsShot,
        averagePointsPerHour,
        averageBirdContactsPerSession,
        averageFlushesPerSession,
        successRate,
        monthlyPoints,
        seasonalData,
        progressOverTime,
      ];
}

/// Punkt på progresjonsgraf
class ProgressPoint extends Equatable {
  final DateTime date;
  final double value;
  final String label;

  const ProgressPoint({
    required this.date,
    required this.value,
    required this.label,
  });

  @override
  List<Object?> get props => [date, value, label];
}

/// Sesongdata for sammenligning
class SeasonalStats extends Equatable {
  final String season; // "Vinter 2024", "Sommer 2024", etc.
  final int sessions;
  final Duration activeTime;
  final int points;
  final int flushes;
  final int birdContacts;
  final double averagePointsPerHour;

  const SeasonalStats({
    required this.season,
    required this.sessions,
    required this.activeTime,
    required this.points,
    required this.flushes,
    required this.birdContacts,
    required this.averagePointsPerHour,
  });

  @override
  List<Object?> get props => [
        season,
        sessions,
        activeTime,
        points,
        flushes,
        birdContacts,
        averagePointsPerHour,
      ];
}

/// Statistikk for sammenligning av hunder
class DogComparisonStats extends Equatable {
  final List<AdvancedDogStats> dogStats;
  final Map<String, double> averagePointsPerHour;
  final Map<String, double> averageBirdContactsPerSession;
  final Map<String, double> successRates;

  const DogComparisonStats({
    required this.dogStats,
    required this.averagePointsPerHour,
    required this.averageBirdContactsPerSession,
    required this.successRates,
  });

  @override
  List<Object?> get props => [
        dogStats,
        averagePointsPerHour,
        averageBirdContactsPerSession,
        successRates,
      ];
}
