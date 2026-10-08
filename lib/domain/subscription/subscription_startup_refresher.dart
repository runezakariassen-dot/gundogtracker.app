class SubscriptionStartupRefresher {
  SubscriptionStartupRefresher(this._refresh);

  final Future<void> Function() _refresh;
  String? _userId;

  Future<void> refreshForUser(String userId) async {
    if (_userId == userId) {
      return;
    }
    _userId = userId;
    try {
      await _refresh();
    } catch (_) {
      if (_userId == userId) {
        _userId = null;
      }
      rethrow;
    }
  }

  void reset() {
    _userId = null;
  }
}
