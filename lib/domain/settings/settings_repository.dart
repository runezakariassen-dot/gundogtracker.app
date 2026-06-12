import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/domain_constants.dart';

class UserProfileSettings {
  const UserProfileSettings({
    this.name,
    this.phone,
    this.email,
    this.birthDate,
    this.personalStandGoal,
  });

  final String? name;
  final String? phone;
  final String? email;
  final DateTime? birthDate;
  final int? personalStandGoal;
}

class SettingsRepository {
  SettingsRepository(this._box);

  final Box<dynamic> _box;

  String? getPreferredLocaleCode() {
    final value = _box.get(preferredLocaleCodeKey);
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  Future<void> setPreferredLocaleCode(String? code) async {
    if (code == null || code.trim().isEmpty) {
      await _box.delete(preferredLocaleCodeKey);
      return;
    }
    await _box.put(preferredLocaleCodeKey, code);
  }

  int? getLastCelebratedPersonalStandGoal() {
    return _readPositiveInt(_profileKey(profileLastCelebratedStandGoalKey));
  }

  Future<void> setLastCelebratedPersonalStandGoal(int? goal) async {
    await _writePositiveInt(_profileKey(profileLastCelebratedStandGoalKey), goal);
  }

  DateTime? getLastBirthdayGreetingShownDate() {
    return _readBirthDate(_profileKey(profileLastBirthdayGreetingShownDateKey));
  }

  Future<void> setLastBirthdayGreetingShownDate(DateTime? date) async {
    final key = _profileKey(profileLastBirthdayGreetingShownDateKey);
    if (date == null) {
      await _box.delete(key);
      return;
    }
    await _box.put(
      key,
      DateTime(date.year, date.month, date.day),
    );
  }

  UserProfileSettings getUserProfile() {
    final nameKey = _profileKey(profileNameKey);
    final phoneKey = _profileKey(profilePhoneKey);
    final emailKey = _profileKey(profileEmailKey);
    final birthDateKey = _profileKey(profileBirthDateKey);
    final standGoalKey = _profileKey(profilePersonalStandGoalKey);
    return UserProfileSettings(
      name: _readTrimmedString(nameKey),
      phone: _readTrimmedString(phoneKey),
      email: _readTrimmedString(emailKey),
      birthDate: _readBirthDate(birthDateKey),
      personalStandGoal: _readPositiveInt(standGoalKey),
    );
  }

  Future<void> setUserProfile(UserProfileSettings profile) async {
    final nameKey = _profileKey(profileNameKey);
    final phoneKey = _profileKey(profilePhoneKey);
    final emailKey = _profileKey(profileEmailKey);
    final birthDateKey = _profileKey(profileBirthDateKey);
    final standGoalKey = _profileKey(profilePersonalStandGoalKey);

    await _writeTrimmedString(nameKey, profile.name);
    await _writeTrimmedString(phoneKey, profile.phone);
    await _writeTrimmedString(emailKey, profile.email);
    await _writePositiveInt(
      standGoalKey,
      profile.personalStandGoal,
    );

    if (profile.birthDate == null) {
      await _box.delete(birthDateKey);
      return;
    }

    final birthDate = DateTime(
      profile.birthDate!.year,
      profile.birthDate!.month,
      profile.birthDate!.day,
    );
    await _box.put(birthDateKey, birthDate);
  }

  String _profileKey(String baseKey) {
    final scope = _activeUserScopeId();
    if (scope == null) {
      return baseKey;
    }
    return '$baseKey::$scope';
  }

  String? _activeUserScopeId() {
    final value = _box.get(currentUserIdKey);
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? _readTrimmedString(String key) {
    final value = _box.get(key);
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  DateTime? _readBirthDate(String key) {
    final value = _box.get(key);
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    if (value is int) {
      final parsed = DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }

  int? _readPositiveInt(String key) {
    final value = _box.get(key);
    if (value is int && value > 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return null;
  }

  Future<void> _writeTrimmedString(String key, String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _box.delete(key);
      return;
    }
    await _box.put(key, value.trim());
  }

  Future<void> _writePositiveInt(String key, int? value) async {
    if (value == null || value <= 0) {
      await _box.delete(key);
      return;
    }
    await _box.put(key, value);
  }
}
