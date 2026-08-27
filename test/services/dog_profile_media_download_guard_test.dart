import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/services/dog_profile_media_download_guard.dart';

void main() {
  test('marks eligible dog once per profileMediaId', () {
    final guard = DogProfileMediaDownloadGuard();
    final dog = _dog(profileMediaId: ' profile-media-1 ');

    expect(guard.markAttemptIfEligible(dog), isTrue);
    expect(guard.markAttemptIfEligible(dog), isFalse);
    expect(
      guard.markAttemptIfEligible(_dog(profileMediaId: 'profile-media-2')),
      isTrue,
    );
  });

  test('rejects missing profileMediaId cloudId or dogKey', () {
    final guard = DogProfileMediaDownloadGuard();

    expect(guard.markAttemptIfEligible(_dog(profileMediaId: null)), isFalse);
    expect(
      guard.markAttemptIfEligible(
        _dog(profileMediaId: 'profile-media-1', cloudId: null),
      ),
      isFalse,
    );
    expect(
      guard.markAttemptIfEligible(
        _dog(profileMediaId: 'profile-media-1', dogKey: ' '),
      ),
      isFalse,
    );
  });
}

Dog _dog({
  String? profileMediaId,
  String? cloudId = 'dog-cloud-1',
  String dogKey = 'DOG-1',
}) {
  return Dog(
    name: 'Birk',
    dogKey: dogKey,
    regNrDisplay: 'NO123/45',
    cloudId: cloudId,
    profileMediaId: profileMediaId,
  );
}
