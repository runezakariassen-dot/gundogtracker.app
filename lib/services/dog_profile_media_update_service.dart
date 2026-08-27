import '../data/local/local_dog_repository.dart';
import '../domain/repositories/dog_repository.dart';
import '../models/dog.dart';
import 'dog_profile_media_upload_service.dart';

typedef DogProfileMediaUploadForDog = Future<DogProfileMediaUploadResult>
    Function({
  required Dog dog,
  required String localImagePath,
  required String currentUserUid,
  String? contentType,
  int? sizeBytes,
});

typedef DogProfileMediaUpdateClock = DateTime Function();

class DogProfileMediaUpdateService {
  DogProfileMediaUpdateService({
    DogRepository? dogRepository,
    DogProfileMediaUploadService? uploadService,
    DogProfileMediaUploadForDog? uploadProfileImageForDog,
    DogProfileMediaUpdateClock? clock,
  })  : _dogRepository = dogRepository ?? LocalDogRepository(),
        _uploadProfileImageForDog = uploadProfileImageForDog ??
            (uploadService ?? DogProfileMediaUploadService())
                .uploadProfileImageForDog,
        _clock = clock ?? DateTime.now;

  final DogRepository _dogRepository;
  final DogProfileMediaUploadForDog _uploadProfileImageForDog;
  final DogProfileMediaUpdateClock _clock;

  Future<Dog> uploadAndSetProfileMediaId({
    required Dog dog,
    required String localImagePath,
    required String currentUserUid,
    String? contentType,
    int? sizeBytes,
  }) async {
    final uploadResult = await _uploadProfileImageForDog(
      dog: dog,
      localImagePath: localImagePath,
      currentUserUid: currentUserUid,
      contentType: contentType,
      sizeBytes: sizeBytes,
    );
    final updatedDog = dog.copyWith(
      profileMediaId: uploadResult.profileMediaId,
      updatedAt: _clock().toUtc(),
    );
    await _dogRepository.upsertDog(updatedDog);
    return updatedDog;
  }
}
