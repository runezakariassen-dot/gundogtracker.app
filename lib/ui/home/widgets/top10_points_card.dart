import 'package:flutter/material.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';

import '../../../domain/milestones/milestone_helpers.dart';
import '../../../domain/repositories/dog_milestone_state_repository.dart';
import '../../../models/dog.dart';
import '../../../models/dog_milestone_state.dart';
import '../../../services/dog_photo_storage.dart';
import '../top10/top10_strings.dart';

const _standIconAsset = 'assets/icon/stand_dog.png';
const _birdIconAsset = 'assets/icons/bird_rype.png';
const double _standIconSize = 40;
const double _birdIconSize = 32;
const double _standBadgeWidth = 110;
const double _milestoneBadgeDefaultWidth = 110;

ImageProvider? _dogAvatarProvider(String? path) {
  final file = DogPhotoStorage.imageFileFromPath(path);
  return file == null ? null : FileImage(file);
}

class Top10PointsCard extends StatelessWidget {
  const Top10PointsCard({
    super.key,
    required this.rank,
    required this.dog,
    required this.totalPoints,
    required this.fieldLabel,
    required this.valueLabel,
    required this.onTap,
    this.showFieldLabel = true,
  });

  final int rank;
  final Dog dog;
  final int totalPoints;
  final String fieldLabel;
  final String valueLabel;
  final VoidCallback onTap;
  final bool showFieldLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameStyle = Theme.of(context).textTheme.titleMedium;
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    final milestoneStateFuture =
        DogMilestoneStateRepository().getOrCreate(dog.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final avatarImage = _dogAvatarProvider(dog.imagePath);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? const Icon(Icons.pets)
                                  : null,
                            ),
                            if (rank <= 3)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: _rankTrophyFor(rank),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dog.displayName,
                            style: nameStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (showFieldLabel) ...[
                            const SizedBox(height: 4),
                            Text(
                              fieldLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            valueLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labelStyle?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // --- Milepæl-badges (stand) ---
                          const SizedBox(height: 8),
                          FutureBuilder<DogMilestoneState>(
                            future: milestoneStateFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final achievedIds =
                                  snapshot.data!.achievedIds.toSet();
                              final badges = _standMilestoneBadges(achievedIds);
                              if (badges.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final milestoneRows = _buildMilestoneRows(
                                context: context,
                                dog: dog,
                                state: snapshot.data!,
                                badges: badges,
                                labelStyle: labelStyle,
                                l10n: l10n,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: milestoneRows,
                              );
                            },
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
      ),
    );
  }

  static const int _maxBadgeCount = 4;

  /// Returnerer stand-milepæler som er oppnådd, sortert høyest først.
  /// Matcher id-formatet "stands_100", "stands_200", osv.
  List<int> _standMilestoneBadges(Set<String> achievedIds) {
    final achieved = <int>[];
    for (final threshold in standThresholds) {
      final id = 'stands_$threshold';
      if (achievedIds.contains(id)) {
        achieved.add(threshold);
      }
    }

    achieved.sort((a, b) => b.compareTo(a));
    return achieved;
  }

  List<Widget> _buildMilestoneRows({
    required BuildContext context,
    required Dog dog,
    required DogMilestoneState state,
    required List<int> badges,
    required TextStyle? labelStyle,
    required AppLocalizations l10n,
  }) {
    final rows = <Widget>[];
    final rowCount =
        badges.length < _maxBadgeCount ? badges.length : _maxBadgeCount;
    for (var i = 0; i < rowCount; i++) {
      final threshold = badges[i];
      final ageText = _standMilestoneAgeText(
        dog,
        state,
        threshold,
        l10n: l10n,
      );
      final isLastRow = i == rowCount - 1;
      rows.add(
        _Top10MilestoneRow(
          iconAsset: _standIconAsset,
          iconSize: _standIconSize,
          threshold: threshold,
          ageText: ageText,
          labelStyle: labelStyle,
          badgeWidth: _standBadgeWidth,
          bottomPadding: isLastRow ? 0 : 6,
        ),
      );
    }
    return rows;
  }
}

class _MilestoneBadge extends StatelessWidget {
  const _MilestoneBadge({
    required this.child,
    this.minWidth = _milestoneBadgeDefaultWidth,
  });

  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.25),
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _Top10MilestoneRow extends StatelessWidget {
  const _Top10MilestoneRow({
    required this.iconAsset,
    required this.iconSize,
    required this.threshold,
    required this.labelStyle,
    this.ageText,
    this.badgeWidth = _milestoneBadgeDefaultWidth,
    this.bottomPadding = 6,
  });

  final String iconAsset;
  final double iconSize;
  final int threshold;
  final TextStyle? labelStyle;
  final String? ageText;
  final double badgeWidth;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final badgeValueStyle = labelStyle?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w800,
    );
    final ageStyle = labelStyle?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: _MilestoneBadge(
        minWidth: badgeWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    iconAsset,
                    width: iconSize,
                    height: iconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$threshold',
                    style: badgeValueStyle,
                  ),
                ],
              ),
            ),
            if (ageText != null) ...[
              const SizedBox(height: 4),
              Text(
                ageText!,
                style: ageStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _rankTrophyFor(int rank) {
  if (rank > 3) return const SizedBox.shrink();

  final color = rank == 1
      ? Colors.amber
      : rank == 2
          ? Colors.blueGrey
          : Colors.brown;

  final icon = Icon(
    Icons.emoji_events,
    color: color,
    size: 30,
  );

  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colors.transparent,
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.55),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    ),
    child: icon,
  );
}

class Top10BirdsCard extends StatelessWidget {
  const Top10BirdsCard({
    super.key,
    required this.rank,
    required this.dog,
    required this.totalBirds,
    required this.fieldLabel,
    required this.valueLabel,
    required this.onTap,
    this.showFieldLabel = true,
  });

  final int rank;
  final Dog dog;
  final int totalBirds;
  final String fieldLabel;
  final String valueLabel;
  final VoidCallback onTap;
  final bool showFieldLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameStyle = Theme.of(context).textTheme.titleMedium;
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    final milestoneStateFuture =
        DogMilestoneStateRepository().getOrCreate(dog.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final avatarImage = _dogAvatarProvider(dog.imagePath);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? const Icon(Icons.pets)
                                  : null,
                            ),
                            if (rank <= 3)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: _rankTrophyFor(rank),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dog.displayName,
                            style: nameStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (showFieldLabel) ...[
                            const SizedBox(height: 4),
                            Text(
                              fieldLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            l10n.birdsDownCount(this.totalBirds),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labelStyle?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<DogMilestoneState>(
                            future: milestoneStateFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final milestoneRows = _buildBirdMilestoneRows(
                                context: context,
                                dog: dog,
                                state: snapshot.data!,
                                labelStyle: labelStyle,
                                l10n: l10n,
                              );

                              if (milestoneRows.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: milestoneRows,
                              );
                            },
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
      ),
    );
  }
}

List<Widget> _buildBirdMilestoneRows({
  required BuildContext context,
  required Dog dog,
  required DogMilestoneState state,
  required TextStyle? labelStyle,
  required AppLocalizations l10n,
}) {
  final rows = <Widget>[];
  final birthDate = dog.birthDate;
  final achievedIds = state.achievedIds.toSet();
  final ids = birdMilestoneIds.reversed
      .where((id) => achievedIds.contains(id))
      .toList(growable: false);

  for (var index = 0; index < ids.length; index++) {
    final milestoneId = ids[index];

    final achievedAt = state.achievedAt[milestoneId];
    final ageText = achievedAt == null
        ? null
        : _birdMilestoneAgeText(
            birthDate,
            achievedAt,
            l10n: l10n,
          );
    final isLast = index == ids.length - 1;
    final threshold = thresholdFromMilestoneId(milestoneId);

    rows.add(
      _Top10MilestoneRow(
        iconAsset: _birdIconAsset,
        iconSize: _birdIconSize,
        threshold: threshold,
        ageText: ageText,
        labelStyle: labelStyle,
        badgeWidth: _milestoneBadgeDefaultWidth,
        bottomPadding: isLast ? 0 : 8,
      ),
    );
  }
  return rows;
}

String? _birdMilestoneAgeText(
  DateTime? birthDate,
  DateTime achievedAt, {
  required AppLocalizations l10n,
}) {
  if (birthDate == null) return null;
  return _top10AgeLabel(
    l10n: l10n,
    start: birthDate,
    end: achievedAt,
  );
}


String? _standMilestoneAgeText(
  Dog dog,
  DogMilestoneState state,
  int threshold, {
  required AppLocalizations l10n,
}) {
  final birthDate = dog.birthDate;
  if (birthDate == null) return null;

  final milestoneDate = state.achievedAt['stands_$threshold'];
  if (milestoneDate == null) return null;

  return _top10AgeLabel(
    l10n: l10n,
    start: birthDate,
    end: milestoneDate,
  );
}

String _top10AgeLabel({
  required AppLocalizations l10n,
  required DateTime start,
  required DateTime end,
}) {
  final normalizedStart = DateTime(start.year, start.month, start.day);
  final normalizedEnd = DateTime(end.year, end.month, end.day);

  var years = normalizedEnd.year - normalizedStart.year;
  var months = normalizedEnd.month - normalizedStart.month;
  var days = normalizedEnd.day - normalizedStart.day;

  var borrowCount = 1;
  while (days < 0) {
    months--;
    final previousMonth = DateTime(
      normalizedEnd.year,
      normalizedEnd.month - borrowCount + 1,
      0,
    );
    days += previousMonth.day;
    borrowCount++;
  }

  if (months < 0) {
    years--;
    months += 12;
  }

  return Top10Strings.ageLabel(
    l10n: l10n,
    years: years,
    months: months,
    days: days,
  );
}
