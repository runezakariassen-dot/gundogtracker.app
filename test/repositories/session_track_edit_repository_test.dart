import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/repositories/session_track_edit_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('session_track_edit_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(SessionTrackEditAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  SessionTrackEdit edit(String sessionId) => SessionTrackEdit(
        sessionId: sessionId,
        sourceTrackId: 'track-1',
        startIndexInclusive: 1,
        endIndexExclusive: 3,
        startTimeAnchor: DateTime.utc(2026, 1, 1, 10),
        endTimeAnchor: DateTime.utc(2026, 1, 1, 11),
        sourcePointCount: 4,
        sourceFingerprint: 'abc123',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 2),
        updatedByUserId: 'editor',
      );

  Future<void> verifiesRoundTripAndReset(String sessionId) async {
    var box = await Hive.openBox<SessionTrackEdit>('edits');
    var repository = SessionTrackEditRepository(box: box);
    await repository.save(edit(sessionId));
    expect(repository.get(sessionId)?.startIndexInclusive, 1);

    await box.close();
    box = await Hive.openBox<SessionTrackEdit>('edits');
    repository = SessionTrackEditRepository(box: box);
    expect(repository.get(sessionId)?.updatedByUserId, 'editor');

    await repository.delete(sessionId);
    expect(repository.get(sessionId), isNull);
  }

  test('UUID session edit survives Hive restart and reset', () async {
    await verifiesRoundTripAndReset('b4ef1834-7d49-43db-9922-c6efcd1a8c0b');
  });

  test('legacy int-key session uses stable string key', () async {
    await verifiesRoundTripAndReset('42');
  });
}
