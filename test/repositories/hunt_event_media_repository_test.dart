import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';
import 'package:jakthund_app/models/hunt_event_media_link.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type_adapter.dart';
import 'package:jakthund_app/repositories/hunt_event_media_repository.dart';
import 'package:jakthund_app/services/media_storage.dart';

void main() {
  late Directory tempDirectory;
  late Box<HuntEventMediaLink> linkBox;
  late Box<DogMediaAsset> mediaBox;
  late Box<HuntSession> sessionBox;
  late HuntEventMediaRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('event_media_');
    Hive.init(tempDirectory.path);
    if (!Hive.isAdapterRegistered(53)) {
      Hive.registerAdapter(HuntEventMediaLinkAdapter());
    }
    if (!Hive.isAdapterRegistered(49)) {
      Hive.registerAdapter(DogMediaAssetAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HuntSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }
    linkBox = await Hive.openBox<HuntEventMediaLink>('links');
    mediaBox = await Hive.openBox<DogMediaAsset>('media');
    sessionBox = await Hive.openBox<HuntSession>('sessions');
    MediaStorage.setDocumentsDirectoryForTesting(tempDirectory.path);
    repository = HuntEventMediaRepository(
      linkBox: linkBox,
      mediaBox: mediaBox,
      sessionBox: sessionBox,
    );
  });

  tearDown(() async {
    MediaStorage.setDocumentsDirectoryForTesting(null);
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('links photos and videos in stable order without duplicates', () async {
    final photo = _asset('photo', DogMediaKind.sessionImage);
    final video = _asset('video', DogMediaKind.sessionVideo);
    await mediaBox.putAll({photo.mediaId: photo, video.mediaId: video});

    await repository.link(huntEventId: 'event', mediaId: photo.mediaId);
    await repository.link(huntEventId: 'event', mediaId: video.mediaId);
    await repository.link(huntEventId: 'event', mediaId: photo.mediaId);

    expect(
      repository.mediaForEvent('event').map((asset) => asset.mediaId),
      ['photo', 'video'],
    );
    expect(repository.linksForEvent('event'), hasLength(2));
  });

  test('unlink removes only association and survives repository reopen',
      () async {
    final photo = _asset('photo', DogMediaKind.sessionImage);
    await mediaBox.put(photo.mediaId, photo);
    await repository.link(huntEventId: 'event', mediaId: photo.mediaId);

    final reopened = HuntEventMediaRepository(
      linkBox: linkBox,
      mediaBox: mediaBox,
    );
    expect(reopened.mediaForEvent('event'), hasLength(1));

    await reopened.unlink('event', photo.mediaId);
    expect(reopened.mediaForEvent('event'), isEmpty);
    expect(mediaBox.get(photo.mediaId), same(photo));
  });

  test('missing and deleted media references are skipped safely', () async {
    final deleted = _asset(
      'deleted',
      DogMediaKind.sessionImage,
      status: DogMediaStatus.deleted,
    );
    await mediaBox.put(deleted.mediaId, deleted);
    await repository.link(huntEventId: 'event', mediaId: 'missing');
    await repository.link(huntEventId: 'event', mediaId: deleted.mediaId);

    expect(repository.mediaForEvent('event'), isEmpty);
    expect(repository.linksForEvent('event'), hasLength(2));
  });

  test('deleting event links keeps underlying session media', () async {
    final video = _asset('video', DogMediaKind.sessionVideo);
    await mediaBox.put(video.mediaId, video);
    await repository.link(huntEventId: 'event', mediaId: video.mediaId);

    await repository.deleteLinksForEvent('event');

    expect(repository.linksForEvent('event'), isEmpty);
    expect(mediaBox.get(video.mediaId), same(video));
  });

  test('replace with unchanged media preserves link IDs and createdAt',
      () async {
    final createdAt = DateTime.utc(2026, 2, 1);
    final first = await repository.link(
      huntEventId: 'event',
      mediaId: 'photo',
      createdAt: createdAt,
    );
    final second = await repository.link(
      huntEventId: 'event',
      mediaId: 'video',
      createdAt: createdAt.add(const Duration(seconds: 1)),
    );

    await repository.replaceLinks('event', ['photo', 'video']);

    final links = repository.linksForEvent('event');
    expect(links.map((link) => link.id), [first.id, second.id]);
    expect(links.map((link) => link.createdAt), [
      first.createdAt,
      second.createdAt,
    ]);
  });

  test('reordering preserves IDs and createdAt while updating sortOrder',
      () async {
    final first = await repository.link(
      huntEventId: 'event',
      mediaId: 'photo',
      createdAt: DateTime.utc(2026, 2, 1),
    );
    final second = await repository.link(
      huntEventId: 'event',
      mediaId: 'video',
      createdAt: DateTime.utc(2026, 2, 2),
    );

    await repository.replaceLinks('event', ['video', 'photo']);

    final links = repository.linksForEvent('event');
    expect(links.map((link) => link.mediaId), ['video', 'photo']);
    expect(links.map((link) => link.id), [second.id, first.id]);
    expect(links.map((link) => link.createdAt), [
      second.createdAt,
      first.createdAt,
    ]);
    expect(links.map((link) => link.sortOrder), [0, 1]);
  });

  test('removing one media deletes only that link', () async {
    final first = await repository.link(
      huntEventId: 'event',
      mediaId: 'photo',
    );
    final removed = await repository.link(
      huntEventId: 'event',
      mediaId: 'video',
    );
    final third = await repository.link(
      huntEventId: 'event',
      mediaId: 'photo-2',
    );

    await repository.replaceLinks('event', ['photo', 'photo-2']);

    expect(linkBox.get(removed.id), isNull);
    expect(linkBox.get(first.id)?.id, first.id);
    expect(linkBox.get(third.id)?.id, third.id);
  });

  test('adding one media creates only one new link', () async {
    final existing = await repository.link(
      huntEventId: 'event',
      mediaId: 'photo',
    );

    await repository.replaceLinks('event', ['photo', 'video']);

    final links = repository.linksForEvent('event');
    expect(links, hasLength(2));
    expect(links.first.id, existing.id);
    expect(links.last.mediaId, 'video');
    expect(links.last.id, isNot(existing.id));
  });

  test('replace prevents duplicate incoming media IDs preserving first order',
      () async {
    await repository.replaceLinks(
      'event',
      ['video', 'photo', 'video', 'photo', 'third'],
    );

    final links = repository.linksForEvent('event');
    expect(links.map((link) => link.mediaId), ['video', 'photo', 'third']);
    expect(links.map((link) => link.sortOrder), [0, 1, 2]);
  });

  test('ordering uses sortOrder then createdAt then id deterministically',
      () async {
    final sameTime = DateTime.utc(2026, 3, 1);
    await linkBox.putAll({
      'z-link': HuntEventMediaLink(
        id: 'z-link',
        huntEventId: 'event',
        mediaId: 'z-media',
        createdAt: sameTime,
        sortOrder: 0,
      ),
      'later': HuntEventMediaLink(
        id: 'later',
        huntEventId: 'event',
        mediaId: 'later-media',
        createdAt: sameTime.add(const Duration(seconds: 1)),
        sortOrder: 0,
      ),
      'a-link': HuntEventMediaLink(
        id: 'a-link',
        huntEventId: 'event',
        mediaId: 'a-media',
        createdAt: sameTime,
        sortOrder: 0,
      ),
      'last-order': HuntEventMediaLink(
        id: 'last-order',
        huntEventId: 'event',
        mediaId: 'last-media',
        createdAt: sameTime,
        sortOrder: 1,
      ),
    });

    expect(
      repository.linksForEvent('event').map((link) => link.id),
      ['a-link', 'z-link', 'later', 'last-order'],
    );
  });

  test('replace never modifies underlying DogMediaAsset', () async {
    final photo = _asset('photo', DogMediaKind.sessionImage);
    final video = _asset('video', DogMediaKind.sessionVideo);
    await mediaBox.putAll({photo.mediaId: photo, video.mediaId: video});
    final before = mediaBox.toMap();
    await repository.link(huntEventId: 'event', mediaId: photo.mediaId);

    await repository.replaceLinks('event', [video.mediaId]);

    expect(mediaBox.toMap(), before);
  });

  test('replaceLinks removes final event-created media and survives reopen',
      () async {
    final asset = _asset(
      'event-photo',
      DogMediaKind.sessionImage,
      createdByHuntEventId: 'event-a',
    );
    final file = File('${tempDirectory.path}/${asset.localPath!}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    await mediaBox.put(asset.mediaId, asset);
    final absoluteSessionPath = file.path;
    await sessionBox.put('session-key', _session([absoluteSessionPath]));
    await repository.link(huntEventId: 'event-a', mediaId: asset.mediaId);

    await repository.replaceLinks('event-a', const []);

    expect(repository.linksForEvent('event-a'), isEmpty);
    expect(mediaBox.get(asset.mediaId), isNull);
    expect(sessionBox.get('session-key')!.mediaPaths, isEmpty);
    expect(await file.exists(), isFalse);

    await linkBox.close();
    await mediaBox.close();
    await sessionBox.close();
    linkBox = await Hive.openBox<HuntEventMediaLink>('links');
    mediaBox = await Hive.openBox<DogMediaAsset>('media');
    sessionBox = await Hive.openBox<HuntSession>('sessions');
    repository = HuntEventMediaRepository(
      linkBox: linkBox,
      mediaBox: mediaBox,
      sessionBox: sessionBox,
    );

    expect(repository.linksForEvent('event-a'), isEmpty);
    expect(mediaBox.get(asset.mediaId), isNull);
    expect(sessionBox.get('session-key')!.mediaPaths, isEmpty);
    expect(await file.exists(), isFalse);
  });

  test('another event link retains asset session path and file', () async {
    final asset = _asset(
      'shared-photo',
      DogMediaKind.sessionImage,
      createdByHuntEventId: 'event-a',
    );
    final file = File('${tempDirectory.path}/${asset.localPath!}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1]);
    await mediaBox.put(asset.mediaId, asset);
    await sessionBox.put('session', _session([asset.localPath!]));
    await repository.link(huntEventId: 'event-a', mediaId: asset.mediaId);
    await repository.link(huntEventId: 'event-b', mediaId: asset.mediaId);

    await repository.replaceLinks('event-a', const []);
    expect(mediaBox.get(asset.mediaId), isNotNull);
    expect(sessionBox.get('session')!.mediaPaths, [asset.localPath]);
    expect(await file.exists(), isTrue);

    await repository.replaceLinks('event-b', const []);
    expect(mediaBox.get(asset.mediaId), isNull);
    expect(sessionBox.get('session')!.mediaPaths, isEmpty);
    expect(await file.exists(), isFalse);
  });

  test('unrelated session and profile media are never deleted', () async {
    final unrelated = _asset('unrelated', DogMediaKind.sessionImage);
    final profile = _asset(
      'profile',
      DogMediaKind.profileImage,
      createdByHuntEventId: 'event-a',
    );
    await mediaBox.putAll({
      unrelated.mediaId: unrelated,
      profile.mediaId: profile,
    });
    await sessionBox.put('session', _session([unrelated.localPath!]));

    expect(
      await repository.deleteEventCreatedMediaIfUnreferenced(
        unrelated.mediaId,
      ),
      isFalse,
    );
    expect(
      await repository.deleteEventCreatedMediaIfUnreferenced(profile.mediaId),
      isFalse,
    );
    expect(mediaBox.get(unrelated.mediaId), isNotNull);
    expect(mediaBox.get(profile.mediaId), isNotNull);
    expect(sessionBox.get('session')!.mediaPaths, [unrelated.localPath]);
  });
}

DogMediaAsset _asset(
  String id,
  DogMediaKind kind, {
  DogMediaStatus status = DogMediaStatus.active,
  String? createdByHuntEventId,
}) {
  return DogMediaAsset(
    mediaId: id,
    dogCloudId: 'dog',
    dogKey: 'DOG',
    sessionId: 'session',
    kind: kind,
    localPath: 'media/dogs/dog/sessions/session/$id',
    status: status,
    syncStatus: DogMediaSyncStatus.localOnly,
    createdAt: DateTime.utc(2026),
    createdByHuntEventId: createdByHuntEventId,
  );
}

HuntSession _session(List<String> mediaPaths) => HuntSession(
      dogId: 'dog',
      sessionId: 'session',
      dateTime: DateTime.utc(2026),
      location: '',
      durationMinutes: 1,
      birdsSeen: 0,
      points: 0,
      flushes: 0,
      notes: '',
      mediaPaths: mediaPaths,
    );
