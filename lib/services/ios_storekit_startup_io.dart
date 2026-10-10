import 'dart:io';

import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

bool get isIOS => Platform.isIOS;

Future<void> enableStoreKit1() async {
  // Required fallback for the 1.0.15 iOS purchase flow.
  // ignore: deprecated_member_use
  await InAppPurchaseStoreKitPlatform.enableStoreKit1();
}
