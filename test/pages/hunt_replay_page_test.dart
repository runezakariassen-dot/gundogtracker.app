// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/pages/hunt_replay_page.dart';

void main() {
  testWidgets('replay page shows map track marker and controls',
      (tester) async {
    final track = Track(
      id: 'track',
      createdAt: DateTime.utc(2026),
      source: 'test',
      points: [
        GpsPoint(lat: 60, lon: 10, time: DateTime.utc(2026)),
        GpsPoint(
          lat: 60.1,
          lon: 10.1,
          time: DateTime.utc(2026).add(const Duration(minutes: 1)),
        ),
      ],
    );
    await _pump(tester, track);

    expect(find.byKey(const ValueKey('hunt-replay-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('hunt-replay-track')), findsOneWidget);
    expect(find.byKey(const ValueKey('hunt-replay-marker')), findsOneWidget);
    expect(find.text('00:00:00 / 00:01:00'), findsOneWidget);
    expect(find.text('10x'), findsOneWidget);
    expect(find.text('Spill av'), findsOneWidget);
  });

  testWidgets('one point track is safe and empty track shows message', (
    tester,
  ) async {
    final onePoint = Track(
      id: 'one',
      createdAt: DateTime.utc(2026),
      source: 'test',
      points: [GpsPoint(lat: 60, lon: 10, time: DateTime.utc(2026))],
    );
    await _pump(tester, onePoint);
    expect(find.byKey(const ValueKey('hunt-replay-marker')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('hunt-replay-play-pause')),
    );
    expect(button.onPressed, isNull);

    final empty = Track(
      id: 'empty',
      createdAt: DateTime.utc(2026),
      source: 'test',
      points: const [],
    );
    await _pump(tester, empty);
    expect(find.byKey(const ValueKey('hunt-replay-empty')), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, Track track) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('nb'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HuntReplayPage(
        key: ValueKey(track.id),
        rawTrack: track,
        tileProvider: _TransparentTileProvider(),
      ),
    ),
  );
  await tester.pump();
}

class _TransparentTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}
