// File: lib/remote/dto/dog_remote_dto.dart
//
// Remote DTO for Firestore dogs/{dogId}

class DogRemoteDto {
  final String dogId;
  final String ownerUid;

  final String name;
  final String? breed;
  final String? sex;
  final int? birthDateMs;

  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;

  final bool? isDeceased;
  final int? deceasedAtMs;
  final String? notes;

  const DogRemoteDto({
    required this.dogId,
    required this.ownerUid,
    required this.name,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.breed,
    this.sex,
    this.birthDateMs,
    this.isDeceased,
    this.deceasedAtMs,
    this.notes,
    this.schemaVersion = 1,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'dogId': dogId,
      'ownerUid': ownerUid,
      'name': name,
      if (breed != null) 'breed': breed,
      if (sex != null) 'sex': sex,
      if (birthDateMs != null) 'birthDateMs': birthDateMs,
      if (isDeceased != null) 'isDeceased': isDeceased,
      if (deceasedAtMs != null) 'deceasedAtMs': deceasedAtMs,
      if (notes != null) 'notes': notes,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
    };
  }

  static DogRemoteDto fromMap(Map<String, dynamic> map) {
    return DogRemoteDto(
      dogId: _asString(map['dogId']) ?? '',
      ownerUid: _asString(map['ownerUid']) ?? '',
      name: _asString(map['name']) ?? '',
      breed: _asString(map['breed']),
      sex: _asString(map['sex']),
      birthDateMs: _asInt(map['birthDateMs']),
      isDeceased: _asBool(map['isDeceased']),
      deceasedAtMs: _asInt(map['deceasedAtMs']),
      notes: _asString(map['notes']),
      createdAtMs: _asInt(map['createdAtMs']) ?? 0,
      updatedAtMs: _asInt(map['updatedAtMs']) ?? 0,
      schemaVersion: _asInt(map['schemaVersion']) ?? 1,
    );
  }

  /// Robust mapper: Dog (Hive model) -> Firestore DTO
  ///
  /// Strategy:
  /// - If dog has toJson()/toMap() returning Map, use that.
  /// - Else if dog is Map, use it.
  /// - Else try common getters like dog.id/dog.dogId and dog.name.
  static DogRemoteDto fromDog({
    required dynamic dog,
    required String ownerUid,
    int? nowMs,
  }) {
    final n = nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;

    final map = _extractMap(dog);

    // dogId
    final dogId = _asString(map?['dogId']) ??
        _asString(map?['id']) ??
        _tryGetStringGetter(dog, 'dogId') ??
        _tryGetStringGetter(dog, 'id') ??
        '';

    // name
    final name =
        _asString(map?['name']) ?? _tryGetStringGetter(dog, 'name') ?? '';

    // optional fields
    final breed = _asString(map?['breed']) ?? _asString(map?['race']);
    final sex = _asString(map?['sex']) ?? _asString(map?['gender']);
    final birthDateMs = _asInt(map?['birthDateMs']) ??
        _dateToMs(map?['birthDate']) ??
        _dateToMs(map?['dob']) ??
        _tryGetDateGetterMs(dog, 'birthDate') ??
        _tryGetDateGetterMs(dog, 'dob');

    final createdAtMs = _asInt(map?['createdAtMs']) ??
        _dateToMs(map?['createdAt']) ??
        _tryGetDateGetterMs(dog, 'createdAt') ??
        n;

    final updatedAtMs = _asInt(map?['updatedAtMs']) ??
        _dateToMs(map?['updatedAt']) ??
        _tryGetDateGetterMs(dog, 'updatedAt') ??
        n;

    final isDeceased = _asBool(map?['isDeceased']) ??
        _asBool(map?['deceased']) ??
        _tryGetBoolGetter(dog, 'isDeceased');

    final deceasedAtMs = _asInt(map?['deceasedAtMs']) ??
        _dateToMs(map?['deceasedAt']) ??
        _tryGetDateGetterMs(dog, 'deceasedAt');

    final notes = _asString(map?['notes']) ?? _tryGetStringGetter(dog, 'notes');

    return DogRemoteDto(
      dogId: dogId,
      ownerUid: ownerUid,
      name: name,
      breed: breed,
      sex: sex,
      birthDateMs: birthDateMs,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      isDeceased: isDeceased,
      deceasedAtMs: deceasedAtMs,
      notes: notes,
      schemaVersion: 1,
    );
  }

  // ---------------------------
  // Extraction helpers
  // ---------------------------

  static Map<String, dynamic>? _extractMap(dynamic dog) {
    if (dog == null) return null;

    if (dog is Map) {
      return dog.map((k, v) => MapEntry(k.toString(), v));
    }

    // Try toJson()
    try {
      // ignore: avoid_dynamic_calls
      final v = (dog as dynamic).toJson();
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val));
      }
    } catch (_) {}

    // Try toMap()
    try {
      // ignore: avoid_dynamic_calls
      final v = (dog as dynamic).toMap();
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val));
      }
    } catch (_) {}

    return null;
  }

  static String? _tryGetStringGetter(dynamic obj, String getterName) {
    try {
      // ignore: avoid_dynamic_calls
      final v = (obj as dynamic).noSuchMethod(
          Invocation.getter(Symbol(getterName)),
          returnValue: null);
      return _asString(v);
    } catch (_) {
      // If the class has a real getter, dynamic access will work like: obj.name
      // But we can't do that by string without mirrors, so return null here.
      return null;
    }
  }

  static bool? _tryGetBoolGetter(dynamic obj, String getterName) {
    try {
      // ignore: avoid_dynamic_calls
      final v = (obj as dynamic).noSuchMethod(
          Invocation.getter(Symbol(getterName)),
          returnValue: null);
      return _asBool(v);
    } catch (_) {
      return null;
    }
  }

  static int? _tryGetDateGetterMs(dynamic obj, String getterName) {
    try {
      // ignore: avoid_dynamic_calls
      final v = (obj as dynamic).noSuchMethod(
          Invocation.getter(Symbol(getterName)),
          returnValue: null);
      if (v is DateTime) return v.toUtc().millisecondsSinceEpoch;
      if (v is int) return v;
      if (v is String) {
        final dt = DateTime.tryParse(v);
        return dt?.toUtc().millisecondsSinceEpoch;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static int? _dateToMs(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is DateTime) return v.toUtc().millisecondsSinceEpoch;
    if (v is String) {
      final dt = DateTime.tryParse(v);
      return dt?.toUtc().millisecondsSinceEpoch;
    }
    return null;
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static bool? _asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes' || s == 'ja') return true;
      if (s == 'false' || s == '0' || s == 'no' || s == 'nei') return false;
    }
    return null;
  }
}
