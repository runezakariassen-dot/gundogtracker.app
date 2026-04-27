import '../../models/dog.dart';
import '../../models/dog_sex.dart';

Map<String, dynamic> dogToJson(Dog dog) {
  return dog.toJson();
}

Dog dogFromJson(Map<String, dynamic> json) {
  return Dog(
    id: _readString(json['id']),
    name: _readString(json['name']) ?? '',
    dogKey: _readString(json['dogKey']) ?? '',
    regNrDisplay: _readString(json['regNrDisplay']) ?? '',
    imagePath: _readString(json['imagePath']),
    birthDate: _parseDate(json['birthDate']),
    pedigreeUrl: _readString(json['pedigreeUrl']),
    breed: _readString(json['breed']),
    ownerUserId: _readString(json['ownerUserId']),
    ownerEmail: _readString(json['ownerEmail']),
    title: _readString(json['title']),
    updatedAt: _parseDate(json['updatedAt']),
    regNr: _readString(json['regNr']),
    sex: _parseDogSex(json['sex']),
    deceasedAt: _parseDate(json['deceasedAt']),
    memorialNote: _readString(json['memorialNote']),
    profileHeroTextAnchor:
        _readString(json['profileHeroTextAnchor']) ?? 'bottomLeft',
    profileHeroTextScale: _readDouble(json['profileHeroTextScale']) ?? 1.0,
    nickname: _readString(json['nickname']),
    watermarkShowTitle: _readBool(json['watermarkShowTitle']) ?? true,
    watermarkShowName: _readBool(json['watermarkShowName']) ?? true,
    watermarkShowOfficialName:
        _readBool(json['watermarkShowOfficialName']) ?? true,
    watermarkShowNickname: _readBool(json['watermarkShowNickname']) ?? true,
    watermarkUseDarkText: _readBool(json['watermarkUseDarkText']) ?? false,
    cloudId: _readString(json['cloudId']),
    cloudOwnerUid: _readString(json['cloudOwnerUid']),
    deletedAt: _parseDate(json['deletedAt']),
  );
}

String? _readString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  final raw = _readString(value);
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

double? _readDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

bool? _readBool(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true') {
    return true;
  }
  if (normalized == 'false') {
    return false;
  }
  return null;
}

DogSex? _parseDogSex(dynamic value) {
  if (value is DogSex) {
    return value;
  }
  final raw = _readString(value);
  if (raw == null || raw.isEmpty) {
    return null;
  }
  for (final sex in DogSex.values) {
    if (sex.name == raw) {
      return sex;
    }
  }
  return null;
}
