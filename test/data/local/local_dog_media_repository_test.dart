import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/local/local_dog_media_repository.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';

void main() {
  late Directory tempDir;
  late Box<DogMediaAsset> box;
  late LocalDogMediaRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dog_media_repo_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(49)) {
      Hive.registerAdapter(DogMediaAssetAdapter());
    }
    box = await Hive.openBox<DogMediaAsset>('dog_media_assets_test');
    repository = LocalDogMediaRepository(box: box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('put get listForDog listForSession and profile lookup', () async {
    final profile = _asset(
      mediaId: 'profile-1',
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      kind: DogMediaKind.profileImage,
      createdAt: DateTime.utc(2026, 6, 18, 9),
    );
    final newerProfile = _asset(
      mediaId: 'profile-2',
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      kind: DogMediaKind.profileImage,
      createdAt: DateTime.utc(2026, 6, 18, 10),
    );
    final sessionImage = _asset(
      mediaId: 'session-image-1',
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      sessionId: 'session-1',
      kind: DogMediaKind.sessionImage,
    );
    final otherDog = _asset(
      mediaId: 'other-dog-image',
      dogCloudId: 'dog-cloud-2',
      dogKey: 'DOG-2',
      sessionId: 'session-1',
      kind: DogMediaKind.sessionImage,
    );

    await repository.put(profile);
    await repository.put(newerProfile);
    await repository.put(sessionImage);
    await repository.put(otherDog);

    expect(repository.get('profile-1')?.mediaId, 'profile-1');
    expect(
      repository.listForDog(dogCloudId: 'dog-cloud-1').map((a) => a.mediaId),
      containsAll(<String>['profile-1', 'profile-2', 'session-image-1']),
    );
    expect(
      repository
          .listForSession(dogKey: 'DOG-1', sessionId: 'session-1')
          .map((a) => a.mediaId),
      <String>['session-image-1'],
    );
    expect(
      repository.getProfileImageForDog(dogCloudId: 'dog-cloud-1')?.mediaId,
      'profile-2',
    );
  });

  test('markDeleted hides asset from default list queries', () async {
    final asset = _asset(
      mediaId: 'media-1',
      dogCloudId: 'dog-cloud-1',
      dogKey: 'DOG-1',
      kind: DogMediaKind.sessionImage,
    );

    await repository.put(asset);
    await repository.markDeleted('media-1');

    expect(repository.get('media-1')?.status, DogMediaStatus.deleted);
    expect(repository.listForDog(dogCloudId: 'dog-cloud-1'), isEmpty);
    expect(
      repository.listForDog(dogCloudId: 'dog-cloud-1', includeDeleted: true),
      hasLength(1),
    );
  });
}

DogMediaAsset _asset({
  required String mediaId,
  required String dogCloudId,
  required String dogKey,
  required DogMediaKind kind,
  String? sessionId,
  DateTime? createdAt,
}) {
  return DogMediaAsset(
    mediaId: mediaId,
    dogCloudId: dogCloudId,
    dogKey: dogKey,
    sessionId: sessionId,
    kind: kind,
    status: DogMediaStatus.active,
    syncStatus: DogMediaSyncStatus.localOnly,
    createdAt: createdAt ?? DateTime.utc(2026, 6, 18),
  );
}
