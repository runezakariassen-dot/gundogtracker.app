import 'package:flutter/foundation.dart';

/// Hindrer dobbelt-trykk / race conditions.
/// Bruk `guard.run(() async { ... })` og disable knapper med `guard.isBusy`.
class AsyncGuard extends ChangeNotifier {
  bool _busy = false;
  bool get isBusy => _busy;

  Future<T?> run<T>(Future<T> Function() action) async {
    if (_busy) return null;
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
