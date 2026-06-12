import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/config/subscription_products.dart';
import 'package:jakthund_app/domain/subscription/subscription_service.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/ui/settings/subscription/subscription_section.dart';

const String _entitlementProductIdKey = 'subscriptionEntitlementProductId';
const String _entitlementTransactionDateKey =
    'subscriptionEntitlementTransactionDate';
const String _entitlementExpiresAtKey = 'subscriptionEntitlementExpiresAt';
const String _entitlementVerifiedAtKey = 'subscriptionEntitlementVerifiedAt';
const String _entitlementSourceKey = 'subscriptionEntitlementSource';

class _FakeSubscriptionStoreClient implements SubscriptionStoreClient {
  _FakeSubscriptionStoreClient({
    List<StoreProduct>? products,
  }) : _products = products ?? const [];

  final List<StoreProduct> _products;
  final StreamController<List<StorePurchaseUpdate>> _controller =
      StreamController<List<StorePurchaseUpdate>>.broadcast();
  Completer<List<StoreProduct>>? queryProductsCompleter;
  int buyCalls = 0;
  int restoreCalls = 0;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseStream => _controller.stream;

  @override
  Future<bool> buy(StoreProduct product) async {
    buyCalls += 1;
    return true;
  }

  @override
  Future<void> completePurchase(StorePurchaseUpdate purchase) async {}

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<StoreProduct>> queryProducts(Set<String> productIds) async {
    final completer = queryProductsCompleter;
    if (completer != null) {
      return completer.future;
    }
    return _products
        .where((product) => productIds.contains(product.id))
        .toList(growable: false);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls += 1;
  }

  void emit(StorePurchaseUpdate update) {
    _controller.add(<StorePurchaseUpdate>[update]);
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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('subscription_section_');
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
    );
  });

  tearDown(() async {
    await service.dispose();
    await storeClient.dispose();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('non-Pro shows upgrade card, price and enabled upgrade button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionSection(service: service),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Fuglehund Pro'), findsOneWidget);
    expect(find.text('49,00 kr'), findsOneWidget);
    expect(find.text('Oppgrader til Pro'), findsOneWidget);
    expect(find.text('Ubegrenset antall hunder'), findsOneWidget);
    expect(find.text('Ubegrenset antall økter'), findsOneWidget);
    expect(find.text('GundogTracker Pro aktiv'), findsNothing);

    final upgradeButton = tester.widget<FilledButton>(
      find.byType(FilledButton).first,
    );
    expect(upgradeButton.onPressed, isNotNull);
  });

  testWidgets('shows inactive status when entitlement is false',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionSection(service: service),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Status: Ikke aktivt'), findsOneWidget);
    final upgradeButton = tester.widget<FilledButton>(
      find.byType(FilledButton).first,
    );
    expect(upgradeButton.onPressed, isNotNull);
  });

  testWidgets('shows active status when entitlement is true', (tester) async {
    final transactionDate = DateTime.now().toUtc().subtract(
          const Duration(days: 1),
        );
    final expiresAt = transactionDate.add(const Duration(days: 32));

    await tester.runAsync(() async {
      await settingsBox.put(_entitlementProductIdKey, monthlyProductId);
      await settingsBox.put(
        _entitlementTransactionDateKey,
        transactionDate.millisecondsSinceEpoch,
      );
      await settingsBox.put(
        _entitlementExpiresAtKey,
        expiresAt.millisecondsSinceEpoch,
      );
      await settingsBox.put(
        _entitlementVerifiedAtKey,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await settingsBox.put(_entitlementSourceKey, 'test');
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionSection(service: service),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('GundogTracker Pro aktiv'), findsOneWidget);
    expect(find.text('Ubegrenset antall hunder'), findsOneWidget);
    expect(find.textContaining('Status: Pro aktiv'), findsOneWidget);
    expect(find.text('Oppgrader til Pro'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('status updates after purchase simulation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionSection(service: service),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Status: Ikke aktivt'), findsOneWidget);

    await tester.runAsync(() async {
      final transactionDate = DateTime.now().toUtc().subtract(
            const Duration(days: 1),
          );
      final expiresAt = transactionDate.add(const Duration(days: 32));

      await settingsBox.put(_entitlementProductIdKey, monthlyProductId);
      await settingsBox.put(
        _entitlementTransactionDateKey,
        transactionDate.millisecondsSinceEpoch,
      );
      await settingsBox.put(
        _entitlementExpiresAtKey,
        expiresAt.millisecondsSinceEpoch,
      );
      await settingsBox.put(
        _entitlementVerifiedAtKey,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await settingsBox.put(_entitlementSourceKey, 'purchase');
      await service.refresh();
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('GundogTracker Pro aktiv'), findsOneWidget);
    expect(find.textContaining('Status: Pro aktiv'), findsOneWidget);
    expect(find.text('Oppgrader til Pro'), findsNothing);
  });

  testWidgets(
      'shows Pro active from stored entitlement before product lookup completes',
      (tester) async {
    final transactionDate = DateTime.now().toUtc().subtract(
          const Duration(days: 1),
        );
    final expiresAt = transactionDate.add(const Duration(days: 32));
    storeClient.queryProductsCompleter = Completer<List<StoreProduct>>();

    await tester.runAsync(() async {
      await settingsBox.put(_entitlementProductIdKey, monthlyProductId);
      await settingsBox.put(
        _entitlementTransactionDateKey,
        transactionDate.millisecondsSinceEpoch,
      );
      await settingsBox.put(
        _entitlementExpiresAtKey,
        expiresAt.millisecondsSinceEpoch,
      );
      await settingsBox.put(
        _entitlementVerifiedAtKey,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await settingsBox.put(_entitlementSourceKey, 'test');
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionSection(service: service),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Status: Pro aktiv'), findsOneWidget);
  });

  testWidgets('shows unavailable state cleanly and blocks purchase', (
    tester,
  ) async {
    storeClient = _FakeSubscriptionStoreClient(products: const []);
    service = SubscriptionService(
      storeClient: storeClient,
      settingsBox: settingsBox,
    );

    await tester.binding.setSurfaceSize(const Size(280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionSection(service: service),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Fuglehund Pro'), findsOneWidget);
    expect(find.text('Pris utilgjengelig'), findsWidgets);
    expect(
      find.text('Produktet er ikke tilgjengelig i butikken akkurat nå.'),
      findsWidgets,
    );

    final upgradeButton = tester.widget<FilledButton>(
      find.byType(FilledButton).first,
    );
    expect(upgradeButton.onPressed, isNotNull);

    await tester.tap(find.text('Oppgrader til Pro'));
    await tester.pump();

    expect(storeClient.buyCalls, 0);
    expect(
      find.text('Produktet er ikke tilgjengelig i butikken akkurat nå.'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
