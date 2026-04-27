import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/config/subscription_products.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/subscription/subscription_service.dart';

class _FakeSubscriptionStoreClient implements SubscriptionStoreClient {
  _FakeSubscriptionStoreClient({
    List<StoreProduct>? products,
  }) : _products = products ?? const [];

  final List<StoreProduct> _products;
  final StreamController<List<StorePurchaseUpdate>> _controller =
      StreamController<List<StorePurchaseUpdate>>.broadcast();

  int restoreCalls = 0;
  int completeCalls = 0;
  int buyCalls = 0;
  Completer<bool>? buyCompleter;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseStream => _controller.stream;

  @override
  Future<bool> buy(StoreProduct product) {
    buyCalls += 1;
    final completer = buyCompleter;
    if (completer != null) {
      return completer.future;
    }
    return Future.value(true);
  }

  @override
  Future<void> completePurchase(StorePurchaseUpdate purchase) async {
    completeCalls += 1;
  }

  void emit(StorePurchaseUpdate update) {
    _controller.add(<StorePurchaseUpdate>[update]);
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<StoreProduct>> queryProducts(Set<String> productIds) async {
    return _products
        .where((product) => productIds.contains(product.id))
        .toList(growable: false);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls += 1;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late _FakeSubscriptionStoreClient storeClient;
  late SubscriptionService service;
  late DateTime now;

  StorePurchaseUpdate monthlyUpdate(StorePurchaseStatus status) {
    return StorePurchaseUpdate(
      productId: monthlyProductId,
      status: status,
      needsCompletion: false,
      transactionDate: now.subtract(const Duration(days: 1)),
    );
  }

  Future<void> waitForSubscriptionState(
    bool Function(SubscriptionViewData data) matches,
  ) async {
    if (matches(service.state.value)) {
      return;
    }

    final completer = Completer<void>();
    late final void Function() listener;
    listener = () {
      if (!completer.isCompleted && matches(service.state.value)) {
        completer.complete();
      }
    };

    service.state.addListener(listener);
    try {
      await completer.future.timeout(const Duration(seconds: 1));
    } finally {
      service.state.removeListener(listener);
    }
  }

  setUp(() async {
    now = DateTime.utc(2026, 1, 15, 12);
    tempDir = await Directory.systemTemp.createTemp('subscription_service_');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox<dynamic>('appSettings');
    storeClient = _FakeSubscriptionStoreClient(
      products: const [
        StoreProduct(
          id: monthlyProductId,
          title: 'Fuglehund Pro',
          price: '49,00 kr',
          rawDetails: null,
        ),
      ],
    );
    service = SubscriptionService(
      storeClient: storeClient,
      settingsBox: settingsBox,
      clock: () => now,
    );
    await service.init();
  });

  tearDown(() async {
    await service.dispose();
    await storeClient.dispose();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('purchase success stores timed pro entitlement and price', () async {
    expect(
      await service.purchaseMonthly(),
      SubscriptionPurchaseResult.started,
    );

    final activeState = waitForSubscriptionState(
      (data) => data.status == SubscriptionStatus.active,
    );

    storeClient.emit(monthlyUpdate(StorePurchaseStatus.purchased));
    await activeState;

    expect(service.isPro, isTrue);
    expect(settingsBox.get(subscriptionIsProKey), isNull);
    expect(service.state.value.monthlyPrice, '49,00 kr');
    expect(service.state.value.status, SubscriptionStatus.active);
  });

  test('cancelled purchase keeps free status', () async {
    expect(
      await service.purchaseMonthly(),
      SubscriptionPurchaseResult.started,
    );

    storeClient.emit(monthlyUpdate(StorePurchaseStatus.cancelled));

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(service.isPro, isFalse);
    expect(service.state.value.status, SubscriptionStatus.inactive);
  });

  test('restore purchases can reactivate pro from current store update',
      () async {
    await service.restorePurchases();
    expect(storeClient.restoreCalls, 1);

    storeClient.emit(monthlyUpdate(StorePurchaseStatus.restored));

    await waitForSubscriptionState(
      (data) => data.status == SubscriptionStatus.active,
    );

    expect(service.isPro, isTrue);
    expect(service.state.value.status, SubscriptionStatus.active);
  });

  test('old local permanent bool does not unlock pro', () async {
    await settingsBox.put(subscriptionIsProKey, true);
    await service.refresh();

    expect(settingsBox.get(subscriptionIsProKey), isNull);
    expect(service.isPro, isFalse);
    expect(service.state.value.status, SubscriptionStatus.inactive);
    expect(
      service.canCreateDog(currentDogCount: freeDogLimit),
      isFalse,
    );
    expect(
      service.canCreateSession(currentSessionCount: freeSessionLimit),
      isFalse,
    );
  });

  test('expired store update does not grant pro', () async {
    await service.restorePurchases();

    storeClient.emit(
      StorePurchaseUpdate(
        productId: monthlyProductId,
        status: StorePurchaseStatus.restored,
        needsCompletion: false,
        transactionDate: now.subtract(const Duration(days: 40)),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(service.isPro, isFalse);
    expect(service.state.value.status, SubscriptionStatus.inactive);
  });

  test('free limits are lifted only while timed entitlement is active',
      () async {
    expect(
      service.canCreateDog(currentDogCount: freeDogLimit - 1),
      isTrue,
    );
    expect(
      service.canCreateDog(currentDogCount: freeDogLimit),
      isFalse,
    );
    expect(
      service.canCreateSession(currentSessionCount: freeSessionLimit - 1),
      isTrue,
    );
    expect(
      service.canCreateSession(currentSessionCount: freeSessionLimit),
      isFalse,
    );

    expect(
      await service.purchaseMonthly(),
      SubscriptionPurchaseResult.started,
    );
    final activeState = waitForSubscriptionState(
      (data) => data.status == SubscriptionStatus.active,
    );
    storeClient.emit(monthlyUpdate(StorePurchaseStatus.purchased));
    await activeState;

    expect(
      service.canCreateDog(currentDogCount: freeDogLimit),
      isTrue,
    );
    expect(
      service.canCreateSession(currentSessionCount: freeSessionLimit),
      isTrue,
    );

    now = now.add(const Duration(days: 33));
    await service.refresh();

    expect(
      service.canCreateDog(currentDogCount: freeDogLimit),
      isFalse,
    );
    expect(
      service.canCreateSession(currentSessionCount: freeSessionLimit),
      isFalse,
    );
  });

  test('purchase start returns while store dialog remains pending', () async {
    storeClient.buyCompleter = Completer<bool>();

    expect(
      await service.purchaseMonthly(),
      SubscriptionPurchaseResult.started,
    );
    expect(storeClient.buyCalls, 1);
    expect(service.isPro, isFalse);

    storeClient.buyCompleter!.complete(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(service.isPro, isFalse);
  });
}
