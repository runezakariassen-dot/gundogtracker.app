import 'dart:io';

import 'package:hive/hive.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/models/achieved_milestone.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/gps_track.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type_adapter.dart';
import 'package:jakthund_app/models/track.dart';

Future<Directory> initHiveForTests({required String prefix}) async {
  final tempDir = await Directory.systemTemp.createTemp(prefix);
  Hive.init(tempDir.path);

  _registerAdapter(DogAdapter());
  _registerAdapter(AchievedMilestoneAdapter());
  _registerAdapter(DogMilestoneStateAdapter());
  _registerAdapter(HuntSessionAdapter());
  _registerAdapter(SessionTypeAdapter());
  _registerAdapter(GpsPointAdapter());
  _registerAdapter(GpsTrackAdapter());
  _registerAdapter(TrackAdapter());
  _registerAdapter(ActiveSessionDraftAdapter());

  await Future.wait([
    Hive.openBox<Dog>(dogsBoxName),
    Hive.openBox<HuntSession>(sessionsBoxName),
    Hive.openBox<GpsTrack>(gpsTracksBoxName),
    Hive.openBox<Track>(tracksBoxName),
    Hive.openBox<String>(birdSpeciesBoxName),
    Hive.openBox<dynamic>(appSettingsBoxName),
    Hive.openBox<DateTime>(milestoneSeenBoxName),
    Hive.openBox<DogMilestoneState>(dogMilestoneStateBoxName),
    Hive.openBox<ActiveSessionDraft>(activeSessionDraftBoxName),
  ]);

  return tempDir;
}

Future<void> teardownHiveForTests(Directory tempDir) async {
  try {
    await Hive.close().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Ignore cleanup failures to avoid hanging tests.
  }
  if (await tempDir.exists()) {
    try {
      await tempDir.delete(recursive: true).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore cleanup failures to avoid hanging tests.
    }
  }
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}
