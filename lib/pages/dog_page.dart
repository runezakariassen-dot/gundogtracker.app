// ignore_for_file: avoid_print
// lib/pages/dog_page.dart
import 'dart:math';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/dogs/dog_visibility.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/pages/dog_detail_page.dart';
import 'package:jakthund_app/pages/dog_editor_page.dart';
import 'package:jakthund_app/pages/settings_page.dart';
import 'package:jakthund_app/pages/invitations_page.dart';
import 'package:jakthund_app/domain/subscription/subscription_service.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/services/user_identity_service.dart';
import 'package:jakthund_app/utils/dog_image_path_resolver.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/ui/subscription/pro_upgrade_sheet.dart';

class DogPage extends StatefulWidget {
  const DogPage({super.key});

  @override
  State<DogPage> createState() => _DogPageState();
}

class _DogPageState extends State<DogPage> {
  late final Box<Dog> _dogsBox;
  late final Box<DogMembership> _membershipBox;
  final UserIdentityService _identityService = UserIdentityService();

  _WisdomService? _wisdomService;
  int? _wisdomIndex;

  @override
  void initState() {
    super.initState();
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _membershipBox =
        HiveLifecycleService.getBox<DogMembership>(dogMembershipsBoxName);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Velg én visdom per app-start / side-livsløp.
    _wisdomService ??= _WisdomService(_wisdomGetters.length);
    _wisdomIndex ??= _wisdomService!.nextIndex();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final wisdomText = (_wisdomIndex == null)
        ? l10n.home_wisdom_empty
        : _wisdomGetters[_wisdomIndex!](l10n);

    final wisdomIcon = (_wisdomIndex == null)
        ? Icons.psychology
        : _wisdomIcons[_wisdomIndex! % _wisdomIcons.length];

    return Scaffold(
      appBar: AppBar(
        // ✅ This is the DOGS tab, so show Dogs title.
        title: Text(l10n.dogs),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: l10n.settings_title,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: _dogsBox.listenable(),
          builder: (context, Box<Dog> dogBox, _) {
            return ValueListenableBuilder(
              valueListenable: _membershipBox.listenable(),
              builder: (context, Box<DogMembership> membershipBox, _) {
                final dogs = dogBox.values.toList();
                final activeDogs =
                    dogs.where((dog) => !dog.isDeleted).toList(growable: false);
                final currentUserIds = _currentUserIds();
                final currentUid = _currentUserIdOrNull();
                final memberships = currentUserIds.isEmpty
                    ? <DogMembership>[]
                    : membershipBox.values
                        .where((membership) =>
                      currentUserIds.contains(
                        membership.userId.trim(),
                      ) &&
                            membership.status == Status.active)
                        .toList();
                final visibleDogs = filterVisibleDogs(
                  dogs: dogs,
                  memberships: memberships,
                  currentUserId: currentUid,
                  currentUserIds: currentUserIds,
                );
                final allowedDogKeys =
                    memberships.map((membership) => membership.dogKey).toSet();
                final fallbackOwnerCount = currentUserIds.isEmpty
                    ? 0
                    : visibleDogs
                        .where((dog) =>
                      currentUserIds
                        .contains(dog.ownerUserId?.trim() ?? '') &&
                            !allowedDogKeys.contains(dog.dogKey))
                        .length;
                if (kDebugMode) {
                  debugPrint(
                    '[TF][UI] dog page visibility uid=$currentUid dogs=${activeDogs.length} memberships=${memberships.length} visible=${visibleDogs.length}',
                  );
                  if (fallbackOwnerCount > 0) {
                    debugPrint(
                      '[TF][UI] dog page owner fallback count=$fallbackOwnerCount',
                    );
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _wisdomCard(context, wisdomText, wisdomIcon),
                    const SizedBox(height: 16),
                    if (activeDogs.isEmpty) ...[
                      _emptyState(context, l10n),
                    ] else if (visibleDogs.isEmpty) ...[
                      _filteredEmptyState(context, l10n),
                    ] else ...[
                      ..._buildDogCards(context, visibleDogs, l10n),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddDogPressed,
        icon: const Icon(Icons.add),
        label: Text(l10n.home_addDog_button),
      ),
    );
  }

  List<Widget> _buildDogCards(
    BuildContext context,
    List<Dog> dogs,
    AppLocalizations l10n,
  ) {
    final widgets = <Widget>[];

    for (var i = 0; i < dogs.length; i++) {
      final dog = dogs[i];

      widgets.add(
        Card(
          child: ListTile(
            // ✅ Bigger avatar (56px)
            leading: _DogAvatar(imagePath: dog.imagePath),
            title: Text(
              dog.name.isNotEmpty ? dog.name : l10n.dog_unnamed,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: _dogSubtitle(dog),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DogDetailPage(dog: dog),
                ),
              );
            },
          ),
        ),
      );

      if (i != dogs.length - 1) {
        widgets.add(const SizedBox(height: 10));
      }
    }

    return widgets;
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.pets_outlined,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.home_empty_title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.home_empty_body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 16),
            _bullet(context, l10n.home_empty_bullet_progress),
            const SizedBox(height: 8),
            _bullet(context, l10n.home_empty_bullet_training),
            const SizedBox(height: 8),
            _bullet(context, l10n.home_empty_bullet_history),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _onAddDogPressed,
                icon: const Icon(Icons.add),
                label: Text(l10n.home_addDog_button),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.home_empty_offline_note,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filteredEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.home_visible_empty_title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.home_visible_empty_body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _openInvitations,
                child: Text(l10n.home_visible_empty_button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openInvitations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InvitationsPage()),
    );
  }

  String? _currentUserIdOrNull() {
    try {
      final authUid = FirebaseAuth.instance.currentUser?.uid.trim();
      if (authUid != null && authUid.isNotEmpty) {
        return authUid;
      }
    } catch (_) {
      // Fall through to local identity.
    }
    final localUid = _identityService.getCurrentUserId().trim();
    return localUid.isEmpty ? null : localUid;
  }

  Set<String> _currentUserIds() {
    final ids = <String>{};
    final localUid = _identityService.getCurrentUserId().trim();
    if (localUid.isNotEmpty) {
      ids.add(localUid);
    }

    try {
      final authUid = FirebaseAuth.instance.currentUser?.uid.trim();
      if (authUid != null && authUid.isNotEmpty) {
        ids.add(authUid);
      }
    } catch (_) {
      // Keep local identity fallback only.
    }

    return ids;
  }

  Widget _wisdomCard(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final quotedText = '“${text.trim()}”';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.secondaryContainer.withValues(alpha: 0.95),
              scheme.secondaryContainer.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                quotedText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isInfinite
            ? MediaQuery.of(context).size.width
            : constraints.maxWidth;
        final availableWidth = maxWidth > 42 ? maxWidth - 42 : maxWidth;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: availableWidth,
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dogSubtitle(Dog dog) {
    final l10n = AppLocalizations.of(context)!;
    final born = _formatBorn(dog);
    final sex = _formatSex(dog, context);

    final parts = <String>[];
    if (born != null && born.isNotEmpty) {
      parts.add(l10n.dog_subtitle_born_prefix(born));
    }
    if (sex != null && sex.isNotEmpty) parts.add(sex);

    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join(' • '));
  }

  String? _formatBorn(Dog dog) {
    try {
      final dynamic d = (dog as dynamic).birthDate ??
          (dog as dynamic).dateOfBirth ??
          (dog as dynamic).birthday;
      if (d == null) return null;
      if (d is DateTime) {
        final dd = d.day.toString().padLeft(2, '0');
        final mm = d.month.toString().padLeft(2, '0');
        final yyyy = d.year.toString();
        return '$dd.$mm.$yyyy';
      }
      return d.toString();
    } catch (_) {
      return null;
    }
  }

  String? _formatSex(Dog dog, BuildContext context) {
    try {
      final dynamic s = (dog as dynamic).sex;
      if (s == null) return null;
      final name = s.toString().toLowerCase();
      final l10n = AppLocalizations.of(context)!;

      // ✅ Put female first to avoid weird contains() collisions.
      if (name.contains('female')) return l10n.dog_sex_female;
      if (name.contains('male')) return l10n.dog_sex_male;

      return null;
    } catch (_) {
      return null;
    }
  }

  void _onAddDogPressed() {
    final currentUserIds = _currentUserIds();
    final currentUid = _currentUserIdOrNull();
    final memberships = currentUserIds.isEmpty
        ? <DogMembership>[]
        : _membershipBox.values
            .where((membership) =>
                currentUserIds.contains(membership.userId.trim()) &&
                membership.status == Status.active)
            .toList(growable: false);
    final dogLimitSnapshot = buildDogLimitCountSnapshot(
      dogs: _dogsBox.values,
      memberships: memberships,
      currentUserId: currentUid,
      currentUserIds: currentUserIds,
    );
    final countedDogCount = dogLimitSnapshot.countedDogs.length;
    final limitReached = !SubscriptionService.instance.canCreateDog(
      currentDogCount: countedDogCount,
    );
    print('[SUBSCRIPTION][DOG_LIMIT] counted dogs: $countedDogCount');
    print(
      '[SUBSCRIPTION][DOG_LIMIT] visible dogs: ${dogLimitSnapshot.visibleDogs.length}',
    );
    print('[SUBSCRIPTION][DOG_LIMIT] limit reached: $limitReached');
    if (limitReached) {
      showProUpgradeSheet(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DogEditorPage()),
    );
  }
}

/// Bigger avatar widget to keep ListTile clean.
class _DogAvatar extends StatelessWidget {
  const _DogAvatar({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final absPath = DogImagePathResolver.toAbsolute(imagePath);
    final hasAvatar =
        absPath != null && absPath.isNotEmpty && File(absPath).existsSync();

    const size = 56.0;

    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: hasAvatar ? FileImage(File(absPath)) : null,
        child: hasAvatar ? null : const Icon(Icons.pets),
      ),
    );
  }
}

/// -------- Wisdom infra --------

class _WisdomService {
  _WisdomService(this._count) : assert(_count > 0);

  final int _count;
  final Random _random = Random();
  final List<int> _bag = [];

  int nextIndex() {
    if (_bag.isEmpty) {
      _bag
        ..clear()
        ..addAll(List<int>.generate(_count, (i) => i))
        ..shuffle(_random);
    }
    return _bag.removeLast();
  }
}

final List<IconData> _wisdomIcons = [
  Icons.pets_outlined,
  Icons.air,
  Icons.terrain,
  Icons.visibility,
  Icons.psychology,
  Icons.emoji_nature,
  Icons.sports,
  Icons.park,
];

final List<String Function(AppLocalizations)> _wisdomGetters = [
  (l) => l.wisdom_001,
  (l) => l.wisdom_002,
  (l) => l.wisdom_003,
  (l) => l.wisdom_004,
  (l) => l.wisdom_005,
  (l) => l.wisdom_006,
  (l) => l.wisdom_007,
  (l) => l.wisdom_008,
  (l) => l.wisdom_009,
  (l) => l.wisdom_010,
  (l) => l.wisdom_011,
  (l) => l.wisdom_012,
  (l) => l.wisdom_013,
  (l) => l.wisdom_014,
  (l) => l.wisdom_015,
  (l) => l.wisdom_016,
  (l) => l.wisdom_017,
  (l) => l.wisdom_018,
  (l) => l.wisdom_019,
  (l) => l.wisdom_020,
  (l) => l.wisdom_021,
  (l) => l.wisdom_022,
  (l) => l.wisdom_023,
  (l) => l.wisdom_024,
  (l) => l.wisdom_025,
  (l) => l.wisdom_026,
  (l) => l.wisdom_027,
  (l) => l.wisdom_028,
  (l) => l.wisdom_029,
  (l) => l.wisdom_030,
  (l) => l.wisdom_031,
  (l) => l.wisdom_032,
  (l) => l.wisdom_033,
  (l) => l.wisdom_034,
  (l) => l.wisdom_035,
  (l) => l.wisdom_036,
  (l) => l.wisdom_037,
  (l) => l.wisdom_038,
  (l) => l.wisdom_039,
  (l) => l.wisdom_040,
  (l) => l.wisdom_041,
  (l) => l.wisdom_042,
  (l) => l.wisdom_043,
  (l) => l.wisdom_044,
  (l) => l.wisdom_045,
  (l) => l.wisdom_046,
  (l) => l.wisdom_047,
  (l) => l.wisdom_048,
  (l) => l.wisdom_049,
  (l) => l.wisdom_050,
  (l) => l.wisdom_051,
  (l) => l.wisdom_052,
  (l) => l.wisdom_053,
  (l) => l.wisdom_054,
  (l) => l.wisdom_055,
  (l) => l.wisdom_056,
  (l) => l.wisdom_057,
  (l) => l.wisdom_058,
  (l) => l.wisdom_059,
  (l) => l.wisdom_060,
  (l) => l.wisdom_061,
  (l) => l.wisdom_062,
  (l) => l.wisdom_063,
  (l) => l.wisdom_064,
  (l) => l.wisdom_065,
  (l) => l.wisdom_066,
  (l) => l.wisdom_067,
  (l) => l.wisdom_068,
  (l) => l.wisdom_069,
  (l) => l.wisdom_070,
  (l) => l.wisdom_071,
  (l) => l.wisdom_072,
  (l) => l.wisdom_073,
  (l) => l.wisdom_074,
  (l) => l.wisdom_075,
  (l) => l.wisdom_076,
  (l) => l.wisdom_077,
  (l) => l.wisdom_078,
  (l) => l.wisdom_079,
  (l) => l.wisdom_080,
  (l) => l.wisdom_081,
  (l) => l.wisdom_082,
  (l) => l.wisdom_083,
  (l) => l.wisdom_084,
  (l) => l.wisdom_085,
  (l) => l.wisdom_086,
  (l) => l.wisdom_087,
  (l) => l.wisdom_088,
  (l) => l.wisdom_089,
  (l) => l.wisdom_090,
];
