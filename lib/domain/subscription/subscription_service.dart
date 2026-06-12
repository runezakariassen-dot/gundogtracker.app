import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../config/subscription_products.dart';
import '../../data/hive_boxes.dart';
import '../../services/hive_lifecycle_service.dart';

enum SubscriptionStatus {
  active,
  inactive,
  unknown,
}

enum SubscriptionPurchaseResult {
  started,
  success,
  cancelled,
  error,
}

enum StorePurchaseStatus {
  pending,
  purchased,
  restored,
  cancelled,
  error,
}

class SubscriptionViewData {
  const SubscriptionViewData({
    required this.status,
    required this.isPro,
    required this.storeAvailable,
    required this.hasMonthlyProduct,
    required this.productTitle,
    required this.monthlyPrice,
  });

  const SubscriptionViewData.initial()
      : status = SubscriptionStatus.unknown,
        isPro = false,
        storeAvailable = false,
        hasMonthlyProduct = false,
        productTitle = null,
        monthlyPrice = null;

  final SubscriptionStatus status;
  final bool isPro;
  final bool storeAvailable;
  final bool hasMonthlyProduct;
  final String? productTitle;
  final String? monthlyPrice;
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.rawDetails,
  });

  final String id;
  final String title;
  final String price;
  final Object? rawDetails;
}

class StorePurchaseUpdate {
  const StorePurchaseUpdate({
    required this.productId,
    required this.status,
    required this.needsCompletion,
    this.transactionDate,
    this.expiresAt,
    this.rawDetails,
  });

  final String productId;
  final StorePurchaseStatus status;
  final bool needsCompletion;
  final DateTime? transactionDate;
  final DateTime? expiresAt;
  final Object? rawDetails;
}

abstract class SubscriptionStoreClient {
  Stream<List<StorePurchaseUpdate>> get purchaseStream;

  Future<bool> isAvailable();

  Future<List<StoreProduct>> queryProducts(Set<String> productIds);

  Future<bool> buy(StoreProduct product);

  Future<void> restorePurchases();

  Future<void> completePurchase(StorePurchaseUpdate purchase);
}

class _InAppPurchaseStoreClient implements SubscriptionStoreClient {
  _InAppPurchaseStoreClient({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseStream => _inAppPurchase
      .purchaseStream
      .map((purchases) => purchases.map(_mapPurchase).toList(growable: false));

  @override
  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  @override
  Future<List<StoreProduct>> queryProducts(Set<String> productIds) async {
    final response = await _inAppPurchase.queryProductDetails(productIds);
    return response.productDetails
        .map(
          (product) => StoreProduct(
            id: product.id,
            title: product.title,
            price: product.price,
            rawDetails: product,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> buy(StoreProduct product) {
    final productDetails = product.rawDetails as ProductDetails;
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    return _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restorePurchases() => _inAppPurchase.restorePurchases();

  @override
  Future<void> completePurchase(StorePurchaseUpdate purchase) {
    final purchaseDetails = purchase.rawDetails as PurchaseDetails;
    return _inAppPurchase.completePurchase(purchaseDetails);
  }

  StorePurchaseUpdate _mapPurchase(PurchaseDetails purchase) {
    return StorePurchaseUpdate(
      productId: purchase.productID,
      status: switch (purchase.status) {
        PurchaseStatus.pending => StorePurchaseStatus.pending,
        PurchaseStatus.purchased => StorePurchaseStatus.purchased,
        PurchaseStatus.restored => StorePurchaseStatus.restored,
        PurchaseStatus.canceled => StorePurchaseStatus.cancelled,
        PurchaseStatus.error => StorePurchaseStatus.error,
      },
      needsCompletion: purchase.pendingCompletePurchase,
      transactionDate: _parseStoreTransactionDate(purchase.transactionDate),
      rawDetails: purchase,
    );
  }

  DateTime? _parseStoreTransactionDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final rawTimestamp = int.tryParse(value.trim());
    if (rawTimestamp == null) {
      return null;
    }

    final millis = rawTimestamp < 1000000000000
        ? rawTimestamp * Duration.millisecondsPerSecond
        : rawTimestamp;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}

class SubscriptionService {
  SubscriptionService({
    SubscriptionStoreClient? storeClient,
    Box<dynamic>? settingsBox,
    DateTime Function()? clock,
  })  : _storeClient = storeClient ?? _InAppPurchaseStoreClient(),
        _settingsBox = settingsBox,
        _clock = clock;

  static final SubscriptionService instance = SubscriptionService();

  static const Duration _monthlyEntitlementDuration = Duration(days: 32);

  static const String _entitlementProductIdKey =
      'subscriptionEntitlementProductId';
  static const String _entitlementTransactionDateKey =
      'subscriptionEntitlementTransactionDate';
  static const String _entitlementExpiresAtKey =
      'subscriptionEntitlementExpiresAt';
  static const String _entitlementVerifiedAtKey =
      'subscriptionEntitlementVerifiedAt';
  static const String _entitlementSourceKey = 'subscriptionEntitlementSource';

  final SubscriptionStoreClient _storeClient;
  final Box<dynamic>? _settingsBox;
  final DateTime Function()? _clock;
  final ValueNotifier<SubscriptionViewData> state =
      ValueNotifier(const SubscriptionViewData.initial());

  StreamSubscription<List<StorePurchaseUpdate>>? _purchaseSub;
  StoreProduct? _monthlyProduct;
  bool _purchaseStartInProgress = false;
  bool _storeAvailable = false;
  bool _initialized = false;

  Box<dynamic> get _box =>
      _settingsBox ?? HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);

  DateTime get _now => (_clock ?? DateTime.now)().toUtc();

  bool get isPro {
    final entitlement = _readEntitlement();
    return entitlement != null && entitlement.isActiveAt(_now);
  }

  Future<void> init() async {
    if (_initialized) {
      await _expireStoredEntitlementIfNeeded();
      _emitState();
      return;
    }

    _initialized = true;
    _purchaseSub ??= _storeClient.purchaseStream.listen(_handlePurchases);

    try {
      await _clearLegacyPermanentProFlag();
      await _expireStoredEntitlementIfNeeded();
      // Reflect any already-persisted entitlement immediately instead of
      // waiting for store product loading to finish.
      _emitState();
      _storeAvailable = await _storeClient.isAvailable();
      _emitState();
      if (_storeAvailable) {
        await _loadProducts();
      } else {
        _monthlyProduct = null;
        debugPrint('[SUBSCRIPTION] store unavailable during init');
      }
    } catch (_) {
      _storeAvailable = false;
      _monthlyProduct = null;
      debugPrint('[SUBSCRIPTION] failed to initialize store availability');
    }

    _emitState();
  }

  Future<SubscriptionViewData> refresh() async {
    await init();
    await _clearLegacyPermanentProFlag();
    await _expireStoredEntitlementIfNeeded();
    // Keep the UI aligned with persisted entitlement even if store refresh
    // stalls or product loading fails.
    _emitState();
    if (_storeAvailable) {
      try {
        await _loadProducts();
      } catch (_) {
        _storeAvailable = false;
        _monthlyProduct = null;
        debugPrint('[SUBSCRIPTION] failed to refresh store products');
      }
    }
    _emitState();
    return state.value;
  }

  bool canCreateDog({required int currentDogCount}) {
    return isPro || currentDogCount < freeDogLimit;
  }

  bool canCreateSession({required int currentSessionCount}) {
    return isPro || currentSessionCount < freeSessionLimit;
  }

  Future<SubscriptionPurchaseResult> purchaseMonthly() async {
    await init();
    final product = _monthlyProduct;
    if (!_storeAvailable || product == null) {
      debugPrint(
        '[SUBSCRIPTION] purchaseMonthly blocked: '
        'storeAvailable=$_storeAvailable product=$product',
      );
      return SubscriptionPurchaseResult.error;
    }

    if (_purchaseStartInProgress) {
      return SubscriptionPurchaseResult.started;
    }

    _purchaseStartInProgress = true;

    late final Future<bool> startFuture;
    try {
      startFuture = _storeClient.buy(product);
    } catch (_) {
      _purchaseStartInProgress = false;
      return SubscriptionPurchaseResult.error;
    }

    unawaited(_observePurchaseStart(startFuture));
    return SubscriptionPurchaseResult.started;
  }

  Future<void> _observePurchaseStart(Future<bool> startFuture) async {
    try {
      final started = await startFuture;
      if (!started) {
        debugPrint('[SUBSCRIPTION] store rejected purchase start');
      }
    } catch (_) {
      debugPrint('[SUBSCRIPTION] store purchase start failed');
    } finally {
      _purchaseStartInProgress = false;
    }
  }

  Future<void> restorePurchases() async {
    await init();
    if (!_storeAvailable) {
      return;
    }
    await _storeClient.restorePurchases();
  }

  Future<void> _loadProducts() async {
    final products = await _storeClient.queryProducts(subscriptionProductIds);
    _monthlyProduct = products.cast<StoreProduct?>().firstWhere(
          (product) => product?.id == monthlyProductId,
          orElse: () => null,
        );
    if (_monthlyProduct == null) {
      debugPrint(
        '[SUBSCRIPTION] monthly product unavailable: id=$monthlyProductId',
      );
    }
  }

  Future<void> _handlePurchases(List<StorePurchaseUpdate> purchases) async {
    var didUpdateEntitlement = false;

    for (final purchase in purchases) {
      if (purchase.productId != monthlyProductId) {
        continue;
      }

      switch (purchase.status) {
        case StorePurchaseStatus.pending:
          break;
        case StorePurchaseStatus.purchased:
          final granted = await _storeMonthlyEntitlement(
            purchase: purchase,
            source: 'purchase',
          );
          didUpdateEntitlement = true;
          if (!granted) {
            debugPrint('[SUBSCRIPTION] purchased update did not grant pro');
          }
          break;
        case StorePurchaseStatus.restored:
          final granted = await _storeMonthlyEntitlement(
            purchase: purchase,
            source: 'restore',
          );
          didUpdateEntitlement = true;
          if (!granted) {
            debugPrint('[SUBSCRIPTION] restored update did not grant pro');
          }
          break;
        case StorePurchaseStatus.cancelled:
          _purchaseStartInProgress = false;
          break;
        case StorePurchaseStatus.error:
          _purchaseStartInProgress = false;
          break;
      }

      if (purchase.needsCompletion) {
        try {
          await _storeClient.completePurchase(purchase);
        } catch (_) {
          // Best effort only. Entitlement is based on store event dates.
        }
      }
    }

    if (didUpdateEntitlement) {
      _emitState();
    }
  }

  Future<bool> _storeMonthlyEntitlement({
    required StorePurchaseUpdate purchase,
    required String source,
  }) async {
    final existingEntitlement = _readEntitlement();
    final transactionDate = purchase.transactionDate?.toUtc();
    final expiresAt = _resolvePurchaseExpiry(
      purchase: purchase,
      transactionDate: transactionDate,
    );
    if (expiresAt == null) {
      debugPrint(
        '[SUBSCRIPTION] $source update missing expiry data; '
        'entitlement unchanged',
      );
      return existingEntitlement?.isActiveAt(_now) ?? false;
    }

    if (!expiresAt.isAfter(_now)) {
      debugPrint(
        '[SUBSCRIPTION] $source update expired at $expiresAt; '
        'entitlement unchanged',
      );
      return existingEntitlement?.isActiveAt(_now) ?? false;
    }

    final effectiveTransactionDate =
        transactionDate ?? expiresAt.subtract(_monthlyEntitlementDuration);
    if (_shouldKeepExistingEntitlement(
      existingEntitlement: existingEntitlement,
      candidateExpiresAt: expiresAt,
      candidateTransactionDate: effectiveTransactionDate,
    )) {
      debugPrint(
        '[SUBSCRIPTION] $source update ignored because a newer active '
        'entitlement is already stored',
      );
      return true;
    }

    await _clearLegacyPermanentProFlag();
    await _box.put(_entitlementProductIdKey, monthlyProductId);
    await _box.put(
      _entitlementTransactionDateKey,
      effectiveTransactionDate.millisecondsSinceEpoch,
    );
    await _box.put(_entitlementExpiresAtKey, expiresAt.millisecondsSinceEpoch);
    await _box.put(_entitlementVerifiedAtKey, _now.millisecondsSinceEpoch);
    await _box.put(_entitlementSourceKey, source);
    return true;
  }

  DateTime? _resolvePurchaseExpiry({
    required StorePurchaseUpdate purchase,
    required DateTime? transactionDate,
  }) {
    final explicitExpiry =
        purchase.expiresAt?.toUtc() ?? _extractExpiryFromRawDetails(purchase);
    if (explicitExpiry != null) {
      return explicitExpiry;
    }
    if (transactionDate == null) {
      return null;
    }
    return transactionDate.add(_monthlyEntitlementDuration);
  }

  DateTime? _extractExpiryFromRawDetails(StorePurchaseUpdate purchase) {
    final rawDetails = purchase.rawDetails;
    if (rawDetails is! PurchaseDetails) {
      return null;
    }

    return _extractExpiryFromStructuredPayload(
          rawDetails.verificationData.localVerificationData,
        ) ??
        _extractExpiryFromStructuredPayload(
          _decodeJwsPayload(rawDetails.verificationData.serverVerificationData),
        );
  }

  DateTime? _extractExpiryFromStructuredPayload(String? payload) {
    if (payload == null) {
      return null;
    }

    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      return _findExpiryDateInJson(jsonDecode(trimmed));
    } catch (_) {
      return null;
    }
  }

  String? _decodeJwsPayload(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final segments = rawValue.split('.');
    if (segments.length < 2) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(segments[1]);
      return utf8.decode(base64Url.decode(normalized), allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  DateTime? _findExpiryDateInJson(
    dynamic value, {
    String? parentKey,
  }) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (_isExpiryKey(key)) {
          final parsed = _parseDateValue(entry.value);
          if (parsed != null) {
            return parsed;
          }
        }

        final nested = _findExpiryDateInJson(entry.value, parentKey: key);
        if (nested != null) {
          return nested;
        }
      }
      return null;
    }

    if (value is List) {
      for (final item in value) {
        final nested = _findExpiryDateInJson(item, parentKey: parentKey);
        if (nested != null) {
          return nested;
        }
      }
      return null;
    }

    if (parentKey != null && _isExpiryKey(parentKey)) {
      return _parseDateValue(value);
    }

    return null;
  }

  bool _isExpiryKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('expir') || normalized.contains('expire');
  }

  DateTime? _parseDateValue(dynamic value) {
    if (value is int) {
      return _dateFromEpochValue(value);
    }

    if (value is double) {
      return _dateFromEpochValue(value.round());
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      final numeric = int.tryParse(trimmed);
      if (numeric != null) {
        return _dateFromEpochValue(numeric);
      }

      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return parsed.toUtc();
      }

      final normalized =
          trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
      final normalizedParsed = DateTime.tryParse('${normalized}Z');
      if (normalizedParsed != null) {
        return normalizedParsed.toUtc();
      }
    }

    return null;
  }

  DateTime _dateFromEpochValue(int rawValue) {
    final millis = rawValue.abs() < 1000000000000
        ? rawValue * Duration.millisecondsPerSecond
        : rawValue;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  bool _shouldKeepExistingEntitlement({
    required _SubscriptionEntitlement? existingEntitlement,
    required DateTime candidateExpiresAt,
    required DateTime candidateTransactionDate,
  }) {
    if (existingEntitlement == null || !existingEntitlement.isActiveAt(_now)) {
      return false;
    }

    if (existingEntitlement.expiresAt.isAfter(candidateExpiresAt)) {
      return true;
    }

    return existingEntitlement.expiresAt.isAtSameMomentAs(candidateExpiresAt) &&
        existingEntitlement.transactionDate.isAfter(candidateTransactionDate);
  }

  _SubscriptionEntitlement? _readEntitlement() {
    final productId = _box.get(_entitlementProductIdKey) as String?;
    if (productId != monthlyProductId) {
      return null;
    }

    final transactionMillis = _readMillis(_entitlementTransactionDateKey);
    final expiresAtMillis = _readMillis(_entitlementExpiresAtKey);
    if (transactionMillis == null || expiresAtMillis == null) {
      return null;
    }

    return _SubscriptionEntitlement(
      productId: monthlyProductId,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        transactionMillis,
        isUtc: true,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        expiresAtMillis,
        isUtc: true,
      ),
    );
  }

  int? _readMillis(String key) {
    final value = _box.get(key);
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<void> _expireStoredEntitlementIfNeeded() async {
    final entitlement = _readEntitlement();
    if (entitlement == null) {
      return;
    }
    if (entitlement.isActiveAt(_now)) {
      return;
    }
    await _clearStoredEntitlement();
    debugPrint(
      '[SUBSCRIPTION] stored entitlement expired at '
      '${entitlement.expiresAt}',
    );
  }

  Future<void> _clearStoredEntitlement() async {
    await _box.delete(_entitlementProductIdKey);
    await _box.delete(_entitlementTransactionDateKey);
    await _box.delete(_entitlementExpiresAtKey);
    await _box.delete(_entitlementVerifiedAtKey);
    await _box.delete(_entitlementSourceKey);
    await _clearLegacyPermanentProFlag();
  }

  Future<void> _clearLegacyPermanentProFlag() async {
    if (_box.containsKey(subscriptionIsProKey)) {
      await _box.delete(subscriptionIsProKey);
    }
  }

  void _emitState() {
    final pro = isPro;
    final status = pro
        ? SubscriptionStatus.active
        : (_storeAvailable
            ? SubscriptionStatus.inactive
            : SubscriptionStatus.unknown);
    state.value = SubscriptionViewData(
      status: status,
      isPro: pro,
      storeAvailable: _storeAvailable,
      hasMonthlyProduct: _monthlyProduct != null,
      productTitle: _monthlyProduct?.title,
      monthlyPrice: _monthlyProduct?.price,
    );
  }

  @visibleForTesting
  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _purchaseStartInProgress = false;
    _initialized = false;
  }
}

class _SubscriptionEntitlement {
  const _SubscriptionEntitlement({
    required this.productId,
    required this.transactionDate,
    required this.expiresAt,
  });

  final String productId;
  final DateTime transactionDate;
  final DateTime expiresAt;

  bool isActiveAt(DateTime now) {
    return productId == monthlyProductId && expiresAt.isAfter(now.toUtc());
  }
}
