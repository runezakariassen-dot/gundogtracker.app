class StatisticsResult {
  final int totalSessions;
  final Duration totalActiveTime;
  final int totalBirdContacts;
  final int totalPoints;
  final int totalFlushes;

  final DateTime? firstSessionDate;
  final DateTime? lastSessionDate;

  const StatisticsResult({
    required this.totalSessions,
    required this.totalActiveTime,
    required this.totalBirdContacts,
    required this.totalPoints,
    required this.totalFlushes,
    required this.firstSessionDate,
    required this.lastSessionDate,
  });

  factory StatisticsResult.empty() => const StatisticsResult(
        totalSessions: 0,
        totalActiveTime: Duration.zero,
        totalBirdContacts: 0,
        totalPoints: 0,
        totalFlushes: 0,
        firstSessionDate: null,
        lastSessionDate: null,
      );
}
