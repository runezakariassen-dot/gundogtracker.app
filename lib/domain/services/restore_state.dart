import 'package:flutter/foundation.dart';

class RestoreState {
  RestoreState._();

  static final ValueNotifier<bool> isRestoring = ValueNotifier<bool>(false);

  static void start(String reason) {
    isRestoring.value = true;
    debugPrint('[RESTORE][STATE] start reason=${reason.trim()}');
  }

  static void stop(String reason) {
    isRestoring.value = false;
    debugPrint('[RESTORE][STATE] stop reason=${reason.trim()}');
  }
}
