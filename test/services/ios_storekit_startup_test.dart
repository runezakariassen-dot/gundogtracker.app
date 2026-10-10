import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/services/ios_storekit_startup.dart';

void main() {
  test('enables StoreKit 1 before iOS app startup', () async {
    final events = <String>[];

    await runAfterIosStoreKitConfiguration(
      () async => events.add('startup'),
      isIOS: true,
      enableStoreKit1: () async => events.add('storekit1'),
    );

    expect(events, <String>['storekit1', 'startup']);
  });

  test('leaves non-iOS app startup unchanged', () async {
    final events = <String>[];

    await runAfterIosStoreKitConfiguration(
      () async => events.add('startup'),
      isIOS: false,
      enableStoreKit1: () async => events.add('storekit1'),
    );

    expect(events, <String>['startup']);
  });
}
