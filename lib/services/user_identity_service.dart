import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import '../domain/domain_constants.dart';

class UserIdentityService {
  final Uuid _uuid = const Uuid();

  String getCurrentUserId() {
    final box = Hive.box<dynamic>(appSettingsBoxName);
    final existing = box.get(currentUserIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newId = _uuid.v4();
    box.put(currentUserIdKey, newId);
    return newId;
  }

  String? getDisplayName() {
    final box = Hive.box<dynamic>(appSettingsBoxName);
    final value = box.get(currentUserDisplayNameKey);
    return value is String ? value : null;
  }

  Future<void> setDisplayName(String? name) async {
    final box = Hive.box<dynamic>(appSettingsBoxName);
    if (name == null || name.trim().isEmpty) {
      await box.delete(currentUserDisplayNameKey);
      return;
    }
    await box.put(currentUserDisplayNameKey, name.trim());
  }

  Future<void> setCurrentUserId(String userId) async {
    final box = Hive.box<dynamic>(appSettingsBoxName);
    await box.put(currentUserIdKey, userId);
  }
}
