import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/subscription/subscription_startup_refresher.dart';

void main() {
  test('refreshes once at startup and again for a real user switch', () async {
    var refreshCalls = 0;
    final refresher = SubscriptionStartupRefresher(() async {
      refreshCalls += 1;
    });

    await refresher.refreshForUser('user-a');
    await refresher.refreshForUser('user-a');
    expect(refreshCalls, 1);

    await refresher.refreshForUser('user-b');
    expect(refreshCalls, 2);
  });

  test('reset permits refresh when the same user authenticates again',
      () async {
    var refreshCalls = 0;
    final refresher = SubscriptionStartupRefresher(() async {
      refreshCalls += 1;
    });

    await refresher.refreshForUser('user-a');
    refresher.reset();
    await refresher.refreshForUser('user-a');

    expect(refreshCalls, 2);
  });

  test('failed startup refresh can be retried for the same user', () async {
    var refreshCalls = 0;
    final refresher = SubscriptionStartupRefresher(() async {
      refreshCalls += 1;
      if (refreshCalls == 1) {
        throw StateError('store unavailable');
      }
    });

    await expectLater(
      refresher.refreshForUser('user-a'),
      throwsA(isA<StateError>()),
    );
    await refresher.refreshForUser('user-a');

    expect(refreshCalls, 2);
  });
}
