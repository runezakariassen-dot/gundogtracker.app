import 'package:flutter/services.dart';

/// V1: Lett haptic kun ved reell suksess.
/// Ikke bruk på valideringsfeil.
class HapticsService {
  const HapticsService._();

  static Future<void> lightSuccess() async {
    // "SelectionClick" er snill og diskret på iOS, ok på Android.
    await HapticFeedback.selectionClick();
  }

  static Future<void> mediumSuccess() async {
    await HapticFeedback.lightImpact();
  }
}
