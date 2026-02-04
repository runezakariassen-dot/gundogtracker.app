import '../../models/dog.dart';

Map<String, dynamic> dogToJson(Dog dog) {
  return {
    'id': dog.id,
    'name': dog.name,
    'dogKey': dog.dogKey,
    'regNrDisplay': dog.regNrDisplay,
    'regNr': dog.regNr,
    'imagePath': dog.imagePath,
    'birthDate': dog.birthDate?.toIso8601String(),
    'pedigreeUrl': dog.pedigreeUrl,
    'breed': dog.breed,
    'ownerUserId': dog.ownerUserId,
    'updatedAt': dog.updatedAt.toIso8601String(),
  };
}

Dog dogFromJson(Map<String, dynamic> json) {
  return Dog(
    id: json['id'] as String?,
    name: json['name'] as String? ?? '',
    dogKey: json['dogKey'] as String? ?? '',
    regNrDisplay: json['regNrDisplay'] as String? ?? '',
    regNr: json['regNr'] as String?,
    imagePath: json['imagePath'] as String?,
    birthDate: _parseDate(json['birthDate']),
    pedigreeUrl: json['pedigreeUrl'] as String?,
    breed: json['breed'] as String?,
    ownerUserId: json['ownerUserId'] as String?,
    updatedAt: _parseDate(json['updatedAt']),
  );
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
