// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/hunt_event.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/pages/session_events_page.dart';
import 'package:jakthund_app/repositories/hunt_event_repository.dart';
import 'package:jakthund_app/services/effective_track_resolver.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String tempPath;
  late Track track;
  late HuntSession session;
  late HuntEventRepository repository;

  setUp(() async {
    final temp = await Directory.systemTemp.createTemp('session_events_');
    tempPath = temp.path;
    HivePathService.setOverridePathForTesting(tempPath);
    HiveLifecycleService.resetForTesting();
    await HivePathService.init();
    registerDomainAdapters();
    await HiveLifecycleService.init();
    repository = _MemoryHuntEventRepository();
    track = Track(
      id: 'track-1',
      createdAt: DateTime.utc(2026),
      source: 'test',
      points: List.generate(
        5,
        (index) => GpsPoint(
          lat: 60 + index / 1000,
          lon: 10 + index / 1000,
          time: DateTime.utc(2026, 1, 1, 10, index),
        ),
      ),
    );
    session = HuntSession(
      sessionId: 'session-1',
      dogId: 'dog-1',
      dogKey: 'DOG-1',
      dateTime: DateTime.utc(2026),
      location: 'Test',
      durationMinutes: 30,
      birdsSeen: 0,
      points: 0,
      flushes: 0,
      notes: '',
      trackId: track.id,
    );
    await tracksBox().put(track.id, track);
    await sessionTrackEditsBox().put(
      session.sessionId,
      SessionTrackEdit(
        sessionId: session.sessionId!,
        sourceTrackId: track.id,
        startIndexInclusive: 2,
        endIndexExclusive: 5,
        startTimeAnchor: track.points[2].time,
        endTimeAnchor: track.points[4].time,
        sourcePointCount: track.points.length,
        sourceFingerprint: EffectiveTrackResolver.fingerprint(track),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    HivePathService.setOverridePathForTesting(null);
    final directory = Directory(tempPath);
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  testWidgets('editor saves selected effective point as raw track index', (
    tester,
  ) async {
    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: session,
    );
    final originalTrackPoints = List<GpsPoint>.from(track.points);
    await _openCreateEditor(tester);
    await _tapPreviewNearEffectiveIndex(tester, 2);
    await tester.pump();

    expect(find.byKey(const ValueKey('event-track-preview-2')), findsOneWidget);
    final selectedTime = track.points[4].time.toLocal();
    final expectedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:'
        '${selectedTime.minute.toString().padLeft(2, '0')}:'
        '${selectedTime.second.toString().padLeft(2, '0')}';

    expect(find.text('Tid: $expectedTime'), findsOneWidget);
    final sliderAfterTap = tester.widget<Slider>(
      find.byKey(const ValueKey('hunt-event-track-slider')),
    );
    expect(sliderAfterTap.value, 2);

    await tester.enterText(
      find.widgetWithText(TextField, 'Notat (valgfritt)'),
      'Ved bekken',
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('save-hunt-event')),
      find.byType(ListView).last,
      const Offset(0, -250),
    );
    await tester.tap(find.byKey(const ValueKey('save-hunt-event')));
    await _pumpRoute(tester);

    final event = repository.listForSession('session-1').single;
    expect(event.trackPointIndex, 4);
    expect(event.latitude, track.points[4].lat);
    expect(event.note, 'Ved bekken');
    expect(track.points, orderedEquals(originalTrackPoints));
  });

  testWidgets('map tap near first middle and final points updates selection', (
    tester,
  ) async {
    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: session,
    );
    await _openCreateEditor(tester);

    await _tapPreviewNearEffectiveIndex(tester, 0, const Offset(-8, 10));
    await tester.pump();
    expect(find.byKey(const ValueKey('event-track-preview-0')), findsOneWidget);
    _expectSelectedTime(tester, track.points[2]);

    await _tapPreviewNearEffectiveIndex(tester, 1, const Offset(10, -8));
    await tester.pump();
    expect(find.byKey(const ValueKey('event-track-preview-1')), findsOneWidget);
    _expectSelectedTime(tester, track.points[3]);

    final sliderAfterMiddleTap = tester.widget<Slider>(
      find.byKey(const ValueKey('hunt-event-track-slider')),
    );
    expect(sliderAfterMiddleTap.value, 1);

    await _tapPreviewNearEffectiveIndex(tester, 2, const Offset(6, -6));
    await tester.pump();
    expect(find.byKey(const ValueKey('event-track-preview-2')), findsOneWidget);
    _expectSelectedTime(tester, track.points[4]);
  });

  testWidgets('slider still updates marker and selected time', (tester) async {
    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: session,
    );
    await _openCreateEditor(tester);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('hunt-event-track-slider')),
    );
    slider.onChanged!(1);
    await tester.pump();
    expect(find.byKey(const ValueKey('event-track-preview-1')), findsOneWidget);
    _expectSelectedTime(tester, track.points[3]);

    slider.onChanged!(2);
    await tester.pump();
    expect(find.byKey(const ValueKey('event-track-preview-2')), findsOneWidget);
    _expectSelectedTime(tester, track.points[4]);
  });

  testWidgets('viewer sees events read-only without add save or delete', (
    tester,
  ) async {
    final event = _event(track.points[3]);
    await repository.upsert(event, enqueueSync: false);
    await _pump(
      tester,
      canEdit: false,
      repository: repository,
      session: session,
    );

    expect(find.byKey(const ValueKey('add-hunt-event')), findsNothing);
    expect(find.byKey(ValueKey('delete-hunt-event-${event.id}')), findsNothing);
    await tester.tap(find.byKey(ValueKey('hunt-event-${event.id}')));
    await _pumpRoute(tester);
    expect(find.byKey(const ValueKey('save-hunt-event')), findsNothing);
    expect(find.byKey(const ValueKey('event-track-preview-1')), findsOneWidget);
    expect(find.text('Hendelse'), findsOneWidget);

    await _tapPreviewNearEffectiveIndex(tester, 2);
    await tester.pump();
    expect(find.byKey(const ValueKey('event-track-preview-1')), findsOneWidget);
  });

  testWidgets('missing track hides add action and handles safely', (
    tester,
  ) async {
    final missingTrackSession = session.copyWith(trackId: 'missing-track');
    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: missingTrackSession,
    );

    expect(find.byKey(const ValueKey('add-hunt-event')), findsNothing);
    expect(find.text('Ingen hendelser registrert'), findsOneWidget);
  });

  testWidgets('empty track hides add action and handles safely', (
    tester,
  ) async {
    final emptyTrack = Track(
      id: 'track-empty',
      createdAt: DateTime.utc(2026),
      source: 'test',
      points: const <GpsPoint>[],
    );
    await tester.runAsync(() async {
      await tracksBox().put(emptyTrack.id, emptyTrack);
    });

    final emptyTrackSession = session.copyWith(trackId: emptyTrack.id);

    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: emptyTrackSession,
    );

    expect(find.byKey(const ValueKey('add-hunt-event')), findsNothing);
    expect(find.text('Ingen hendelser registrert'), findsOneWidget);
  });

  testWidgets('editor can update and soft-delete an event', (tester) async {
    final event = _event(track.points[3]);
    await repository.upsert(event, enqueueSync: false);
    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: session,
    );

    await tester.tap(find.byKey(ValueKey('hunt-event-${event.id}')));
    await _pumpRoute(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Notat (valgfritt)'),
      'Oppdatert',
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('save-hunt-event')),
      find.byType(ListView).last,
      const Offset(0, -250),
    );
    await tester.tap(find.byKey(const ValueKey('save-hunt-event')));
    await _pumpRoute(tester);
    expect(repository.getById(event.id)!.note, 'Oppdatert');

    await tester.tap(find.byKey(ValueKey('delete-hunt-event-${event.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Slett').last);
    await _pumpRoute(tester);
    expect(repository.listForSession('session-1'), isEmpty);
    expect(repository.getById(event.id)!.isDeleted, isTrue);
  });
}

HuntEvent _event(GpsPoint point) => HuntEvent(
      id: 'event-1',
      sessionId: 'session-1',
      dogId: 'dog-1',
      type: HuntEventType.stand,
      occurredAt: point.time,
      sourceTrackId: 'track-1',
      trackPointIndex: 3,
      latitude: point.lat,
      longitude: point.lon,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      createdByUserId: 'owner',
    );

Future<void> _pump(
  WidgetTester tester, {
  required bool canEdit,
  required HuntEventRepository repository,
  required HuntSession session,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('nb'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SessionEventsPage(
        sessionKey: 0,
        session: session,
        canEdit: canEdit,
        repository: repository,
        currentUserId: () => 'owner',
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void _expectSelectedTime(WidgetTester tester, GpsPoint point) {
  final formatted = DateFormat('HH:mm:ss').format(point.time.toLocal());
  expect(find.text('Tid: $formatted'), findsOneWidget);
}

Future<void> _openCreateEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('add-hunt-event')));
  await _pumpRoute(tester);
}

Future<void> _tapPreviewNearEffectiveIndex(
  WidgetTester tester,
  int index, [
  Offset delta = Offset.zero,
]) async {
  final area = find.byKey(const ValueKey('hunt-event-track-preview-tap-area'));
  final rect = tester.getRect(area);
  const padding = 16.0;
  const totalPoints = 3;
  final ratio = totalPoints == 1 ? 0.0 : index / (totalPoints - 1);
  final local = Offset(
    padding + ((rect.width - (padding * 2)) * ratio),
    rect.height - padding - ((rect.height - (padding * 2)) * ratio),
  );
  await tester.tapAt(rect.topLeft + local + delta);
}

class _MemoryHuntEventRepository extends HuntEventRepository {
  _MemoryHuntEventRepository() : super(box: huntEventsBox(), enableSync: false);

  final Map<String, HuntEvent> _events = <String, HuntEvent>{};

  @override
  HuntEvent? getById(String id) => _events[id];

  @override
  List<HuntEvent> listForSession(
    String sessionId, {
    bool includeDeleted = false,
  }) {
    final values = _events.values
        .where(
          (event) =>
              event.sessionId == sessionId &&
              (includeDeleted || event.deletedAt == null),
        )
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return values;
  }

  @override
  Future<void> upsert(HuntEvent event, {bool enqueueSync = true}) async {
    _events[event.id] = event;
  }

  @override
  Future<HuntEvent?> softDelete(
    String id, {
    required DateTime deletedAt,
    String? updatedByUserId,
    bool enqueueSync = true,
  }) async {
    final existing = _events[id];
    if (existing == null) return null;
    final tombstone = existing.copyWith(
      updatedAt: deletedAt.toUtc(),
      updatedByUserId: updatedByUserId,
      deletedAt: deletedAt.toUtc(),
    );
    _events[id] = tombstone;
    return tombstone;
  }
}
