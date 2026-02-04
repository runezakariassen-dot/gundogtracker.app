import '../data/local/local_dog_repository.dart';
import '../data/local/local_membership_repository.dart';
import '../domain/repositories/dog_repository.dart';
import '../domain/repositories/membership_repository.dart';
import '../models/dog.dart';
import '../models/dog_membership.dart';
import '../utils/reg_nr.dart';
import 'user_identity_service.dart';

class DogService {
  DogService({
    UserIdentityService? identityService,
    DogRepository? dogRepository,
    DogMembershipRepository? membershipRepository,
  })  : _identityService = identityService ?? UserIdentityService(),
        _dogRepository = dogRepository ?? LocalDogRepository(),
        _membershipRepository =
            membershipRepository ?? LocalDogMembershipRepository();

  final UserIdentityService _identityService;
  final DogRepository _dogRepository;
  final DogMembershipRepository _membershipRepository;

  Future<Dog> createDog({
    required String regNrInput,
    required String name,
    String? imagePath,
    DateTime? birthDate,
    String? pedigreeUrl,
    String? breed,
  }) async {
    final regNrDisplay = regNrInput.trim().toUpperCase();
    final dogKey = normalizeRegNr(regNrDisplay);
    if (!validateRegNr(dogKey)) {
      throw FormatException('Ugyldig reg.nr');
    }

    final exists = await _dogRepository.getDog(dogKey) != null;
    if (exists) {
      throw StateError('exists');
    }

    final currentUserId = _identityService.getCurrentUserId();
    final dog = Dog(
      name: name.trim(),
      dogKey: dogKey,
      regNrDisplay: regNrDisplay,
      imagePath: imagePath,
      birthDate: birthDate,
      pedigreeUrl: pedigreeUrl,
      breed: breed,
      ownerUserId: currentUserId,
      updatedAt: DateTime.now(),
    );

    await _dogRepository.upsertDog(dog);

    final membership = DogMembership(
      dogKey: dogKey,
      userId: currentUserId,
      role: Role.admin,
      status: Status.active,
      addedAt: DateTime.now(),
      addedByUserId: currentUserId,
    );
    await _membershipRepository.upsertMembership(membership);

    return dog;
  }
}
