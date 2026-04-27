import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/models/hunt_session.dart';

void main() {
  test('HuntSession normalizes location on create', () {
    final session = HuntSession(
      dogId: 'dog-1',
      dateTime: DateTime(2024, 1, 1, 8, 0),
      location: '  Fjell  ',
      durationMinutes: 45,
      birdsSeen: 2,
      points: 1,
      flushes: 1,
      notes: 'Notat',
    );

    expect(session.location, 'Fjell');
  });

  test('HuntSession normalizes blank location on create and copyWith', () {
    final session = HuntSession(
      dogId: 'dog-1',
      dateTime: DateTime(2024, 1, 1, 8, 0),
      location: '   ',
      durationMinutes: 45,
      birdsSeen: 2,
      points: 1,
      flushes: 1,
      notes: 'Notat',
    );

    final updated = session.copyWith(location: '   ');

    expect(session.location, '');
    expect(updated.location, '');
  });
}
