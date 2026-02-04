import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/data/local/local_hunt_session_repository.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jakthund_session_');

    // Kritisk: gjør domain/HivePathService plugin-uavhengig i tester.
    HivePathService.setOverridePathForTesting(tempDir.path);

    // Init Hive via HivePathService (som nå bruker Hive.init når override er satt).
    await HivePathService.init();

    // Safety: hvis noe i initDomainLayer åpner bokser, må Hive være init’et først.
  });

  tearDown(() async {
    try {
      await Hive.close();
    } catch (_) {}

    // Rydd override så ikke andre tester arver path.
    HivePathService.setOverridePathForTesting(null);

    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('create, update, and close session', () async {
    await initDomainLayer();
    final repo = LocalHuntSessionRepository();

    final startedAt = DateTime(2024, 1, 1, 8, 0);
    final sessionId = await repo.createSession(
      dogId: 'dog-1',
      startedAt: startedAt,
      locationName: 'Fjell',
      timeActiveSeconds: 3600,
      birdContacts: 2,
      points: 1,
      flushes: 1,
      notes: 'Start',
    );

    final created = await repo.getSession(sessionId);
    expect(created, isNotNull);
    expect(created!.dogId, 'dog-1');
    expect(created.location, 'Fjell');
    expect(created.durationMinutes, 60);

    await repo.updateSession(
      sessionId,
      birdContacts: 3,
      points: 2,
      flushes: 2,
      notes: 'Oppdatert',
      timeActiveSeconds: 5400,
    );

    final updated = await repo.getSession(sessionId);
    expect(updated!.birdsSeen, 3);
    expect(updated.points, 2);
    expect(updated.flushes, 2);
    expect(updated.notes, 'Oppdatert');
    expect(updated.durationMinutes, 90);

    await repo.closeSession(
      sessionId,
      startedAt.add(const Duration(minutes: 120)),
    );

    final closed = await repo.getSession(sessionId);
    expect(closed!.durationMinutes, 120);
  });
}
