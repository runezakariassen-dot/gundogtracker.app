import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';

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
}
