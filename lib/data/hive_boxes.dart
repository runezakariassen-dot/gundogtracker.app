import 'package:hive/hive.dart';

import '../models/dog.dart';
import '../models/dog_media_asset.dart';
import '../models/dog_milestone_state.dart';
import '../models/dog_membership.dart';
import '../models/hunt_session.dart';
import '../models/ownership_transfer.dart';
import '../models/share_invitation.dart';
import '../models/sync_task.dart';
import '../models/outbox_entry.dart';
import '../models/sync_state.dart';
import '../models/track.dart';
import '../domain/models/active_session_draft.dart';

import '../services/hive_lifecycle_service.dart';

const String dogsBoxName = 'dogsBox_v2';
const String sessionsBoxName = 'sessionsBox_v2';
const String tracksBoxName = 'tracks';
const String dogMembershipsBoxName = 'dogMembershipsBox_v1';
const String shareInvitesBoxName = 'shareInvitesBox_v1';
const String ownershipTransfersBoxName = 'ownershipTransfersBox_v1';
const String syncTasksBoxName = 'syncTasksBox_v1';
const String syncOutboxBoxName = 'sync_outbox_v1';
const String syncStateBoxName = 'sync_state_v1';
const String milestoneSeenBoxName = 'milestone_seen_box';
const String breedCatalogBoxName = 'breed_catalog';
const String activeSessionDraftBoxName = 'active_session_draft';
const String dogMilestoneStateBoxName = 'dog_milestone_state';
const String dogMediaAssetsBoxName = 'dog_media_assets_v1';
const String dogMilestoneStateLegacyBoxName = 'dogMilestoneStateBox_v1';
const String mapSettingsBoxName = 'mapSettings';
const String gpsTracksBoxName = 'gpsTracksBox_v1';
const String birdSpeciesBoxName = 'birdSpeciesBox';
const String appSettingsBoxName = 'appSettings';

const String milestonesEnabledKey = 'milestonesEnabled';
const String hapticsEnabledKey = 'hapticsEnabled';
const String themeSeasonOverrideKey = 'themeSeasonOverride';
const String preferredLocaleCodeKey = 'preferredLocaleCode';
const String dogMilestoneStateMigrationKey = 'dogMilestoneStateMigrationDone';
const String soundOnAppStartKey = 'soundOnAppStart';
const String soundOnMilestoneKey = 'soundOnMilestone';
const String milestoneSeasonGoalPointsKey = 'milestoneSeasonGoalPoints';
const String milestonePersonalGoalPointsKey = 'milestonePersonalGoalPoints';
const String milestoneSeasonGoalAchievedKey = 'milestoneSeasonGoalAchieved';
const String milestonePersonalGoalAchievedKey = 'milestonePersonalGoalAchieved';
const String subscriptionIsProKey = 'subscriptionIsPro';
const String profileNameKey = 'profileName';
const String profilePhoneKey = 'profilePhone';
const String profileEmailKey = 'profileEmail';
const String profileBirthDateKey = 'profileBirthDate';
const String profilePersonalStandGoalKey = 'profilePersonalStandGoal';
const String profileLastCelebratedStandGoalKey =
    'profileLastCelebratedStandGoal';
const String profileLastBirthdayGreetingShownDateKey =
    'profileLastBirthdayGreetingShownDate';

Box<Dog> dogsBox() => HiveLifecycleService.getBox<Dog>(dogsBoxName);
Box<HuntSession> sessionsBox() =>
    HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);

Box<Track> tracksBox() => HiveLifecycleService.getBox<Track>(tracksBoxName);

Box<DogMembership> dogMembershipsBox() =>
    HiveLifecycleService.getBox<DogMembership>(dogMembershipsBoxName);

Box<ShareInvitation> shareInvitesBox() =>
    HiveLifecycleService.getBox<ShareInvitation>(shareInvitesBoxName);

Box<OwnershipTransfer> ownershipTransfersBox() =>
    HiveLifecycleService.getBox<OwnershipTransfer>(ownershipTransfersBoxName);

Box<SyncTask> syncTasksBox() =>
    HiveLifecycleService.getBox<SyncTask>(syncTasksBoxName);

Box<OutboxEntry> syncOutboxBox() =>
    HiveLifecycleService.getBox<OutboxEntry>(syncOutboxBoxName);

Box<SyncState> syncStateBox() =>
    HiveLifecycleService.getBox<SyncState>(syncStateBoxName);

Box<DateTime> milestoneSeenBox() =>
    HiveLifecycleService.getBox<DateTime>(milestoneSeenBoxName);

Box<dynamic> breedCatalogBox() =>
    HiveLifecycleService.getBox<dynamic>(breedCatalogBoxName);

Box<ActiveSessionDraft> activeSessionDraftBox() =>
    HiveLifecycleService.getBox<ActiveSessionDraft>(activeSessionDraftBoxName);

Box<DogMilestoneState> dogMilestoneStateBox() =>
    HiveLifecycleService.getBox<DogMilestoneState>(dogMilestoneStateBoxName);

Box<DogMediaAsset> dogMediaAssetsBox() =>
    HiveLifecycleService.getBox<DogMediaAsset>(dogMediaAssetsBoxName);
