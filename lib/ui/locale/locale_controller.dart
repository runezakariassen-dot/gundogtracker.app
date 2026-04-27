import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/hive_boxes.dart';
import '../../domain/settings/settings_repository.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._repository);

  static LocaleController? _instance;
  static LocaleController get instance => _instance!;

  final SettingsRepository _repository;
  Locale? _locale;
  Box<dynamic>? _box;
  ValueListenable<Box<dynamic>>? _listenable;

  Locale? get locale => _locale;

  Future<void> init() async {
    _instance = this;
    _box = Hive.box<dynamic>(appSettingsBoxName);
    _readFromSettings();
    _listenable = _box!.listenable(keys: [preferredLocaleCodeKey]);
    _listenable!.addListener(_readFromSettings);
  }

  void disposeListener() {
    _listenable?.removeListener(_readFromSettings);
  }

  void _readFromSettings() {
    final code = _repository.getPreferredLocaleCode();
    _locale = code == null ? null : Locale(code);
    notifyListeners();
  }

  Future<void> setPreferredLocaleCode(String? code) async {
    await _repository.setPreferredLocaleCode(code);
    _readFromSettings();
  }
}
