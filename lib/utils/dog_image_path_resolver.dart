import '../services/dog_photo_storage.dart';

class DogImagePathResolver {
  static String? toAbsolute(String? storedPath) {
    return DogPhotoStorage.resolveAbsolutePath(storedPath);
  }
}
