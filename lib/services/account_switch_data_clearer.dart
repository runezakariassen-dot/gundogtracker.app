import 'package:flutter/foundation.dart';

import '../data/hive_boxes.dart';
import '../domain/models/active_session_draft.dart';
import '../models/dog.dart';
import '../models/dog_membership.dart';
import '../models/dog_milestone_state.dart';
import '../models/gps_track.dart';
import '../models/hunt_session.dart';
import '../models/outbox_entry.dart';
import '../models/ownership_transfer.dart';
import '../models/share_invitation.dart';
import '../models/sync_state.dart';
import '../models/sync_task.dart';
import '../models/track.dart';
import 'hive_lifecycle_service.dart';

class AccountSwitchDataClearer {
  AccountSwitchDataClearer._();

  static Future<void> clearUserScopedData({
    required String oldUid,
    required String newUid,
  }) async {
    final before = _AccountSwitchCounts.read();
    debugPrint(
      '[AUTH][SWITCH_CLEAR] start oldUid=$oldUid newUid=$newUid '
      'dogs=${before.dogs} memberships=${before.memberships} '
      'sessions=${before.sessions}',
    );

    await _clearBox<Dog>(dogsBoxName);
    await _clearBox<HuntSession>(sessionsBoxName);
    await _clearBox<Track>(tracksBoxName);
    await _clearBox<GpsTrack>(gpsTracksBoxName);
    await _clearBox<DogMembership>(dogMembershipsBoxName);
    await _clearBox<ShareInvitation>(shareInvitesBoxName);
    await _clearBox<OwnershipTransfer>(ownershipTransfersBoxName);
    await _clearBox<SyncTask>(syncTasksBoxName);
    await _clearBox<OutboxEntry>(syncOutboxBoxName);
    await _clearBox<SyncState>(syncStateBoxName);
    await _clearBox<ActiveSessionDraft>(activeSessionDraftBoxName);
    await _clearBox<DogMilestoneState>(dogMilestoneStateBoxName);

    final after = _AccountSwitchCounts.read();
    debugPrint(
      '[AUTH][SWITCH_CLEAR] complete oldUid=$oldUid newUid=$newUid '
      'dogs=${before.dogs}->${after.dogs} '
      'memberships=${before.memberships}->${after.memberships} '
      'sessions=${before.sessions}->${after.sessions}',
    );
  }

  static Future<void> _clearBox<T>(String boxName) async {
    final box = HiveLifecycleService.getBox<T>(boxName);
    final before = box.length;
    await box.clear();
    debugPrint(
      '[AUTH][SWITCH_CLEAR] cleared box=$boxName count=$before->${box.length}',
    );
  }
}

class _AccountSwitchCounts {
  const _AccountSwitchCounts({
    required this.dogs,
    required this.memberships,
    required this.sessions,
  });

  final int dogs;
  final int memberships;
  final int sessions;

  static _AccountSwitchCounts read() {
    return _AccountSwitchCounts(
      dogs: dogsBox().length,
      memberships: dogMembershipsBox().length,
      sessions: sessionsBox().length,
    );
  }
}
