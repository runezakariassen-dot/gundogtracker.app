import '../../models/dog.dart';
import '../../models/hunt_session.dart';

class DogLeaderboardEntry {
  final Dog dog;
  // totalPoints == sum of HuntSession.points; currently used as stand count equivalent.
  final int totalPoints;
  final DateTime? lastSessionAt;

  const DogLeaderboardEntry({
    required this.dog,
    required this.totalPoints,
    required this.lastSessionAt,
  });
}

class DogLeaderboardService {
  List<DogLeaderboardEntry> buildTopTen(
    List<Dog> dogs,
    List<HuntSession> sessions,
  ) {
    final totals = <String, _DogPointsAggregate>{};
    for (final session in sessions) {
      if (session.isDeleted) {
        continue;
      }
      final aggregate =
          totals.putIfAbsent(session.dogId, () => _DogPointsAggregate());
      aggregate.totalPoints += session.points;
      if (aggregate.lastSessionAt == null ||
          session.dateTime.isAfter(aggregate.lastSessionAt!)) {
        aggregate.lastSessionAt = session.dateTime;
      }
    }

    final entries = dogs.where((dog) => !dog.isDeleted).map((dog) {
      final aggregate = totals[dog.id];
      return DogLeaderboardEntry(
        dog: dog,
        totalPoints: aggregate?.totalPoints ?? 0,
        lastSessionAt: aggregate?.lastSessionAt,
      );
    }).toList(growable: false);

    entries.sort((a, b) {
      final byPoints = b.totalPoints.compareTo(a.totalPoints);
      if (byPoints != 0) return byPoints;
      final aTime = a.lastSessionAt?.millisecondsSinceEpoch ?? -1;
      final bTime = b.lastSessionAt?.millisecondsSinceEpoch ?? -1;
      final byDate = bTime.compareTo(aTime);
      if (byDate != 0) return byDate;
      return a.dog.name.compareTo(b.dog.name);
    });

    if (entries.length <= 10) {
      return entries;
    }
    return entries.sublist(0, 10);
  }
}

class _DogPointsAggregate {
  int totalPoints = 0;
  DateTime? lastSessionAt;
}
