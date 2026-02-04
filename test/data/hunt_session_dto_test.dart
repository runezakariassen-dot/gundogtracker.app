import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/data/dto/hunt_session_dto.dart';
import 'package:jakthund_app/models/hunt_session.dart';

void main() {
  test('HuntSessionDto roundtrip', () {
    final session = HuntSession(
      dogId: 'dog-1',
      dogKey: 'NO123-45',
      dateTime: DateTime(2024, 1, 1, 8, 0),
      location: 'Skog',
      durationMinutes: 45,
      birdsSeen: 2,
      points: 1,
      flushes: 1,
      notes: 'Notat',
      secondaryPoints: 0,
      trackKey: 123,
      trackId: 'track-1',
      birdSpecies: const ['Rype'],
      mediaPaths: const ['path.jpg'],
      createdByUserId: 'owner',
    );

    final dto = HuntSessionDto.fromModel('session-1', session);
    final json = dto.toJson();
    final decoded = HuntSessionDto.fromJson(json).toModel();

    expect(decoded.dogId, session.dogId);
    expect(decoded.dateTime, session.dateTime);
    expect(decoded.durationMinutes, session.durationMinutes);
    expect(decoded.birdsSeen, session.birdsSeen);
    expect(decoded.points, session.points);
    expect(decoded.flushes, session.flushes);
    expect(decoded.notes, session.notes);
    expect(decoded.trackId, session.trackId);
  });
}
