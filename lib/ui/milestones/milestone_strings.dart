import 'package:flutter/material.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import 'package:jakthund_app/domain/milestones/milestone_catalog.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/milestones/milestone_models.dart';
import 'package:jakthund_app/ui/text/text_helpers.dart';

String milestoneTitle(BuildContext context, MilestoneDef def) {
  final l10n = AppLocalizations.of(context)!;

  // Century: points_100, points_200, ...
  if (isCenturyMilestoneId(def.id)) {
    final points = _pointsFromId(def.id) ?? 0;
    if (Localizations.localeOf(context).languageCode == 'nb') {
      return standText(points);
    }
    return l10n.milestone_century_points_title(points);
  }

  return milestoneTitleL10n(def, l10n);
}

String milestoneTitleL10n(MilestoneDef def, AppLocalizations l10n) {
  if (isCenturyMilestoneId(def.id)) {
    final points = _pointsFromId(def.id) ?? 0;
    return l10n.milestone_century_points_title(points);
  }

  switch (def.id) {
    case MilestoneId.stands1:
    case 'first_point':
      return l10n.milestone_first_point_title;
    case MilestoneId.firstFlush:
      return l10n.milestone_first_flush_title;
    case MilestoneId.sessions1:
      return l10n.milestone_first_session_title;
    case MilestoneId.sessions10:
      return l10n.milestone_sessions_10_title;
    case MilestoneId.activeHours10:
      return l10n.milestone_active_hours_10_title;
  }

  final threshold = _thresholdFromId(def.id);
  if (threshold != null) {
    if (_isSessionsId(def.id)) {
      return sessionsCountTextL10n(threshold, l10n);
    }
    if (_isStandId(def.id)) {
      return standsCountTextL10n(threshold, l10n);
    }
    if (_isBirdId(def.id)) {
      return birdsCountTextL10n(threshold, l10n);
    }
  }

  return l10n.common_unknown;
}

String milestoneSubtitleText(
  BuildContext context,
  MilestoneDef def,
  String dogName,
) {
  final l10n = AppLocalizations.of(context)!;

  if (isCenturyMilestoneId(def.id)) {
    final points = _pointsFromId(def.id) ?? 0;
    if (Localizations.localeOf(context).languageCode == 'nb') {
      return '$dogName har passert ${standText(points)}.';
    }
    return l10n.milestone_century_points_subtitle(dogName, points);
  }

  switch (def.id) {
    case 'stands_1':
    case 'first_point':
      return l10n.milestone_first_point_subtitle(dogName);

    case 'first_flush':
      return l10n.milestone_first_flush_subtitle(dogName);

    case 'sessions_10':
      return l10n.milestone_sessions_10_subtitle(dogName);

    case 'active_hours_10':
      return l10n.milestone_active_hours_10_subtitle(dogName);
  }

  return milestoneSubtitle(def, dogName);
}

int? _pointsFromId(String id) {
  if (!id.startsWith('points_')) return null;
  return int.tryParse(id.substring('points_'.length));
}

int? _thresholdFromId(String id) {
  final parts = id.split('_');
  if (parts.isEmpty) return null;
  return int.tryParse(parts.last);
}

bool _isSessionsId(String id) => id.startsWith('sessions_');

bool _isStandId(String id) => id.startsWith('stands_');

bool _isBirdId(String id) =>
    id.startsWith('birds_') || id.startsWith('birds_felled_');
