import '../models/dog.dart';

class DogProfileMediaDownloadGuard {
  final Set<String> _attemptedProfileMediaIds = <String>{};

  bool markAttemptIfEligible(Dog dog) {
    final profileMediaId = dog.profileMediaId?.trim();
    final cloudId = dog.cloudId?.trim();
    final dogKey = dog.dogKey.trim();
    if (profileMediaId == null ||
        profileMediaId.isEmpty ||
        cloudId == null ||
        cloudId.isEmpty ||
        dogKey.isEmpty) {
      return false;
    }
    return _attemptedProfileMediaIds.add(profileMediaId);
  }
}
