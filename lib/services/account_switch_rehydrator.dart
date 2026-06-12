import 'package:flutter/foundation.dart';

import 'cloud/firestore_dog_sync_service.dart';
import 'cloud/pull_sync_service.dart';

class AccountSwitchRehydrator {
  AccountSwitchRehydrator({
    Future<int> Function()? restoreAccessibleDogsToHive,
    Future<void> Function()? pullAllVisibleData,
  })  : _restoreAccessibleDogsToHive = restoreAccessibleDogsToHive,
        _pullAllVisibleData = pullAllVisibleData;

  final Future<int> Function()? _restoreAccessibleDogsToHive;
  final Future<void> Function()? _pullAllVisibleData;

  Future<void> rehydrateForCurrentUser() async {
    debugPrint('[AUTH][REHYDRATE] start');

    final restoredDogCount = await (_restoreAccessibleDogsToHive ??
        FirestoreDogSyncService.instance.restoreAccessibleDogsToHive)();
    debugPrint('[AUTH][REHYDRATE] restored dogs count=$restoredDogCount');

    await (_pullAllVisibleData ?? PullSyncService().pullAllVisibleData)();
    debugPrint('[AUTH][REHYDRATE] pull complete');
  }
}
