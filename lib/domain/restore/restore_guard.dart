import 'package:flutter/foundation.dart';

/// Global guard for å blokkere UI/tilgang under restore + signal om restart.
/// - inProgress: settes true mens restore/kopi pågår
/// - restartRequested: settes true når restore er ferdig og app må restartes
class RestoreGuard {
  static final ValueNotifier<bool> inProgress = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> restartRequested =
      ValueNotifier<bool>(false);

  static Future<T> withRestoreLock<T>(
    Future<T> Function() action, {
    String? label,
    String? reason, // støtter begge navn (tidligere build-feil pga "reason")
  }) async {
    final tag = label ?? reason ?? 'restore';
    debugPrint('[RESTORE_GUARD] withRestoreLock begin ($tag)');
    inProgress.value = true;
    try {
      debugPrint('[RESTORE_GUARD] start');
      final res = await action();
      debugPrint('[RESTORE_GUARD] withRestoreLock success ($tag)');
      return res;
    } catch (e, st) {
      debugPrint('[RESTORE_GUARD] withRestoreLock error ($tag): $e');
      debugPrint(st.toString());
      rethrow;
    } finally {
      debugPrint('[RESTORE_GUARD] end');
      inProgress.value = false;
      debugPrint('[RESTORE_GUARD] withRestoreLock finally ($tag)');
    }
  }

  static void requestRestart({String? reason}) {
    debugPrint('[RESTORE_GUARD] restartRequested=true reason=${reason ?? '-'}');
    restartRequested.value = true;
  }

  static void clearRestartRequest() {
    restartRequested.value = false;
  }
}
