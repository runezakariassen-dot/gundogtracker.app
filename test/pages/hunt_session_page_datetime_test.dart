// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HuntSessionPage date/time functionality', () {
    late String tempDirPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('hunt_session_');
      tempDirPath = tempDir.path;
      HivePathService.setOverridePathForTesting(tempDirPath);
      HiveLifecycleService.resetForTesting();
      await HivePathService.init();
      registerDomainAdapters();
      await HiveLifecycleService.init();
    });

    tearDown(() async {
      await Hive.close();
      HiveLifecycleService.resetForTesting();
      HivePathService.setOverridePathForTesting(null);
      final tempDir = Directory(tempDirPath);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('session datetime is preserved after hive restart', () async {
      final sessionsBox = Hive.box<HuntSession>('sessionsBox_v2');
      final sessionBefore = HuntSession(
        dogId: 'test-dog',
        dateTime: DateTime(2024, 1, 15, 14, 30),
        location: 'Test Location',
        durationMinutes: 60,
        birdsSeen: 2,
        points: 4,
        flushes: 1,
        notes: 'Test notes',
      );

      final key = await sessionsBox.add(sessionBefore);
      expect(sessionsBox.get(key)!.dateTime, DateTime(2024, 1, 15, 14, 30));

      await Hive.close();
      HiveLifecycleService.resetForTesting();
      await HivePathService.init();
      registerDomainAdapters();
      await HiveLifecycleService.init();

      final sessionsBoxAfter = Hive.box<HuntSession>('sessionsBox_v2');
      final sessionAfter = sessionsBoxAfter.get(key);
      expect(sessionAfter, isNotNull);
      expect(sessionAfter!.dateTime, DateTime(2024, 1, 15, 14, 30));
    });
  });

  group('Session list date/time display', () {
    test('formats session date in dd.MM.yyyy HH:mm', () {
      final sessionDate = DateTime(2025, 9, 28, 10, 45);
      final formatted = DateFormat('dd.MM.yyyy HH:mm').format(sessionDate);
      expect(formatted, '28.09.2025 10:45');
    });

    test('formats multiple session dates correctly', () {
      final date1 = DateTime(2025, 9, 25, 7, 30);
      final date2 = DateTime(2025, 9, 28, 18, 5);

      final formatted1 = DateFormat('dd.MM.yyyy HH:mm').format(date1);
      final formatted2 = DateFormat('dd.MM.yyyy HH:mm').format(date2);

      expect(formatted1, '25.09.2025 07:30');
      expect(formatted2, '28.09.2025 18:05');
    });
  });
}
