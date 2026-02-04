import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import '../data/hive_boxes.dart';
import '../models/dog.dart';
import '../models/dog_membership.dart';
import '../models/dog_sex.dart';
import '../models/gps_track.dart';
import '../models/hunt_session.dart';
import '../models/share_invitation.dart';
import '../domain/models/active_session_draft.dart';
import '../services/dog_photo_storage.dart';
import '../services/hive_lifecycle_service.dart';
import '../services/user_identity_service.dart';
import '../domain/repositories/dog_milestone_state_repository.dart';

class DogEditorPage extends StatefulWidget {
  const DogEditorPage({
    super.key,
    this.initialDog,
  });

  final Dog? initialDog;

  @override
  State<DogEditorPage> createState() => _DogEditorPageState();
}

class _DogEditorPageState extends State<DogEditorPage> {
  static const List<_HeroScaleOption> _heroScaleOptions = [
    _HeroScaleOption(_HeroScaleLabelKey.small, 0.85),
    _HeroScaleOption(_HeroScaleLabelKey.normal, 1.0),
    _HeroScaleOption(_HeroScaleLabelKey.large, 1.2),
  ];
  late final Box<Dog> _dogsBox;
  late final Box<HuntSession> _sessionsBox;
  late final Box<ActiveSessionDraft> _draftBox;
  late final Box<GpsTrack> _gpsTracksBox;
  late final Box<DogMembership> _membershipBox;
  late final Box<ShareInvitation> _shareBox;
  late final Box<dynamic> _breedCatalogBox;

  final DogMilestoneStateRepository _milestoneStateRepository =
      DogMilestoneStateRepository();
  final UserIdentityService _identityService = UserIdentityService();

  bool get _isEditing => widget.initialDog != null;

  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _regNrController;
  late final TextEditingController _pedigreeUrlController;
  final TextEditingController _newBreedController = TextEditingController();
  final TextEditingController _memorialController = TextEditingController();
  late final TextEditingController _ownerEmailController;

  DateTime? _selectedBirthDate;
  DateTime? _selectedDeathDate;
  DogSex _selectedSex = DogSex.male;
  Role _selectedRole = Role.owner;
  List<String> _breedOptions = [];
  String? _selectedBreed;
  bool _registeredDead = false;
  ProfileHeroTextAnchor _heroTextAnchor = ProfileHeroTextAnchor.bottomLeft;
  double _heroTextScale = 1.0;

  bool _isSaving = false;
  bool _isDeletingDog = false;

  @override
  void initState() {
    super.initState();

    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _draftBox = HiveLifecycleService.getBox<ActiveSessionDraft>(
        activeSessionDraftBoxName);
    _gpsTracksBox = HiveLifecycleService.getBox<GpsTrack>(gpsTracksBoxName);
    _membershipBox =
        HiveLifecycleService.getBox<DogMembership>(dogMembershipsBoxName);
    _shareBox =
        HiveLifecycleService.getBox<ShareInvitation>(shareInvitesBoxName);
    _breedCatalogBox =
        HiveLifecycleService.getBox<dynamic>(breedCatalogBoxName);

    final dog = widget.initialDog;

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
    _registeredDead = dog?.deceasedAt != null;
    _selectedSex = dog?.sex ?? DogSex.male;
    final initialBreed = dog?.breed;
    final trimmedBreed = initialBreed?.trim();
    _selectedBreed =
        (trimmedBreed != null && trimmedBreed.isNotEmpty) ? trimmedBreed : null;
    _memorialController.text = dog?.memorialNote ?? '';
    _ownerEmailController = TextEditingController(text: dog?.ownerEmail ?? '');
    _heroTextAnchor = profileHeroTextAnchorFromValue(dog?.profileHeroTextAnchor);
    _heroTextScale = dog?.profileHeroTextScale ?? 1.0;

    _loadBreedOptions();
    _persistSelectedBreedIfMissing();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _regNrController.dispose();
    _pedigreeUrlController.dispose();
    _newBreedController.dispose();
    _memorialController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final l10n = AppLocalizations.of(context)!;
      final name = _nameController.text.trim();
      final currentUserId = _identityService.getCurrentUserId();
      final nicknameText = _nicknameController.text.trim();
      final nickname = nicknameText.isEmpty ? null : nicknameText;
      if (name.isEmpty) {
        if (!mounted) return;
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
      final dog = widget.initialDog;
      String? ownerEmail;
      final ownerEmailInput = _selectedRole == Role.owner
          ? null
          : _ownerEmailController.text.trim();
      if (!_isEditing && ownerEmailInput != null) {
        if (ownerEmailInput.isEmpty || !ownerEmailInput.contains('@')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.dog_editor_owner_email_required_error)),
          );
          return;
        }
        ownerEmail = ownerEmailInput;
      }

      if (dog != null) {
        int? hiveKey;
        for (final entry in _dogsBox.toMap().entries) {
          if (entry.value.id == dog.id) {
            hiveKey = entry.key;
            break;
          }
        }

        final updated = dog.copyWith(
          name: name,
          nickname: nickname,
          birthDate: _selectedBirthDate,
          regNrDisplay: regNrDisplay,
          regNr: regNr,
          breed: breed?.isEmpty ?? true ? null : breed,
          pedigreeUrl: pedigreeUrl.isEmpty ? null : pedigreeUrl,
          sex: _selectedSex,
          updatedAt: DateTime.now(),
          deceasedAt: deathDate,
          memorialNote: memorialNote,
          profileHeroTextAnchor: _heroTextAnchor.name,
          profileHeroTextScale: _heroTextScale,
        );

        if (hiveKey != null) {
          if (kDebugMode) {
            debugPrint('Saving dog sex (update): ${_selectedSex.name}');
          }
          await _dogsBox.put(hiveKey, updated);
        } else {
          if (kDebugMode) {
            debugPrint('Saving dog sex (new entry): ${_selectedSex.name}');
          }
          await _dogsBox.add(updated);
        }
      } else {
        final ownerUserId =
            _selectedRole == Role.owner ? currentUserId : null;
        final created = Dog(
          name: name,
          dogKey: const Uuid().v4(),
          regNrDisplay: regNrDisplay,
          regNr: regNr,
          birthDate: _selectedBirthDate,
          breed: breed?.isEmpty ?? true ? null : breed,
          pedigreeUrl: pedigreeUrl.isEmpty ? null : pedigreeUrl,
          sex: _selectedSex,
          deceasedAt: deathDate,
          memorialNote: memorialNote,
          profileHeroTextAnchor: _heroTextAnchor.name,
          profileHeroTextScale: _heroTextScale,
          nickname: nickname,
          ownerUserId: ownerUserId,
          ownerEmail: ownerEmail,
        );

        if (kDebugMode) {
          debugPrint('Saving dog sex (create): ${_selectedSex.name}');
        }
        await _dogsBox.add(created);
        await _storeMembershipForUser(created.dogKey, currentUserId);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteDog() async {
    if (!_isEditing || _isDeletingDog) return;

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

    if (confirmed != true) return;
    await _deleteDogCascade();
  }

  Future<void> _deleteDogCascade() async {
    final dog = widget.initialDog;
    if (dog == null) return;

    setState(() => _isDeletingDog = true);
    try {
      final sessionEntries = _sessionsBox
          .toMap()
          .entries
          .where((entry) => entry.value.dogId == dog.id)
          .toList(growable: false);
      for (final entry in sessionEntries) {
        await _sessionsBox.delete(entry.key);
      }

      final draftEntries = _draftBox
          .toMap()
          .entries
          .where((entry) => entry.value.dogId == dog.id)
          .toList(growable: false);
      for (final entry in draftEntries) {
        await _draftBox.delete(entry.key);
      }

      final trackEntries = _gpsTracksBox
          .toMap()
          .entries
          .where((entry) => entry.value.dogId == dog.id)
          .toList(growable: false);
      for (final entry in trackEntries) {
        await _gpsTracksBox.delete(entry.key);
      }

      final membershipEntries = _membershipBox
          .toMap()
          .entries
          .where((entry) => entry.value.dogKey == dog.dogKey)
          .toList(growable: false);
      for (final entry in membershipEntries) {
        await _membershipBox.delete(entry.key);
      }

      final shareEntries = _shareBox
          .toMap()
          .entries
          .where((entry) => entry.value.dogKey == dog.dogKey)
          .toList(growable: false);
      for (final entry in shareEntries) {
        await _shareBox.delete(entry.key);
      }

      await _milestoneStateRepository.delete(dog.id);
      await DogPhotoStorage.deleteIfExists(dog.imagePath);

      int? dogHiveKey;
      for (final entry in _dogsBox.toMap().entries) {
        if (entry.value.id == dog.id) {
          dogHiveKey = entry.key;
          break;
        }
      }
      if (dogHiveKey != null) {
        await _dogsBox.delete(dogHiveKey);
      }

      if (!mounted) return;
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
      firstDate: DateTime(1990),
      lastDate: DateTime(today.year + 1),
    );
    if (picked == null) return;
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
    if (picked == null) return;
    setState(() => _selectedDeathDate = picked);
  }

  void _toggleRegisteredDead(bool value) {
    setState(() {
      _registeredDead = value;
      if (!value) {
        _selectedDeathDate = null;
      }
    });
  }

  String _deathDateButtonLabel(BuildContext context) {
    final date = _selectedDeathDate;
    if (date == null) {
      return AppLocalizations.of(context)!.dog_editor_death_date_picker_hint;
    }
    return DateFormat('dd.MM.yyyy').format(date);
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
        DropdownButtonFormField<ProfileHeroTextAnchor>(
          value: _heroTextAnchor,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
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
            if (value == null) return;
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

  Widget _buildHeroScaleChip(_HeroScaleOption option, AppLocalizations l10n) {
    return ChoiceChip(
      label: Text(_heroScaleLabel(l10n, option.labelKey)),
      selected: _heroTextScale == option.scale,
      onSelected: (selected) {
        if (!selected) return;
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
          if (trimmed.isEmpty) continue;
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
    if (breed == null || breed.trim().isEmpty) return;
    final exists = _breedOptions.any(
      (option) => option.toLowerCase() == breed.toLowerCase(),
    );
    if (exists) return;
    final updated = [..._breedOptions, breed];
    updated.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _breedCatalogBox.put('breeds', updated);
    _breedOptions = updated;
  }

  Future<void> _ensureBreedStored(String breed) async {
    final trimmed = breed.trim();
    if (trimmed.isEmpty) return;
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
    if (trimmed.isEmpty) return;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.dog_editor_section_breed_title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: _selectedBreed,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: l10n.dog_editor_select_breed_label,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.dog_editor_select_breed_placeholder),
            ),
            ..._breedOptions.map(
              (breed) => DropdownMenuItem<String?>(
                value: breed,
                child: Text(breed),
              ),
            ),
          ],
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
            if (value == null) return;
            setState(() => _selectedRole = value);
          },
        ),
        RadioListTile<Role>(
          value: Role.admin,
          groupValue: _selectedRole,
          title: Text(l10n.dog_editor_role_admin),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedRole = value);
          },
        ),
        RadioListTile<Role>(
          value: Role.viewer,
          groupValue: _selectedRole,
          title: Text(l10n.dog_editor_role_user),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            if (value == null) return;
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

  Future<void> _storeMembershipForUser(String dogKey, String userId) async {
    final membership = DogMembership(
      dogKey: dogKey,
      userId: userId,
      role: _selectedRole,
      status: Status.active,
      addedAt: DateTime.now(),
      addedByUserId: userId,
    );
    await _membershipBox.put(_membershipKey(dogKey, userId), membership);
  }

  String _membershipKey(String dogKey, String userId) => '$dogKey::$userId';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _isEditing
        ? l10n.dog_editor_title_edit_dog
        : l10n.dog_editor_title_add_dog;
    final birthDateText = _selectedBirthDate == null
        ? l10n.dog_editor_birthdate_not_set
        : DateFormat('dd.MM.yyyy').format(_selectedBirthDate!);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.dog_editor_name_label),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: l10n.dog_editor_nickname_label,
                hintText: l10n.dog_editor_nickname_hint,
              ),
              textInputAction: TextInputAction.next,
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
                    if (value == null) return;
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
              onPressed: _isSaving ? null : _handleSave,
              child: Text(_isSaving ? l10n.dog_editor_saving : l10n.dog_editor_save),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed:
                    (_isDeletingDog || _isSaving) ? null : _confirmDeleteDog,
                icon: const Icon(Icons.delete_outline),
                label: Text(_isDeletingDog
                    ? l10n.dog_editor_deleting
                    : l10n.dog_editor_delete_dog),
                style: FilledButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
