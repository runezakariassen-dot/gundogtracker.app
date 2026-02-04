import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../config/subscription_products.dart';

enum SubscriptionStatus {
  active,
  inactive,
  unknown,
}

class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  ProductDetails? _monthlyProduct;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  List<PurchaseDetails> _latestPurchases = const [];

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      return;
    }
    _purchaseSub ??= _iap.purchaseStream.listen((purchases) {
      _latestPurchases = purchases;
    });
    final response = await _iap.queryProductDetails(
      {monthlyProductId},
    );
    if (response.productDetails.isNotEmpty) {
      _monthlyProduct = response.productDetails.first;
    }
  }

  Future<SubscriptionStatus> getStatus() async {
    final available = await _iap.isAvailable();
    if (!available) {
      return SubscriptionStatus.unknown;
    }
    final purchases = _latestPurchases;
    if (purchases.isEmpty) {
      return SubscriptionStatus.unknown;
    }
    for (final purchase in purchases) {
      if (purchase.productID == monthlyProductId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        return SubscriptionStatus.active;
      }
    }
    return SubscriptionStatus.inactive;
  }

  Future<void> purchaseMonthly() async {
    if (_monthlyProduct == null) {
      await init();
    }
    final product = _monthlyProduct;
    if (product == null) {
      throw StateError('Produkt ikke tilgjengelig');
    }
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
  }
}
