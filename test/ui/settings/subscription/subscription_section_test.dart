import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/config/subscription_products.dart';
import 'package:jakthund_app/domain/subscription/subscription_service.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/ui/settings/subscription/subscription_section.dart';

class _FakeSubscriptionStoreClient implements SubscriptionStoreClient {
  _FakeSubscriptionStoreClient({
    List<StoreProduct>? products,
  }) : _products = products ?? const [];

  final List<StoreProduct> _products;
  final StreamController<List<StorePurchaseUpdate>> _controller =
      StreamController<List<StorePurchaseUpdate>>.broadcast();
  int buyCalls = 0;

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
    return _products
        .where((product) => productIds.contains(product.id))
        .toList(growable: false);
  }

  @override
  Future<void> restorePurchases() async {}

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

  testWidgets('renders product title, price and upgrade button', (
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

    final upgradeButton = tester.widget<FilledButton>(
      find.byType(FilledButton).first,
    );
    expect(upgradeButton.onPressed, isNotNull);
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
