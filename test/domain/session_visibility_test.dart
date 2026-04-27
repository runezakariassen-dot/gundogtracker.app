import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/sessions/session_visibility.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/hunt_session.dart';

void main() {
  test('deleted session is filtered out from visible sessions', () {
    final visible = _buildSession(
      dogId: 'dog-1',
      dateTime: DateTime.utc(2024, 1, 1, 12),
    );
    final deleted = _buildSession(
      dogId: 'dog-1',
      dateTime: DateTime.utc(2024, 1, 2, 12),
      deletedAt: DateTime.utc(2024, 1, 3, 12),
    );

    final sessions = filterVisibleSessions(
      sessions: <HuntSession>[visible, deleted],
      dogs: <Dog>[_buildDog(id: 'dog-1')],
    );

    expect(sessions, <HuntSession>[visible]);
  });

  test('session for deleted dog is filtered out from visible sessions', () {
    final session = _buildSession(
      dogId: 'dog-1',
      dateTime: DateTime.utc(2024, 1, 1, 12),
    );

    final sessions = filterVisibleSessions(
      sessions: <HuntSession>[session],
      dogs: <Dog>[
        _buildDog(
          id: 'dog-1',
          deletedAt: DateTime.utc(2024, 1, 2, 12),
        ),
      ],
    );

    expect(sessions, isEmpty);
  });

  test('non-deleted session for active dog stays visible', () {
    final session = _buildSession(
      dogId: 'dog-1',
      dateTime: DateTime.utc(2024, 1, 1, 12),
    );

    final sessions = filterVisibleSessionsForDog(
      sessions: <HuntSession>[session],
      dogId: 'dog-1',
      dogs: <Dog>[_buildDog(id: 'dog-1')],
    );

    expect(sessions, <HuntSession>[session]);
  });

  test('detail visibility helper hides deleted or orphaned sessions', () {
    final activeDog = _buildDog(id: 'dog-1');
    final deletedDog = _buildDog(
      id: 'dog-1',
      deletedAt: DateTime.utc(2024, 1, 2, 12),
    );
    final activeSession = _buildSession(
      dogId: 'dog-1',
      dateTime: DateTime.utc(2024, 1, 1, 12),
    );
    final deletedSession = _buildSession(
      dogId: 'dog-1',
      dateTime: DateTime.utc(2024, 1, 2, 12),
      deletedAt: DateTime.utc(2024, 1, 3, 12),
    );

    expect(
      isSessionVisibleInUi(session: activeSession, dog: activeDog),
      isTrue,
    );
    expect(
      isSessionVisibleInUi(session: deletedSession, dog: activeDog),
      isFalse,
    );
    expect(
      isSessionVisibleInUi(session: activeSession, dog: deletedDog),
      isFalse,
    );
    expect(
      isSessionVisibleInUi(session: activeSession, dog: null),
      isFalse,
    );
  });
}

Dog _buildDog({
  required String id,
  DateTime? deletedAt,
}) {
  return Dog(
    id: id,
    name: 'Birk',
    dogKey: 'DOG-$id',
    regNrDisplay: 'NO123/45',
    updatedAt: DateTime.utc(2024, 1, 1, 12),
    deletedAt: deletedAt,
  );
}

HuntSession _buildSession({
  required String dogId,
  required DateTime dateTime,
  DateTime? deletedAt,
}) {
  return HuntSession(
    dogId: dogId,
    dateTime: dateTime,
    location: 'Test',
    durationMinutes: 30,
    birdsSeen: 2,
    points: 1,
    flushes: 0,
    notes: '',
    updatedAt: deletedAt ?? dateTime,
    deletedAt: deletedAt,
  );
}
