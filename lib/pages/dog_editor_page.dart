// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import '../data/local/local_membership_repository.dart';
import '../data/local/sync_outbox_service.dart';
import '../domain/dogs/dog_visibility.dart';
import '../domain/subscription/subscription_service.dart';
import '../domain/models/active_session_draft.dart';
import '../models/dog.dart';
import '../models/dog_membership.dart';
import '../models/dog_sex.dart';
import '../pages/dog_detail_page.dart';
import '../services/dog_profile_media_update_service.dart';
import '../services/dog_photo_storage.dart';
import '../services/cloud/firestore_dog_sync_service.dart';
import '../services/hive_lifecycle_service.dart';
import '../services/user_identity_service.dart';
import '../ui/subscription/pro_upgrade_sheet.dart';
import '../utils/dog_image_path_resolver.dart';

typedef RevokeSharedDogMembership = Future<bool> Function({
  required Dog dog,
  required DogMembership membership,
});
typedef UpsertDogMembershipForTesting = Future<void> Function(
  DogMembership membership,
);

class DogEditorPage extends StatefulWidget {
  const DogEditorPage({
    super.key,
    this.initialDog,
    this.revokeSharedDogMembership,
    @visibleForTesting this.currentUserIdOverride,
    @visibleForTesting this.upsertMembershipOverride,
  });

  final Dog? initialDog;
  final RevokeSharedDogMembership? revokeSharedDogMembership;
  final String? currentUserIdOverride;
  final UpsertDogMembershipForTesting? upsertMembershipOverride;

  @override
  State<DogEditorPage> createState() => _DogEditorPageState();
}

@visibleForTesting
bool canGloballyDeleteDog({
  required Dog dog,
  required Iterable<DogMembership> memberships,
  required Iterable<String> userIds,
}) {
  final normalizedUserIds = userIds
      .map((userId) => userId.trim())
      .where((userId) => userId.isNotEmpty)
      .toSet();
  if (normalizedUserIds.isEmpty) {
    return false;
  }

  final ownerUserId = dog.ownerUserId?.trim();
  if (ownerUserId != null &&
      ownerUserId.isNotEmpty &&
      normalizedUserIds.contains(ownerUserId)) {
    return true;
  }

  return memberships.any((membership) {
    return membership.dogKey == dog.dogKey &&
        normalizedUserIds.contains(membership.userId.trim()) &&
        membership.status == Status.active &&
        membership.role == Role.owner;
  });
}

@visibleForTesting
DogMembership? activeSharedMembershipForUser({
  required Dog dog,
  required Iterable<DogMembership> memberships,
  required Iterable<String> userIds,
  String? preferredUserId,
}) {
  final normalizedUserIds = userIds
      .map((userId) => userId.trim())
      .where((userId) => userId.isNotEmpty)
      .toSet();
  if (normalizedUserIds.isEmpty) {
    return null;
  }

  final preferred = preferredUserId?.trim();
  if (preferred != null && preferred.isNotEmpty) {
    for (final membership in memberships) {
      if (membership.dogKey == dog.dogKey &&
          membership.userId.trim() == preferred &&
          membership.status == Status.active &&
          membership.role != Role.owner) {
        return membership;
      }
    }
  }

  for (final membership in memberships) {
    if (membership.dogKey == dog.dogKey &&
        normalizedUserIds.contains(membership.userId.trim()) &&
        membership.status == Status.active &&
        membership.role != Role.owner) {
      return membership;
    }
  }
  return null;
}

class _DogEditorPageState extends State<DogEditorPage> {
  static const List<_HeroScaleOption> _heroScaleOptions = [
    _HeroScaleOption(_HeroScaleLabelKey.small, 0.85),
    _HeroScaleOption(_HeroScaleLabelKey.normal, 1.0),
    _HeroScaleOption(_HeroScaleLabelKey.large, 1.2),
  ];

  late final Box<Dog> _dogsBox;
  late final Box<ActiveSessionDraft> _draftBox;
  late final Box<dynamic> _breedCatalogBox;
  late final Box<DogMembership> _membershipBox;
  late final String _dogId;

  final UserIdentityService _identityService = UserIdentityService();
  final LocalDogMembershipRepository _membershipRepository =
      LocalDogMembershipRepository();
  final SyncOutboxService _syncOutboxService = SyncOutboxService();
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isEditing => widget.initialDog != null;

  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _regNrController;
  late final TextEditingController _pedigreeUrlController;
  final TextEditingController _newBreedController = TextEditingController();
  final TextEditingController _memorialController = TextEditingController();
  final TextEditingController _memorialStoryController =
      TextEditingController();
  late final TextEditingController _ownerEmailController;

  DateTime? _selectedBirthDate;
  DateTime? _selectedDeathDate;
  DogSex _selectedSex = DogSex.male;
  Role _selectedRole = Role.owner;
  List<String> _breedOptions = [];
  String? _selectedBreed;
  String? _selectedImagePath;
  bool _profilePhotoChanged = false;
  bool _registeredDead = false;
  ProfileHeroTextAnchor _heroTextAnchor = ProfileHeroTextAnchor.bottomLeft;
  double _heroTextScale = 1.0;

  bool _isSaving = false;
  bool _isDeletingDog = false;
  bool _isRemovingSharedDog = false;
  bool _allowImmediatePop = false;
  late final _DogEditorSnapshot _initialSnapshot;

  @override
  void initState() {
    super.initState();

    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _draftBox = HiveLifecycleService.getBox<ActiveSessionDraft>(
      activeSessionDraftBoxName,
    );
    _breedCatalogBox =
        HiveLifecycleService.getBox<dynamic>(breedCatalogBoxName);
    _membershipBox =
        HiveLifecycleService.getBox<DogMembership>(dogMembershipsBoxName);

    final dog = widget.initialDog;
    _dogId = dog?.id ?? const Uuid().v4();

    final regNrDisplay = dog?.regNrDisplay;
    final hasRegNrDisplay =
        regNrDisplay != null && regNrDisplay.trim().isNotEmpty;
    final regNr = hasRegNrDisplay ? regNrDisplay : dog?.regNr;

    _nameController = TextEditingController(text: dog?.name ?? '');
    _nicknameController = TextEditingController(text: dog?.nickname ?? '');
    _regNrController = TextEditingController(text: regNr ?? '');
    _pedigreeUrlController =
        TextEditingController(text: dog?.pedigreeUrl ?? '');

    _selectedBirthDate = dog?.birthDate;
    _selectedDeathDate = dog?.deceasedAt;
    _selectedImagePath = dog?.imagePath;
    _registeredDead = dog?.deceasedAt != null;
    _selectedSex = dog?.sex ?? DogSex.male;
    final initialBreed = dog?.breed;
    final trimmedBreed = initialBreed?.trim();
    _selectedBreed =
        (trimmedBreed != null && trimmedBreed.isNotEmpty) ? trimmedBreed : null;
    _memorialController.text = dog?.memorialNote ?? '';
    _memorialStoryController.text = dog?.memorialStory ?? '';
    _ownerEmailController = TextEditingController(text: dog?.ownerEmail ?? '');
    _heroTextAnchor =
        profileHeroTextAnchorFromValue(dog?.profileHeroTextAnchor);
    _heroTextScale = dog?.profileHeroTextScale ?? 1.0;

    _loadBreedOptions();
    _persistSelectedBreedIfMissing();
    _initialSnapshot = _currentSnapshot();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _regNrController.dispose();
    _pedigreeUrlController.dispose();
    _newBreedController.dispose();
    _memorialController.dispose();
    _memorialStoryController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (kDebugMode) {
      debugPrint('[TF][UI] dog editor save requested');
    }
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);

    try {
      final l10n = AppLocalizations.of(context)!;
      final name = _nameController.text.trim();
      final currentUserId = _currentMembershipUserId();
      final nicknameText = _nicknameController.text.trim();
      final nickname = nicknameText.isEmpty ? null : nicknameText;
      if (name.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dog_editor_error_name_missing)),
        );
        return;
      }

      final regNrValue = _regNrController.text.trim();
      final regNrDisplay = regNrValue;
      final regNr = regNrValue.isEmpty ? null : regNrValue;
      final pedigreeUrl = _pedigreeUrlController.text.trim();
      final breed = _selectedBreed?.trim();
      if (breed != null && breed.isNotEmpty) {
        await _ensureBreedStored(breed);
      }

      final deathDate = _registeredDead ? _selectedDeathDate : null;
      final memorialText = _memorialController.text.trim();
      final memorialNote =
          (_registeredDead && memorialText.isNotEmpty) ? memorialText : null;
      final memorialStoryText = _memorialStoryController.text.trim();
      final memorialStory = (_registeredDead && memorialStoryText.isNotEmpty)
          ? memorialStoryText
          : null;
      final dog = widget.initialDog;
      String? ownerEmail;
      final ownerEmailInput = _selectedRole == Role.owner
          ? null
          : _ownerEmailController.text.trim();
      if (!_isEditing && ownerEmailInput != null) {
        if (ownerEmailInput.isEmpty || !ownerEmailInput.contains('@')) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.dog_editor_owner_email_required_error)),
          );
          return;
        }
        ownerEmail = ownerEmailInput;
      }

      if (dog != null) {
        final updated = dog.copyWith(
          name: name,
          nickname: nickname,
          imagePath: _selectedImagePath ?? dog.imagePath,
          birthDate: _selectedBirthDate,
          regNrDisplay: regNrDisplay,
          regNr: regNr,
          breed: breed?.isEmpty ?? true ? null : breed,
          pedigreeUrl: pedigreeUrl.isEmpty ? null : pedigreeUrl,
          sex: _selectedSex,
          updatedAt: DateTime.now(),
          deceasedAt: deathDate,
          memorialNote: memorialNote,
          memorialStory: memorialStory,
          profileHeroTextAnchor: _heroTextAnchor.name,
          profileHeroTextScale: _heroTextScale,
        );

        await _persistDogLocally(updated);
        await _enqueueDogAutosync(updated);
        await _tryUploadProfilePhotoToCloud(updated);
      } else {
        final currentUid = currentUserId;
        final memberships = currentUid == null
            ? <DogMembership>[]
            : _membershipBox.values
                .where((membership) =>
                    membership.userId.trim() == currentUid &&
                    membership.status == Status.active)
                .toList(growable: false);
        final dogLimitSnapshot = buildDogLimitCountSnapshot(
          dogs: _dogsBox.values,
          memberships: memberships,
          currentUserId: currentUid,
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
          if (!mounted) {
            return;
          }
          await showProUpgradeSheet(context);
          return;
        }

        final ownerUserId =
            _selectedRole == Role.owner ? _currentMembershipUserId() : null;
        final created = Dog(
          id: _dogId,
          name: name,
          dogKey: const Uuid().v4(),
          regNrDisplay: regNrDisplay,
          imagePath: _selectedImagePath,
          regNr: regNr,
          birthDate: _selectedBirthDate,
          breed: breed?.isEmpty ?? true ? null : breed,
          pedigreeUrl: pedigreeUrl.isEmpty ? null : pedigreeUrl,
          sex: _selectedSex,
          deceasedAt: deathDate,
          memorialNote: memorialNote,
          memorialStory: memorialStory,
          profileHeroTextAnchor: _heroTextAnchor.name,
          profileHeroTextScale: _heroTextScale,
          nickname: nickname,
          ownerUserId: ownerUserId,
          ownerEmail: ownerEmail,
        );

        await _persistDogLocally(created);
        await _storeMembershipForUser(created);
        await _enqueueDogAutosync(created);
      }

      if (!mounted) {
        return;
      }
      _allowImmediatePop = true;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDeleteDog() async {
    if (!_isEditing || _isDeletingDog || !_canDeleteInitialDog) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.dog_editor_delete_dog_title),
          content: Text(l10n.dog_editor_delete_dog_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.dog_editor_button_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.dog_editor_button_delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }
    await _deleteDogCascade();
  }

  Future<void> _confirmRemoveSharedDog() async {
    if (!_isEditing ||
        _isRemovingSharedDog ||
        _isDeletingDog ||
        !_canRemoveInitialDogForCurrentUser) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.dog_editor_remove_shared_dog_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dog_editor_remove_shared_dog_body),
              const SizedBox(height: 8),
              Text(l10n.dog_editor_remove_shared_dog_explanation),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.dog_editor_button_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.dog_editor_remove_shared_dog_confirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }
    await _removeSharedDogForCurrentUser();
  }

  Future<void> _removeSharedDogForCurrentUser() async {
    final dog = widget.initialDog;
    final membership = _activeSharedMembershipForCurrentUser;
    if (dog == null || membership == null) {
      return;
    }

    setState(() => _isRemovingSharedDog = true);
    try {
      String? activeUid;
      try {
        activeUid = FirebaseAuth.instance.currentUser?.uid.trim();
      } catch (_) {
        activeUid = null;
      }
      final targetCloudDogId = (dog.cloudId ?? '').trim();
      final canonicalPath = activeUid != null &&
              activeUid.isNotEmpty &&
              targetCloudDogId.isNotEmpty
          ? 'dogs/$targetCloudDogId/members/$activeUid'
          : 'dogs/{missing-cloudId}/members/{missing-uid}';

      if (kDebugMode) {
        debugPrint(
          '[SHARE][LEAVE] start '
          'uid=${activeUid ?? 'null'} '
          'dog=${dog.name} dogId=${dog.id} cloudId=${dog.cloudId} '
          'dogKey=${dog.dogKey} cloudOwnerUid=${dog.cloudOwnerUid} '
          'role=${membership.role.name}',
        );
        debugPrint(
          '[SHARE][LEAVE] member path=$canonicalPath',
        );
      }

      final revokedMembership = membership.copyWith(status: Status.revoked);
      final revokeSharedDogMembership = widget.revokeSharedDogMembership ??
          FirestoreDogSyncService
              .instance.revokeCurrentUserMembershipBestEffort;
      var cloudUpdated = false;
      try {
        cloudUpdated = await revokeSharedDogMembership(
          dog: dog,
          membership: revokedMembership,
        );
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('[SHARE][LEAVE] cloud revoke failed: $error');
          debugPrint(stackTrace.toString());
        }
        cloudUpdated = false;
      }
      if (kDebugMode) {
        debugPrint(
          cloudUpdated
              ? '[SHARE][LEAVE] cloud revoke success'
              : '[SHARE][LEAVE] cloud revoke failed',
        );
      }

      if (!cloudUpdated) {
        if (kDebugMode) {
          debugPrint(
              '[SHARE][LEAVE] cloud revoke failed (continuing local leave)');
        }
      }

      final upsertMembership = widget.upsertMembershipOverride ??
          _membershipRepository.upsertMembership;
      await upsertMembership(revokedMembership);
      if (kDebugMode) {
        debugPrint(
          '[SHARE][LEAVE] local revoke success',
        );
      }

      if (!mounted) {
        return;
      }
      setState(() => _allowImmediatePop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isRemovingSharedDog = false);
      }
    }
  }

  Future<void> _deleteDogCascade() async {
    final dog = widget.initialDog;
    if (dog == null) {
      return;
    }
    if (!_canDeleteInitialDog) {
      if (kDebugMode) {
        debugPrint(
          '[DOG][DELETE] blocked global delete for non-owner: ${dog.id}',
        );
      }
      return;
    }

    setState(() => _isDeletingDog = true);
    try {
      final draftEntries = _draftBox
          .toMap()
          .entries
          .where((entry) => entry.value.dogId == dog.id)
          .toList(growable: false);
      for (final entry in draftEntries) {
        await _draftBox.delete(entry.key);
      }

      final deletedAt = DateTime.now().toUtc();
      final deletedDog = dog.copyWith(
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      );
      final dogHiveKey = _findDogHiveKey(dog.id, fallbackDogKey: dog.dogKey);
      if (dogHiveKey != null) {
        await _dogsBox.put(dogHiveKey, deletedDog);
        print(
            '[SUBSCRIPTION][DOG_LIMIT] dog soft-deleted in Hive: ${dog.id} dogKey=${dog.dogKey}');
      } else {
        // Hive key not found – the local box was NOT updated.
        // The dog will still appear as non-deleted and count toward the limit
        // until the next Firestore pull applies the cloud tombstone.
        print(
            '[SUBSCRIPTION][DOG_LIMIT] WARNING: dog not found in Hive box, soft-delete skipped: id=${dog.id} dogKey=${dog.dogKey}');
      }
      if (kDebugMode) {
        debugPrint('[TF][SYNC] dog delete requested: ${dog.id}');
      }
      await _syncOutboxService.enqueueDeleteDog(
        deletedDog,
        deletedAt: deletedAt,
      );
      await FirestoreDogSyncService.instance.tombstoneDogBestEffort(deletedDog);

      if (!mounted) {
        return;
      }
      _allowImmediatePop = true;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isDeletingDog = false);
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final initial = _selectedBirthDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(today.year + 1),
    );
    if (picked == null) {
      return;
    }
    setState(() => _selectedBirthDate = picked);
  }

  Future<void> _pickDeathDate() async {
    final today = DateTime.now();
    final initial = _selectedDeathDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year + 1),
    );
    if (picked == null) {
      return;
    }
    setState(() => _selectedDeathDate = picked);
  }

  void _toggleRegisteredDead(bool value) {
    setState(() {
      _registeredDead = value;
      if (value) {
        _selectedDeathDate ??= DateTime.now();
      } else {
        _selectedDeathDate = null;
      }
    });
  }

  String _deathDateButtonLabel(BuildContext context) {
    final date = _selectedDeathDate;
    if (date == null) {
      return AppLocalizations.of(context)!.dog_editor_death_date_picker_hint;
    }
    return _formatDate(context, date);
  }

  Future<void> _showPhotoSourcePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.dog_detail_photo_source_gallery),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.dog_detail_photo_source_camera),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(l10n.dog_editor_button_cancel),
                onTap: () => Navigator.of(sheetContext).pop(null),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }
    await _pickAndPersistPhoto(source);
  }

  Future<void> _pickAndPersistPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
      );
      if (picked == null) {
        return;
      }

      final savedPath = await DogPhotoStorage.saveDogPhoto(
        dogId: _dogId,
        sourcePath: picked.path,
      );
      final absolutePath = DogImagePathResolver.toAbsolute(savedPath);
      if (absolutePath != null) {
        await FileImage(File(absolutePath)).evict();
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImagePath = savedPath;
        _profilePhotoChanged = true;
      });
    } catch (error, stackTrace) {
      debugPrint('[DOG][EDITOR] Failed to save profile photo: $error');
      debugPrint('$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dog_detail_snackbar_image_save_failed)),
      );
    }
  }

  Widget _buildLifeSection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.pets),
            const SizedBox(width: 8),
            Text(
              l10n.dog_editor_section_lifecycle_title,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _registeredDead,
          onChanged: _toggleRegisteredDead,
          title: Text(l10n.dog_editor_death_registered_title),
          secondary: const Icon(Icons.heart_broken, color: Colors.red),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.trailing,
        ),
        if (_registeredDead) ...[
          const SizedBox(height: 12),
          Text(
            l10n.dog_editor_death_date_label,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          FilledButton.tonal(
            onPressed: _pickDeathDate,
            child: Text(_deathDateButtonLabel(context)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memorialController,
            decoration: InputDecoration(
              labelText: l10n.dog_editor_memory_words_label,
            ),
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memorialStoryController,
            decoration: InputDecoration(
              labelText: l10n.dog_memorial_story_label,
              hintText: l10n.dog_memorial_story_hint,
            ),
            maxLines: null,
            minLines: 3,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ],
    );
  }

  Widget _buildHeroTextSection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.photo),
            const SizedBox(width: 8),
            Text(
              l10n.dog_editor_section_hero_title,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showPhotoSourcePicker,
          child: _buildHeroPreview(l10n, theme),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _showPhotoSourcePicker,
          icon: const Icon(Icons.photo_camera),
          label: Text(l10n.dog_detail_button_edit_photo),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ProfileHeroTextAnchor>(
          initialValue: _heroTextAnchor,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.dog_editor_image_text_anchor_label,
          ),
          items: ProfileHeroTextAnchor.values
              .map(
                (anchor) => DropdownMenuItem(
                  value: anchor,
                  child: Text(_heroAnchorLabel(l10n, anchor)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _heroTextAnchor = value);
          },
        ),
        const SizedBox(height: 12),
        Text(
          l10n.dog_editor_text_size_label,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: _heroScaleOptions
              .map((option) => _buildHeroScaleChip(option, l10n))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHeroPreview(AppLocalizations l10n, ThemeData theme) {
    final absolutePath = DogImagePathResolver.toAbsolute(_selectedImagePath);
    final previewAlignment = _alignmentFromHeroAnchor(_heroTextAnchor);
    final nickname = _nicknameController.text.trim();
    final name = _nameController.text.trim();
    final displayName = nickname.isNotEmpty
        ? nickname
        : (name.isNotEmpty ? name : l10n.dog_unnamed);
    final showFullName = nickname.isNotEmpty && name.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
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
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.pets,
                  size: 52,
                  color: theme.colorScheme.onSurfaceVariant,
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
                  stops: [0.35, 1.0],
                ),
              ),
            ),
            Align(
              alignment: previewAlignment,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Transform.scale(
                  scale: _heroTextScale,
                  alignment: previewAlignment,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (showFullName) ...[
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
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

  Widget _buildHeroScaleChip(_HeroScaleOption option, AppLocalizations l10n) {
    return ChoiceChip(
      label: Text(_heroScaleLabel(l10n, option.labelKey)),
      selected: _heroTextScale == option.scale,
      onSelected: (selected) {
        if (!selected) {
          return;
        }
        setState(() => _heroTextScale = option.scale);
      },
    );
  }

  void _loadBreedOptions() {
    final raw = _breedCatalogBox.get('breeds');
    final list = <String>[];
    if (raw is Iterable) {
      for (final entry in raw) {
        if (entry is String) {
          final trimmed = entry.trim();
          if (trimmed.isEmpty) {
            continue;
          }
          final exists = list.any(
            (breed) => breed.toLowerCase() == trimmed.toLowerCase(),
          );
          if (!exists) {
            list.add(trimmed);
          }
        }
      }
    }
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _breedOptions = list;
  }

  void _persistSelectedBreedIfMissing() {
    final breed = _selectedBreed;
    if (breed == null || breed.trim().isEmpty) {
      return;
    }
    final exists = _breedOptions.any(
      (option) => option.toLowerCase() == breed.toLowerCase(),
    );
    if (exists) {
      return;
    }
    final updated = [..._breedOptions, breed];
    updated.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _breedCatalogBox.put('breeds', updated);
    _breedOptions = updated;
  }

  Future<void> _ensureBreedStored(String breed) async {
    final trimmed = breed.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final exists = _breedOptions.any(
      (option) => option.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      if (_selectedBreed != trimmed) {
        setState(() => _selectedBreed = trimmed);
      }
      return;
    }
    final updated = [..._breedOptions, trimmed];
    updated.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _breedCatalogBox.put('breeds', updated);
    if (mounted) {
      setState(() {
        _breedOptions = updated;
        _selectedBreed = trimmed;
      });
    } else {
      _breedOptions = updated;
      _selectedBreed = trimmed;
    }
  }

  Future<void> _addBreed(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final exists = _breedOptions.any(
      (option) => option.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      final matched = _breedOptions.firstWhere(
        (option) => option.toLowerCase() == trimmed.toLowerCase(),
      );
      setState(() => _selectedBreed = matched);
      return;
    }
    final updated = [..._breedOptions, trimmed];
    updated.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _breedCatalogBox.put('breeds', updated);
    if (mounted) {
      setState(() {
        _breedOptions = updated;
        _selectedBreed = trimmed;
      });
    } else {
      _breedOptions = updated;
      _selectedBreed = trimmed;
    }
  }

  Future<void> _showAddBreedDialog() async {
    _newBreedController.clear();
    final l10n = AppLocalizations.of(context)!;
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.dog_editor_new_breed_title),
          content: TextField(
            controller: _newBreedController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: l10n.dog_editor_new_breed_hint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.dog_editor_button_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.dog_editor_button_add),
            ),
          ],
        );
      },
    );
    if (added == true) {
      await _addBreed(_newBreedController.text);
    }
  }

  Widget _buildBreedSection() {
    final l10n = AppLocalizations.of(context)!;
    final uniqueBreeds = <String>[];
    final seenBreeds = <String>{};
    for (final breed in _breedOptions) {
      if (seenBreeds.add(breed)) {
        uniqueBreeds.add(breed);
      }
    }
    final items = [
      DropdownMenuItem<String?>(
        value: null,
        child: Text(l10n.dog_editor_select_breed_placeholder),
      ),
      ...uniqueBreeds.map(
        (breed) => DropdownMenuItem<String?>(
          value: breed,
          child: Text(breed),
        ),
      ),
    ];
    final selectedBreedMatchCount =
        items.where((item) => item.value == _selectedBreed).length;
    final dropdownValue = selectedBreedMatchCount == 1 ? _selectedBreed : null;
    print('[DOG][BREED] items count: ${_breedOptions.length}');
    print('[DOG][BREED] unique items count: ${uniqueBreeds.length}');
    print('[DOG][BREED] selected breed: $dropdownValue');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.dog_editor_section_breed_title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          initialValue: dropdownValue,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.dog_editor_select_breed_label,
          ),
          items: items,
          onChanged: (value) => setState(() => _selectedBreed = value),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddBreedDialog,
          icon: const Icon(Icons.add),
          label: Text(l10n.dog_editor_new_breed_option),
        ),
      ],
    );
  }

  Widget _buildRoleSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.dog_editor_role_section_title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        RadioListTile<Role>(
          value: Role.owner,
          groupValue: _selectedRole,
          title: Text(l10n.dog_editor_role_owner),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedRole = value);
          },
        ),
        RadioListTile<Role>(
          value: Role.admin,
          groupValue: _selectedRole,
          title: Text(l10n.dog_editor_role_admin),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedRole = value);
          },
        ),
        RadioListTile<Role>(
          value: Role.viewer,
          groupValue: _selectedRole,
          title: Text(l10n.dog_editor_role_user),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedRole = value);
          },
        ),
        if (_selectedRole != Role.owner) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _ownerEmailController,
            decoration: InputDecoration(
              labelText: l10n.dog_editor_owner_email_label,
              hintText: l10n.dog_editor_owner_email_hint,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ],
    );
  }

  Future<void> _storeMembershipForUser(Dog dog) async {
    final uid = _currentMembershipUserId();
    if (uid == null || uid.isEmpty) {
      return;
    }

    final effectiveDogKey = dog.dogKey.trim().isEmpty ? dog.id : dog.dogKey;
    final existing = await _membershipRepository.getMembership(
      effectiveDogKey,
      uid,
    );
    if (existing != null) {
      return;
    }

    final membership = DogMembership(
      dogKey: effectiveDogKey,
      userId: uid,
      role: _selectedRole,
      status: Status.active,
      addedAt: DateTime.now(),
      addedByUserId: uid,
    );
    await _membershipRepository.upsertMembership(membership);
    if (kDebugMode) {
      debugPrint('[TF][FIX] dog membership saved: dogId=${dog.id} userId=$uid');
    }
  }

  Future<dynamic> _persistDogLocally(Dog dog) async {
    final existingHiveKey = _findDogHiveKey(dog.id, fallbackDogKey: dog.dogKey);
    if (existingHiveKey != null) {
      if (kDebugMode) {
        debugPrint('Saving dog sex (update): ${_selectedSex.name}');
      }
      await _dogsBox.put(existingHiveKey, dog);
      if (kDebugMode) {
        debugPrint('[TF][FIX] dog saved locally: ${dog.id}');
      }
      return existingHiveKey;
    }

    if (kDebugMode) {
      debugPrint('Saving dog sex (create): ${_selectedSex.name}');
    }
    final newHiveKey = await _dogsBox.add(dog);
    if (kDebugMode) {
      debugPrint('[TF][FIX] dog saved locally: ${dog.id}');
    }
    return newHiveKey;
  }

  Future<void> _enqueueDogAutosync(Dog dog) async {
    if (kDebugMode) {
      debugPrint('[TF][SYNC] dog autosync queued: ${dog.id}');
    }
    await _syncOutboxService.enqueueUpsertDog(dog);
  }

  Future<void> _tryUploadProfilePhotoToCloud(Dog dog) async {
    if (!_profilePhotoChanged) {
      return;
    }
    final selectedImagePath = _selectedImagePath?.trim();
    if (selectedImagePath == null || selectedImagePath.isEmpty) {
      debugPrint(
        '[DOG][PROFILE_MEDIA] editor cloud upload skipped: missing selected image path',
      );
      return;
    }
    final resolvedCloudId = dog.cloudId?.trim();
    final dogCloudId = (resolvedCloudId == null || resolvedCloudId.isEmpty)
        ? dog.id.trim()
        : resolvedCloudId;
    if (dogCloudId.isEmpty) {
      debugPrint(
        '[DOG][PROFILE_MEDIA] editor cloud upload skipped: missing cloudId and dog.id fallback',
      );
      return;
    }
    if (dog.dogKey.trim().isEmpty) {
      debugPrint(
        '[DOG][PROFILE_MEDIA] editor cloud upload skipped: missing dogKey',
      );
      return;
    }
    String? currentUserUid;
    try {
      currentUserUid = FirebaseAuth.instance.currentUser?.uid.trim();
    } catch (_) {
      currentUserUid = null;
    }
    if (currentUserUid == null || currentUserUid.isEmpty) {
      debugPrint(
        '[DOG][PROFILE_MEDIA] editor cloud upload skipped: missing Firebase uid',
      );
      return;
    }
    final absolutePath = DogImagePathResolver.toAbsolute(selectedImagePath);
    if (absolutePath == null || absolutePath.trim().isEmpty) {
      debugPrint(
        '[DOG][PROFILE_MEDIA] editor cloud upload skipped: could not resolve absolute image path',
      );
      return;
    }

    try {
      final file = File(absolutePath);
      final sizeBytes = await file.exists() ? await file.length() : null;
      final updatedDog =
          await DogProfileMediaUpdateService().uploadAndSetProfileMediaId(
        dog: dog.copyWith(cloudId: dogCloudId),
        localImagePath: absolutePath,
        currentUserUid: currentUserUid,
        contentType: 'image/jpeg',
        sizeBytes: sizeBytes,
      );
      await _syncOutboxService.enqueueUpsertDog(updatedDog);
      _profilePhotoChanged = false;
    } catch (error, stackTrace) {
      debugPrint('[DOG][PROFILE_MEDIA] editor cloud upload failed: $error');
      debugPrint('$stackTrace');
    }
  }

  dynamic _findDogHiveKey(String dogId, {String? fallbackDogKey}) {
    // Primary: search by the Dog.id field.
    for (final entry in _dogsBox.toMap().entries) {
      if (entry.value.id == dogId) {
        return entry.key;
      }
    }
    // Fallback: search by dogKey.
    // Needed for dogs whose id field (HiveField 4) was never stored
    // (created with an older schema) – in that case every Hive read generates
    // a new random UUID for .id, so the primary search never matches.
    if (fallbackDogKey != null && fallbackDogKey.trim().isNotEmpty) {
      for (final entry in _dogsBox.toMap().entries) {
        if (entry.value.dogKey == fallbackDogKey) {
          return entry.key;
        }
      }
    }
    return null;
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

  String? _currentMembershipUserId() {
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      currentUser = null;
    }
    final authUid = currentUser?.uid.trim();
    if (authUid != null && authUid.isNotEmpty) {
      return authUid;
    }
    final overrideUid = widget.currentUserIdOverride?.trim();
    if (overrideUid != null && overrideUid.isNotEmpty) {
      return overrideUid;
    }
    final localUid = _identityService.getCurrentUserId().trim();
    return localUid.isEmpty ? null : localUid;
  }

  Set<String> _currentMembershipUserIds() {
    final ids = <String>{};
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      currentUser = null;
    }
    final authUid = currentUser?.uid.trim();
    if (authUid != null && authUid.isNotEmpty) {
      ids.add(authUid);
    }
    final overrideUid = widget.currentUserIdOverride?.trim();
    if (overrideUid != null && overrideUid.isNotEmpty) {
      ids.add(overrideUid);
    }
    final localUid = _identityService.getCurrentUserId().trim();
    if (localUid.isNotEmpty) {
      ids.add(localUid);
    }
    return ids;
  }

  String? _preferredMembershipUserId() {
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      currentUser = null;
    }
    final authUid = currentUser?.uid.trim();
    if (authUid != null && authUid.isNotEmpty) {
      return authUid;
    }
    final overrideUid = widget.currentUserIdOverride?.trim();
    if (overrideUid != null && overrideUid.isNotEmpty) {
      return overrideUid;
    }
    final localUid = _identityService.getCurrentUserId().trim();
    return localUid.isEmpty ? null : localUid;
  }

  bool get _canDeleteInitialDog {
    final dog = widget.initialDog;
    if (dog == null) {
      return false;
    }
    return canGloballyDeleteDog(
      dog: dog,
      memberships: _membershipBox.values,
      userIds: _currentMembershipUserIds(),
    );
  }

  DogMembership? get _activeSharedMembershipForCurrentUser {
    final dog = widget.initialDog;
    if (dog == null) {
      return null;
    }
    return activeSharedMembershipForUser(
      dog: dog,
      memberships: _membershipBox.values,
      userIds: _currentMembershipUserIds(),
      preferredUserId: _preferredMembershipUserId(),
    );
  }

  bool get _canRemoveInitialDogForCurrentUser {
    return _isEditing &&
        !_canDeleteInitialDog &&
        _activeSharedMembershipForCurrentUser != null;
  }

  _DogEditorSnapshot _currentSnapshot() {
    return _DogEditorSnapshot(
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim(),
      imagePath: _selectedImagePath,
      regNr: _regNrController.text.trim(),
      pedigreeUrl: _pedigreeUrlController.text.trim(),
      birthDate: _selectedBirthDate,
      deathDate: _selectedDeathDate,
      sex: _selectedSex,
      role: _selectedRole,
      breed: _selectedBreed?.trim(),
      registeredDead: _registeredDead,
      memorialNote: _memorialController.text.trim(),
      memorialStory: _memorialStoryController.text.trim(),
      ownerEmail: _ownerEmailController.text.trim(),
      heroTextAnchor: _heroTextAnchor,
      heroTextScale: _heroTextScale,
    );
  }

  bool get _hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;

  Future<bool> _confirmDiscardChanges() async {
    if (_isSaving || _isDeletingDog || _isRemovingSharedDog) {
      return false;
    }

    if (!_hasUnsavedChanges) {
      return true;
    }

    final l10n = AppLocalizations.of(context)!;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.dog_editor_discard_changes_title),
          content: Text(l10n.dog_editor_discard_changes_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.dog_editor_button_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.dog_editor_discard_changes_confirm),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  Future<void> _handlePopAttempt() async {
    if (_allowImmediatePop) {
      return;
    }

    final shouldPop = await _confirmDiscardChanges();
    if (!mounted || !shouldPop) {
      return;
    }

    _allowImmediatePop = true;
    Navigator.of(context).pop(false);
  }

  Future<void> _openShareDog() async {
    final existingDog = widget.initialDog;
    if (existingDog == null) {
      return;
    }

    Dog? currentDog;
    final hiveKey =
        _findDogHiveKey(existingDog.id, fallbackDogKey: existingDog.dogKey);
    if (hiveKey != null) {
      currentDog = _dogsBox.get(hiveKey);
    }
    currentDog ??= existingDog;

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DogDetailPage(dog: currentDog!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _isEditing
        ? l10n.dog_editor_title_edit_dog
        : l10n.dog_editor_title_add_dog;
    final birthDateText = _selectedBirthDate == null
        ? l10n.dog_editor_birthdate_not_set
        : _formatDate(context, _selectedBirthDate!);

    return PopScope(
      canPop: _allowImmediatePop || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _handlePopAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (_isEditing)
              TextButton.icon(
                onPressed: _openShareDog,
                icon: const Icon(Icons.share),
                label: const Text('Del hund'),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (!_isEditing) ...[
                _EditorIntroCard(
                  title: l10n.dog_editor_intro_title,
                  body: l10n.dog_editor_intro_body,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _nameController,
                decoration:
                    InputDecoration(labelText: l10n.dog_editor_name_label),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: l10n.dog_editor_nickname_label,
                  hintText: l10n.dog_editor_nickname_hint,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dog_editor_section_sex,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: DogSex.values.map((sex) {
                  final label = sex == DogSex.male
                      ? l10n.dog_sex_male
                      : l10n.dog_sex_female;
                  return RadioListTile<DogSex>(
                    value: sex,
                    groupValue: _selectedSex,
                    title: Text(label),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedSex = value);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (!_isEditing) ...[
                _buildRoleSection(l10n),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.dog_editor_birthdate_label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              FilledButton.tonal(
                onPressed: _pickBirthDate,
                child: Text(birthDateText),
              ),
              const SizedBox(height: 16),
              _buildBreedSection(),
              const SizedBox(height: 16),
              _buildHeroTextSection(),
              const SizedBox(height: 16),
              TextField(
                controller: _regNrController,
                decoration:
                    InputDecoration(labelText: l10n.dog_editor_regnr_label),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pedigreeUrlController,
                decoration: InputDecoration(
                  labelText: l10n.dog_editor_pedigree_url_label,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              _buildLifeSection(),
              const SizedBox(height: 20),
              FilledButton(
                onPressed:
                    (_isSaving || _isRemovingSharedDog) ? null : _handleSave,
                child: Text(
                  _isSaving ? l10n.dog_editor_saving : l10n.dog_editor_save,
                ),
              ),
              if (_isEditing && _canDeleteInitialDog) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed:
                      (_isDeletingDog || _isSaving) ? null : _confirmDeleteDog,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    _isDeletingDog
                        ? l10n.dog_editor_deleting
                        : l10n.dog_editor_delete_dog,
                  ),
                  style: FilledButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ] else if (_isEditing && _canRemoveInitialDogForCurrentUser) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: (_isRemovingSharedDog || _isSaving)
                      ? null
                      : _confirmRemoveSharedDog,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: Text(
                    _isRemovingSharedDog
                        ? l10n.dog_editor_removing_shared_dog
                        : l10n.dog_editor_remove_shared_dog,
                  ),
                  style: FilledButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String _heroScaleLabel(AppLocalizations l10n, _HeroScaleLabelKey key) {
  switch (key) {
    case _HeroScaleLabelKey.small:
      return l10n.dog_editor_text_size_small;
    case _HeroScaleLabelKey.normal:
      return l10n.dog_editor_text_size_normal;
    case _HeroScaleLabelKey.large:
      return l10n.dog_editor_text_size_large;
  }
}

String _heroAnchorLabel(AppLocalizations l10n, ProfileHeroTextAnchor anchor) {
  switch (anchor) {
    case ProfileHeroTextAnchor.bottomLeft:
      return l10n.dog_editor_anchor_bottom_left;
    case ProfileHeroTextAnchor.bottomCenter:
      return l10n.dog_editor_anchor_bottom_center;
    case ProfileHeroTextAnchor.topLeft:
      return l10n.dog_editor_anchor_top_left;
  }
}

enum _HeroScaleLabelKey { small, normal, large }

class _HeroScaleOption {
  const _HeroScaleOption(this.labelKey, this.scale);

  final _HeroScaleLabelKey labelKey;
  final double scale;
}

class _EditorIntroCard extends StatelessWidget {
  const _EditorIntroCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.pets_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DogEditorSnapshot {
  const _DogEditorSnapshot({
    required this.name,
    required this.nickname,
    required this.imagePath,
    required this.regNr,
    required this.pedigreeUrl,
    required this.birthDate,
    required this.deathDate,
    required this.sex,
    required this.role,
    required this.breed,
    required this.registeredDead,
    required this.memorialNote,
    required this.memorialStory,
    required this.ownerEmail,
    required this.heroTextAnchor,
    required this.heroTextScale,
  });

  final String name;
  final String nickname;
  final String? imagePath;
  final String regNr;
  final String pedigreeUrl;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final DogSex sex;
  final Role role;
  final String? breed;
  final bool registeredDead;
  final String memorialNote;
  final String memorialStory;
  final String ownerEmail;
  final ProfileHeroTextAnchor heroTextAnchor;
  final double heroTextScale;

  @override
  bool operator ==(Object other) {
    return other is _DogEditorSnapshot &&
        other.name == name &&
        other.nickname == nickname &&
        other.imagePath == imagePath &&
        other.regNr == regNr &&
        other.pedigreeUrl == pedigreeUrl &&
        other.birthDate == birthDate &&
        other.deathDate == deathDate &&
        other.sex == sex &&
        other.role == role &&
        other.breed == breed &&
        other.registeredDead == registeredDead &&
        other.memorialNote == memorialNote &&
        other.memorialStory == memorialStory &&
        other.ownerEmail == ownerEmail &&
        other.heroTextAnchor == heroTextAnchor &&
        other.heroTextScale == heroTextScale;
  }

  @override
  int get hashCode => Object.hash(
        name,
        nickname,
        imagePath,
        regNr,
        pedigreeUrl,
        birthDate,
        deathDate,
        sex,
        role,
        breed,
        registeredDead,
        memorialNote,
        memorialStory,
        ownerEmail,
        heroTextAnchor,
        heroTextScale,
      );
}
