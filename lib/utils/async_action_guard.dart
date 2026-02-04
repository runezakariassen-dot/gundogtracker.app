import 'package:flutter/foundation.dart';

/// Hindrer dobbelt-trykk / race conditions ved async actions.
/// - returnerer true hvis handling startet
/// - returnerer false hvis den allerede kjører
class AsyncActionGuard extends ChangeNotifier {
  bool _busy = false;
  String? _label;

  bool get isBusy => _busy;
  String? get label => _label;

  /// Kjører [action] dersom guard ikke allerede er busy.
  /// [busyLabel] kan brukes til UI: "Starter...", "Stopper...", "Importer..."
  Future<T?> run<T>({
    required Future<T> Function() action,
    String? busyLabel,
  }) async {
    if (_busy) return null;

    _busy = true;
    _label = busyLabel;
    notifyListeners();

    try {
      final result = await action();
      return result;
    } finally {
      _busy = false;
      _label = null;
      notifyListeners();
    }
  }
}
