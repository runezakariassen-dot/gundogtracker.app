import 'package:flutter/widgets.dart';

import '../models/hunt_event.dart';
import '../l10n/app_localizations.dart';

String huntEventTypeLabel(BuildContext context, HuntEventType type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type) {
    case HuntEventType.stand:
      return l10n.hunt_event_type_stand;
    case HuntEventType.birdContact:
      return l10n.hunt_event_type_bird_contact;
    case HuntEventType.flush:
      return l10n.hunt_event_type_flush;
    case HuntEventType.bump:
      return l10n.hunt_event_type_bump;
    case HuntEventType.birdDown:
      return l10n.hunt_event_type_bird_down;
    case HuntEventType.backing:
      return l10n.hunt_event_type_backing;
    case HuntEventType.emptyStand:
      return l10n.hunt_event_type_empty_stand;
    case HuntEventType.other:
      return l10n.hunt_event_type_other;
  }
}

IconData huntEventTypeIcon(HuntEventType type) {
  switch (type) {
    case HuntEventType.stand:
      return const IconData(0xe3b7, fontFamily: 'MaterialIcons');
    case HuntEventType.birdContact:
      return const IconData(0xe91d, fontFamily: 'MaterialIcons');
    case HuntEventType.flush:
      return const IconData(0xe566, fontFamily: 'MaterialIcons');
    case HuntEventType.bump:
      return const IconData(0xe3e7, fontFamily: 'MaterialIcons');
    case HuntEventType.birdDown:
      return const IconData(0xe3f3, fontFamily: 'MaterialIcons');
    case HuntEventType.backing:
      return const IconData(0xe7fb, fontFamily: 'MaterialIcons');
    case HuntEventType.emptyStand:
      return const IconData(0xe888, fontFamily: 'MaterialIcons');
    case HuntEventType.other:
      return const IconData(0xe5d3, fontFamily: 'MaterialIcons');
  }
}
