import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

class DogBoxHelpers {
  DogBoxHelpers._();

  static Future<void> updateDogPhotoPath({
    required String dogId,
    String? fallbackDogKey,
    required String photoPath,
  }) async {
    final box = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    final key = _keyForDog(box, dogId, fallbackDogKey: fallbackDogKey);
    if (key == null) return;

    final dog = box.get(key);
    if (dog == null) return;

    final updated = dog.copyWith(
      imagePath: photoPath,
      updatedAt: DateTime.now(),
    );
    await box.put(key, updated);
    await box.flush();
  }

  static dynamic _keyForDog(
    Box<Dog> box,
    String dogId, {
    String? fallbackDogKey,
  }) {
    for (final entry in box.toMap().entries) {
      if (entry.value.id == dogId) {
        return entry.key;
      }
    }
    if (fallbackDogKey != null && fallbackDogKey.trim().isNotEmpty) {
      for (final entry in box.toMap().entries) {
        if (entry.value.dogKey == fallbackDogKey) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
