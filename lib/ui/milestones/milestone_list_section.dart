// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, prefer_const_constructors
// lib/ui/milestones/milestone_list_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import '../../domain/milestones/milestone_models.dart';
import '../../domain/services/dog_milestone_display_service.dart';
import '../../models/dog_sex.dart';
import '../../widgets/animated_dog_widget.dart';
import 'milestone_strings.dart';

class MilestoneListSection extends StatelessWidget {
  const MilestoneListSection({
    super.key,
    required this.milestones,
    this.dogName,
    this.dogBirthDate,
    this.dogSex,
  });

  final List<DogMilestoneDisplay> milestones;
  final String? dogName;
  final DateTime? dogBirthDate;
  final DogSex? dogSex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sorted = List<DogMilestoneDisplay>.from(milestones)
      ..sort((a, b) {
        final byCat = a.def.category.index.compareTo(b.def.category.index);
        if (byCat != 0) return byCat;

        final byOrder = a.def.sortOrder.compareTo(b.def.sortOrder);
        if (byOrder != 0) return byOrder;

        final titleA = milestoneTitleL10n(a.def, l10n);
        final titleB = milestoneTitleL10n(b.def, l10n);
        return titleA.compareTo(titleB);
      });

    final groups = <MilestoneCategory, List<DogMilestoneDisplay>>{};
    for (final m in sorted) {
      groups.putIfAbsent(m.def.category, () => <DogMilestoneDisplay>[]).add(m);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.milestones_achieved_title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Text(
            l10n.milestones_achieved_empty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          )
        else
          ..._buildGroupedList(context, groups),
      ],
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    Map<MilestoneCategory, List<DogMilestoneDisplay>> groups,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final orderedCats = <MilestoneCategory>[
      MilestoneCategory.firsts,
      MilestoneCategory.sessions,
      MilestoneCategory.points,
      MilestoneCategory.time,
      MilestoneCategory.contacts,
    ];

    final widgets = <Widget>[];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = colorScheme.surfaceContainerHighest;
    final birdSectionTitle = l10n.milestone_section_birds_down_title;

    void addSection(String title, List<DogMilestoneDisplay> entries) {
      if (entries.isEmpty) return;
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 4));

      for (final milestone in entries) {
        final def = milestone.def;

        final achievedAt = milestone.achievedAt;
        final dateText =
            achievedAt == null ? null : _formatDate(context, achievedAt);

        final heroLine = (achievedAt != null)
            ? _buildExplanation(
                context: context,
                milestone: milestone,
                achievedAt: achievedAt,
                dogName: dogName,
                dogBirthDate: dogBirthDate,
                dogSex: dogSex,
              )
            : null;

        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MilestoneIconWithBadge(
                  icon: _iconFor(def.icon),
                  assetPath:
                      def.icon == 'point' ? 'assets/icon/stand_dog.png' : null,
                  useBirdIcon: def.icon == 'bird',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(milestoneTitle(context, def)),
                      if (dateText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateText),
                              if (heroLine != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    heroLine,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.85),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    for (final cat in orderedCats) {
      final items = groups[cat];
      if (items == null || items.isEmpty) continue;

      if (cat == MilestoneCategory.points) {
        final standItems =
            items.where((e) => !_isBirdMilestone(e.def)).toList();
        final birdItems = items.where((e) => _isBirdMilestone(e.def)).toList();
        addSection(_categoryTitle(context, cat), standItems);
        addSection(birdSectionTitle, birdItems);
      } else {
        addSection(_categoryTitle(context, cat), items);
      }
    }

    return widgets;
  }

  String _categoryTitle(BuildContext context, MilestoneCategory category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case MilestoneCategory.firsts:
        return l10n.milestones_category_firsts;
      case MilestoneCategory.sessions:
        return l10n.milestones_category_sessions;
      case MilestoneCategory.points:
        return l10n.milestones_category_points;
      case MilestoneCategory.time:
        return l10n.milestones_category_time;
      case MilestoneCategory.contacts:
        return l10n.milestones_category_contacts;
    }
  }

  static IconData _iconFor(String? icon) {
    switch (icon) {
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

class _MilestoneIconWithBadge extends StatelessWidget {
  const _MilestoneIconWithBadge({
    required this.icon,
    this.assetPath,
    this.useBirdIcon = false,
  });

  final IconData icon;
  final String? assetPath;
  final bool useBirdIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = theme.colorScheme.primary;
    final borderColor = theme.colorScheme.surface;

    final iconColor = theme.colorScheme.onSurface;
    final Widget mainIcon = (assetPath != null)
        ? (assetPath == 'assets/icon/stand_dog.png'
            ? AnimatedDogWidget(
                width: 36,
                height: 36,
              )
            : Image.asset(
                assetPath!,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ))
        : useBirdIcon
            ? Image.asset(
                'assets/icons/bird_rype.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              )
            : Icon(icon, size: 32, color: iconColor);

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          mainIcon,
          Positioned(
            right: 2,
            bottom: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime dt) {
  final l10n = AppLocalizations.of(context)!;
  return DateFormat.yMd(l10n.localeName).format(dt);
}

String _buildLocalizedAgeText(AppLocalizations l10n, _AgeParts ageParts) {
  final segments = <String>[];
  if (ageParts.years > 0) {
    segments.add(l10n.age_years(ageParts.years));
  }
  if (ageParts.months > 0) {
    segments.add(l10n.age_months(ageParts.months));
  }
  if (ageParts.days > 0) {
    segments.add(l10n.age_days(ageParts.days));
  }

  if (segments.isEmpty) {
    return l10n.age_zero_days;
  }

  if (segments.length == 1) {
    return segments.first;
  }

  final allButLast = segments.sublist(0, segments.length - 1).join(' ');
  final last = segments.last;
  return '$allButLast ${l10n.age_and} $last';
}

_AgeParts? _calculateAgeParts(DateTime from, DateTime to) {
  if (to.isBefore(from)) return null;

  var years = to.year - from.year;
  var months = to.month - from.month;
  var days = to.day - from.day;

  if (days < 0) {
    months -= 1;
    final prevMonth = DateTime(to.year, to.month, 0);
    days += prevMonth.day;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  if (years < 0) return null;

  return _AgeParts(years, months, days);
}

bool _isBirdMilestone(MilestoneDef def) {
  return def.icon == 'bird' || def.id.startsWith('birds_felled_');
}

String _buildExplanation({
  required BuildContext context,
  required DogMilestoneDisplay milestone,
  required DateTime achievedAt,
  required String? dogName,
  required DateTime? dogBirthDate,
  required DogSex? dogSex,
}) {
  final l10n = AppLocalizations.of(context)!;

  final trimmedName = dogName?.trim();
  final hero = (trimmedName != null && trimmedName.isNotEmpty)
      ? trimmedName
      : l10n.milestone_dog_fallback_name;

  final dateText = _formatDate(context, achievedAt);

  final ageParts = (dogBirthDate != null)
      ? _calculateAgeParts(dogBirthDate, achievedAt)
      : null;
  final milestoneLabel = milestoneTitle(context, milestone.def);
  final base = "$hero oppnådde '$milestoneLabel' $dateText";

  if (ageParts == null) {
    return '$base.';
  }

  final ageText = _buildLocalizedAgeText(l10n, ageParts);
  final pronoun = switch (dogSex) {
    DogSex.female => 'hun',
    DogSex.male => 'han',
    null => null,
  };

  final subject = pronoun ?? 'den';
  return '$base da $subject var $ageText gammel.';
}

/// Privat liten type for “alder på milepæl”.
class _AgeParts {
  const _AgeParts(this.years, this.months, this.days);

  final int years;
  final int months;
  final int days;
}
