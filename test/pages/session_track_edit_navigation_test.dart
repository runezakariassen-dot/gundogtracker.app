// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/domain/domain_constants.dart';
import 'package:jakthund_app/hunt_session_page.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/pages/hunt_replay_page.dart';
import 'package:jakthund_app/pages/session_track_edit_page.dart';
import 'package:jakthund_app/services/effective_track_resolver.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('session edit navigation', () {
    late String tempDirPath;

    setUp(() async {
      PackageInfo.setMockInitialValues(
        appName: 'Jakthund',
        packageName: 'jakthund_app',
        version: '1.0.19',
        buildNumber: '1',
        buildSignature: 'test',
      );
      final tempDir = await Directory.systemTemp.createTemp('track_edit_nav_');
      tempDirPath = tempDir.path;
      HivePathService.setOverridePathForTesting(tempDirPath);
      HiveLifecycleService.resetForTesting();
      await HivePathService.init();
      registerDomainAdapters();
      await HiveLifecycleService.init();

      await Hive.box<dynamic>(appSettingsBoxName)
          .put(currentUserIdKey, 'owner-1');
      await Hive.box<Dog>(dogsBoxName).put(
        'dog-1',
        Dog(
          id: 'dog-1',
          name: 'Testhund',
          dogKey: 'DOG-1',
          regNrDisplay: 'NO100/01',
          ownerUserId: 'owner-1',
        ),
      );
    });

    tearDown(() async {
      await Hive.close();
      HiveLifecycleService.resetForTesting();
      HivePathService.setOverridePathForTesting(null);
      final tempDir = Directory(tempDirPath);
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    testWidgets('general edit and GPS track edit open separate pages',
        (tester) async {
      await tester.runAsync(() async {
        await _storeSession(key: 0, trackId: 'track-1');
        await Hive.box<Track>(tracksBoxName).put('track-1', _track('track-1'));
      });
      await _pumpSessions(tester,
          replayTileProvider: _TransparentTileProvider());

      expect(find.text('Rediger GPS-spor'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpRoute(tester);
      await tester.tap(find.byKey(const ValueKey('edit-session-0')));
      await _pumpRoute(tester);

      expect(find.byType(SessionTrackEditPage), findsNothing);
      expect(find.text('Rediger økt'), findsWidgets);
      expect(find.widgetWithText(TextField, 'Sted'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await _pumpRoute(tester);
      await tester
          .ensureVisible(find.byKey(const ValueKey('edit-gps-track-0')));
      await _pumpRoute(tester);
      await tester.tap(find.byKey(const ValueKey('edit-gps-track-0')));
      await _pumpRoute(tester);

      expect(find.byType(SessionTrackEditPage), findsOneWidget);
      expect(find.text('Rediger GPS-spor'), findsOneWidget);
    });

    testWidgets('GPS track edit is only shown for a valid local modern Track',
        (tester) async {
      await tester.runAsync(() async {
        await _storeSession(key: 0);
        await _storeSession(key: 1, trackId: 'missing-track');
      });
      await _pumpSessions(
        tester,
        replayTileProvider: _TransparentTileProvider(),
      );

      expect(find.text('Rediger GPS-spor'), findsNothing);
      expect(find.byKey(const ValueKey('edit-gps-track-0')), findsNothing);
      expect(find.byKey(const ValueKey('edit-gps-track-1')), findsNothing);
    });

    testWidgets('valid imported local Track shows replay and opens page',
        (tester) async {
      await tester.runAsync(() async {
        await _storeSession(key: 0, trackId: 'imported-track');
        await Hive.box<Track>(tracksBoxName).put(
          'imported-track',
          _track('imported-track', source: 'gpx_import'),
        );
      });
      await _pumpSessions(
        tester,
        replayTileProvider: _TransparentTileProvider(),
      );

      final replay = find.byKey(
        const ValueKey('hunt-replay-0'),
        skipOffstage: false,
      );
      expect(replay, findsOneWidget);
      await tester.ensureVisible(replay);
      await _pumpRoute(tester);
      await tester.tap(replay);
      await _pumpRoute(tester);
      expect(find.byType(HuntReplayPage), findsOneWidget);
    });

    testWidgets('valid trimmed Track shows replay', (tester) async {
      final track = _track('trimmed-track');
      await tester.runAsync(() async {
        await _storeSession(key: 0, trackId: track.id);
        await Hive.box<Track>(tracksBoxName).put(track.id, track);
        await Hive.box<SessionTrackEdit>(sessionTrackEditsBoxName).put(
          'session-0',
          SessionTrackEdit(
            sessionId: 'session-0',
            sourceTrackId: track.id,
            startIndexInclusive: 1,
            endIndexExclusive: 2,
            startTimeAnchor: track.points[1].time,
            endTimeAnchor: track.points[1].time,
            sourcePointCount: track.points.length,
            sourceFingerprint: EffectiveTrackResolver.fingerprint(track),
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
      });
      await _pumpSessions(tester);

      expect(
        find.byKey(const ValueKey('hunt-replay-0'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('missing Track hides replay', (tester) async {
      await tester.runAsync(() async {
        await _storeSession(key: 0, trackId: 'missing-track');
      });
      await _pumpSessions(tester);

      expect(find.byKey(const ValueKey('hunt-replay-0')), findsNothing);
    });

    testWidgets('empty Track hides replay', (tester) async {
      await tester.runAsync(() async {
        await _storeSession(key: 0, trackId: 'empty-track');
        await Hive.box<Track>(tracksBoxName).put(
          'empty-track',
          Track(
            id: 'empty-track',
            createdAt: DateTime.utc(2026),
            source: 'test',
            points: const [],
          ),
        );
      });
      await _pumpSessions(tester);

      expect(find.byKey(const ValueKey('hunt-replay-0')), findsNothing);
    });
  });
}

Future<void> _storeSession({required int key, String? trackId}) {
  return Hive.box<HuntSession>(sessionsBoxName).put(
    key,
    HuntSession(
      dogId: 'dog-1',
      dogKey: 'DOG-1',
      sessionId: 'session-$key',
      dateTime: DateTime(2026, 10, 14, 10),
      location: 'Teststed $key',
      durationMinutes: 30,
      birdsSeen: 0,
      points: 0,
      flushes: 0,
      notes: '',
      trackId: trackId,
      createdByUserId: 'owner-1',
    ),
  );
}

Track _track(String id, {String source = 'test'}) => Track(
      id: id,
      createdAt: DateTime.utc(2026, 10, 14, 10),
      source: source,
      points: [
        GpsPoint(lat: 60, lon: 10, time: DateTime.utc(2026, 10, 14, 10)),
        GpsPoint(
          lat: 60.001,
          lon: 10.001,
          time: DateTime.utc(2026, 10, 14, 10, 1),
        ),
      ],
    );

Future<void> _pumpSessions(
  WidgetTester tester, {
  TileProvider? replayTileProvider,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('nb'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HuntSessionPage(
        showNewSessionSection: false,
        showSessionList: true,
        replayTileProvider: replayTileProvider,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _TransparentTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
