import 'package:flutter/material.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

import '../../domain/milestones/milestone_catalog.dart';
import '../../domain/milestones/milestone_id.dart';
import '../../domain/milestones/milestone_models.dart';
import '../app_shell.dart';
import '../text/text_helpers.dart';
import 'milestone_celebration_overlay.dart';
import '../../pages/dog_detail_page.dart';

String milestoneTitle(BuildContext context, MilestoneDef def) {
  final l10n = AppLocalizations.of(context)!;

  // Century-format: points_100, points_200 ...
  if (isCenturyMilestoneId(def.id)) {
    final points = _pointsFromId(def.id) ?? 0;
    return l10n.milestone_century_points_title(points);
  }

  switch (def.id) {
    case MilestoneId.stands1:
      return l10n.milestone_first_point_title;
    case MilestoneId.firstFlush:
      return l10n.milestone_first_flush_title;
    case MilestoneId.sessions1:
      return l10n.milestone_first_session_title;
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

  return def.title;
}

String milestoneSubtitleText(
  BuildContext context,
  MilestoneDef def,
  String dogName,
) {
  final l10n = AppLocalizations.of(context)!;

  if (isCenturyMilestoneId(def.id)) {
    final points = _pointsFromId(def.id) ?? 0;
    return l10n.milestone_century_points_subtitle(dogName, points);
  }

  switch (def.id) {
    case MilestoneId.stands1:
      return l10n.milestone_first_point_subtitle(dogName);
    case MilestoneId.firstFlush:
      return l10n.milestone_first_flush_subtitle(dogName);
    case MilestoneId.sessions1:
      return l10n.milestone_first_session_subtitle(dogName);
    case MilestoneId.activeHours10:
      return l10n.milestone_active_hours_10_subtitle(dogName);
  }

  final threshold = _thresholdFromId(def.id);
  if (threshold != null) {
    if (_isSessionsId(def.id)) {
      return l10n.milestone_sessions_count_subtitle(
        dogName,
        sessionsCountTextL10n(threshold, l10n),
      );
    }
    if (_isStandId(def.id)) {
      return l10n.milestone_stands_count_subtitle(
        dogName,
        standsCountTextL10n(threshold, l10n),
      );
    }
    if (_isBirdId(def.id)) {
      return l10n.milestone_birds_count_subtitle(
        dogName,
        birdsCountTextL10n(threshold, l10n),
      );
    }
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

bool _isBirdId(String id) => id.startsWith('birds_felled_');

class MilestoneCelebrationPresenter {
  MilestoneCelebrationPresenter();

  static void showSnackBar({
    required BuildContext context,
    required String text,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  final Set<String> _shownMilestoneIds = {};

  Future<bool> show(
    BuildContext context, {
    required Dog dog,
    required List<String> newIds,
    required DateTime achievedAt,
    bool hapticsEnabled = true,
  }) async {
    if (newIds.isEmpty) return false;

    // Unngå duplikat-visning
    final unseenIds =
        newIds.where((id) => !_shownMilestoneIds.contains(id)).toList();
    if (unseenIds.isEmpty) return false;

    // Capture stable states BEFORE await
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final BuildContext rootContext = rootNavigator.context;

    final NavigatorState tabNavigator =
        Navigator.of(context, rootNavigator: false);
    final BuildContext tabContext = tabNavigator.context;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    // Capture strings BEFORE await (context kan bli deaktivert)
    final l10n = AppLocalizations.of(context)!;
    final viewAllLabel = l10n.milestone_sheet_button_viewAll;

    // Kun "kjente" defs (ingen fallback som kan kræsje på konstruktør)
        final defs = <MilestoneDef>[];
        for (final id in unseenIds) {
          final def = milestoneDefById(id);
          if (def != null) defs.add(def);
        }

    // Marker alt som vist (også ukjente) for å unngå spam-loop
    _shownMilestoneIds.addAll(unseenIds);

    if (defs.isEmpty) {
      // Ukjente milepæler: ingen overlay, men ikke feile appen.
      return false;
    }

    final titles = defs
        .map((def) => milestoneTitle(rootContext, def))
        .where((t) => t.isNotEmpty)
        .toList();

    if (titles.isEmpty) return false;

    final summary = _buildSummary(dog, titles, l10n);

    // Vis overlays med rootContext (stabilt)
    for (final def in defs) {
      if (!rootContext.mounted) break;
      await showMilestoneCelebrationOverlay(
        context: rootContext,
        def: def,
        dog: dog,
        achievedAt: achievedAt,
      );
    }

    if (!rootContext.mounted) return true;

    final iconWidget = _buildMilestoneIcon(
      context: rootContext,
      def: defs.first,
      size: 24,
    );

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.milestone_snackbar_new_title),
                  Text(summary),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: viewAllLabel,
          onPressed: () => _navigateToDogDetail(
            tabContext: tabContext,
            messenger: messenger,
            dog: dog,
            l10n: l10n,
          ),
        ),
      ),
    );

    return true;
  }

  void _navigateToDogDetail({
    required BuildContext tabContext,
    required ScaffoldMessengerState messenger,
    required Dog dog,
    required AppLocalizations l10n,
  }) {
    void showError() {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.milestone_snackbar_open_error)),
      );
    }

    if (dog.id.isEmpty) {
      showError();
      return;
    }

    try {
      final box = HiveLifecycleService.getBox<Dog>(dogsBoxName);

      Dog? storedDog;
      for (final candidate in box.values) {
        if (candidate.id == dog.id) {
          storedDog = candidate;
          break;
        }
      }
      if (storedDog == null) {
        showError();
        return;
      }

      // ✅ Lås inn non-null type, så analyzer blir glad.
      final Dog resolvedDog = storedDog;

      messenger.hideCurrentSnackBar();

      // ✅ Primær: Naviger via AppShell, slik at bottom nav alltid er med.
      final shellState = AppShell.of(tabContext);
      if (shellState != null) {
        shellState.openDogDetails(resolvedDog);
        return;
      }

      // Fallback (bør sjelden trigges): push i samme tab-context.
      Navigator.of(tabContext).push(
        MaterialPageRoute(
          builder: (_) => DogDetailPage(dog: resolvedDog),
        ),
      );
    } catch (_) {
      showError();
    }
  }

  String _buildSummary(
    Dog dog,
    List<String> titles,
    AppLocalizations l10n,
  ) {
    final dogName = dog.name;
    if (titles.length == 1) return '$dogName: ${titles.first}';
    if (titles.length == 2) {
      return '$dogName: ${titles[0]} ${conjunctionAndL10n(l10n)} ${titles[1]}';
    }
    return '$dogName: ${titles.first} +${titles.length - 1}';
  }

  Widget _buildMilestoneIcon({
    required BuildContext context,
    required MilestoneDef def,
    double size = 24,
  }) {
    final iconColor = Theme.of(context).colorScheme.onSurface;
    if (def.icon == 'bird') {
      return Image.asset(
        'assets/icons/bird_rype.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Icon(
      _iconForMilestone(def.icon),
      size: size,
      color: iconColor,
    );
  }

  IconData _iconForMilestone(String? iconKey) {
    switch (iconKey) {
      case 'point':
        return Icons.flag;
      case 'flush':
        return Icons.outlined_flag;
      case 'sessions':
        return Icons.event_note;
      case 'time':
        return Icons.timer;
      case 'century':
        return Icons.emoji_events;
      case 'bird':
        return Icons.flight_takeoff;
    }
    return Icons.bookmark_border;
  }
}
