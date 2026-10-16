// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/hive_path_service.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';
import 'package:jakthund_app/models/hunt_event.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_track_edit.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/pages/session_events_page.dart';
import 'package:jakthund_app/repositories/hunt_event_repository.dart';
import 'package:jakthund_app/services/media_storage.dart';
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
    MediaStorage.setDocumentsDirectoryForTesting(tempPath);
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
    await sessionsBox().put(0, session);
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
    MediaStorage.setDocumentsDirectoryForTesting(null);
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

  testWidgets('editor contains basemap track and selected marker layers', (
    tester,
  ) async {
    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: session,
    );
    await _openCreateEditor(tester);

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hunt-event-basemap-layer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hunt-event-track-layer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hunt-event-marker-layer')),
      findsOneWidget,
    );
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
    await _scrollEditorToBottom(tester);
    expect(
        find.byKey(const ValueKey('hunt-event-media-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-hunt-event-image')), findsNothing);
    expect(find.byKey(const ValueKey('add-hunt-event-video')), findsNothing);
    expect(find.byKey(const ValueKey('event-track-preview-1')), findsOneWidget);
    expect(find.text('Hendelse'), findsOneWidget);

    await _tapPreviewNearEffectiveIndex(tester, 2);
    await tester.pump();
    expect(find.byKey(const ValueKey('event-track-preview-1')), findsOneWidget);
  });

  testWidgets('media section is below note and above save with edit actions',
      (tester) async {
    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: session,
    );
    await _openCreateEditor(tester);
    await _scrollEditorToBottom(tester);

    expect(
        find.byKey(const ValueKey('hunt-event-media-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-hunt-event-image')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-hunt-event-video')), findsOneWidget);
    final note = find.widgetWithText(TextField, 'Notat (valgfritt)');
    final media = find.byKey(const ValueKey('hunt-event-media-section'));
    final save = find.byKey(const ValueKey('save-hunt-event'));
    await tester.ensureVisible(save);
    expect(tester.getTopLeft(note).dy, lessThan(tester.getTopLeft(media).dy));
    expect(tester.getTopLeft(media).dy, lessThan(tester.getTopLeft(save).dy));
  });

  testWidgets('save button is below note and reachable on a small screen', (
    tester,
  ) async {
    await _pump(
      tester,
      canEdit: true,
      repository: repository,
      session: session,
    );
    await _openCreateEditor(tester);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();

    final save = find.byKey(const ValueKey('save-hunt-event'));
    final editorScroll = find.descendant(
      of: find.byKey(const ValueKey('hunt-event-editor-scroll')),
      matching: find.byType(Scrollable),
    );
    final scrollable = tester.state<ScrollableState>(
      editorScroll.first,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.getSize(save).height, 52);
    await tester.tap(save);
    await _pumpRoute(tester);
    expect(repository.listForSession('session-1'), hasLength(1));
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

  testWidgets(
      'production editor import persists provenance and removes final media',
      (tester) async {
    final persistedRepository = HuntEventRepository(enableSync: false);
    final source = File('$tempPath/new-event-image.png');
    await tester.runAsync(
      () => source.writeAsBytes(TileProvider.transparentImage),
    );

    await _pump(
      tester,
      canEdit: true,
      repository: persistedRepository,
      session: session,
      pickMedia: (_) async => source.path,
    );
    await _openCreateEditor(tester);
    await _scrollEditorToBottom(tester);
    final saveEvent = tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('save-hunt-event')),
        )
        .onPressed!;
    final addImage = find.byKey(const ValueKey('add-hunt-event-image'));
    await tester.ensureVisible(addImage);
    final addImageCallback = tester.widget<OutlinedButton>(addImage).onPressed!;
    await tester.runAsync(
      () => _waitForAsyncOperation(
        addImageCallback,
        () => huntEventMediaLinksBox().isNotEmpty,
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => _waitForAsyncOperation(saveEvent, () => huntEventsBox().isNotEmpty),
    );
    await _pumpRoute(tester);

    final event = huntEventsBox().values.single;
    final link = huntEventMediaLinksBox().values.single;
    final asset = dogMediaAssetsBox().get(link.mediaId)!;
    final storedSession = sessionsBox().get(0)!;
    final normalizedAfterAdd =
        await MediaStorage.normalizeMediaPaths(storedSession.mediaPaths);

    expect(link.huntEventId, event.id);
    expect(asset.mediaId, link.mediaId);
    expect(asset.createdByHuntEventId, event.id);
    expect(asset.sessionId, session.sessionId);
    expect(normalizedAfterAdd, hasLength(1));
    expect(normalizedAfterAdd.single, asset.localPath);
    final persistedFile = File(
      (await MediaStorage.resolveMediaPath(asset.localPath!))!,
    );
    expect(await tester.runAsync(persistedFile.exists), isTrue);

    await tester.tap(find.byKey(ValueKey('hunt-event-${event.id}')));
    await _pumpRoute(tester);
    await _scrollEditorToBottom(tester);
    final saveRemoval = tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('save-hunt-event')),
        )
        .onPressed!;
    await tester.tap(
      find.byKey(ValueKey('unlink-hunt-event-media-${asset.mediaId}')),
    );
    await tester.runAsync(
      () => _waitForAsyncOperation(
        saveRemoval,
        () =>
            huntEventMediaLinksBox().isEmpty &&
            dogMediaAssetsBox().get(asset.mediaId) == null,
      ),
    );
    await _pumpRoute(tester);

    expect(huntEventMediaLinksBox().values, isEmpty);
    expect(dogMediaAssetsBox().get(asset.mediaId), isNull);
    expect(sessionsBox().get(0)!.mediaPaths, isEmpty);
    expect(await tester.runAsync(persistedFile.exists), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await Hive.close();
      HiveLifecycleService.resetForTesting();
      await HivePathService.init();
      registerDomainAdapters();
      await HiveLifecycleService.init();
    });

    expect(huntEventMediaLinksBox().values, isEmpty);
    expect(dogMediaAssetsBox().get(asset.mediaId), isNull);
    expect(sessionsBox().get(0)!.mediaPaths, isEmpty);
    expect(await tester.runAsync(persistedFile.exists), isFalse);
  });

  testWidgets(
      'direct import repairs orphan provenance but session choice does not',
      (tester) async {
    const canonicalPath =
        'media/dogs/dog-1/sessions/session-1/reused-image.png';
    final canonicalFile = File('$tempPath/$canonicalPath');
    await tester.runAsync(() async {
      await canonicalFile.parent.create(recursive: true);
      await canonicalFile.writeAsBytes(TileProvider.transparentImage);
    });
    final orphan = DogMediaAsset(
      mediaId: 'orphan-media',
      dogCloudId: 'dog-1',
      dogKey: 'DOG-1',
      sessionId: 'session-1',
      kind: DogMediaKind.sessionImage,
      localPath: canonicalPath,
      status: DogMediaStatus.active,
      syncStatus: DogMediaSyncStatus.localOnly,
      createdAt: DateTime.utc(2026),
    );
    await tester.runAsync(
      () => dogMediaAssetsBox().put(orphan.mediaId, orphan),
    );
    final persistedRepository = HuntEventRepository(enableSync: false);

    await _pump(
      tester,
      canEdit: true,
      repository: persistedRepository,
      session: session,
      pickMedia: (_) async => canonicalPath,
    );
    await _openCreateEditor(tester);
    await _scrollEditorToBottom(tester);
    final saveFirstEvent = tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('save-hunt-event')),
        )
        .onPressed!;
    final addImage = find.byKey(const ValueKey('add-hunt-event-image'));
    await tester.ensureVisible(addImage);
    final addImageCallback = tester.widget<OutlinedButton>(addImage).onPressed!;
    await tester.runAsync(
      () => _waitForAsyncOperation(
        addImageCallback,
        () =>
            dogMediaAssetsBox()
                .get(orphan.mediaId)
                ?.createdByHuntEventId
                ?.isNotEmpty ==
            true,
      ),
    );
    await tester.pump();

    final repaired = dogMediaAssetsBox().get(orphan.mediaId)!;
    expect(repaired.createdByHuntEventId, isNotNull);

    await tester.runAsync(
      () => _waitForAsyncOperation(
        saveFirstEvent,
        () => huntEventsBox().isNotEmpty,
      ),
    );
    await _pumpRoute(tester);
    final firstEvent = huntEventsBox().values.single;
    expect(repaired.createdByHuntEventId, firstEvent.id);

    const preExistingPath =
        'media/dogs/dog-1/sessions/session-1/pre-existing.png';
    final preExistingFile = File('$tempPath/$preExistingPath');
    await tester.runAsync(
      () => preExistingFile.writeAsBytes(TileProvider.transparentImage),
    );
    final preExisting = DogMediaAsset(
      mediaId: 'pre-existing-media',
      dogCloudId: 'dog-1',
      dogKey: 'DOG-1',
      sessionId: 'session-1',
      kind: DogMediaKind.sessionImage,
      localPath: preExistingPath,
      status: DogMediaStatus.active,
      syncStatus: DogMediaSyncStatus.localOnly,
      createdAt: DateTime.utc(2026),
    );
    await tester.runAsync(
      () => dogMediaAssetsBox().put(preExisting.mediaId, preExisting),
    );
    final sessionWithExisting =
        sessionsBox().get(0)!.copyWith(mediaPaths: <String>[preExistingPath]);
    await tester.runAsync(() => sessionsBox().put(0, sessionWithExisting));

    await _pump(
      tester,
      canEdit: true,
      repository: persistedRepository,
      session: sessionWithExisting,
    );
    await _openCreateEditor(tester);
    await _scrollEditorToBottom(tester);
    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('choose-hunt-event-session-media')),
        )
        .onPressed!();
    await _pumpRoute(tester);
    await tester.tap(find.text('pre-existing.png'));
    await _pumpRoute(tester);

    expect(
      dogMediaAssetsBox().get(preExisting.mediaId)!.createdByHuntEventId,
      isNull,
    );
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
  Future<String?> Function(bool video)? pickMedia,
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
        eventMapTileProvider: _TransparentTileProvider(),
        pickMedia: pickMedia,
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

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _waitForAsyncOperation(
  VoidCallback start,
  bool Function() condition,
) async {
  start();
  for (var attempt = 0; attempt < 250 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(condition(), isTrue);
  // The observable persistence condition can become true just before the
  // editor's async callback reaches its final setState.
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void _expectSelectedTime(WidgetTester tester, GpsPoint point) {
  final formatted = DateFormat('HH:mm:ss').format(point.time.toLocal());
  expect(find.text('Tid: $formatted'), findsOneWidget);
}

Future<void> _openCreateEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('add-hunt-event')));
  await _pumpRoute(tester);
}

Future<void> _scrollEditorToBottom(WidgetTester tester) async {
  final scrollable = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byKey(const ValueKey('hunt-event-editor-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
  await tester.pump();
}

Future<void> _tapPreviewNearEffectiveIndex(
  WidgetTester tester,
  int index, [
  Offset delta = Offset.zero,
]) async {
  final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
  final callback = map.options.onTap;
  if (callback == null) return;
  final rawIndex = index + 2;
  callback(
    TapPosition(delta, delta),
    LatLng(60 + rawIndex / 1000, 10 + rawIndex / 1000),
  );
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
