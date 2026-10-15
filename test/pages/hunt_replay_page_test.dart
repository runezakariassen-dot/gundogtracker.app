// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/features/map/map_tile_sources.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/hunt_event.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/pages/hunt_replay_page.dart';
import 'package:jakthund_app/services/hunt_replay_controller.dart';

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
    final tileLayer = tester.widget<TileLayer>(
      find.byKey(const ValueKey('hunt-replay-basemap')),
    );
    expect(tileLayer.urlTemplate, standardTileSource.urlTemplate);
    expect(tileLayer.tileProvider, isA<_TransparentTileProvider>());
    expect(find.text('00:00:00 / 00:01:00'), findsOneWidget);
    expect(find.text('50x'), findsOneWidget);
    expect(find.text('Spill av'), findsOneWidget);
  });

  testWidgets('event triggers once, pauses, and automatically resumes', (
    tester,
  ) async {
    final track = _timedTrack();
    final event = _event('stand', 1, track);
    final replay = HuntReplayController(track.points);
    await _pump(
      tester,
      track,
      events: [event],
      eventPauseDuration: const Duration(milliseconds: 500),
      replayController: replay,
    );

    expect(
        find.byKey(const ValueKey('hunt-replay-event-stand')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hunt-replay-play-pause')));
    replay.advanceBy(const Duration(milliseconds: 100));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hunt-replay-event-card-stand')),
      findsOneWidget,
    );
    expect(find.text('Pause'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 510));
    expect(
      find.byKey(const ValueKey('hunt-replay-event-card-stand')),
      findsNothing,
    );
    expect(find.text('Pause'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      find.byKey(const ValueKey('hunt-replay-event-card-stand')),
      findsNothing,
    );
  });

  testWidgets('manual pause during event prevents automatic resume', (
    tester,
  ) async {
    final track = _timedTrack();
    final replay = HuntReplayController(track.points);
    await _pump(
      tester,
      track,
      events: [_event('contact', 1, track)],
      eventPauseDuration: const Duration(milliseconds: 500),
      replayController: replay,
    );
    await tester.tap(find.byKey(const ValueKey('hunt-replay-play-pause')));
    replay.advanceBy(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hunt-replay-play-pause')));
    await tester.pump(const Duration(milliseconds: 510));

    expect(find.text('Spill av'), findsOneWidget);
  });

  testWidgets('events at final near-identical point trigger without a loop', (
    tester,
  ) async {
    final track = _timedTrack();
    final replay = HuntReplayController(track.points);
    await _pump(
      tester,
      track,
      events: [_event('last-a', 3, track), _event('last-b', 3, track)],
      eventPauseDuration: const Duration(milliseconds: 100),
      replayController: replay,
    );
    await tester.tap(find.byKey(const ValueKey('hunt-replay-play-pause')));
    replay.advanceBy(const Duration(seconds: 2));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hunt-replay-event-card-last-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hunt-replay-event-card-last-b')),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 110));
    expect(find.byKey(const ValueKey('hunt-replay-event-card-last-a')),
        findsNothing);
    expect(find.text('Spill av'), findsOneWidget);
  });

  testWidgets('seek skips crossed events and backward seek permits retrigger', (
    tester,
  ) async {
    final track = _timedTrack();
    final replay = HuntReplayController(track.points);
    await _pump(
      tester,
      track,
      events: [_event('flush', 1, track)],
      eventPauseDuration: const Duration(milliseconds: 500),
      replayController: replay,
    );
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('hunt-replay-slider')),
    );
    slider.onChangeStart!(0.8);
    slider.onChanged!(0.8);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hunt-replay-event-card-flush')),
      findsNothing,
    );

    final movedSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('hunt-replay-slider')),
    );
    movedSlider.onChangeStart!(0);
    movedSlider.onChanged!(0);
    await tester.tap(find.byKey(const ValueKey('hunt-replay-play-pause')));
    replay.advanceBy(const Duration(milliseconds: 100));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hunt-replay-event-card-flush')),
      findsOneWidget,
    );
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

Track _timedTrack() => Track(
      id: 'timed-track',
      createdAt: DateTime.utc(2026),
      source: 'test',
      points: List.generate(
        4,
        (index) => GpsPoint(
          lat: 60 + index / 1000,
          lon: 10 + index / 1000,
          time: DateTime.utc(2026).add(
            Duration(seconds: const [0, 1, 50, 100][index]),
          ),
        ),
      ),
    );

HuntEvent _event(String id, int index, Track track) => HuntEvent(
      id: id,
      sessionId: 'session',
      dogId: 'dog',
      type: HuntEventType.stand,
      occurredAt: track.points[index].time,
      sourceTrackId: track.id,
      trackPointIndex: index,
      birdSpecies: 'Rype',
      note: 'Testnotat',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      createdByUserId: 'owner',
    );

Future<void> _pump(
  WidgetTester tester,
  Track track, {
  List<HuntEvent> events = const [],
  Duration eventPauseDuration = const Duration(milliseconds: 2500),
  HuntReplayController? replayController,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('nb'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HuntReplayPage(
        key: ValueKey(track.id),
        rawTrack: track,
        events: events,
        tileProvider: _TransparentTileProvider(),
        eventPauseDuration: eventPauseDuration,
        replayController: replayController,
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
