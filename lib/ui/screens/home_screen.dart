// ignore_for_file: deprecated_member_use
// lib/ui/screens/home_screen.dart
import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/repositories/local_active_session_draft_repository.dart';
import 'package:jakthund_app/domain/dogs/dog_visibility.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/domain/repositories/active_session_draft_repository.dart';
import 'package:jakthund_app/domain/sessions/session_visibility.dart';
import 'package:jakthund_app/domain/statistics/dog_leaderboard_service.dart';
import 'package:jakthund_app/domain/milestones/milestone_helpers.dart';
import 'package:jakthund_app/hunt_session_page.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/ui/text/text_helpers.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/share_invitation.dart';
import 'package:jakthund_app/pages/dog_editor_page.dart';
import 'package:jakthund_app/pages/dog_detail_page.dart';
import 'package:jakthund_app/pages/invitations_page.dart';
import 'package:jakthund_app/pages/settings_page.dart';
import 'package:jakthund_app/services/cloud/firestore_share_invitation_sync_service.dart';
import 'package:jakthund_app/services/dog_profile_media_download_guard.dart';
import 'package:jakthund_app/services/dog_profile_media_download_service.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/services/user_identity_service.dart';
import 'package:jakthund_app/ui/home/widgets/active_session_restore_banner.dart';
import 'package:jakthund_app/ui/home/widgets/top10_points_card.dart';
import 'package:jakthund_app/services/dog_profile_image_resolver.dart';

typedef PendingInvitePuller = Future<int> Function();

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.currentUserIdOverride,
    this.currentUserEmailOverride,
    this.pendingInvitePuller,
  });

  final String? currentUserIdOverride;
  final String? currentUserEmailOverride;
  final PendingInvitePuller? pendingInvitePuller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final Box<Dog> _dogsBox;
  late final Box<HuntSession> _sessionsBox;
  late final Box<DogMembership> _membershipBox;
  late final Box<ShareInvitation> _shareInvitesBox;
  late final Box<dynamic> _settingsBox;
  late final ActiveSessionDraftRepository _draftRepository;
  final UserIdentityService _identityService = UserIdentityService();
  final DogProfileMediaDownloadGuard _profileMediaDownloadGuard =
      DogProfileMediaDownloadGuard();
  final DogProfileMediaDownloadService _profileMediaDownloadService =
      DogProfileMediaDownloadService();

  _WisdomService? _wisdomService;
  int? _wisdomIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _membershipBox =
        HiveLifecycleService.getBox<DogMembership>(dogMembershipsBoxName);
    _shareInvitesBox =
        HiveLifecycleService.getBox<ShareInvitation>(shareInvitesBoxName);
    _settingsBox = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    _draftRepository = LocalActiveSessionDraftRepository();
    _triggerPendingInvitePull(reason: 'home_init');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerPendingInvitePull(reason: 'app_resumed');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wisdomService ??= _WisdomService(_wisdomGetters.length);
    _wisdomIndex ??= _wisdomService!.nextIndex();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final wisdomText = _wisdomIndex == null
        ? l10n.home_wisdom_empty
        : _wisdomGetters[_wisdomIndex!](l10n);

    final wisdomIcon = _wisdomIndex == null
        ? Icons.pets_outlined
        : _wisdomIcons[_wisdomIndex! % _wisdomIcons.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home_title),
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
                return ValueListenableBuilder(
                  valueListenable: _shareInvitesBox.listenable(),
                  builder: (context, Box<ShareInvitation> shareInvitesBox, _) {
                    return ValueListenableBuilder(
                      valueListenable: _settingsBox.listenable(),
                      builder: (context, Box<dynamic> settingsBox, _) {
                        final dogs = dogBox.values.toList(growable: false);
                        final activeDogs = dogs
                            .where((dog) => !dog.isDeleted)
                            .toList(growable: false);
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
                        final pendingInviteCount = _pendingInviteCount(
                          shareInvitesBox.values,
                          currentUserIds: currentUserIds,
                        );
                        final visibleDogs = filterVisibleDogs(
                          dogs: dogs,
                          memberships: memberships,
                          currentUserId: currentUid,
                          currentUserIds: currentUserIds,
                        );
                        _scheduleProfileMediaDownloadsForVisibleDogs(
                          visibleDogs,
                        );
                        final allowedDogKeys = memberships
                            .map((membership) => membership.dogKey)
                            .toSet();
                        final fallbackOwnerCount = currentUserIds.isEmpty
                            ? 0
                            : visibleDogs
                                .where((dog) =>
                                    currentUserIds.contains(
                                      dog.ownerUserId?.trim() ?? '',
                                    ) &&
                                    !allowedDogKeys.contains(dog.dogKey))
                                .length;
                        final hasDogs = visibleDogs.isNotEmpty;
                        final visibleSessions = filterVisibleSessions(
                          sessions: _sessionsBox.values,
                          dogs: visibleDogs,
                        );
                        final latestSession =
                            _latestVisibleSession(visibleSessions);
                        final dogNamesById = {
                          for (final dog in visibleDogs)
                            dog.id: dog.displayName,
                        };

                        if (kDebugMode) {
                          debugPrint(
                            '[TF][UI] home visibility uid=$currentUid dogs=${activeDogs.length} memberships=${memberships.length} visible=${visibleDogs.length}',
                          );
                          if (fallbackOwnerCount > 0) {
                            debugPrint(
                              '[TF][UI] home owner fallback count=$fallbackOwnerCount',
                            );
                          }
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _InlineWisdom(
                              text: wisdomText,
                              icon: wisdomIcon,
                            ),
                            if (pendingInviteCount > 0) ...[
                              const SizedBox(height: 16),
                              _PendingInvitationsBanner(
                                count: pendingInviteCount,
                                onPressed: _openInvitations,
                              ),
                            ],
                            const SizedBox(height: 16),
                            ActiveSessionRestoreBanner(
                              repository: _draftRepository,
                              dogLookup: _findDogById,
                              onContinue: _onContinueDraft,
                              onDiscard: _onDiscardDraft,
                            ),
                            const SizedBox(height: 16),
                            if (hasDogs) ...[
                              _MyDogsCard(
                                dogs: visibleDogs,
                                onDogTap: (dog) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DogDetailPage(dog: dog),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            _HomeLatestSessionCard(
                              session: latestSession,
                              dogName: latestSession == null
                                  ? null
                                  : dogNamesById[latestSession.dogId],
                            ),
                            const SizedBox(height: 16),
                            _Top10PointsSection(
                              dogs: visibleDogs,
                              sessionsBox: _sessionsBox,
                              hideWhenNoDogs: !hasDogs,
                            ),
                            const SizedBox(height: 16),
                            _Top10BirdsSection(
                              dogs: visibleDogs,
                              sessionsBox: _sessionsBox,
                              hideWhenNoDogs: !hasDogs,
                            ),
                            if (!hasDogs) ...[
                              const SizedBox(height: 16),
                              _HomeEmptyStateCardIntroOnly(
                                onAddDogPressed: _openAddDogEditor,
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _onContinueDraft(ActiveSessionDraft draft) {
    final dog = _findDogById(draft.dogId);
    final l10n = AppLocalizations.of(context);

    if (dog == null) {
      if (l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.home_continueActiveSessionMissingDogTitle),
          ),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HuntSessionPage(initialDraft: draft),
      ),
    );
  }

  Future<void> _onDiscardDraft() async {
    await _draftRepository.clear();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.home_discardActiveSessionSnackbar)),
    );
  }

  Future<void> _openAddDogEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DogEditorPage()),
    );
  }

  Future<void> _openInvitations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InvitationsPage()),
    );
  }

  void _triggerPendingInvitePull({required String reason}) {
    if (widget.pendingInvitePuller == null && Firebase.apps.isEmpty) {
      debugPrint(
        '[CLOUD][INVITE] skip home pull reason=$reason firebaseInitialized=false',
      );
      return;
    }

    unawaited(_pullPendingInvites(reason: reason));
  }

  Future<void> _pullPendingInvites({required String reason}) async {
    final puller = widget.pendingInvitePuller ??
        FirestoreShareInvitationSyncService
            .instance.pullPendingInvitesForCurrentUserIntoLocalBox;
    try {
      final upserted = await puller();
      debugPrint(
        '[CLOUD][INVITE] home pull complete reason=$reason upserted=$upserted',
      );
    } catch (error, stackTrace) {
      debugPrint(
          '[CLOUD][INVITE] home pull failed reason=$reason error=$error');
      debugPrint(stackTrace.toString());
    }
  }

  int _pendingInviteCount(
    Iterable<ShareInvitation> invites, {
    required Set<String> currentUserIds,
  }) {
    final currentEmail = _currentUserEmail();
    return invites.where((invite) {
      if (invite.status != Status.pending) {
        return false;
      }
      final recipientEmail = invite.recipientEmail.trim().toLowerCase();
      final recipientUserId = invite.recipientUserId?.trim();
      final matchesEmail = currentEmail != null &&
          currentEmail.isNotEmpty &&
          recipientEmail == currentEmail;
      final matchesUid = recipientUserId != null &&
          recipientUserId.isNotEmpty &&
          currentUserIds.contains(recipientUserId);
      return matchesEmail || matchesUid;
    }).length;
  }

  String? _currentUserEmail() {
    final override = widget.currentUserEmailOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override.toLowerCase();
    }

    try {
      final email = FirebaseAuth.instance.currentUser?.email?.trim();
      if (email != null && email.isNotEmpty) {
        return email.toLowerCase();
      }
    } catch (_) {
      // Local-only tests and offline startup may not have Firebase available.
    }
    return null;
  }

  Dog? _findDogById(String dogId) {
    final currentUserIds = _currentUserIds();
    final currentUid = _currentUserIdOrNull();
    final memberships = _membershipBox.values
        .where((membership) =>
            currentUserIds.contains(membership.userId.trim()) &&
            membership.status == Status.active)
        .toList(growable: false);
    return findVisibleDogById(
      dogs: _dogsBox.values,
      memberships: memberships,
      currentUserId: currentUid,
      currentUserIds: currentUserIds,
      dogId: dogId,
    );
  }

  Set<String> _currentUserIds() {
    if (widget.currentUserIdOverride != null) {
      final override = widget.currentUserIdOverride!.trim();
      return override.isEmpty ? <String>{} : <String>{override};
    }

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

  String? _currentUserIdOrNull() {
    if (widget.currentUserIdOverride != null) {
      final override = widget.currentUserIdOverride!.trim();
      return override.isEmpty ? null : override;
    }
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

  HuntSession? _latestVisibleSession(List<HuntSession> sessions) {
    if (sessions.isEmpty) {
      return null;
    }
    final sorted = List<HuntSession>.from(sessions)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return sorted.first;
  }

  void _scheduleProfileMediaDownloadsForVisibleDogs(List<Dog> dogs) {
    for (final dog in dogs) {
      if (!_profileMediaDownloadGuard.markAttemptIfEligible(dog)) {
        continue;
      }

      Future.microtask(() async {
        try {
          final downloadedAsset = await _profileMediaDownloadService
              .downloadProfileImageForDog(dog);
          if (downloadedAsset != null && mounted) {
            setState(() {});
          }
        } catch (error, stackTrace) {
          debugPrint(
            '[DOG][PROFILE_MEDIA] Home background profile download failed dogId=${dog.id} error=$error',
          );
          debugPrint(stackTrace.toString());
        }
      });
    }
  }
}

class _PendingInvitationsBanner extends StatelessWidget {
  const _PendingInvitationsBanner({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.home_pendingInvitationsTitle(count),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onPressed,
              child: Text(l10n.home_pendingInvitationsButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLatestSessionCard extends StatelessWidget {
  const _HomeLatestSessionCard({
    required this.session,
    required this.dogName,
  });

  final HuntSession? session;
  final String? dogName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final materialL10n = MaterialLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.home_dashboard_latest_session_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (session == null)
              Text(
                l10n.home_dashboard_latest_session_empty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              )
            else ...[
              Text(
                dogName?.trim().isNotEmpty == true
                    ? dogName!
                    : l10n.home_dashboard_latest_session_unknown_dog,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                materialL10n.formatMediumDate(session!.dateTime),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_summaryText(session!, l10n).isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _summaryText(session!, l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SessionMetaChip(label: l10n.standsCount(session!.points)),
                  _SessionMetaChip(
                    label: l10n.birdContactsCount(session!.birdsSeen),
                  ),
                  if (session!.location.trim().isNotEmpty)
                    _SessionMetaChip(label: session!.location.trim()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _summaryText(HuntSession session, AppLocalizations l10n) {
    final note = session.notes.trim();
    if (note.isNotEmpty) {
      return note;
    }

    final parts = <String>[];
    if (session.points > 0) {
      parts.add(l10n.standsCount(session.points));
    }
    if (session.birdsSeen > 0) {
      parts.add(l10n.birdContactsCount(session.birdsSeen));
    }
    if (session.location.trim().isNotEmpty) {
      parts.add(session.location.trim());
    }
    return parts.join(' • ');
  }
}

class _SessionMetaChip extends StatelessWidget {
  const _SessionMetaChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A “fills-the-screen-a-bit” card for when you have 1–many dogs.
/// Keeps Home from feeling empty before the user has logged lots of sessions.
class _MyDogsCard extends StatefulWidget {
  const _MyDogsCard({
    required this.dogs,
    required this.onDogTap,
  });

  final List<Dog> dogs;
  final void Function(Dog dog) onDogTap;

  @override
  State<_MyDogsCard> createState() => _MyDogsCardState();
}

class _MyDogsCardState extends State<_MyDogsCard> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  Timer? _resumeAutoScrollTimer;
  static const Duration _autoScrollDuration = Duration(seconds: 5);
  static const Duration _resumeDelay = Duration(seconds: 8);

  bool get _canAutoScroll => widget.dogs.length > 1;

  int get _currentPageIndex {
    if (!_pageController.hasClients) return _pageController.initialPage;
    final page = _pageController.page;
    if (page == null) return _pageController.initialPage;
    return page.round();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!_canAutoScroll || !mounted) return;
    _resumeAutoScrollTimer?.cancel();
    _autoScrollTimer =
        Timer.periodic(_autoScrollDuration, (_) => _goToNextPage());
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _resumeAutoScrollTimer?.cancel();
    _resumeAutoScrollTimer = null;
  }

  void _pauseAutoScroll() {
    _stopAutoScroll();
    _scheduleAutoScrollResume();
  }

  void _scheduleAutoScrollResume() {
    _resumeAutoScrollTimer?.cancel();
    if (!_canAutoScroll || !mounted) return;
    _resumeAutoScrollTimer = Timer(_resumeDelay, () {
      if (!mounted) return;
      _startAutoScroll();
    });
  }

  void _goToNextPage() {
    if (!_canAutoScroll || !_pageController.hasClients || !mounted) return;
    final next = (_currentPageIndex + 1) % widget.dogs.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeAutoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MyDogsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dogs.length != widget.dogs.length) {
      if (_canAutoScroll) {
        _startAutoScroll();
      } else {
        _stopAutoScroll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.dogs.length == 1
        ? l10n.dogs
        : '${l10n.dogs} (${widget.dogs.length})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _pauseAutoScroll();
              } else if (notification is ScrollEndNotification) {
                _scheduleAutoScrollResume();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.dogs.length,
              padEnds: false,
              itemBuilder: (context, index) {
                final dog = widget.dogs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _DogCarouselCard(
                    dog: dog,
                    onTap: () => widget.onDogTap(dog),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DogCarouselCard extends StatelessWidget {
  const _DogCarouselCard({
    required this.dog,
    required this.onTap,
  });

  final Dog dog;
  final VoidCallback onTap;

  String get _displayName => dog.displayName;

  String _ageLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (dog.birthDate == null) return l10n.age_unknown;
    final reference = dog.deceasedAt ?? DateTime.now();
    final full = formatDurationBetween(dog.birthDate!, reference, l10n: l10n);
    final parts = full.split(' ${l10n.age_and} ');
    return parts.take(2).join(' ');
  }

  Widget _buildImage(BuildContext context) {
    final resolved = DogProfileImageResolver().resolve(dog);
    if (resolved != null && File(resolved).existsSync()) {
      return Image.file(
        File(resolved),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
      child: Center(
        child: Icon(
          Icons.pets_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 64,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(context),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            if (dog.deceasedAt != null)
              const Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.heart_broken,
                  color: Colors.red,
                  size: 22,
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ageLabel(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeEmptyStateCardIntroOnly extends StatelessWidget {
  const _HomeEmptyStateCardIntroOnly({
    required this.onAddDogPressed,
  });

  final VoidCallback onAddDogPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.home_empty_title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.home_empty_body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Bullet(text: l10n.home_empty_bullet_progress),
                  const SizedBox(height: 6),
                  _Bullet(text: l10n.home_empty_bullet_training),
                  const SizedBox(height: 6),
                  _Bullet(text: l10n.home_empty_bullet_history),
                  const SizedBox(height: 12),
                  Text(
                    l10n.home_empty_offline_note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onAddDogPressed,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.home_addDog_button),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.home_empty_next_step,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.72),
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

class _InlineWisdom extends StatelessWidget {
  const _InlineWisdom({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = scheme.primaryContainer.withValues(alpha: 0.55);
    final border = scheme.onPrimaryContainer.withValues(alpha: 0.18);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(width: 1, color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '“${text.trim()}”',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.35,
                color: scheme.onPrimaryContainer.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}

class _Top10PointsSection extends StatelessWidget {
  const _Top10PointsSection({
    required this.dogs,
    required this.sessionsBox,
    required this.hideWhenNoDogs,
  });

  final List<Dog> dogs;
  final Box<HuntSession> sessionsBox;
  final bool hideWhenNoDogs;

  @override
  Widget build(BuildContext context) {
    if (hideWhenNoDogs) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: sessionsBox.listenable(),
      builder: (context, Box<HuntSession> sessionBox, _) {
        final l10n = AppLocalizations.of(context)!;
        final sessions = sessionBox.values.toList(growable: false);
        final service = DogLeaderboardService();
        final entries = service.buildTopTen(dogs, sessions);
        final hasScores = entries.any((e) => e.totalPoints > 0);

        final theme = Theme.of(context);
        final appBarColor =
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary;
        const warmSeasonColors = [
          Color(0xFF9FB8A0),
          Color(0xFFD6CFC2),
        ];
        final isWarmSeason = warmSeasonColors.contains(appBarColor);
        final cardColor = (isWarmSeason
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.tertiaryContainer)
            .withValues(alpha: 0.58);
        final borderColor = (isWarmSeason
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onTertiaryContainer)
            .withOpacity(0.14);

        return Card(
          clipBehavior: Clip.antiAlias,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.home_top10_points_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (dogs.isEmpty || !hasScores)
                  Text(
                    l10n.home_top10_points_empty,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length < 10 ? entries.length : 10,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final rank = index + 1;

                      final glowDecoration = () {
                        switch (rank) {
                          case 1:
                            return BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.withOpacity(0.26),
                                  Colors.amber.withOpacity(0.08),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.28),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            );
                          case 2:
                            return BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.withOpacity(0.24),
                                  Colors.grey.withOpacity(0.08),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.30),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            );
                          case 3:
                            return BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFCD7F32).withOpacity(0.24),
                                  const Color(0xFFCD7F32).withOpacity(0.08),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFCD7F32).withOpacity(0.28),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            );
                          default:
                            return null;
                        }
                      }();

                      Widget cardChild = Top10PointsCard(
                        rank: rank,
                        dog: entry.dog,
                        totalPoints: entry.totalPoints,
                        fieldLabel: l10n.standsLabel,
                        valueLabel: l10n.standsCount(entry.totalPoints),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DogDetailPage(dog: entry.dog),
                            ),
                          );
                        },
                        showFieldLabel: false,
                      );

                      if (glowDecoration != null) {
                        cardChild = DecoratedBox(
                          decoration: glowDecoration,
                          child: Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: cardChild,
                          ),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                        child: cardChild,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Top10BirdsSection extends StatelessWidget {
  const _Top10BirdsSection({
    required this.dogs,
    required this.sessionsBox,
    required this.hideWhenNoDogs,
  });

  final List<Dog> dogs;
  final Box<HuntSession> sessionsBox;
  final bool hideWhenNoDogs;

  @override
  Widget build(BuildContext context) {
    if (hideWhenNoDogs || dogs.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: sessionsBox.listenable(),
      builder: (context, Box<HuntSession> _, __) {
        final l10n = AppLocalizations.of(context)!;
        final entries = _buildBirdMilestoneLeaderboard(dogs);
        final hasScores = entries.isNotEmpty;

        final theme = Theme.of(context);
        final appBarColor =
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary;
        const warmSeasonColors = [
          Color(0xFF9FB8A0),
          Color(0xFFD6CFC2),
        ];
        final isWarmSeason = warmSeasonColors.contains(appBarColor);
        final cardColor = (isWarmSeason
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.tertiaryContainer)
            .withOpacity(0.58);
        final borderColor = (isWarmSeason
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onTertiaryContainer)
            .withOpacity(0.14);

        return Card(
          clipBehavior: Clip.antiAlias,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.home_top10_birds_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (!hasScores)
                  Text(
                    l10n.home_top10_birds_empty,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length < 10 ? entries.length : 10,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final rank = index + 1;

                      final glowDecoration = () {
                        switch (rank) {
                          case 1:
                            return BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.withOpacity(0.26),
                                  Colors.amber.withOpacity(0.08),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.28),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            );
                          case 2:
                            return BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.withOpacity(0.24),
                                  Colors.grey.withOpacity(0.08),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.30),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            );
                          case 3:
                            return BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFCD7F32).withOpacity(0.24),
                                  const Color(0xFFCD7F32).withOpacity(0.08),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFCD7F32).withOpacity(0.28),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            );
                          default:
                            return null;
                        }
                      }();

                      Widget cardChild = Top10BirdsCard(
                        rank: rank,
                        dog: entry.dog,
                        totalBirds: entry.highestThreshold,
                        fieldLabel: l10n.home_top10_birds_fieldLabel,
                        valueLabel: birdText(entry.highestThreshold),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DogDetailPage(dog: entry.dog),
                            ),
                          );
                        },
                        showFieldLabel: false,
                      );

                      if (glowDecoration != null) {
                        cardChild = DecoratedBox(
                          decoration: glowDecoration,
                          child: Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: cardChild,
                          ),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                        child: cardChild,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

List<_BirdMilestoneLeaderboardEntry> _buildBirdMilestoneLeaderboard(
  List<Dog> dogs,
) {
  final milestoneBox = dogMilestoneStateBox();
  final entries = <_BirdMilestoneLeaderboardEntry>[];

  for (final dog in dogs) {
    final state = milestoneBox.get(dog.id);
    if (state == null) continue;

    var highestThreshold = 0;
    DateTime? highestAchievedAt;

    for (final milestoneId in birdMilestoneIds) {
      final achievedAt = state.achievedAt[milestoneId];
      if (achievedAt == null) continue;

      final threshold = thresholdFromMilestoneId(milestoneId);
      if (threshold > highestThreshold) {
        highestThreshold = threshold;
        highestAchievedAt = achievedAt;
      }
    }

    if (highestThreshold == 0) continue;

    entries.add(
      _BirdMilestoneLeaderboardEntry(
        dog: dog,
        highestThreshold: highestThreshold,
        highestAchievedAt: highestAchievedAt,
      ),
    );
  }

  entries.sort((a, b) {
    final thresholdDiff = b.highestThreshold.compareTo(a.highestThreshold);
    if (thresholdDiff != 0) return thresholdDiff;

    final aTime = a.highestAchievedAt?.millisecondsSinceEpoch ?? -1;
    final bTime = b.highestAchievedAt?.millisecondsSinceEpoch ?? -1;
    final dateDiff = bTime.compareTo(aTime);
    if (dateDiff != 0) return dateDiff;

    return a.dog.name.compareTo(b.dog.name);
  });

  if (entries.length <= 10) return entries;
  return entries.sublist(0, 10);
}

class _BirdMilestoneLeaderboardEntry {
  const _BirdMilestoneLeaderboardEntry({
    required this.dog,
    required this.highestThreshold,
    required this.highestAchievedAt,
  });

  final Dog dog;
  final int highestThreshold;
  final DateTime? highestAchievedAt;
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
