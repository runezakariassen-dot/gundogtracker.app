// ignore_for_file: avoid_types_as_parameter_names, depend_on_referenced_packages, deprecated_member_use, prefer_const_constructors, use_build_context_synchronously
// lib/pages/dog_detail_page.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/dog_box_helpers.dart';
import '../data/hive_boxes.dart';
import '../domain/dog_milestone_backfill_bootstrap.dart';
import '../domain/dogs/dog_visibility.dart';
import '../domain/domain_errors.dart';
import '../domain/milestones/milestone_catalog.dart';
import '../domain/milestones/milestone_helpers.dart';
import '../domain/repositories/dog_milestone_state_repository.dart';
import '../domain/sessions/session_visibility.dart';
import '../domain/services/dog_milestone_display_service.dart';
import '../models/dog.dart';
import '../models/dog_membership.dart';
import '../models/dog_sex.dart';
import '../models/hunt_session.dart';
import '../models/ownership_transfer.dart';
import '../models/share_invitation.dart';
import '../services/dog_photo_storage.dart';
import 'session_media_image_helper.dart';
import '../services/hive_lifecycle_service.dart';
import '../services/ownership_service.dart';
import '../services/sharing_service.dart';
import '../services/user_identity_service.dart';
import '../ui/milestones/milestone_list_section.dart';
import '../ui/milestones/milestone_strings.dart';
import '../ui/text/text_helpers.dart';
import '../utils/dog_image_path_resolver.dart';
import '../domain/user/app_user.dart';
import 'dog_editor_page.dart';

@visibleForTesting
Role? resolveHighestActiveRoleForUserIds({
  required Iterable<DogMembership> memberships,
  required String dogKey,
  required Iterable<String> userIds,
}) {
  final normalizedIds = userIds
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
  if (normalizedIds.isEmpty) {
    return null;
  }

  Role? resolvedRole;
  for (final membership in memberships) {
    if (membership.dogKey != dogKey ||
        membership.status != Status.active ||
        !normalizedIds.contains(membership.userId)) {
      continue;
    }
    if (resolvedRole == null ||
        _globalRolePriority(membership.role) <
            _globalRolePriority(resolvedRole)) {
      resolvedRole = membership.role;
    }
  }
  return resolvedRole;
}

int _globalRolePriority(Role role) {
  switch (role) {
    case Role.owner:
      return 0;
    case Role.admin:
      return 1;
    case Role.editor:
      return 2;
    case Role.viewer:
      return 3;
  }
}

class DogDetailPage extends StatefulWidget {
  const DogDetailPage({
    super.key,
    required this.dog,
  });

  final Dog dog;

  @override
  State<DogDetailPage> createState() => _DogDetailPageState();
}

class _DogDetailPageState extends State<DogDetailPage> {
  static const String _idPrefix = '_';

  late final Box<Dog> _dogsBox;
  late final Box<HuntSession> _sessionsBox;

  late final Box<ShareInvitation> _shareBox;
  late final Box<DogMembership> _membershipBox;

  late final String _currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, AppUser?> _sharedProfiles = {};
  final Set<String> _sharedProfilesLoading = <String>{};

  final Set<String> _processingInvites = <String>{};
  final TextEditingController _shareEmailController = TextEditingController();

  bool _isSendingInvite = false;
  final OwnershipService _ownershipService = OwnershipService();
  final Set<String> _processingTransfers = <String>{};

  final Set<String> _legacyMigrations = <String>{};
  int _avatarRevision = 0;

  final Set<String> _ownerEmailEnsured = <String>{};
  bool _wmShowTitle = true;
  bool _wmShowOfficialName = true;
  bool _wmPrefsInitialized = false;
  String? _wmPrefsDogId;

  late final DogMilestoneStateRepository _milestoneStateRepository;
  late final DogMilestoneDisplayService _milestoneDisplayService;
  late final Future<List<DogMilestoneDisplay>> _milestonesFuture;

  @override
  void initState() {
    super.initState();

    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);

    _shareBox =
        HiveLifecycleService.getBox<ShareInvitation>(shareInvitesBoxName);
    _membershipBox =
        HiveLifecycleService.getBox<DogMembership>(dogMembershipsBoxName);

    _currentUserId = UserIdentityService().getCurrentUserId();

    _milestoneStateRepository = DogMilestoneStateRepository();
    _milestoneDisplayService = DogMilestoneDisplayService(
      stateRepository: _milestoneStateRepository,
    );

    _milestonesFuture = _ensureMilestonesBackfilled().then(
      (_) => _milestoneDisplayService.listForDog(widget.dog.id),
    );
  }

  @override
  void dispose() {
    _shareEmailController.dispose();
    super.dispose();
  }

  Future<void> _ensureMilestonesBackfilled() async {
    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    await ensureDogMilestonesBackfilled(
      dogs: _dogsBox.values,
      settingsBox: settingsBox,
      stateRepository: _milestoneStateRepository,
    );
  }

  void _handleEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DogEditorPage(initialDog: widget.dog),
      ),
    );
  }

  Set<String> get _currentMembershipUserIds {
    final ids = <String>{};
    final localId = _currentUserId.trim();
    if (localId.isNotEmpty) {
      ids.add(localId);
    }
    final authId = FirebaseAuth.instance.currentUser?.uid.trim();
    if (authId != null && authId.isNotEmpty) {
      ids.add(authId);
    }
    return ids;
  }

  void _showShareError(ShareException error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_shareErrorMessage(l10n, error.code))),
    );
  }

  Future<void> _handleRevokeInvite(ShareInvitation invite) async {
    if (_processingInvites.contains(invite.inviteId)) return;
    setState(() => _processingInvites.add(invite.inviteId));
    try {
      await SharingService().revokeInvite(invite.inviteId);
    } on ShareException catch (error) {
      _showShareError(error);
    } finally {
      if (mounted) {
        setState(() => _processingInvites.remove(invite.inviteId));
      }
    }
  }

  String _shareErrorMessage(AppLocalizations l10n, ShareError code) {
    switch (code) {
      case ShareError.notOwner:
        return l10n.share_error_not_owner;
      case ShareError.inviteNotFound:
        return l10n.share_error_invite_not_found;
      case ShareError.inviteExpired:
        return l10n.share_error_invite_expired;
      case ShareError.inviteRevoked:
        return l10n.share_error_invite_revoked;
      case ShareError.inviteInactive:
        return l10n.share_error_invite_inactive;
      case ShareError.alreadyHasAccess:
        return l10n.share_error_already_has_access;
      case ShareError.alreadyInvited:
        return l10n.share_error_already_invited;
      case ShareError.invalidRole:
        return l10n.share_error_invalid_role;
      case ShareError.invalidEmail:
        return l10n.share_error_invalid_email;
    }
  }

  String _transferErrorMessage(AppLocalizations l10n, TransferError code) {
    switch (code) {
      case TransferError.notOwner:
        return l10n.transfer_error_not_owner;
      case TransferError.notRecipient:
        return l10n.transfer_error_not_recipient;
      case TransferError.transferNotFound:
        return l10n.transfer_error_not_found;
      case TransferError.transferExpired:
        return l10n.transfer_error_expired;
      case TransferError.transferNotPending:
        return l10n.transfer_error_not_pending;
      case TransferError.cannotTransferToSelf:
        return l10n.transfer_error_cannot_transfer_to_self;
      case TransferError.cancelled:
        return l10n.transfer_error_cancelled;
    }
  }

  Future<void> _acceptOwnershipTransfer(OwnershipTransfer transfer) async {
    final transferId = transfer.transferId;
    setState(() => _processingTransfers.add(transferId));
    try {
      await _ownershipService.acceptTransfer(transferId);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dog_detail_snackbar_ownership_accepted)),
      );
    } on TransferException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_transferErrorMessage(l10n, error.code))),
      );
    } finally {
      if (mounted) {
        setState(() => _processingTransfers.remove(transferId));
      } else {
        _processingTransfers.remove(transferId);
      }
    }
  }

  Future<void> _declineOwnershipTransfer(OwnershipTransfer transfer) async {
    final transferId = transfer.transferId;
    setState(() => _processingTransfers.add(transferId));
    try {
      await _ownershipService.declineTransfer(transferId);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dog_detail_snackbar_request_declined)),
      );
    } on TransferException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_transferErrorMessage(l10n, error.code))),
      );
    } finally {
      if (mounted) {
        setState(() => _processingTransfers.remove(transferId));
      } else {
        _processingTransfers.remove(transferId);
      }
    }
  }

  Future<void> _cancelOwnershipTransfer(OwnershipTransfer transfer) async {
    final transferId = transfer.transferId;
    setState(() => _processingTransfers.add(transferId));
    try {
      await _ownershipService.cancelTransfer(transferId);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dog_detail_snackbar_request_cancelled)),
      );
    } on TransferException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_transferErrorMessage(l10n, error.code))),
      );
    } finally {
      if (mounted) {
        setState(() => _processingTransfers.remove(transferId));
      } else {
        _processingTransfers.remove(transferId);
      }
    }
  }

  Future<void> _showPhotoOptions(Dog dog) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.dog_detail_photo_source_gallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.dog_detail_photo_source_camera),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(l10n.dog_detail_button_cancel),
                onTap: () => Navigator.of(context).pop(null),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    await _pickAndPersistPhoto(dog, source);
  }

  Future<void> _pickAndPersistPhoto(Dog dog, ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
      );
      if (picked == null) return;

      final savedPath = await DogPhotoStorage.saveDogPhoto(
        dogId: dog.id,
        sourcePath: picked.path,
      );

      await DogBoxHelpers.updateDogPhotoPath(
        dogId: dog.id,
        fallbackDogKey: dog.dogKey,
        photoPath: savedPath,
      );

      final absPath = DogImagePathResolver.toAbsolute(savedPath);
      if (absPath != null) {
        await FileImage(File(absPath)).evict();
      }

      if (!mounted) return;
      setState(() => _avatarRevision++);
    } catch (error, stack) {
      debugPrint('🐕 [PHOTO] Error picking photo: $error');
      debugPrint('$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dog_detail_snackbar_image_save_failed)),
      );
    }
  }

  Dog? _resolveDog(Box<Dog> box) {
    for (final d in box.values) {
      if (d.id == widget.dog.id) return d;
    }
    return null;
  }

  Future<void> _openPedigreeUrl(String url) async {
    final normalized = url.trim();
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      _showInvalidUrl();
      return;
    }
    final target = uri.hasScheme ? uri : Uri.parse('https://$normalized');
    final launched = await launchUrl(
      target,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) _showInvalidUrl();
  }

  void _showInvalidUrl() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.dog_detail_snackbar_pedigree_invalid),
      ),
    );
  }

  Widget _buildInfoCard(Dog dog) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <_InfoRow>[];

    rows.add(
      _InfoRow(
        label: l10n.dog_detail_info_label_sex,
        value: dog.sex == DogSex.male ? l10n.dog_sex_male : l10n.dog_sex_female,
      ),
    );

    if (dog.birthDate != null) {
      rows.add(
        _InfoRow(
          label: l10n.dog_detail_info_label_born,
          value: DateFormat('dd.MM.yyyy').format(dog.birthDate!),
        ),
      );
    }

    if (dog.regNrDisplay.trim().isNotEmpty) {
      rows.add(_InfoRow(label: 'Reg.nr', value: dog.regNrDisplay));
    } else if ((dog.regNr ?? '').trim().isNotEmpty) {
      rows.add(_InfoRow(label: 'Reg.nr', value: dog.regNr!));
    }

    if ((dog.breed ?? '').trim().isNotEmpty) {
      rows.add(_InfoRow(label: 'Rase', value: dog.breed!));
    }

    if (rows.isEmpty) {
      rows.add(const _InfoRow(label: 'Info', value: 'Ingen detaljer'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: rows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          row.value,
                          textAlign: TextAlign.right,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDeceasedBanner(Dog dog) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateText = dog.deceasedAt != null
        ? DateFormat('dd.MM.yyyy').format(dog.deceasedAt!)
        : 'Dato ikke registrert';
    final note = dog.memorialNote?.trim().isNotEmpty ?? false
        ? dog.memorialNote!.trim()
        : null;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      color: colorScheme.secondaryContainer.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.heart_broken,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.dog_detail_farewell_prefix}: $dateText',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _deceasedAgeLine(dog),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deceasedAgeLine(Dog dog) {
    final birth = dog.birthDate;
    final death = dog.deceasedAt;
    if (birth == null || death == null || death.isBefore(birth)) {
      return const SizedBox.shrink();
    }

    var years = death.year - birth.year;
    var months = death.month - birth.month;
    var days = death.day - birth.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(death.year, death.month, 0);
      days += prevMonth.day;
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years < 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final name = dog.name.isNotEmpty ? dog.name : l10n.dog_generic_name;
    final yearsText = l10n.age_years(years);
    final monthsText = l10n.age_months(months);
    final daysText = l10n.age_days(days);
    final text = l10n.dog_detail_farewell_age_sentence(
      name,
      yearsText,
      monthsText,
      daysText,
    );
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.heart_broken,
            size: 20,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.eco,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  String? _livingAgeText(Dog dog) {
    final birth = dog.birthDate;
    final now = DateTime.now();
    if (birth == null || now.isBefore(birth)) {
      return null;
    }

    var years = now.year - birth.year;
    var months = now.month - birth.month;

    if (now.day < birth.day) {
      months -= 1;
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years < 0) return null;

    final l10n = AppLocalizations.of(context)!;
    final yearsText = l10n.age_years_short(years);
    final monthsText = l10n.age_months_short(months);
    return '$yearsText $monthsText';
  }

  Widget _buildHeroSection(Dog dog, String? absolutePath) {
    final theme = Theme.of(context);
    final metaParts = <String>[];
    final breed = dog.breed?.trim();
    if (breed != null && breed.isNotEmpty) {
      metaParts.add(breed);
    }
    final ageText = _livingAgeText(dog);
    if (ageText != null && ageText.isNotEmpty) {
      metaParts.add(ageText);
    }
    final metaText = metaParts.join(' · ');
    final heroAnchor =
        profileHeroTextAnchorFromValue(dog.profileHeroTextAnchor);
    final heroAlignment = _alignmentFromHeroAnchor(heroAnchor);
    final heroScale = dog.profileHeroTextScale;

    final displayName = dog.displayName;
    final canonicalName = dog.name.trim();
    final hasNickname = dog.nickname?.trim().isNotEmpty ?? false;
    final showFullName = hasNickname && canonicalName.isNotEmpty;

    return SizedBox(
      height: 240,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (absolutePath != null && File(absolutePath).existsSync())
              Image.file(
                File(absolutePath),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                ),
                child: Center(
                  child: Icon(
                    Icons.pets,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            Align(
              alignment: heroAlignment,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Transform.scale(
                  scale: heroScale,
                  alignment: heroAlignment,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showFullName) ...[
                        const SizedBox(height: 4),
                        Text(
                          canonicalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                      if (metaText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          metaText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Alignment _alignmentFromHeroAnchor(ProfileHeroTextAnchor anchor) {
    switch (anchor) {
      case ProfileHeroTextAnchor.bottomLeft:
        return Alignment.bottomLeft;
      case ProfileHeroTextAnchor.bottomCenter:
        return Alignment.bottomCenter;
      case ProfileHeroTextAnchor.topLeft:
        return Alignment.topLeft;
    }
  }

  Widget _buildPedigreeCard(Dog dog) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dog_detail_pedigree_section_title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              dog.pedigreeUrl ?? l10n.dog_pedigree_no_link,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.75),
                  ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: dog.pedigreeUrl == null
                  ? null
                  : () => _openPedigreeUrl(dog.pedigreeUrl!),
              child: Text(l10n.dog_detail_button_open_pedigree),
            ),
          ],
        ),
      ),
    );
  }

  int _totalStandsForDog(Dog dog) {
    return filterVisibleSessionsForDog(
      sessions: _sessionsBox.values,
      dogId: dog.id,
      dogs: [dog],
    ).fold<int>(0, (sum, session) => sum + session.points);
  }

  int _totalBirdsForDog(Dog dog) {
    return filterVisibleSessionsForDog(
      sessions: _sessionsBox.values,
      dogId: dog.id,
      dogs: [dog],
    ).fold<int>(0, (sum, session) => sum + session.birdsShotCount);
  }

  Widget _buildNextMilestoneSection({
    required BuildContext context,
    required int totalStands,
    required int totalBirds,
    required Set<String> achievedIds,
  }) {
    final standTarget = _nextMilestoneTarget(
      context: context,
      total: totalStands,
      achievedIds: achievedIds,
      thresholds: standThresholds,
      idPrefix: 'stands',
      fallbackCategory: 'stander',
    );
    final birdTarget = _nextMilestoneTarget(
      context: context,
      total: totalBirds,
      achievedIds: achievedIds,
      thresholds: birdThresholds,
      idPrefix: 'birds_felled',
      fallbackCategory: 'fugl felt',
    );
    final target = _chooseMilestoneTarget(standTarget, birdTarget);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    final seasonGoal =
        (settingsBox.get(milestoneSeasonGoalPointsKey) as int?) ?? 0;
    final personalGoal =
        (settingsBox.get(milestonePersonalGoalPointsKey) as int?) ?? 0;

    if (target == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dog_detail_next_milestone_title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Alle milepæler nådd',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    final progressCurrent =
        target.current > target.threshold ? target.threshold : target.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dog_detail_next_milestone_title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$progressCurrent / ${target.threshold}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (seasonGoal > 0 || personalGoal > 0) ...[
          Text(
            'Mål:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          if (seasonGoal > 0)
            Text(
              'Sesongmål: $seasonGoal stander',
              style: theme.textTheme.bodySmall,
            ),
          if (personalGoal > 0)
            Text(
              'Personlig mål: $personalGoal stander',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  _MilestoneTarget? _nextMilestoneTarget({
    required BuildContext context,
    required int total,
    required Set<String> achievedIds,
    required List<int> thresholds,
    required String idPrefix,
    required String fallbackCategory,
  }) {
    for (final threshold in thresholds) {
      final id = '$idPrefix$_idPrefix$threshold';
      if (achievedIds.contains(id)) continue;
      final def = milestoneDefById(id);
      final label = def != null
          ? milestoneTitle(context, def)
          : _fallbackMilestoneLabel(context, threshold, fallbackCategory);
      return _MilestoneTarget(
        id: id,
        threshold: threshold,
        current: total,
        label: label,
      );
    }
    return null;
  }

  _MilestoneTarget? _chooseMilestoneTarget(
    _MilestoneTarget? stand,
    _MilestoneTarget? bird,
  ) {
    if (stand == null) return bird;
    if (bird == null) return stand;
    return stand.threshold <= bird.threshold ? stand : bird;
  }

  String _fallbackMilestoneLabel(
    BuildContext context,
    int threshold,
    String fallbackCategory,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (fallbackCategory == 'stander') {
      return standsCountTextL10n(threshold, l10n);
    }
    if (threshold == 1) {
      return l10n.milestone_first_bird_title;
    }
    return '$threshold $fallbackCategory';
  }

  Widget _buildAvatar({
    required String dogId,
    required String? absolutePath,
    required int revision,
  }) {
    if (absolutePath != null && File(absolutePath).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(absolutePath),
          key: ValueKey('${dogId}_$revision'),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    return const CircleAvatar(
      radius: 60,
      child: Icon(Icons.pets),
    );
  }

  Widget? _buildMyRoleSection(Dog dog) {
    final role = _resolveMyRole(dog);
    if (role == null) return null;
    final l10n = AppLocalizations.of(context)!;
    final roleLabel = _shareRoleLabel(l10n, role);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l10n.dog_detail_my_role_label(roleLabel),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildShareDisabledNotice(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        l10n.dog_detail_share_disabled_explanation,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildAccessSection(Dog dog, AppLocalizations l10n) {
    final membershipEntries = _membershipBox.values
        .where((membership) =>
            membership.dogKey == dog.dogKey &&
            membership.status == Status.active)
        .toList()
      ..sort((a, b) => _rolePriority(a.role).compareTo(_rolePriority(b.role)));

    final userIds = membershipEntries.map((entry) => entry.userId).toSet();
    _maybeLoadSharedProfiles(userIds);

    final pendingInvites = _shareBox.values
        .where((invite) =>
            invite.dogKey == dog.dogKey && invite.status == Status.pending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final myRole = _resolveMyRole(dog);
    final roleLabel = myRole != null ? _shareRoleLabel(l10n, myRole) : null;
    final canShare = myRole == Role.owner || myRole == Role.admin;

    final children = <Widget>[
      Text(
        l10n.dog_detail_section_access,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
    ];

    if (roleLabel != null) {
      children.add(Text(
        l10n.dog_detail_my_role_label(roleLabel),
        style: Theme.of(context).textTheme.bodyMedium,
      ));
      children.add(const SizedBox(height: 12));
    }

    if (membershipEntries.isEmpty) {
      final emptyText = _isOwner(dog)
          ? l10n.dog_detail_share_empty_owner
          : l10n.dog_detail_share_empty;
      children.add(
        Text(
          emptyText,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    } else {
      for (var i = 0; i < membershipEntries.length; i++) {
        children.add(_buildMembershipTile(
          membershipEntries[i],
          dog,
          canShare,
          l10n,
          myRole,
        ));
        if (i != membershipEntries.length - 1) {
          children.add(const SizedBox(height: 8));
        }
      }
    }

    children.add(const SizedBox(height: 16));
    children.add(Text(
      l10n.dog_detail_section_invites,
      style: Theme.of(context).textTheme.titleMedium,
    ));
    children.add(const SizedBox(height: 8));

    if (pendingInvites.isEmpty) {
      children.add(Text(
        l10n.invitations_empty,
        style: Theme.of(context).textTheme.bodyMedium,
      ));
    } else {
      children.add(_buildPendingInvitesList(
        context,
        pendingInvites,
        l10n,
        canShare,
      ));
    }

    children.add(const SizedBox(height: 16));

    if (canShare) {
      children.add(_buildInviteForm(dog, l10n));
    } else {
      children.add(_buildShareDisabledNotice(l10n));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _buildPendingInvitesList(
    BuildContext context,
    List<ShareInvitation> invites,
    AppLocalizations l10n,
    bool canRevoke,
  ) {
    final children = <Widget>[];
    for (var i = 0; i < invites.length; i++) {
      final invite = invites[i];
      final emailLabel = invite.recipientEmail.isNotEmpty
          ? invite.recipientEmail
          : l10n.common_unknown_email;

      children.add(
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            emailLabel,
            style: Theme.of(context).textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(l10n.invite_status_invited),
          trailing: TextButton(
            onPressed:
                (!canRevoke || _processingInvites.contains(invite.inviteId))
                    ? null
                    : () => _handleRevokeInvite(invite),
            child: Text(l10n.invite_revoke_button),
          ),
        ),
      );
      if (i != invites.length - 1) {
        children.add(const SizedBox(height: 8));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildInviteForm(Dog dog, AppLocalizations l10n) {
    final trimmedEmail = _shareEmailController.text.trim();
    final canSend = trimmedEmail.contains('@');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _shareEmailController,
          decoration: InputDecoration(
            labelText: l10n.invite_send_email_label,
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: (!canSend || _isSendingInvite)
              ? null
              : () async {
                  setState(() => _isSendingInvite = true);
                  final emailToSend = _shareEmailController.text.trim();
                  try {
                    final invite = await SharingService().createShareInvite(
                      dogKey: dog.dogKey,
                      recipientEmail: emailToSend,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(l10n.invite_sent_to(invite.recipientEmail)),
                      ),
                    );
                    setState(() {
                      _shareEmailController.clear();
                    });
                  } on ShareException catch (error) {
                    _showShareError(error);
                  } finally {
                    if (mounted) setState(() => _isSendingInvite = false);
                  }
                },
          child: _isSendingInvite
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.invite_send_button),
        ),
      ],
    );
  }

  Widget _buildMembershipTile(
    DogMembership membership,
    Dog dog,
    bool canShare,
    AppLocalizations l10n,
    Role? myRole,
  ) {
    final title = _memberDisplayName(membership, dog, l10n);
    final canManage = _canManageMembership(membership, myRole);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _canonicalRoleLabel(l10n, membership.role),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: canManage
          ? PopupMenuButton<_MembershipAction>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => _membershipMenuItems(membership, l10n),
              onSelected: (action) =>
                  _handleMembershipAction(action, membership),
            )
          : null,
    );
  }

  String _memberDisplayName(
    DogMembership membership,
    Dog dog,
    AppLocalizations l10n,
  ) {
    final profile = _sharedProfiles[membership.userId];
    final name = profile?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final email = profile?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    if (membership.role == Role.owner) {
      final ownerEmail = dog.ownerEmail?.trim();
      if (ownerEmail != null && ownerEmail.isNotEmpty) {
        return ownerEmail;
      }
    }
    return l10n.common_unknown_member;
  }

  bool _canManageMembership(DogMembership membership, Role? myRole) {
    if (myRole != Role.owner && myRole != Role.admin) return false;
    if (_currentMembershipUserIds.contains(membership.userId)) return false;
    if (membership.role == Role.owner || membership.role == Role.admin) {
      return false;
    }
    return true;
  }

  List<PopupMenuEntry<_MembershipAction>> _membershipMenuItems(
    DogMembership membership,
    AppLocalizations l10n,
  ) {
    final items = <PopupMenuEntry<_MembershipAction>>[];
    if (membership.role != Role.viewer) {
      items.add(
        PopupMenuItem<_MembershipAction>(
          value: _MembershipAction.setReader,
          child: Text(l10n.dog_detail_member_action_set_reader),
        ),
      );
    }
    if (membership.role != Role.editor) {
      items.add(
        PopupMenuItem<_MembershipAction>(
          value: _MembershipAction.setUser,
          child: Text(l10n.dog_detail_member_action_set_user),
        ),
      );
    }
    items.add(
      PopupMenuItem<_MembershipAction>(
        value: _MembershipAction.remove,
        child: Text(l10n.dog_detail_member_action_remove_access),
      ),
    );
    return items;
  }

  Future<void> _handleMembershipAction(
    _MembershipAction action,
    DogMembership membership,
  ) async {
    final key = _membershipKey(membership);
    switch (action) {
      case _MembershipAction.setReader:
        await _membershipBox.put(
          key,
          membership.copyWith(role: Role.viewer),
        );
        break;
      case _MembershipAction.setUser:
        await _membershipBox.put(
          key,
          membership.copyWith(role: Role.editor),
        );
        break;
      case _MembershipAction.remove:
        await _membershipBox.delete(key);
        break;
    }
    if (mounted) setState(() {});
  }

  String _membershipKey(DogMembership membership) {
    return '${membership.dogKey}::${membership.userId}';
  }

  int _rolePriority(Role role) {
    return _globalRolePriority(role);
  }

  String _shareRoleLabel(AppLocalizations l10n, Role role) {
    switch (role) {
      case Role.owner:
        return l10n.share_role_owner;
      case Role.admin:
        return l10n.share_role_admin;
      case Role.viewer:
      case Role.editor:
        return l10n.share_role_user;
    }
  }

  String _canonicalRoleLabel(AppLocalizations l10n, Role role) {
    return role.isCanonicalAdmin ? l10n.share_role_admin : l10n.share_role_user;
  }

  Role? _resolveMyRole(Dog dog) {
    final resolvedRole = resolveHighestActiveRoleForUserIds(
      memberships: _membershipBox.values,
      dogKey: dog.dogKey,
      userIds: _currentMembershipUserIds,
    );
    if (resolvedRole != null) {
      return resolvedRole;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final ownerEmail = dog.ownerEmail?.trim();
    final currentEmail = currentUser?.email?.trim();
    if (ownerEmail != null &&
        ownerEmail.isNotEmpty &&
        currentEmail != null &&
        ownerEmail.toLowerCase() == currentEmail.toLowerCase()) {
      return Role.owner;
    }

    return Role.viewer;
  }

  bool _looksLikeFirebaseUid(String value) {
    return value.length >= 20 && !value.contains('-');
  }

  void _maybeLoadSharedProfiles(Set<String> userIds) {
    final idsToLoad = userIds
        .where((id) =>
            id.isNotEmpty &&
            !_sharedProfiles.containsKey(id) &&
            !_sharedProfilesLoading.contains(id) &&
            _looksLikeFirebaseUid(id))
        .toList();
    if (idsToLoad.isEmpty) return;

    for (final id in idsToLoad) {
      _sharedProfilesLoading.add(id);
      _firestore.collection('users').doc(id).get().then((snapshot) {
        if (snapshot.exists) {
          _sharedProfiles[id] = AppUser.fromSnapshot(snapshot);
        } else {
          _sharedProfiles[id] = null;
        }
      }).catchError((error) {
        if (kDebugMode) {
          debugPrint('[Shares] Failed to load profile for $id: $error');
        }
        _sharedProfiles[id] = null;
      }).whenComplete(() {
        _sharedProfilesLoading.remove(id);
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Widget _buildOwnershipSection(Dog dog) {
    return ValueListenableBuilder(
      valueListenable: ownershipTransfersBox().listenable(),
      builder: (context, Box<OwnershipTransfer> transferBox, _) {
        final pending = transferBox.values
            .where((transfer) =>
                transfer.dogKey == dog.dogKey &&
                transfer.status == Status.pending)
            .toList();
        final ownerTransfers = pending
            .where((transfer) => transfer.fromUserId == _currentUserId)
            .toList();
        final recipientTransfers = pending
            .where((transfer) => transfer.toUserId == _currentUserId)
            .toList();

        if (ownerTransfers.isEmpty && recipientTransfers.isEmpty) {
          return const SizedBox.shrink();
        }

        final sections = <Widget>[];
        if (recipientTransfers.isNotEmpty) {
          sections.add(_buildIncomingOwnershipCard(recipientTransfers));
        }
        if (ownerTransfers.isNotEmpty) {
          sections.add(_buildOwnerOwnershipCard(ownerTransfers));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sections.asMap().entries.expand<Widget>((entry) sync* {
            yield entry.value;
            if (entry.key != sections.length - 1) {
              yield const SizedBox(height: 16);
            }
          }).toList(),
        );
      },
    );
  }

  dynamic _keyForDog(String dogId) {
    for (final entry in _dogsBox.toMap().entries) {
      if (entry.value.id == dogId) return entry.key;
    }
    return null;
  }

  bool _ensureOwnerEmail(Dog dog) {
    if (_ownerEmailEnsured.contains(dog.id)) return false;
    _ownerEmailEnsured.add(dog.id);

    final hasOwnerEmail = (dog.ownerEmail?.trim().isNotEmpty ?? false);
    if (hasOwnerEmail) return false;

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentEmail = currentUser?.email?.trim();
    if (currentEmail == null || currentEmail.isEmpty) return false;

    final hasOwnerMembership = _membershipBox.values.any((membership) {
      return membership.dogKey == dog.dogKey &&
          _currentMembershipUserIds.contains(membership.userId) &&
          membership.status == Status.active &&
          membership.role == Role.owner;
    });
    if (!hasOwnerMembership) return false;

    final key = _keyForDog(dog.id);
    if (key == null) return false;

    final updated = dog.copyWith(ownerEmail: currentEmail);
    _dogsBox.put(key, updated);
    return true;
  }

  Future<void> _handleMarkAsDead(Dog dog) async {
    final messenger = ScaffoldMessenger.of(context);
    final details = await _promptForDeceasedDetails();
    if (details == null) return;
    final key = _keyForDog(dog.id);
    if (key == null) return;

    final updated = dog.copyWith(
      deceasedAt: details.date,
      memorialNote: details.note,
      updatedAt: DateTime.now(),
    );

    await _dogsBox.put(key, updated);

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text('${dog.name} er markert som død')),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showDeceasedSummary(updated);
    });
  }

  void _onWatermarkToggle({
    required bool value,
    required Dog dog,
    required bool isTitle,
  }) {
    setState(() {
      if (isTitle) {
        _wmShowTitle = value;
      } else {
        _wmShowOfficialName = value;
      }
    });
    unawaited(
      _persistWmPrefs(
        dog,
        showTitle: _wmShowTitle,
        showOfficialName: _wmShowOfficialName,
      ),
    );
  }

  Future<void> _persistWmPrefs(
    Dog dog, {
    required bool showTitle,
    required bool showOfficialName,
  }) async {
    final key = _keyForDog(dog.id);
    if (key == null) return;

    final updated = dog.copyWith(
      watermarkShowTitle: showTitle,
      watermarkShowOfficialName: showOfficialName,
      updatedAt: DateTime.now(),
    );

    await _dogsBox.put(key, updated);
  }

  void _showWatermarkShareMissingPhoto(AppLocalizations l10n) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.dog_detail_watermark_share_missing_photo)),
    );
  }

  Future<void> _openDogPhotoViewer(Dog dog) async {
    final l10n = AppLocalizations.of(context)!;
    final storedPath = dog.imagePath;
    if (storedPath == null || storedPath.trim().isEmpty) {
      _showWatermarkShareMissingPhoto(l10n);
      return;
    }
    await openSessionImage(
      context: context,
      storedPath: storedPath,
      displayName: dog.displayName,
      watermarkDogTitle: dog.title,
      watermarkDogOfficialName: dog.name,
      watermarkDogNickname: dog.nickname,
      watermarkShowTitle: dog.watermarkShowTitle,
      watermarkShowOfficialName: dog.watermarkShowOfficialName,
      watermarkShowNickname: dog.watermarkShowNickname,
      dogId: dog.id,
    );
  }

  Future<_DeceasedDetails?> _promptForDeceasedDetails() async {
    final l10n = AppLocalizations.of(context)!;
    DateTime selectedDate = DateTime.now();
    String noteText = widget.dog.memorialNote?.trim() ?? '';

    final result = await showDialog<_DeceasedDetails>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Marker som død'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.dog_detail_label_death_date),
                    subtitle:
                        Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(1970),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text(l10n.dog_detail_button_edit),
                    ),
                  ),
                  TextFormField(
                    initialValue: noteText,
                    onChanged: (value) => noteText = value,
                    decoration: const InputDecoration(
                      labelText: 'Minnetekst (valgfritt)',
                    ),
                    maxLines: null,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(l10n.dog_detail_button_cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final note = noteText.trim();
                    Navigator.of(context).pop(
                      _DeceasedDetails(
                        date: selectedDate,
                        note: note.isEmpty ? null : note,
                      ),
                    );
                  },
                  child: Text(l10n.dog_detail_button_register_death),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }

  Future<void> _showDeceasedSummary(Dog dog) async {
    final sessions = filterVisibleSessionsForDog(
      sessions: _sessionsBox.values,
      dogId: dog.id,
      dogs: [dog],
    )..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final sessionCount = sessions.length;
    final totalMinutes =
        sessions.fold<int>(0, (sum, session) => sum + session.durationMinutes);
    final totalPoints =
        sessions.fold<int>(0, (sum, session) => sum + session.points);
    final totalBirds = sessions.fold<int>(
      0,
      (sum, session) => sum + session.birdsShotCount,
    );
    final firstSession = sessions.isEmpty ? null : sessions.first.dateTime;
    final lastSession = sessions.isEmpty ? null : sessions.last.dateTime;
    final milestones = await _milestoneDisplayService.listForDog(dog.id);
    final topMilestones = milestones.reversed.take(3).toList();

    final theme = Theme.of(context);
    final l10nSummary = AppLocalizations.of(context)!;

    Widget summaryTile(String label, String value) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing: Text(
          value,
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kjærlig minne',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  summaryTile(
                      l10nSummary.dog_detail_summary_session_count_label,
                      sessionCount.toString()),
                  summaryTile(l10nSummary.dog_detail_summary_active_time_label,
                      _formatDuration(totalMinutes)),
                  summaryTile(l10nSummary.dog_detail_summary_points_label,
                      totalPoints.toString()),
                  summaryTile(l10nSummary.dog_detail_summary_birds_down_label,
                      totalBirds.toString()),
                  summaryTile(
                      l10nSummary.dog_detail_summary_first_session_label,
                      _formatDateTime(firstSession)),
                  summaryTile(l10nSummary.dog_detail_summary_last_session_label,
                      _formatDateTime(lastSession)),
                  const SizedBox(height: 16),
                  Text(
                    l10nSummary.dog_detail_next_milestones_title,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (topMilestones.isEmpty)
                    Text(
                      l10nSummary.milestones_achieved_empty,
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topMilestones
                          .map(
                            (entry) => Chip(
                              label: Text(
                                milestoneTitleL10n(entry.def, l10nSummary),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int minutes) {
    final duration = Duration(minutes: minutes);
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    final parts = <String>[];
    if (hours > 0) parts.add('$hours t');
    if (mins > 0) parts.add('$mins min');
    return parts.isEmpty ? '0 min' : parts.join(' ');
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '–';
    return DateFormat('dd.MM.yyyy HH:mm').format(value);
  }

  Widget _buildIncomingOwnershipCard(List<OwnershipTransfer> transfers) {
    final l10n = AppLocalizations.of(context)!;
    final actionWidgets = <Widget>[];
    for (var i = 0; i < transfers.length; i++) {
      final transfer = transfers[i];
      final isProcessing = _processingTransfers.contains(transfer.transferId);
      actionWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dog_detail_label_from_user(transfer.fromUserId),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () => _acceptOwnershipTransfer(transfer),
                    child: Text(l10n.dog_detail_button_accept),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing
                        ? null
                        : () => _declineOwnershipTransfer(transfer),
                    child: Text(l10n.dog_detail_button_decline),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      if (i != transfers.length - 1) {
        actionWidgets.add(const SizedBox(height: 12));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dog_detail_section_owner_request_title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...actionWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerOwnershipCard(List<OwnershipTransfer> transfers) {
    final l10n = AppLocalizations.of(context)!;
    final actionWidgets = <Widget>[];
    for (var i = 0; i < transfers.length; i++) {
      final transfer = transfers[i];
      final isProcessing = _processingTransfers.contains(transfer.transferId);
      actionWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dog_detail_label_to_user(transfer.toUserId),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () => _cancelOwnershipTransfer(transfer),
              child: Text(l10n.dog_detail_button_cancel_request),
            ),
          ],
        ),
      );
      if (i != transfers.length - 1) {
        actionWidgets.add(const SizedBox(height: 12));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dog_detail_section_owner_request_title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...actionWidgets,
          ],
        ),
      ),
    );
  }

  bool _isOwner(Dog dog) {
    return _membershipBox.values.any((membership) {
      final isTargetDog = membership.dogKey == dog.dogKey;
      final isCurrentUser =
          _currentMembershipUserIds.contains(membership.userId);
      final hasPrivileges =
          membership.role == Role.owner || membership.role == Role.admin;
      return isTargetDog &&
          isCurrentUser &&
          membership.status == Status.active &&
          hasPrivileges;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _dogsBox.listenable(),
      builder: (context, Box<Dog> box, _) {
        final l10n = AppLocalizations.of(context)!;
        final foundDog = _resolveDog(box);
        if (!isDogVisibleInUi(foundDog)) {
          if (kDebugMode) {
            debugPrint(
              '[UI][DETAIL] deleted entity fallback: dog ${widget.dog.id}',
            );
          }
          return Scaffold(
            appBar: AppBar(title: Text(l10n.dog_detail_appbar_title)),
            body: Center(
              child: Text(
                l10n.dog_detail_error_dog_not_found,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        Dog dog = foundDog!;
        if (_ensureOwnerEmail(dog)) {
          final refreshed = _resolveDog(box);
          if (refreshed != null) {
            dog = refreshed;
          }
        }
        final storedPath = dog.imagePath;
        final resolvedAvatarPath = DogImagePathResolver.toAbsolute(storedPath);

        if (storedPath != null &&
            storedPath.startsWith('/') &&
            !_legacyMigrations.contains(storedPath)) {
          _legacyMigrations.add(storedPath);
          Future.microtask(() async {
            final migrated =
                await DogPhotoStorage.migrateLegacyPath(storedPath);
            if (!mounted) return;
            if (migrated != null && migrated != storedPath) {
              await DogBoxHelpers.updateDogPhotoPath(
                dogId: dog.id,
                fallbackDogKey: dog.dogKey,
                photoPath: migrated,
              );
              if (mounted) setState(() => _avatarRevision++);
            }
          });
        }

        if (!_wmPrefsInitialized || _wmPrefsDogId != dog.id) {
          _wmShowTitle = dog.watermarkShowTitle;
          _wmShowOfficialName = dog.watermarkShowOfficialName;
          _wmPrefsInitialized = true;
          _wmPrefsDogId = dog.id;
        }
        final myRoleSection = _buildMyRoleSection(dog);
        final bodyContent = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroSection(dog, resolvedAvatarPath),
            const SizedBox(height: 16),
            if (myRoleSection != null) ...[
              myRoleSection,
              const SizedBox(height: 16),
            ],
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showPhotoOptions(dog),
              child: SizedBox(
                width: 140,
                height: 140,
                child: Center(
                  child: _buildAvatar(
                    dogId: dog.id,
                    absolutePath: resolvedAvatarPath,
                    revision: _avatarRevision,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: Text(l10n.dog_detail_button_edit_photo),
                onPressed: () => _showPhotoOptions(dog),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.dog_detail_watermark_section_title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.dog_detail_watermark_info,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(l10n.dog_detail_watermark_toggle_title),
                      value: _wmShowTitle,
                      onChanged: (value) => _onWatermarkToggle(
                          value: value, dog: dog, isTitle: true),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(l10n.dog_detail_watermark_toggle_name),
                      value: _wmShowOfficialName,
                      onChanged: (value) => _onWatermarkToggle(
                          value: value, dog: dog, isTitle: false),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.share),
                      label: Text(l10n.dog_detail_watermark_share_button),
                      onPressed: () => _openDogPhotoViewer(dog),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (dog.deceasedAt != null) ...[
              const SizedBox(height: 12),
              _buildDeceasedBanner(dog),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.heart_broken),
                  label: Text(l10n.dog_detail_button_mark_dead),
                  onPressed: () => _handleMarkAsDead(dog),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildInfoCard(dog),
            const SizedBox(height: 16),
            _buildPedigreeCard(dog),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: _shareBox.listenable(),
              builder: (context, _, __) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAccessSection(dog, l10n),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOwnershipSection(dog),
            const SizedBox(height: 16),
            FutureBuilder<List<DogMilestoneDisplay>>(
              future: _milestonesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final milestones = snapshot.data ?? <DogMilestoneDisplay>[];
                final achievedIds =
                    milestones.map((milestone) => milestone.id).toSet();
                final totalStands = _totalStandsForDog(dog);
                final totalBirds = _totalBirdsForDog(dog);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNextMilestoneSection(
                      context: context,
                      totalStands: totalStands,
                      totalBirds: totalBirds,
                      achievedIds: achievedIds,
                    ),
                    MilestoneListSection(
                      milestones: milestones,
                      dogName: dog.name,
                      dogBirthDate: dog.birthDate,
                    ),
                  ],
                );
              },
            ),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: null,
            title: Text(
              dog.name.isNotEmpty ? dog.name : l10n.dog_detail_title_add_dog,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: l10n.dog_detail_tooltip_edit_profile,
                onPressed: _handleEdit,
              ),
            ],
          ),
          body: bodyContent,
        );
      },
    );
  }
}

class _MilestoneTarget {
  const _MilestoneTarget({
    required this.id,
    required this.threshold,
    required this.current,
    required this.label,
  });

  final String id;
  final int threshold;
  final int current;
  final String label;
}

class _DeceasedDetails {
  const _DeceasedDetails({
    required this.date,
    this.note,
  });

  final DateTime date;
  final String? note;
}

class _InfoRow {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

enum _MembershipAction {
  setReader,
  setUser,
  remove,
}
