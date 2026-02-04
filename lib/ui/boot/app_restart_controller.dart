import 'package:flutter/foundation.dart';

/// Kontrollerer "soft restart" av appen ved å bygge root widget-tree på nytt.
/// Brukes etter restore for å garantere at Hive åpnes på nytt på ren måte.
class AppRestartController {
  AppRestartController._();

  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  static void restartApp({String reason = 'unknown'}) {
    tick.value = tick.value + 1;
    debugPrint(
        '[APP_RESTART] restart requested (reason=$reason) tick=${tick.value}');
  }
}
