import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/data/dto/hunt_session_dto.dart';
import 'package:jakthund_app/models/hunt_session.dart';

void main() {
  test('HuntSessionDto roundtrip preserves updatedAt', () {
    final deletedAt = DateTime.utc(2024, 1, 3, 10, 15);
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
      updatedAt: DateTime.utc(2024, 1, 2, 9, 30),
      deletedAt: deletedAt,
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
    expect(decoded.location, session.location);
    expect(decoded.updatedAt, session.updatedAt);
    expect(decoded.deletedAt, deletedAt);
  });

  test('HuntSessionDto falls back updatedAt to dateTime when missing', () {
    final decoded = HuntSessionDto.fromJson({
      'id': 'session-1',
      'dogId': 'dog-1',
      'dateTime': '2024-01-01T08:00:00.000Z',
      'location': 'Skog',
      'durationMinutes': 45,
      'birdsSeen': 2,
      'points': 1,
      'flushes': 1,
      'notes': 'Notat',
      'secondaryPoints': 0,
    }).toModel();

    expect(decoded.updatedAt, DateTime.parse('2024-01-01T08:00:00.000Z'));
  });

  test('HuntSessionDto tolerates missing or blank location', () {
    final missingLocation = HuntSessionDto.fromJson({
      'id': 'session-1',
      'dogId': 'dog-1',
      'dateTime': '2024-01-01T08:00:00.000',
      'durationMinutes': 45,
      'birdsSeen': 2,
      'points': 1,
      'flushes': 1,
      'notes': 'Notat',
      'secondaryPoints': 0,
    }).toModel();

    final blankLocation = HuntSessionDto.fromJson({
      'id': 'session-2',
      'dogId': 'dog-1',
      'dateTime': '2024-01-01T08:00:00.000',
      'location': '   ',
      'durationMinutes': 45,
      'birdsSeen': 2,
      'points': 1,
      'flushes': 1,
      'notes': 'Notat',
      'secondaryPoints': 0,
    }).toModel();

    expect(missingLocation.location, '');
    expect(blankLocation.location, '');
  });
}
