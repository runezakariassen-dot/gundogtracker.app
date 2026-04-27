import 'package:flutter/foundation.dart';

import '../../models/dog.dart';
import '../../models/hunt_session.dart';

bool isSessionVisibleInUi({
  required HuntSession? session,
  Dog? dog,
}) {
  return session != null && !session.isDeleted && dog != null && !dog.isDeleted;
}

List<HuntSession> filterVisibleSessions({
  required Iterable<HuntSession> sessions,
  Iterable<Dog>? dogs,
}) {
  final activeDogIds =
      dogs?.where((dog) => !dog.isDeleted).map((dog) => dog.id).toSet();

  return sessions.where((session) {
    if (session.isDeleted) {
      if (kDebugMode) {
        debugPrint(
          '[UI][VISIBILITY] hidden deleted session: ${session.key ?? session.dogId}',
        );
      }
      return false;
    }

    if (activeDogIds != null && !activeDogIds.contains(session.dogId)) {
      if (kDebugMode) {
        debugPrint(
          '[UI][VISIBILITY] hidden deleted session dog: ${session.key ?? session.dogId}',
        );
      }
      return false;
    }

    return true;
  }).toList(growable: false);
}

List<HuntSession> filterVisibleSessionsForDog({
  required Iterable<HuntSession> sessions,
  required String dogId,
  Iterable<Dog>? dogs,
}) {
  return filterVisibleSessions(
    sessions: sessions.where((session) => session.dogId == dogId),
    dogs: dogs,
  );
}
