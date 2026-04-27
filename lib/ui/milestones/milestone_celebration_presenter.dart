import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

import '../../domain/milestones/milestone_catalog.dart';
import '../../domain/milestones/milestone_id.dart';
import '../../domain/milestones/milestone_models.dart';
import '../../pages/dog_detail_page.dart';
import '../app_shell.dart';
import '../text/text_helpers.dart';
import 'milestone_celebration_overlay.dart';

String milestoneTitle(BuildContext context, MilestoneDef def) {
  final l10n = AppLocalizations.of(context)!;

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
  if (!id.startsWith('points_')) {
    return null;
  }
  return int.tryParse(id.substring('points_'.length));
}

int? _thresholdFromId(String id) {
  final parts = id.split('_');
  if (parts.isEmpty) {
    return null;
  }
  return int.tryParse(parts.last);
}

bool _isSessionsId(String id) => id.startsWith('sessions_');

bool _isStandId(String id) => id.startsWith('stands_');

bool _isBirdId(String id) => id.startsWith('birds_felled_');

void _logMilestoneInfo(String message) {
  debugPrint('[MILESTONE][INFO] $message');
}

const Key _milestoneInfoCloseButtonKey = Key('milestone_info_close_button');

enum _MilestoneInfoDismissReason {
  auto,
  manual,
}

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

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showMilestoneInfoSnackBar({
    required BuildContext context,
    required Widget leading,
    required String title,
    required String summary,
    String? actionLabel,
    VoidCallback? onAction,
    Duration autoDismissDuration = const Duration(seconds: 5),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
        controller;

    controller = messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1),
        content: _MilestoneInfoSnackContent(
          leading: leading,
          title: title,
          summary: summary,
          actionLabel: actionLabel,
          autoDismissDuration: autoDismissDuration,
          onDismiss: () => controller.close(),
          onAction: onAction,
        ),
      ),
    );

    return controller;
  }

  final Set<String> _shownMilestoneIds = {};

  Future<bool> show(
    BuildContext context, {
    required Dog dog,
    required List<String> newIds,
    required DateTime achievedAt,
    bool hapticsEnabled = true,
  }) async {
    if (newIds.isEmpty) {
      return false;
    }

    final unseenIds =
        newIds.where((id) => !_shownMilestoneIds.contains(id)).toList();
    if (unseenIds.isEmpty) {
      return false;
    }

    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final BuildContext rootContext = rootNavigator.context;

    final NavigatorState tabNavigator =
        Navigator.of(context, rootNavigator: false);
    final BuildContext tabContext = tabNavigator.context;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final viewAllLabel = l10n.milestone_sheet_button_viewAll;

    final defs = <MilestoneDef>[];
    final goalIds = <String>[];
    for (final id in unseenIds) {
      if (id == 'season_goal' || id == 'personal_goal') {
        goalIds.add(id);
      } else {
        final def = milestoneDefById(id);
        if (def != null) {
          defs.add(def);
        }
      }
    }

    _shownMilestoneIds.addAll(unseenIds);

    if (defs.isEmpty && goalIds.isEmpty) {
      return false;
    }

    final titles = <String>[];
    titles.addAll(
      defs
          .map((def) => milestoneTitle(rootContext, def))
          .where((title) => title.isNotEmpty),
    );

    for (final goalId in goalIds) {
      if (goalId == 'season_goal') {
        titles.add(l10n.settings_milestones_season_goal_title);
      } else if (goalId == 'personal_goal') {
        titles.add(l10n.settings_milestones_personal_goal_title);
      }
    }

    if (titles.isEmpty) {
      return false;
    }

    final summary = _buildSummary(dog, titles, l10n);

    for (final def in defs) {
      if (!rootContext.mounted) {
        break;
      }
      await showMilestoneCelebrationOverlay(
        context: rootContext,
        def: def,
        dog: dog,
        achievedAt: achievedAt,
      );
    }

    for (final goalId in goalIds) {
      if (!rootContext.mounted) {
        break;
      }
      final goalTitle = goalId == 'season_goal'
          ? l10n.settings_milestones_season_goal_title
          : l10n.settings_milestones_personal_goal_title;
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.milestone_goal_achieved(dog.name, goalTitle),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    if (!rootContext.mounted) {
      return true;
    }

    final iconWidget = _buildMilestoneIcon(
      context: rootContext,
      def: defs.first,
      size: 24,
    );

    showMilestoneInfoSnackBar(
      context: rootContext,
      leading: iconWidget,
      title: l10n.milestone_snackbar_new_title,
      summary: summary,
      actionLabel: viewAllLabel,
      onAction: () => _navigateToDogDetail(
        tabContext: tabContext,
        messenger: messenger,
        dog: dog,
        l10n: l10n,
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

      final resolvedDog = storedDog;
      messenger.hideCurrentSnackBar();

      final shellState = AppShell.of(tabContext);
      if (shellState != null) {
        shellState.openDogDetails(resolvedDog);
        return;
      }

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
    if (titles.length == 1) {
      return '$dogName: ${titles.first}';
    }
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

class _MilestoneInfoSnackContent extends StatefulWidget {
  const _MilestoneInfoSnackContent({
    required this.leading,
    required this.title,
    required this.summary,
    required this.onDismiss,
    required this.autoDismissDuration,
    this.actionLabel,
    this.onAction,
  });

  final Widget leading;
  final String title;
  final String summary;
  final String? actionLabel;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final Duration autoDismissDuration;

  @override
  State<_MilestoneInfoSnackContent> createState() =>
      _MilestoneInfoSnackContentState();
}

class _MilestoneInfoSnackContentState
    extends State<_MilestoneInfoSnackContent> {
  Timer? _timer;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _logMilestoneInfo('shown');
    _logMilestoneInfo(
      'auto dismiss scheduled ${widget.autoDismissDuration.inSeconds}s',
    );
    _timer = Timer(widget.autoDismissDuration, () {
      _logMilestoneInfo('auto dismiss fired');
      _safeDismiss(_MilestoneInfoDismissReason.auto);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _safeDismiss(_MilestoneInfoDismissReason reason) {
    if (_isClosed) {
      _logMilestoneInfo('dismiss skipped already closed');
      return;
    }

    _isClosed = true;
    _timer?.cancel();
    _timer = null;

    if (reason == _MilestoneInfoDismissReason.manual) {
      _logMilestoneInfo('manual dismiss');
    }

    widget.onDismiss();
  }

  void _handleManualDismiss() {
    _safeDismiss(_MilestoneInfoDismissReason.manual);
  }

  void _handleAction() {
    _safeDismiss(_MilestoneInfoDismissReason.manual);
    widget.onAction?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionLabel = widget.actionLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: widget.leading,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    key: _milestoneInfoCloseButtonKey,
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleManualDismiss,
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _handleAction,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: theme.colorScheme.inversePrimary,
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
