import 'package:flutter/services.dart';

/// V1: Haptics kun når vi faktisk har suksess.
/// Ikke kall haptics på valideringsfeil eller avbrutt flow.
class Haptics {
  const Haptics._();

  static Future<void> lightSuccess() async {
    // HapticFeedback.lightImpact fungerer på iOS/Android uten ekstra deps.
    await HapticFeedback.lightImpact();
  }

  static Future<void> selectionClick() async {
    // Litt “tørrere” feedback, fin på toggles.
    await HapticFeedback.selectionClick();
  }
}
