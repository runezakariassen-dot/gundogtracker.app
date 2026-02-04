import 'package:flutter/foundation.dart';

class RestoreState {
  RestoreState._();

  static final ValueNotifier<bool> inProgress = ValueNotifier<bool>(false);

  static void start([String? reason]) {
    inProgress.value = true;
    debugPrint('[RESTORE][STATE] inProgress=true ${reason ?? ""}'.trim());
  }

  static void stop([String? reason]) {
    inProgress.value = false;
    debugPrint('[RESTORE][STATE] inProgress=false ${reason ?? ""}'.trim());
  }
}
