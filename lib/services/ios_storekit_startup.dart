import 'ios_storekit_startup_stub.dart'
    if (dart.library.io) 'ios_storekit_startup_io.dart' as platform;

typedef StoreKit1Enabler = Future<void> Function();

/// Runs [startup] only after iOS has switched the purchase plugin to StoreKit 1.
Future<T> runAfterIosStoreKitConfiguration<T>(
  Future<T> Function() startup, {
  bool? isIOS,
  StoreKit1Enabler? enableStoreKit1,
}) async {
  if (isIOS ?? platform.isIOS) {
    await (enableStoreKit1 ?? platform.enableStoreKit1)();
  }

  return startup();
}
