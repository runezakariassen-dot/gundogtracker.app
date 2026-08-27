import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/repositories/dog_repository.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_media_asset.dart';
import 'package:jakthund_app/services/cloud/firestore_dog_sync_service.dart';
import 'package:jakthund_app/services/dog_profile_media_update_service.dart';
import 'package:jakthund_app/services/dog_profile_media_upload_service.dart';

void main() {
  test('happy path updates local dog profileMediaId after upload', () async {
    final repository = _FakeDogRepository();
    final dog = Dog(
      name: 'Birk',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO123/45',
      cloudId: 'dog-cloud-1',
      imagePath: '/local/birk.jpg',
      updatedAt: DateTime.utc(2026, 6, 18, 9),
    );
    await repository.upsertDog(dog);
    final service = DogProfileMediaUpdateService(
      dogRepository: repository,
      clock: () => DateTime.utc(2026, 6, 18, 10),
      uploadProfileImageForDog: ({
        required Dog dog,
        required String localImagePath,
        required String currentUserUid,
        String? contentType,
        int? sizeBytes,
      }) async {
        expect(dog.cloudId, 'dog-cloud-1');
        expect(dog.dogKey, 'DOG-1');
        expect(localImagePath, '/local/birk.jpg');
        expect(currentUserUid, 'owner-uid');
        expect(contentType, 'image/jpeg');
        expect(sizeBytes, 1234);
        return _result(
          mediaId: 'profile-media-1',
          dog: dog,
          localPath: localImagePath,
        );
      },
    );

    final updatedDog = await service.uploadAndSetProfileMediaId(
      dog: dog,
      localImagePath: '/local/birk.jpg',
      currentUserUid: 'owner-uid',
      contentType: 'image/jpeg',
      sizeBytes: 1234,
    );

    expect(updatedDog.profileMediaId, 'profile-media-1');
    expect(updatedDog.imagePath, '/local/birk.jpg');
    expect(updatedDog.updatedAt, DateTime.utc(2026, 6, 18, 10));
    expect(repository.upsertedDogs.last.profileMediaId, 'profile-media-1');
    expect(repository.upsertedDogs.last.imagePath, '/local/birk.jpg');
    expect(repository.upsertedDogs.last.id, dog.id);
  });

  test('upload failure does not change local dog profileMediaId', () async {
    final repository = _FakeDogRepository();
    final dog = Dog(
      name: 'Birk',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO123/45',
      cloudId: 'dog-cloud-1',
      imagePath: '/local/birk.jpg',
      profileMediaId: 'old-profile-media',
      updatedAt: DateTime.utc(2026, 6, 18, 9),
    );
    await repository.upsertDog(dog);
    repository.upsertedDogs.clear();
    final service = DogProfileMediaUpdateService(
      dogRepository: repository,
      uploadProfileImageForDog: ({
        required Dog dog,
        required String localImagePath,
        required String currentUserUid,
        String? contentType,
        int? sizeBytes,
      }) async {
        throw StateError('upload failed');
      },
    );

    await expectLater(
      service.uploadAndSetProfileMediaId(
        dog: dog,
        localImagePath: '/local/birk.jpg',
        currentUserUid: 'owner-uid',
      ),
      throwsA(isA<StateError>()),
    );

    expect(repository.upsertedDogs, isEmpty);
    expect(repository.storedDog.profileMediaId, 'old-profile-media');
    expect(repository.storedDog.imagePath, '/local/birk.jpg');
  });

  test('missing dog cloud id or dog key is rejected before dog update',
      () async {
    final repository = _FakeDogRepository();
    final dog = Dog(
      name: 'Birk',
      dogKey: '',
      regNrDisplay: 'NO123/45',
      imagePath: '/local/birk.jpg',
    );
    final service = DogProfileMediaUpdateService(
      dogRepository: repository,
      uploadProfileImageForDog: ({
        required Dog dog,
        required String localImagePath,
        required String currentUserUid,
        String? contentType,
        int? sizeBytes,
      }) async {
        throw ArgumentError.value(
            dog.cloudId, 'dogCloudId', 'Must not be empty.');
      },
    );

    await expectLater(
      service.uploadAndSetProfileMediaId(
        dog: dog,
        localImagePath: '/local/birk.jpg',
        currentUserUid: 'owner-uid',
      ),
      throwsArgumentError,
    );

    expect(repository.upsertedDogs, isEmpty);
  });

  test('FirestoreDogSyncService payload contains profileMediaId after update',
      () async {
    final repository = _FakeDogRepository();
    final dog = Dog(
      name: 'Birk',
      dogKey: 'DOG-1',
      regNrDisplay: 'NO123/45',
      cloudId: 'dog-cloud-1',
      imagePath: '/local/birk.jpg',
      updatedAt: DateTime.utc(2026, 6, 18, 9),
    );
    final service = DogProfileMediaUpdateService(
      dogRepository: repository,
      clock: () => DateTime.utc(2026, 6, 18, 10),
      uploadProfileImageForDog: ({
        required Dog dog,
        required String localImagePath,
        required String currentUserUid,
        String? contentType,
        int? sizeBytes,
      }) async {
        return _result(
          mediaId: 'profile-media-1',
          dog: dog,
          localPath: localImagePath,
        );
      },
    );

    final updatedDog = await service.uploadAndSetProfileMediaId(
      dog: dog,
      localImagePath: '/local/birk.jpg',
      currentUserUid: 'owner-uid',
    );
    final payload = FirestoreDogSyncService.buildUpsertPayload(
      dog: updatedDog,
      cloudDogId: 'dog-cloud-1',
      cloudOwnerUid: 'owner-uid',
    );

    expect(payload['profileMediaId'], 'profile-media-1');
    expect(payload.containsKey('imagePath'), isFalse);
  });
}

DogProfileMediaUploadResult _result({
  required String mediaId,
  required Dog dog,
  required String localPath,
}) {
  final asset = DogMediaAsset(
    mediaId: mediaId,
    dogCloudId: dog.cloudId ?? '',
    dogKey: dog.dogKey,
    kind: DogMediaKind.profileImage,
    localPath: localPath,
    status: DogMediaStatus.active,
    syncStatus: DogMediaSyncStatus.uploaded,
    createdAt: DateTime.utc(2026, 6, 18, 10),
  );
  return DogProfileMediaUploadResult(
    mediaId: mediaId,
    profileMediaId: mediaId,
    asset: asset,
  );
}

class _FakeDogRepository implements DogRepository {
  Dog? _storedDog;
  final List<Dog> upsertedDogs = <Dog>[];

  Dog get storedDog => _storedDog!;

  @override
  Future<void> deleteDog(String dogKey) async {
    if (_storedDog?.dogKey == dogKey) {
      _storedDog = null;
    }
  }

  @override
  Future<Dog?> getDog(String dogKey) async {
    if (_storedDog?.dogKey == dogKey) return _storedDog;
    return null;
  }

  @override
  Future<List<Dog>> getMyDogs() async {
    final dog = _storedDog;
    if (dog == null) return const <Dog>[];
    return <Dog>[dog];
  }

  @override
  Future<void> upsertDog(Dog dog) async {
    _storedDog = dog;
    upsertedDogs.add(dog);
  }
}
