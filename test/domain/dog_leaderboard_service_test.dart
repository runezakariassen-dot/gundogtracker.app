import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/statistics/dog_leaderboard_service.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/hunt_session.dart';

Dog _makeDog(String id, String name) {
  return Dog(
    id: id,
    name: name,
    dogKey: id,
    regNrDisplay: id,
  );
}

HuntSession _makeSession(String dogId, int points) {
  return HuntSession(
    dogId: dogId,
    dateTime: DateTime.utc(2024, 1, 1),
    location: 'Skog',
    durationMinutes: 60,
    birdsSeen: 0,
    points: points,
    flushes: 0,
    notes: '',
  );
}

void main() {
  test('DogLeaderboardService sorts by points desc', () {
    final dogs = [
      _makeDog('dog-a', 'A'),
      _makeDog('dog-b', 'B'),
      _makeDog('dog-c', 'C'),
    ];
    final sessions = [
      _makeSession('dog-b', 12),
      _makeSession('dog-a', 5),
      _makeSession('dog-c', 1),
    ];

    final entries = DogLeaderboardService().buildTopTen(dogs, sessions);

    expect(entries.map((e) => e.dog.id).toList(), ['dog-b', 'dog-a', 'dog-c']);
  });
}
