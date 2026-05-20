// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:jakthund_app/data/local/local_hunt_session_repository.dart';
import 'package:jakthund_app/data/local/sync_outbox_service.dart';
import 'package:jakthund_app/data/repositories/local_active_session_draft_repository.dart';
import 'package:jakthund_app/domain/milestones/milestone_evaluator.dart';
import 'package:jakthund_app/domain/milestones/milestone_service.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';
import 'package:jakthund_app/domain/sessions/session_visibility.dart';
import 'package:jakthund_app/domain/services/active_session_autosave_service.dart';
import 'package:jakthund_app/features/session/active_session_controller.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/gps_track.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/hunt_session_page.dart';
import 'package:jakthund_app/pages/session_map_page.dart';
import 'package:jakthund_app/repositories/session_repository.dart';
import 'package:jakthund_app/repositories/track_repository.dart';
import 'package:jakthund_app/services/gpx_file_loader.dart';
import 'package:jakthund_app/services/gpx_importer.dart';
import 'package:jakthund_app/pages/session_media_image_helper.dart';
import 'package:jakthund_app/pages/session_media_video_helper.dart';
import 'package:jakthund_app/services/media_storage.dart';
import 'package:jakthund_app/services/cloud/firestore_session_sync_service.dart';
import 'package:jakthund_app/services/cloud/sync_status_service.dart';
import 'package:jakthund_app/ui/components/sync_indicator.dart';
import 'package:jakthund_app/ui/components/meta_chip.dart';
import 'package:jakthund_app/ui/milestones/milestone_celebration_presenter.dart';
import 'package:jakthund_app/ui/text/text_helpers.dart';
import 'package:jakthund_app/utils/dog_label_resolver.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/services/dog_photo_storage.dart';
import 'package:jakthund_app/utils/gpx_exporter.dart';

const bool _gpsAdvancedEnabled = false;

/// Midlertidig rute-widget for å åpne "detaljvisning" uten å være avhengig av
/// en egen SessionDetailPage-klasse (som kan være flyttet/rename'et).

class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({
    super.key,
    this.showNewSessionSection = true,
    this.showSessionList = true,
    this.homeCompact = false,
    this.autoStartNow = false,
    this.editSessionKey,
    this.pageTitle,
    this.initialDraft,
    this.detailMode = false,
  });

  final bool showNewSessionSection;
  final bool showSessionList;
  final bool homeCompact;
  final bool autoStartNow;
  final int? editSessionKey;
  final String? pageTitle;
  final ActiveSessionDraft? initialDraft;
  final bool detailMode;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage>
    with WidgetsBindingObserver {
  final TrackRepository _trackRepository = TrackRepository();
  final SessionRepository _sessionRepository = SessionRepository();
  final SyncOutboxService _syncOutboxService = SyncOutboxService();
  final SyncStatusService _syncStatusService = SyncStatusService();
  late final LocalHuntSessionRepository _huntSessionRepository;
  late final DogMilestoneStateRepository _dogMilestoneStateRepository;
  late final MilestoneService _milestoneService;
  final Uuid _uuid = const Uuid();
  final DateFormat _trackTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  late final ActiveSessionAutosaveService _autosaveService;
  late final LocalActiveSessionDraftRepository _draftRepository;
  late final ActiveSessionController _activeSessionController;
  bool _isApplyingControllerState = false;
  late final MilestoneCelebrationPresenter _milestoneCelebrationPresenter;

  // Controllers
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _birdsController = TextEditingController();
  final _pointsController = TextEditingController();
  final _secondaryPointsController = TextEditingController();
  final _tomstandController = TextEditingController();
  final _flushesController = TextEditingController();
  final _notesController = TextEditingController();

  // Hive
  late final Box<HuntSession> _sessionsBox;
  late final Box<Dog> _dogsBox;
  late final Box<DogMembership> _membershipBox;
  late final Box<GpsTrack> _tracksBox;
  late final Box<Track> _tracksStore;
  late final Box<String> _birdSpeciesBox;

  // Selection
  String? _selectedDogId;
  DateTime? _selectedDateTime;
  final List<String> _selectedBirdSpecies = [];
  final List<String> _mediaPaths = [];
  HuntSession? _editingSession;
  int? _editingSessionKey;
  bool get _detailMode => widget.detailMode;
  bool get _isEditMode =>
      !_detailMode && _editingSession != null && _editingSessionKey != null;
  String? _sessionDogFilterId;

  // GPS tracking (skjult bak "Avansert")
  StreamSubscription<Position>? _positionSub;
  final List<GpsPoint> _currentTrack = [];
  bool _isTracking = false;
  List<GpsPoint> _importedTrackPreview = [];
  final Map<String, List<GpsPoint>> _sessionTrackPreview = {};
  String? _importedTrackId;
  int _importedTrackPoints = 0;
  bool _isPickingGpx = false;
  bool _durationFromTrack = false;
  bool _settingDurationProgrammatically = false;
  String? _versionText;

  // --- UI guards / loading states ---
  bool _isSavingSession = false;
  final bool _isStartingGps = false;
  bool _isStoppingGps = false;
  bool _isExportingGpx = false;

  bool get _gpsBusy => _isStartingGps || _isStoppingGps;

  bool get _anyBusy =>
      _isSavingSession || _gpsBusy || _isPickingGpx || _isExportingGpx;

  Future<void> _hapticSuccess() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // ignore
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _membershipBox =
        HiveLifecycleService.getBox<DogMembership>(dogMembershipsBoxName);
    _tracksBox = HiveLifecycleService.getBox<GpsTrack>(gpsTracksBoxName);
    _tracksStore = HiveLifecycleService.getBox<Track>(tracksBoxName);
    _birdSpeciesBox = HiveLifecycleService.getBox<String>(birdSpeciesBoxName);

    _dogMilestoneStateRepository = DogMilestoneStateRepository();
    _huntSessionRepository = LocalHuntSessionRepository(box: _sessionsBox);
    _milestoneService = MilestoneService(
      evaluator: evaluateMilestones,
      milestoneStateRepository: _dogMilestoneStateRepository,
      huntSessionRepository: _huntSessionRepository,
    );
    _milestoneCelebrationPresenter = MilestoneCelebrationPresenter();

    _draftRepository = LocalActiveSessionDraftRepository();
    _autosaveService = ActiveSessionAutosaveService(_draftRepository);

    _loadVersion();

    if (widget.editSessionKey != null) {
      final session = _sessionsBox.get(widget.editSessionKey);
      if (session != null) {
        _editingSession = session;
        _editingSessionKey = widget.editSessionKey;

        _selectedDateTime = session.dateTime;
        _locationController.text = session.location;
        _durationController.text = session.durationMinutes.toString();
        _birdsController.text = session.birdsSeen.toString();
        _pointsController.text = session.points.toString();
        _secondaryPointsController.text = session.secondaryPoints.toString();
        _tomstandController.text = session.tomstandCount.toString();
        _flushesController.text = session.flushes.toString();
        _notesController.text = session.notes;

        _selectedBirdSpecies
          ..clear()
          ..addAll(session.birdSpecies);

        _mediaPaths
          ..clear()
          ..addAll(session.mediaPaths);

        String? matchedDogId;
        for (final d in _activeDogs()) {
          if (d.id == session.dogId || d.name == session.dogId) {
            matchedDogId = d.id;
            break;
          }
        }
        _selectedDogId = matchedDogId ?? _selectedDogId;

        if (session.trackId != null) {
          _loadDurationFromTrack(session.trackId!);
        }
        if (kDebugMode) {
          final sessionIdLog = session.key?.toString() ?? session.dogId;
          debugPrint(
            '[MEDIA] screen sessionKey=${widget.editSessionKey} sessionId=$sessionIdLog',
          );
        }
      }
    }

    final activeDogs = _activeDogs();
    if (_selectedDogId == null && activeDogs.isNotEmpty) {
      _selectedDogId = activeDogs.first.id;
    }

    if (!_isEditMode && widget.initialDraft == null && widget.autoStartNow) {
      _selectedDateTime = DateTime.now();
    }

    _activeSessionController = ActiveSessionController(
      autosaveService: _autosaveService,
      draftRepository: _draftRepository,
      finalizeSession: _saveSession,
      draftEnabled: _isDraftEnabled,
      initialState: _stateFromUi(),
    );

    if (!_isEditMode && widget.initialDraft != null) {
      _restoreDraft(widget.initialDraft!);
    }

    if (_isDraftEnabled) {
      _attachDraftListeners();
    }
  }

  bool get _isDraftEnabled => widget.autoStartNow && !_isEditMode;

  void _attachDraftListeners() {
    _locationController.addListener(_onLocationChanged);
    _durationController.addListener(_onDurationChanged);
    _birdsController.addListener(_onBirdsChanged);
    _pointsController.addListener(_onPointsChanged);
    _secondaryPointsController.addListener(_onSecondaryPointsChanged);
    _tomstandController.addListener(_onTomstandChanged);
    _flushesController.addListener(_onFlushesChanged);
    _notesController.addListener(_onNotesChanged);
  }

  ActiveSessionState _stateFromUi() {
    return ActiveSessionState(
      dogId: _selectedDogId,
      startedAt: _selectedDateTime,
      activeMinutes: _parseNonNegative(_durationController.text),
      birdCount: _parseNonNegative(_birdsController.text),
      standCount: _parseNonNegative(_pointsController.text),
      tomstandCount: _parseNonNegative(_tomstandController.text),
      flushCount: _parseNonNegative(_flushesController.text),
      notes: _notesController.text,
      locationName: _locationController.text,
      trackId: _importedTrackId,
    );
  }

  void _restoreDraft(ActiveSessionDraft draft) {
    final dog = _dogById(draft.dogId);
    if (dog == null) return;

    _activeSessionController.restoreFromDraft(draft);
    _applyControllerState();

    if (draft.trackId != null) {
      _restoreTrackPreviewFromDraft(draft.trackId!);
    }
  }

  void _applyControllerState() {
    final state = _activeSessionController.state;
    _isApplyingControllerState = true;

    _selectedDogId = state.dogId;
    _selectedDateTime = state.startedAt;
    _locationController.text = state.locationName ?? '';
    _durationController.text = state.activeMinutes.toString();
    _birdsController.text = state.birdCount.toString();
    _pointsController.text = state.standCount.toString();
    _tomstandController.text = state.tomstandCount.toString();
    _flushesController.text = state.flushCount.toString();
    _notesController.text = state.notes ?? '';
    _importedTrackId = state.trackId;

    _isApplyingControllerState = false;
  }

  void _onLocationChanged() {
    if (_isApplyingControllerState) return;
    _activeSessionController.setLocationName(_locationController.text);
  }

  void _onDurationChanged() {
    if (_isApplyingControllerState) return;
    _activeSessionController.setActiveMinutes(
      _parseNonNegative(_durationController.text),
    );
  }

  void _onBirdsChanged() {
    if (_isApplyingControllerState) return;
    _activeSessionController.setBirdCount(
      _parseNonNegative(_birdsController.text),
    );
  }

  void _onPointsChanged() {
    if (_isApplyingControllerState) return;
    _activeSessionController.setStandCount(
      _parseNonNegative(_pointsController.text),
    );
  }

  void _onSecondaryPointsChanged() {
    if (_isApplyingControllerState) return;
    _activeSessionController.scheduleAutosave();
  }

  void _onTomstandChanged() {
    if (_isApplyingControllerState) return;
    _activeSessionController.setTomstandCount(
      _parseNonNegative(_tomstandController.text),
    );
  }

  void _onFlushesChanged() {
    if (_isApplyingControllerState) return;
    _activeSessionController.setFlushCount(
      _parseNonNegative(_flushesController.text),
    );
  }

  void _onNotesChanged() {
    if (_isApplyingControllerState) return;
    _activeSessionController.setNotes(_notesController.text);
  }

  Future<void> _restoreTrackPreviewFromDraft(String trackId) async {
    final track = await _trackRepository.getTrack(trackId);
    if (track == null || track.points.isEmpty) return;
    if (!mounted) return;

    setState(() {
      _importedTrackPreview = track.points
          .map((p) => GpsPoint(lat: p.lat, lon: p.lon, time: p.time))
          .toList();
      _importedTrackPoints = track.points.length;
    });
  }

  void _showSnackL10n(String Function(AppLocalizations) text) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text(l10n))),
    );
  }

  Future<void> _showDogPickerSheet() async {
    if (_anyBusy) return;

    final dogs = _activeDogs();
    final dogLabelResolver = DogLabelResolver(dogs);

    if (dogs.isEmpty) {
      _showSnackL10n((l10n) => l10n.session_error_no_dogs_registered);
      return;
    }

    final selected = await showModalBottomSheet<Dog>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            itemCount: dogs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dog = dogs[index];
              return ListTile(
                leading: () {
                  final avatarFile =
                      DogPhotoStorage.imageFileFromPath(dog.imagePath);
                  return avatarFile == null
                      ? const CircleAvatar(child: Icon(Icons.pets))
                      : CircleAvatar(
                          backgroundImage: FileImage(avatarFile),
                        );
                }(),
                title: Text.rich(
                  dogLabelResolver.spanForDog(
                    context,
                    dog,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, dog),
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      _setSelectedDogId(selected.id);
    }
  }

  Dog? _dogById(String? dogId) {
    if (dogId == null) return null;
    for (final dog in _activeDogs()) {
      if (dog.id == dogId) return dog;
    }
    return null;
  }

  String? _currentUserIdOrNull() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid.trim();
      return uid == null || uid.isEmpty ? null : uid;
    } catch (_) {
      return null;
    }
  }

  List<Dog> _activeDogs() => visibleSessionDogsForUser(
        dogs: _dogsBox.values,
        memberships: _membershipBox.values,
        currentUserId: _currentUserIdOrNull(),
      );

  List<HuntSession> _visibleSessions() => filterVisibleSessions(
        sessions: _sessionsBox.values,
        dogs: _activeDogs(),
      );

  Dog? get _selectedDog => _dogById(_selectedDogId);

  void _setSelectedDogId(String? dogId, {bool notify = true}) {
    _selectedDogId = dogId;
    _activeSessionController.setDogId(dogId);
    if (notify && mounted) setState(() {});
  }

  void _setSelectedDateTime(DateTime? dateTime, {bool notify = true}) {
    _selectedDateTime = dateTime;
    _activeSessionController.setStartedAt(dateTime);
    if (notify && mounted) setState(() {});
  }

  void _setImportedTrackId(String? trackId, {bool notify = true}) {
    _importedTrackId = trackId;
    _activeSessionController.setTrackId(trackId);
    if (notify && mounted) setState(() {});
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final base = 'v${info.version}';
      final l10n = AppLocalizations.of(context)!;
      final build =
          kDebugMode ? l10n.session_detail_version_build(info.buildNumber) : '';
      if (!mounted) return;
      setState(() => _versionText = '$base$build');
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionText = null);
    }
  }

  Future<void> _loadDurationFromTrack(String trackId) async {
    final track = await _trackRepository.getTrack(trackId);
    if (track == null || track.points.isEmpty) return;
    _setDurationFromPoints(track.points);
  }

  // ---------- Date/time pickers ----------
  Future<void> _pickDate() async {
    if (_anyBusy) return;

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (_selectedDateTime != null) {
      final t = TimeOfDay.fromDateTime(_selectedDateTime!);
      _setSelectedDateTime(
        DateTime(date.year, date.month, date.day, t.hour, t.minute),
      );
    } else {
      _setSelectedDateTime(DateTime(date.year, date.month, date.day));
    }
  }

  Future<void> _pickTime() async {
    if (_anyBusy) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    if (_selectedDateTime != null) {
      _setSelectedDateTime(
        DateTime(
          _selectedDateTime!.year,
          _selectedDateTime!.month,
          _selectedDateTime!.day,
          time.hour,
          time.minute,
        ),
      );
    } else {
      final now = DateTime.now();
      _setSelectedDateTime(
        DateTime(now.year, now.month, now.day, time.hour, time.minute),
      );
    }
  }

  // ---------- Bird species ----------
  Future<void> _showBirdSpeciesPicker() async {
    if (_anyBusy) return;

    final existing = _birdSpeciesBox.values.toList()..sort();
    final selected = Set<String>.from(_selectedBirdSpecies);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.session_detail_bird_species_picker_title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: existing.isEmpty
                          ? Center(
                              child: Text(
                                l10n.session_detail_bird_species_empty_saved,
                              ),
                            )
                          : ListView.separated(
                              itemCount: existing.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final species = existing[index];
                                final isSelected = selected.contains(species);
                                return ListTile(
                                  title: Text(
                                    species,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : const Icon(Icons.circle_outlined),
                                  onTap: () {
                                    setSheetState(() {
                                      if (isSelected) {
                                        selected.remove(species);
                                      } else {
                                        selected.add(species);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final created =
                                    await _promptNewBirdSpecies(ctx);
                                if (created == null) return;
                                if (!existing.contains(created)) {
                                  existing.add(created);
                                  existing.sort();
                                }
                                setSheetState(() => selected.add(created));
                              },
                              icon: const Icon(Icons.add),
                              label: Text(l10n.session_detail_bird_species_new),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(
                                ctx,
                                selected.toList()..sort(),
                              ),
                              child: Text(l10n.session_detail_action_done),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedBirdSpecies
        ..clear()
        ..addAll(result);
    });
    _activeSessionController.scheduleAutosave();
  }

  Future<String?> _promptNewBirdSpecies(BuildContext ctx) async {
    if (_anyBusy) return null;

    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: ctx,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.session_detail_bird_species_dialog_title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.session_detail_bird_species_dialog_name_label,
            ),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.session_action_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(l10n.session_action_save),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return null;

    final exists = _birdSpeciesBox.values.any(
      (entry) => entry.trim().toLowerCase() == result.toLowerCase(),
    );
    if (!exists) {
      await _birdSpeciesBox.add(result);
    }
    return result;
  }

  int _parseNonNegative(String input) {
    final value = int.tryParse(input) ?? 0;
    return value < 0 ? 0 : value;
  }

  int? _durationMinutesFromPoints(List<GpsPoint> points) {
    if (points.isEmpty) return null;
    final sorted = List<GpsPoint>.from(points)
      ..sort((a, b) => a.time.compareTo(b.time));
    final start = sorted.first.time;
    final end = sorted.last.time;
    if (end.isBefore(start)) return null;
    return end.difference(start).inMinutes;
  }

  void _setDurationFromPoints(List<GpsPoint> points) {
    final minutes = _durationMinutesFromPoints(points);
    if (minutes == null) return;

    _settingDurationProgrammatically = true;
    _durationController.text = minutes.toString();
    _settingDurationProgrammatically = false;

    setState(() => _durationFromTrack = true);
  }

  Widget _buildDogFilterChips(List<Dog> dogs, DogLabelResolver labelResolver) {
    if (dogs.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.session_detail_filter_all_dogs),
            selected: _sessionDogFilterId == null,
            onSelected: (_) => setState(() => _sessionDogFilterId = null),
          ),
          const SizedBox(width: 8),
          for (final dog in dogs) ...[
            ChoiceChip(
              label: labelResolver.chipLabelForDog(context, dog),
              selected: _sessionDogFilterId == dog.id,
              onSelected: (_) => setState(() => _sessionDogFilterId = dog.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Future<void> _importGpxForNewSession() async {
    if (_isPickingGpx) return;

    final l10n = AppLocalizations.of(context)!;
    final hadExistingTrack = _importedTrackId != null;

    if (hadExistingTrack) {
      final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx)!;
              return AlertDialog(
                title: Text(l10n.session_detail_gpx_replace_title),
                content: Text(l10n.session_detail_gpx_replace_body),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.session_action_cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.session_detail_gpx_replace_confirm),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!confirm) return;
    }

    if (mounted) setState(() => _isPickingGpx = true);

    GpxFilePayload? gpxFile;
    try {
      gpxFile = await GpxFileLoader.pickAndLoadGpx();
    } catch (e, stackTrace) {
      _logGpxImportError('new-session-pick', null, e, stackTrace);
      gpxFile = null;
    } finally {
      if (mounted) setState(() => _isPickingGpx = false);
    }
    if (gpxFile == null) return;

    int? parsedPoints;
    try {
      final points = GpxImporter.parse(gpxFile.xml);
      parsedPoints = points.length;
      _logGpxImportInfo('new-session-parse', gpxFile, points.length);

      if (points.length < 2) {
        throw FormatException(
          l10n.session_detail_error_gpx_too_few_points,
        );
      }

      if (_importedTrackId != null) {
        await _trackRepository.deleteTrack(_importedTrackId!);
      }

      final track = Track(
        id: _uuid.v4(),
        createdAt: DateTime.now().toUtc(),
        source: 'gpx_import',
        points: points,
      );

      await _trackRepository.upsertTrack(track);

      if (!mounted) return;

      setState(() {
        _importedTrackId = track.id;
        _importedTrackPoints = points.length;
        _importedTrackPreview = points
            .map((p) => GpsPoint(lat: p.lat, lon: p.lon, time: p.time))
            .toList();
        _selectedDateTime ??= points.first.time;
      });

      _activeSessionController.setTrackId(_importedTrackId);
      _activeSessionController.setStartedAt(_selectedDateTime);
      _setDurationFromPoints(points);

      await _hapticSuccess();

      final message = hadExistingTrack
          ? l10n.session_detail_gpx_replaced_snackbar(points.length)
          : l10n.session_detail_gpx_imported_snackbar(points.length);

      _showSnackL10n((l10n) => l10n.session_snackbar_message(message));

      if (kDebugMode) {
        final stored = await _trackRepository.getTrack(track.id);
        if (stored == null) {
          debugPrint(
            'New session import ERROR: trackId=${track.id} not stored',
          );
        } else {
          debugPrint(
            'Imported GPX points: ${points.length}, trackId: ${track.id}, points=${stored.points.length}',
          );
        }
      }
    } on FormatException catch (e, stackTrace) {
      _logGpxImportError(
        'new-session-parse',
        gpxFile,
        e,
        stackTrace,
        parsedPoints,
      );
      _showSnackL10n((l10n) => l10n.gpx_import_failed_see_log);
    } catch (e, stackTrace) {
      _logGpxImportError(
        'new-session-parse',
        gpxFile,
        e,
        stackTrace,
        parsedPoints,
      );
      _showSnackL10n((l10n) => l10n.gpx_import_failed_see_log);
    }
  }

  Future<void> _importGpxForExistingSession(
    int sessionKey,
    HuntSession session,
  ) async {
    if (_isPickingGpx) return;

    final l10n = AppLocalizations.of(context)!;
    final hadExistingTrack = session.trackId != null;

    if (hadExistingTrack) {
      final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx)!;
              return AlertDialog(
                title: Text(l10n.session_detail_gpx_replace_title),
                content: Text(l10n.session_detail_gpx_replace_body),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.session_action_cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.session_detail_gpx_replace_confirm),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!confirm) return;
    }

    if (mounted) setState(() => _isPickingGpx = true);

    GpxFilePayload? gpxFile;
    try {
      gpxFile = await GpxFileLoader.pickAndLoadGpx();
    } catch (e, stackTrace) {
      _logGpxImportError('existing-session-pick', null, e, stackTrace);
      gpxFile = null;
    } finally {
      if (mounted) setState(() => _isPickingGpx = false);
    }
    if (gpxFile == null) return;

    int? parsedPoints;
    try {
      final points = GpxImporter.parse(gpxFile.xml);
      parsedPoints = points.length;
      _logGpxImportInfo('existing-session-parse', gpxFile, points.length);

      if (points.length < 2) {
        throw FormatException(
          l10n.session_detail_error_gpx_too_few_points,
        );
      }

      final sessionId = sessionKey.toString();

      await _sessionRepository.replaceTrackForSession(
        sessionId,
        points,
        source: 'gpx_import',
      );

      final updatedSession = _sessionsBox.get(sessionKey);
      if (updatedSession != null) {
        final minutes = _durationMinutesFromPoints(points);
        await _sessionsBox.put(
          sessionKey,
          updatedSession.copyWith(
            durationMinutes: minutes ?? updatedSession.durationMinutes,
          ),
        );
      }

      final trackId = updatedSession?.trackId;
      final track =
          trackId != null ? await _trackRepository.getTrack(trackId) : null;

      final clonedPoints = track?.points
          .map((p) => GpsPoint(lat: p.lat, lon: p.lon, time: p.time))
          .toList();

      if (!mounted) return;

      setState(() {
        if (clonedPoints != null) {
          _sessionTrackPreview[sessionId] = clonedPoints;
        }
      });

      await _hapticSuccess();

      if (kDebugMode) {
        if (trackId == null || track == null) {
          debugPrint(
            'Existing session import ERROR: sessionId=$sessionId, trackId=${updatedSession?.trackId}, trackStored=false',
          );
        } else {
          debugPrint(
            'Existing session import: sessionId=$sessionId, trackId=$trackId, '
            'trackStored=true, points=${track.points.length}',
          );
        }
      }

      final message = hadExistingTrack
          ? 'Spor erstattet: ${points.length} punkter'
          : 'GPX importert: ${points.length} punkter';

      _showSnackL10n((l10n) => l10n.session_snackbar_message(message));
    } on FormatException catch (e, stackTrace) {
      _logGpxImportError(
        'existing-session-parse',
        gpxFile,
        e,
        stackTrace,
        parsedPoints,
      );
      _showSnackL10n((l10n) => l10n.gpx_import_failed_see_log);
    } catch (e, stackTrace) {
      _logGpxImportError(
        'existing-session-parse',
        gpxFile,
        e,
        stackTrace,
        parsedPoints,
      );
      _showSnackL10n((l10n) => l10n.gpx_import_failed_see_log);
    }
  }

  void _logGpxImportInfo(String contextLabel, GpxFilePayload file, int points) {
    final preview = _safePreview(file.xml);
    debugPrint(
      'GPX import [$contextLabel] file="${file.fileName}" '
      'size=${file.fileSizeBytes}B points=$points preview="$preview"',
    );
  }

  void _logGpxImportError(
    String contextLabel,
    GpxFilePayload? file,
    Object error,
    StackTrace stackTrace, [
    int? points,
  ]) {
    final fileName = file?.fileName ?? 'unknown';
    final size = file?.fileSizeBytes;
    final preview = file == null ? 'n/a' : _safePreview(file.xml);

    debugPrint(
      'GPX import [$contextLabel] ERROR file="$fileName" '
      'size=${size ?? 'n/a'} points=${points ?? 'n/a'} preview="$preview"',
    );
    debugPrint('GPX import [$contextLabel] error: $error');
    debugPrint(stackTrace.toString());
  }

  String _safePreview(String input) {
    final normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 200) return normalized;
    return normalized.substring(0, 200);
  }

  // ---------- GPS tracking ----------
  Future<void> _stopTracking() async {
    if (!_isTracking || _gpsBusy) return;

    setState(() => _isStoppingGps = true);

    try {
      await _positionSub?.cancel();
      _positionSub = null;
      _isTracking = false;
      if (mounted) setState(() {});
      await _hapticSuccess();
    } catch (e) {
      debugPrint('GPS stop ERROR: $e');
      _showSnackL10n((l10n) => l10n.gps_stop_failed);
    } finally {
      if (mounted) {
        setState(() => _isStoppingGps = false);
      } else {
        _isStoppingGps = false;
      }
    }
  }

  // ---------- Save session ----------
  Future<void> _saveSession() async {
    if (_isSavingSession) return;

    setState(() => _isSavingSession = true);

    try {
      final l10n = AppLocalizations.of(context)!;

      if (_selectedDog == null) {
        _showSnackL10n((l10n) => l10n.session_select_dog_first);
        return;
      }

      if (_isTracking) {
        await _stopTracking();
      }

      if (_isEditMode) {
        final updated = _editingSession!.copyWith(
          dogId: _selectedDog!.id,
          dateTime: _selectedDateTime ?? _editingSession!.dateTime,
          location: _locationController.text,
          durationMinutes: _parseNonNegative(_durationController.text),
          birdsSeen: _parseNonNegative(_birdsController.text),
          points: _parseNonNegative(_pointsController.text),
          secondaryPoints: _parseNonNegative(_secondaryPointsController.text),
          tomstandCount: _parseNonNegative(_tomstandController.text),
          flushes: _parseNonNegative(_flushesController.text),
          notes: _notesController.text,
          birdSpecies: List<String>.from(_selectedBirdSpecies),
          mediaPaths: List<String>.from(_mediaPaths),
        );

        await _sessionsBox.put(_editingSessionKey, updated);
        await _hapticSuccess();

        if (mounted) {
          final newMilestoneIds = await _handleMilestones(
            updated.dogId,
            updated.dateTime,
          );
          await _presentMilestoneFeedback(
            dogId: updated.dogId,
            milestoneIds: newMilestoneIds,
            achievedAt: updated.dateTime,
            fallbackMessage: l10n.session_detail_snackbar_changes_saved,
          );
          Navigator.of(context).pop(updated);
        }
        return;
      }

      int? trackKey;
      if (_currentTrack.isNotEmpty) {
        final track = GpsTrack(
          dogId: _selectedDog!.id,
          startTime: _currentTrack.first.time,
          endTime: _currentTrack.last.time,
          points: List<GpsPoint>.from(_currentTrack),
        );
        trackKey = await _tracksBox.add(track);
      }

      final trackId = _importedTrackId;

      final session = HuntSession(
        dogId: _selectedDog!.id,
        dateTime: _selectedDateTime ?? DateTime.now(),
        location: _locationController.text,
        durationMinutes: _parseNonNegative(_durationController.text),
        birdsSeen: _parseNonNegative(_birdsController.text),
        points: _parseNonNegative(_pointsController.text),
        secondaryPoints: _parseNonNegative(_secondaryPointsController.text),
        tomstandCount: _parseNonNegative(_tomstandController.text),
        flushes: _parseNonNegative(_flushesController.text),
        notes: _notesController.text,
        trackKey: trackKey,
        trackId: trackId,
        birdSpecies: List<String>.from(_selectedBirdSpecies),
        mediaPaths: List<String>.from(_mediaPaths),
      );

      final sessionKey = await _sessionsBox.add(session);
      final sessionId = sessionKey.toString();
      final newMilestoneIds = await _handleMilestones(
        session.dogId,
        session.dateTime,
      );

      final savedMessage = trackId != null
          ? l10n.session_detail_snackbar_saved_with_imported_gpx(
              _importedTrackPoints)
          : trackKey == null
              ? l10n.session_detail_snackbar_session_saved
              : l10n.session_detail_snackbar_saved_with_gps_track(
                  _currentTrack.length);

      if (kDebugMode) {
        final storedTrack = session.trackId != null
            ? await _trackRepository.getTrack(session.trackId!)
            : null;

        if (session.trackId == null || storedTrack == null) {
          debugPrint(
            'Saved sessionId: $sessionKey, trackId missing or track not found',
          );
        } else {
          debugPrint(
            'Saved sessionId: $sessionKey, trackId: ${session.trackId}, points=${storedTrack.points.length}',
          );
          final cloned = storedTrack.points
              .map((p) => GpsPoint(lat: p.lat, lon: p.lon, time: p.time))
              .toList();
          setState(() => _sessionTrackPreview[sessionId] = cloned);
        }
      }

      await _hapticSuccess();

      if (mounted) {
        await _presentMilestoneFeedback(
          dogId: session.dogId,
          milestoneIds: newMilestoneIds,
          achievedAt: session.dateTime,
          fallbackMessage: savedMessage,
        );
      }

      _locationController.clear();
      _durationController.clear();
      _birdsController.clear();
      _pointsController.clear();
      _secondaryPointsController.clear();
      _tomstandController.clear();
      _flushesController.clear();
      _notesController.clear();
      _selectedBirdSpecies.clear();
      _mediaPaths.clear();
      _setSelectedDateTime(null, notify: false);
      _currentTrack.clear();
      _setImportedTrackId(null, notify: false);
      _importedTrackPoints = 0;
      _importedTrackPreview = [];
      if (mounted) setState(() {});
    } finally {
      if (mounted) {
        setState(() => _isSavingSession = false);
      } else {
        _isSavingSession = false;
      }
    }
  }

  Future<List<String>> _handleMilestones(
    String dogId,
    DateTime sessionDateTime,
  ) async {
    try {
      return await _milestoneService.evaluateForDog(
        dogId,
        sessionDateTime: sessionDateTime,
      );
    } catch (error, stack) {
      debugPrint('Failed to evaluate milestones: $error');
      debugPrint('$stack');
      return const [];
    }
  }

  Future<bool> _presentMilestoneFeedback({
    required String dogId,
    required List<String> milestoneIds,
    required DateTime achievedAt,
    required String fallbackMessage,
  }) async {
    if (!mounted) return false;

    if (kDebugMode && milestoneIds.isNotEmpty) {
      debugPrint('New milestones for $dogId: $milestoneIds');
    }

    if (milestoneIds.isNotEmpty) {
      final dog = _dogById(dogId);
      if (dog != null) {
        final shown = await _milestoneCelebrationPresenter.show(
          context,
          dog: dog,
          newIds: milestoneIds,
          achievedAt: achievedAt,
        );
        if (shown) {
          return true;
        }
      }
    }

    _showSnackL10n((l10n) => l10n.session_snackbar_message(fallbackMessage));
    return false;
  }

  void _openMapForNewSession() {
    if (_importedTrackPreview.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final labelResolver = DogLabelResolver(_dogsBox.values.toList());
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    final titleSpan = _selectedDog == null
        ? null
        : TextSpan(
            children: [
              TextSpan(text: l10n.session_detail_map_prefix, style: titleStyle),
              labelResolver.spanForDog(context, _selectedDog!,
                  style: titleStyle),
            ],
          );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionMapPage(
          trackId: _importedTrackId,
          previewPoints: _importedTrackPreview,
          title: l10n.session_detail_map_title,
          titleSpan: titleSpan,
        ),
      ),
    );
  }

  String _dogLabelForId(String dogId) {
    return DogLabelResolver(_dogsBox.values.toList()).labelForId(dogId);
  }

  static const Set<String> _videoExtensions = {
    '.mp4',
    '.mov',
    '.m4v',
    '.avi',
    '.mkv',
    '.webm',
    '.flv',
    '.3gp',
  };

  bool _isVideoPath(String path) {
    final extension = p.extension(path).toLowerCase();
    return _videoExtensions.contains(extension);
  }

  Widget _buildSessionMediaPreview(List<String> mediaPaths) {
    if (mediaPaths.isEmpty) return const SizedBox.shrink();

    final visible = mediaPaths.length > 3 ? 3 : mediaPaths.length;
    final remaining = mediaPaths.length - visible;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: List.generate(visible, (index) {
          final path = mediaPaths[index];
          final validation = MediaStorage.resolveAndValidateMedia(path);
          final resolvedPath = validation?.resolvedPath;
          final exists = validation?.exists ?? false;
          final isVideo = _isVideoPath(path);

          return Padding(
            padding: EdgeInsets.only(right: index == visible - 1 ? 0 : 6),
            child: Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: exists && !isVideo && resolvedPath != null
                      ? Image.file(
                          File(resolvedPath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        )
                      : Center(
                          child: Icon(
                            isVideo ? Icons.videocam : Icons.image,
                            size: 24,
                          ),
                        ),
                ),
                if (isVideo)
                  const Positioned.fill(
                    child: Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white),
                    ),
                  ),
                if (index == visible - 1 && remaining > 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Text(
                        '+$remaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _openMapForSession(int sessionKey, HuntSession session) {
    if (session.trackId == null) return;

    final l10n = AppLocalizations.of(context)!;
    final sessionId = sessionKey.toString();
    final preview = _sessionTrackPreview[sessionId];
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    final titleSpan = TextSpan(
      children: [
        TextSpan(text: l10n.session_detail_map_prefix, style: titleStyle),
        DogLabelResolver(_dogsBox.values.toList()).spanForId(
          context,
          session.dogId,
          style: titleStyle,
        ),
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionMapPage(
          sessionId: sessionId,
          trackId: session.trackId,
          previewPoints: preview,
          title: l10n.session_detail_map_title,
          titleSpan: titleSpan,
        ),
      ),
    );
  }

  Future<void> _exportGpxForSession(HuntSession session) async {
    if (_isExportingGpx) return;
    setState(() => _isExportingGpx = true);

    try {
      final key = session.trackKey;
      if (key == null) {
        _showSnackL10n((l10n) => l10n.session_export_no_track);
        return;
      }

      final track = _tracksBox.get(key);
      if (track == null || track.points.isEmpty) {
        _showSnackL10n((l10n) => l10n.session_track_missing_or_empty);
        return;
      }

      final dogLabel = _dogLabelForId(session.dogId);
      final gpx = GPXExporter.exportToGpx(
        trackName: '${dogLabel}_${session.dateTime.toIso8601String()}',
        points: track.points,
      );

      final home = Platform.environment['HOME'] ?? '';
      final desktop = Directory('$home/Desktop');
      if (!desktop.existsSync()) desktop.createSync(recursive: true);

      final safeDog = dogLabel.replaceAll(' ', '_');

      // ✅ Prefix: fuglehund
      final filename =
          'fuglehund_${safeDog}_${session.dateTime.millisecondsSinceEpoch}.gpx';
      final file = File('${desktop.path}/$filename');

      await file.writeAsString(gpx, encoding: utf8);

      await _hapticSuccess();

      _showSnackL10n((l10n) => l10n.gpx_exported_to_desktop(filename));
    } finally {
      if (mounted) setState(() => _isExportingGpx = false);
    }
  }

  // ---------- Bottom sheet menu ----------
  void _showSessionMenu(int sessionKey, HuntSession session) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.map),
                title: Text(_isExportingGpx
                    ? l10n.session_detail_session_menu_exporting
                    : l10n.session_detail_session_menu_export),
                onTap: _isExportingGpx
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _exportGpxForSession(session);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.session_detail_session_menu_edit),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToEditSession(sessionKey);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(l10n.session_detail_session_menu_delete),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) {
                      final dl10n = AppLocalizations.of(dialogCtx)!;
                      return AlertDialog(
                        title:
                            Text(dl10n.session_detail_confirm_delete_title),
                        content:
                            Text(dl10n.session_detail_confirm_delete_body),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogCtx, false),
                            child: Text(dl10n.common_cancel),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogCtx, true),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(dialogCtx).colorScheme.error,
                            ),
                            child: Text(dl10n.dog_editor_button_delete),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm != true) return;
                  await _deleteSessionWithSync(sessionKey, session);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSessionWithSync(
    int sessionKey,
    HuntSession session,
  ) async {
    final deletedAt = DateTime.now().toUtc();
    final tombstone = session.copyWith(
      updatedAt: deletedAt,
      deletedAt: deletedAt,
    );

    await _syncOutboxService.enqueueDeleteSession(
      sessionKey.toString(),
      tombstone,
      deletedAt: deletedAt,
    );
    await FirestoreSessionSyncService.instance.tombstoneSessionBestEffort(
      sessionId: sessionKey.toString(),
      session: tombstone,
    );

    final key = session.trackKey;
    if (key != null) {
      await _tracksBox.delete(key);
    }
    await _sessionsBox.delete(sessionKey);
  }

  Widget _buildSessionSyncIndicator(
    String sessionId, {
    double size = 18,
  }) {
    return StreamBuilder<SyncStatus>(
      stream: _syncStatusService.watchSessionStatus(sessionId),
      initialData: _syncStatusService.statusForSession(sessionId),
      builder: (context, snapshot) {
        return SyncIndicator(
          status: snapshot.data ?? SyncStatus.synced,
          size: size,
        );
      },
    );
  }

  List<Widget> _buildAppBarSyncActions(int? sessionKey) {
    if (sessionKey == null) {
      return const [];
    }
    final sessionId = sessionKey.toString();
    return [
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 16),
        child: Center(
          child: _buildSessionSyncIndicator(
            sessionId,
            size: 20,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDetailView(
    HuntSession session,
    int sessionKey,
    AppLocalizations l10n,
  ) {
    return [
      Text(
        l10n.session_detail_media_section_title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      _buildMediaGrid(l10n, session.mediaPaths),
      const SizedBox(height: 20),
      Text(
        l10n.session_detail_section_notes,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          session.notes.isNotEmpty
              ? session.notes
              : l10n.session_detail_empty_notes,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      const SizedBox(height: 16),
      _buildDetailsExpansion(session, sessionKey, l10n),
    ];
  }

  Widget _buildMediaGrid(AppLocalizations l10n, List<String> mediaPaths) {
    if (mediaPaths.isEmpty) {
      return Text(
        l10n.session_detail_empty_media,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).hintColor),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: mediaPaths
          .map((path) => _buildMediaThumbnail(path))
          .toList(growable: false),
    );
  }

  Widget _buildMediaThumbnail(String path) {
    final l10n = AppLocalizations.of(context)!;
    final validation = MediaStorage.resolveAndValidateMedia(path);
    final resolvedPath = validation?.resolvedPath;
    final exists = validation?.exists ?? false;
    final isVideo = _isVideoPath(path);
    final placeholder = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        l10n.session_detail_media_empty_placeholder,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
    final child = !exists || resolvedPath == null
        ? placeholder
        : isVideo
            ? const Icon(Icons.videocam, size: 36)
            : Image.file(
                File(resolvedPath),
                fit: BoxFit.cover,
              );
    return InkWell(
      onTap:
          exists && resolvedPath != null ? () => _handleMediaTap(path) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 108,
          height: 108,
          color: Colors.black12,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildSelectedMediaRow(int index) {
    final l10n = AppLocalizations.of(context)!;
    final path = _mediaPaths[index];
    final validation = MediaStorage.resolveAndValidateMedia(path);
    final resolvedPath = validation?.resolvedPath;
    final exists = validation?.exists ?? false;
    final isVideo = _isVideoPath(path);
    final placeholder = Text(
      l10n.session_detail_media_empty_placeholder,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
    final preview = !exists || resolvedPath == null
        ? placeholder
        : isVideo
            ? const Icon(Icons.videocam, size: 32)
            : Image.file(
                File(resolvedPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 32,
                ),
              );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            color: Colors.black12,
            alignment: Alignment.center,
            child: preview,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path.split('/').last,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: _anyBusy ? null : () => _confirmDeleteSessionMedia(index),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSessionMedia(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final dl10n = AppLocalizations.of(dialogCtx)!;
        return AlertDialog(
          title: Text(dl10n.session_detail_media_delete_title),
          content: Text(dl10n.session_detail_media_delete_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(dl10n.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogCtx).colorScheme.error,
              ),
              child: Text(dl10n.dog_editor_button_delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _deleteSessionMediaAt(index);
  }

  Future<void> _deleteSessionMediaAt(int index) async {
    if (index < 0 || index >= _mediaPaths.length) return;
    final path = _mediaPaths[index];
    setState(() {
      _mediaPaths.removeAt(index);
    });
    if (kDebugMode) {
      debugPrint('[MEDIA] removed from session: $path');
    }
    final sessionKey = _editingSessionKey;
    if (sessionKey != null) {
      final source = _editingSession ?? _sessionsBox.get(sessionKey);
      if (source != null) {
        final updated =
            source.copyWith(mediaPaths: List<String>.from(_mediaPaths));
        await _sessionsBox.put(sessionKey, updated);
        _editingSession = updated;
      }
    }
    await MediaStorage.deletePersistedMedia(path);
  }

  Future<void> _handleMediaTap(String path) async {
    if (!mounted) return;
    if (_isVideoPath(path)) {
      if (kDebugMode) {
        debugPrint('[VIDEO] tapped path=$path');
      }
      await openSessionVideo(
        context: context,
        storedPath: path,
        displayName: p.basename(path),
      );
      return;
    }
    final currentDog = _selectedDog;
    await openSessionImage(
      context: context,
      storedPath: path,
      displayName: p.basename(path),
      watermarkDogTitle: currentDog?.title,
      watermarkDogOfficialName: currentDog?.name,
      watermarkDogNickname: currentDog?.nickname,
      watermarkShowTitle: currentDog?.watermarkShowTitle,
      watermarkShowOfficialName: currentDog?.watermarkShowOfficialName,
      watermarkShowNickname: currentDog?.watermarkShowNickname,
      watermarkUseDarkText: currentDog?.watermarkUseDarkText,
      dogId: currentDog?.id,
    );
  }

  Widget _buildDetailsExpansion(
    HuntSession session,
    int sessionKey,
    AppLocalizations l10n,
  ) {
    final dateText = DateFormat('dd.MM.yyyy HH:mm').format(session.dateTime);
    final durationText = _formatDuration(
      Duration(minutes: session.durationMinutes),
      l10n,
    );
    final birdsText = birdText(session.birdsSeen, l10n: l10n);
    final standTextValue = standText(session.points);
    final secondaryText = session.secondaryPoints.toString();
    final tomstandText = session.tomstandCount.toString();
    final flushTextValue = flushText(session.flushes);
    final speciesText = session.birdSpecies.isEmpty
        ? l10n.session_detail_empty_bird_species
        : session.birdSpecies.join(', ');

    return ExpansionTile(
      title: Text(l10n.session_detail_detail_title),
      initiallyExpanded: false,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildDetailRow(
          l10n.session_detail_detail_label_date,
          dateText,
        ),
        _buildDetailRow(
          l10n.session_detail_detail_label_location,
          session.location.isEmpty
              ? l10n.session_detail_empty_location
              : session.location,
        ),
        _buildDetailRow(
          l10n.session_detail_detail_label_active_time,
          durationText,
        ),
        _buildDetailRow(
          l10n.session_detail_field_bird_contacts_label,
          birdsText,
        ),
        _buildDetailRow(
          l10n.session_detail_label_points,
          standTextValue,
        ),
        _buildDetailRow(
          l10n.session_detail_field_secondary_points_label,
          secondaryText,
        ),
        _buildDetailRow(
          l10n.session_detail_field_tomstand_label,
          tomstandText,
        ),
        _buildDetailRow(
          l10n.session_detail_label_flushes,
          flushTextValue,
        ),
        _buildDetailRow(
          l10n.session_detail_label_bird_species,
          speciesText,
        ),
        _buildDetailRow(
          l10n.session_detail_label_gps_track,
          session.trackId != null
              ? l10n.session_detail_label_yes
              : l10n.session_detail_label_no,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed:
                  _anyBusy ? null : () => _navigateToEditSession(sessionKey),
              child: Text(l10n.session_detail_edit_title),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: style?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditSession(int sessionKey) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HuntSessionPage(
          showNewSessionSection: false,
          showSessionList: false,
          editSessionKey: sessionKey,
          pageTitle: l10n.session_detail_edit_title,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    _autosaveService.dispose();
    _activeSessionController.dispose();

    _locationController.dispose();
    _durationController.dispose();
    _birdsController.dispose();
    _pointsController.dispose();
    _secondaryPointsController.dispose();
    _tomstandController.dispose();
    _flushesController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isDraftEnabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _activeSessionController.flushAutosave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showForm =
        (widget.showNewSessionSection || _isEditMode) && !_detailMode;
    final showTracking = showForm && !_isEditMode;
    final detailSessionKey = _detailMode ? widget.editSessionKey : null;
    final dogs = _activeDogs();
    final sessions = _visibleSessions();
    final activeDogIds = dogs.map((dog) => dog.id).toSet();
    if (detailSessionKey != null) {
      final detailSession = _sessionsBox.get(detailSessionKey);
      final detailDog =
          detailSession == null ? null : _dogById(detailSession.dogId);
      final detailSessionDogId = detailSession?.dogId;
      if (!isSessionVisibleInUi(session: detailSession, dog: detailDog) ||
          detailSessionDogId == null ||
          !activeDogIds.contains(detailSessionDogId)) {
        if (kDebugMode) {
          debugPrint(
            '[UI][DETAIL] deleted entity fallback: session $detailSessionKey',
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.pageTitle ?? l10n.session_detail_title_main),
          ),
          body: const Center(
            child: Text('Fant ikke økt'),
          ),
        );
      }
    }
    final sessionEntries = _sessionsBox
        .toMap()
        .entries
        .where((entry) =>
            !entry.value.isDeleted && activeDogIds.contains(entry.value.dogId))
        .map(
          (entry) => MapEntry(
            entry.key as int,
            entry.value,
          ),
        )
        .toList(growable: false);
    final latestSessionEntry = sessionEntries.isEmpty
        ? null
        : (List<MapEntry<int, HuntSession>>.from(sessionEntries)
              ..sort((a, b) => b.value.dateTime.compareTo(a.value.dateTime)))
            .first;
    final latestSession = latestSessionEntry?.value;
    final dogLabelResolver = DogLabelResolver(dogs);

    final filteredEntries = _sessionDogFilterId == null
        ? sessionEntries
        : sessionEntries
            .where((entry) => entry.value.dogId == _sessionDogFilterId)
            .toList();

    final dogSessions = _selectedDog == null
        ? <HuntSession>[]
        : sessions.where((s) => s.dogId == _selectedDog!.id).toList();

    final totalDuration =
        dogSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalBirds = dogSessions.fold<int>(0, (sum, s) => sum + s.birdsSeen);
    final totalPoints = dogSessions.fold<int>(0, (sum, s) => sum + s.points);
    final totalSecondaryPoints =
        dogSessions.fold<int>(0, (sum, s) => sum + s.secondaryPoints);
    final totalTomstand =
      dogSessions.fold<int>(0, (sum, s) => sum + s.tomstandCount);
    final totalFlushes = dogSessions.fold<int>(0, (sum, s) => sum + s.flushes);

    if (widget.homeCompact &&
        widget.showNewSessionSection &&
        !widget.showSessionList &&
        !_isEditMode) {
      const dogLabelStyle =
          TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
      const lastInfoStyle = TextStyle(fontSize: 14);

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.pageTitle ?? l10n.session_detail_title_home),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _anyBusy ? null : _showDogPickerSheet,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _selectedDog == null
                                ? Text(l10n.session_detail_label_choose_dog,
                                    style: dogLabelStyle)
                                : Text.rich(
                                    dogLabelResolver.spanForDog(
                                      context,
                                      _selectedDog!,
                                      style: dogLabelStyle,
                                    ),
                                  ),
                          ),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: latestSession == null
                              ? Text(l10n.session_detail_empty_sessions_yet,
                                  style: lastInfoStyle)
                              : Text.rich(
                                  TextSpan(
                                    children: [
                                      dogLabelResolver.spanForId(
                                        context,
                                        latestSession.dogId,
                                        style: lastInfoStyle,
                                      ),
                                      TextSpan(
                                        text:
                                            ' · ${DateFormat('dd.MM.yyyy').format(latestSession.dateTime)}',
                                        style: lastInfoStyle,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        if (latestSession != null)
                          OutlinedButton(
                            onPressed: _anyBusy
                                ? null
                                : () {
                                    final key = latestSessionEntry?.key;
                                    if (key == null) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SessionDetailPage(
                                          editSessionKey: key,
                                          detailMode: true,
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(
                                l10n.session_detail_button_open_latest_session),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _anyBusy
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HuntSessionPage(
                                showNewSessionSection: true,
                                showSessionList: false,
                                homeCompact: false,
                                autoStartNow: true,
                                pageTitle:
                                    l10n.session_detail_title_active_session,
                              ),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.session_detail_button_start_new_session,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.session_detail_help_notes_first,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isPickingGpx ? null : _importGpxForNewSession,
                        child: Text(_isPickingGpx
                            ? l10n.session_detail_button_importing
                            : l10n.session_detail_button_import_gpx),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _anyBusy ? null : () {},
                        child: Text(l10n.session_detail_button_settings),
                      ),
                    ),
                  ],
                ),
                if (_versionText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text(
                        _versionText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle ?? l10n.session_detail_title_main),
        actions: _buildAppBarSyncActions(detailSessionKey),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        children: [
          if (detailSessionKey != null)
            ValueListenableBuilder<Box<HuntSession>>(
              valueListenable:
                  _sessionsBox.listenable(keys: [detailSessionKey]),
              builder: (context, box, _) {
                final session = box.get(detailSessionKey);
                final detailSession = session;
                if (!isSessionVisibleInUi(
                  session: detailSession,
                  dog: detailSession == null
                      ? null
                      : _dogById(detailSession.dogId),
                )) {
                  if (kDebugMode) {
                    debugPrint(
                      '[UI][DETAIL] deleted entity fallback: session $detailSessionKey',
                    );
                  }
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Fant ikke økt'),
                    ),
                  );
                }
                final visibleSession = detailSession!;
                if (kDebugMode) {
                  debugPrint(
                    '[MEDIA] render session id=$detailSessionKey mediaCount=${visibleSession.mediaPaths.length}',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children:
                      _buildDetailView(visibleSession, detailSessionKey, l10n),
                );
              },
            ),
          if (showForm) ...[
            Text(
              l10n.session_detail_section_dog,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (dogs.isEmpty)
              Text(l10n.session_detail_empty_dogs_registered)
            else
              Builder(
                builder: (context) {
                  final dogIds = dogs.map((d) => d.id).toSet();
                  String? selectedDogId = _selectedDogId;

                  if (selectedDogId != null &&
                      !dogIds.contains(selectedDogId)) {
                    selectedDogId = dogs.isNotEmpty ? dogs.first.id : null;
                    if (selectedDogId != _selectedDogId) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _setSelectedDogId(selectedDogId);
                      });
                    }
                  }

                  final selectedStyle = Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 16) ??
                      const TextStyle(fontSize: 16);

                  final itemStyle = Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                              fontSize: 16, fontWeight: FontWeight.w600) ??
                      const TextStyle(fontSize: 16);

                  return DropdownButton<String>(
                    isExpanded: true,
                    value: selectedDogId,
                    style: selectedStyle,
                    selectedItemBuilder: (context) {
                      return dogs
                          .map(
                            (d) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                dogLabelResolver.labelForDog(d),
                                style: selectedStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList();
                    },
                    items: dogs
                        .map(
                          (d) => DropdownMenuItem<String>(
                            value: d.id,
                            child: Text(
                              dogLabelResolver.labelForDog(d),
                              style: itemStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _anyBusy ? null : (id) => _setSelectedDogId(id),
                  );
                },
              ),
            const SizedBox(height: 16),
            if (_selectedDog != null) ...[
              Builder(
                builder: (context) {
                  final nameStyle = Theme.of(context).textTheme.titleMedium;
                  final nameColor = nameStyle?.color;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: l10n.session_detail_label_dog_prefix,
                          children: [
                            dogLabelResolver.spanForDog(
                              context,
                              _selectedDog!,
                              style:
                                  (nameStyle ?? const TextStyle(fontSize: 16))
                                      .copyWith(color: nameColor),
                            ),
                          ],
                        ),
                        style: (nameStyle ?? const TextStyle(fontSize: 16))
                            .copyWith(color: nameColor),
                      ),
                      if (widget.autoStartNow)
                        MetaChip(
                          label: l10n.session_detail_title_active_session,
                          icon: Icons.timelapse,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.session_detail_stats_sessions_count(dogSessions.length),
              ),
              Text(
                l10n.session_detail_stats_total_active_time(totalDuration),
              ),
              Text(
                l10n.session_detail_stats_total_birds(totalBirds),
              ),
              Text(
                l10n.session_detail_stats_total_points(totalPoints),
              ),
              Text(
                l10n.session_detail_stats_total_secondary_points(
                    totalSecondaryPoints),
              ),
              Text(
                l10n.session_detail_stats_total_tomstand(totalTomstand),
              ),
              Text(
                l10n.session_detail_stats_total_flushes(totalFlushes),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              _isEditMode
                  ? l10n.session_detail_title_edit_session
                  : l10n.session_detail_title_new_session,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          if (showForm && !widget.autoStartNow) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _anyBusy ? null : _pickDate,
                    child: Text(
                      _selectedDateTime == null
                          ? l10n.session_detail_button_select_date
                          : '${_selectedDateTime!.day.toString().padLeft(2, '0')}.'
                              '${_selectedDateTime!.month.toString().padLeft(2, '0')}.'
                              '${_selectedDateTime!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _anyBusy ? null : _pickTime,
                    child: Text(
                      _selectedDateTime == null
                          ? l10n.session_detail_button_select_time
                          : '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:'
                              '${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_gpsAdvancedEnabled && showTracking) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isPickingGpx ? null : _importGpxForNewSession,
                icon: const Icon(Icons.file_upload),
                label: Text(_isPickingGpx
                    ? l10n.session_detail_button_importing
                    : l10n.session_detail_button_import_gpx),
              ),
            ),
            if (_importedTrackPreview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _TrackSummaryWidget(
                  summary: _summaryFromPoints(_importedTrackPreview)!,
                  timeFormat: _trackTimeFormat,
                ),
              ),
            if (_importedTrackPreview.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _anyBusy ? null : _openMapForNewSession,
                icon: const Icon(Icons.map),
                label: Text(l10n.session_detail_map_title),
              ),
            ],
            const SizedBox(height: 12),
          ],
          if (showTracking) ...[
            const SizedBox(height: 16),
          ],
          if (showForm) ...[
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: l10n.session_detail_field_location_label,
              ),
              enabled: !_anyBusy,
            ),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: l10n.session_detail_field_active_time_minutes_label,
              ),
              keyboardType: TextInputType.number,
              enabled: !_anyBusy,
              onChanged: (_) {
                if (_settingDurationProgrammatically) return;
                if (_durationFromTrack) {
                  setState(() => _durationFromTrack = false);
                }
              },
            ),
            if (_durationFromTrack)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.session_detail_label_duration_from_track,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            TextField(
              controller: _birdsController,
              decoration: InputDecoration(
                labelText: l10n.session_detail_field_bird_contacts_label,
              ),
              keyboardType: TextInputType.number,
              enabled: !_anyBusy,
            ),
            TextField(
              controller: _pointsController,
              decoration: InputDecoration(
                labelText: l10n.session_detail_field_points_label,
              ),
              keyboardType: TextInputType.number,
              enabled: !_anyBusy,
            ),
            TextField(
              controller: _secondaryPointsController,
              decoration: InputDecoration(
                labelText: l10n.session_detail_field_secondary_points_label,
              ),
              keyboardType: TextInputType.number,
              enabled: !_anyBusy,
            ),
            TextField(
              controller: _tomstandController,
              decoration: InputDecoration(
                labelText: l10n.session_detail_field_tomstand_label,
              ),
              keyboardType: TextInputType.number,
              enabled: !_anyBusy,
            ),
            TextField(
              controller: _flushesController,
              decoration: InputDecoration(
                labelText: l10n.session_detail_field_flushes_label,
              ),
              keyboardType: TextInputType.number,
              enabled: !_anyBusy,
            ),
          ],
          if (showForm) ...[
            const SizedBox(height: 16),
            Text(
              l10n.session_detail_bird_section_title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _anyBusy ? null : _showBirdSpeciesPicker,
              icon: const Icon(Icons.list),
              label: Text(l10n.session_detail_bird_species_button_label),
            ),
            const SizedBox(height: 8),
            if (_selectedBirdSpecies.isEmpty)
              Text(l10n.session_detail_bird_species_empty_selection),
            if (_selectedBirdSpecies.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedBirdSpecies
                    .map(
                      (species) => Chip(
                        label: Text(species),
                        onDeleted: _anyBusy
                            ? null
                            : () {
                                setState(() {
                                  _selectedBirdSpecies.remove(species);
                                });
                              },
                      ),
                    )
                    .toList(),
              ),
          ],
          if (showForm) ...[
            const SizedBox(height: 16),
            Text(
              l10n.session_detail_section_media,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_mediaPaths.isNotEmpty)
              Column(
                children: [
                  for (var i = 0; i < _mediaPaths.length; i++)
                    _buildSelectedMediaRow(i),
                ],
              ),
          ],
          if (showForm) ...[
            const SizedBox(height: 16),
            Text(
              l10n.session_detail_section_notes,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              minLines: 8,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 16),
              enabled: !_anyBusy,
              decoration: InputDecoration(
                labelText: l10n.session_detail_field_notes_label,
                alignLabelWithHint: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          if (showForm) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSavingSession
                  ? null
                  : _activeSessionController.finalizeSession,
              child: Text(
                _isSavingSession
                    ? l10n.session_detail_action_saving
                    : (_isEditMode
                        ? l10n.session_detail_action_save_changes
                        : l10n.session_detail_action_save_session),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (widget.showSessionList) ...[
            Text(
              l10n.session_detail_saved_sessions_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDogFilterChips(dogs, dogLabelResolver),
            const SizedBox(height: 12),
          ],
          if (widget.showSessionList)
            if (filteredEntries.isEmpty)
              Text(l10n.session_detail_empty_sessions_for_selected_dog)
            else
              for (var i = 0; i < filteredEntries.length; i++)
                Card(
                  child: InkWell(
                    onTap: _anyBusy
                        ? null
                        : () {
                            final sessionKey = filteredEntries[i].key;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SessionDetailPage(
                                  editSessionKey: sessionKey,
                                  detailMode: true,
                                ),
                              ),
                            );
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (_) {
                              final sessionKey = filteredEntries[i].key;
                              final sessionId = sessionKey.toString();
                              final summary = _getSummaryForSession(
                                sessionId,
                                filteredEntries[i].value,
                                _tracksStore,
                                _sessionTrackPreview,
                              );
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              dogLabelResolver.spanForId(
                                                context,
                                                filteredEntries[i].value.dogId,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              TextSpan(
                                                text:
                                                    ' – ${filteredEntries[i].value.location}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (summary != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: _TrackSummaryWidget(
                                              summary: summary,
                                              timeFormat: _trackTimeFormat,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 8,
                                    ),
                                    child:
                                        _buildSessionSyncIndicator(sessionId),
                                  ),
                                  IconButton(
                                    onPressed: _anyBusy
                                        ? null
                                        : () => _showSessionMenu(
                                              filteredEntries[i].key,
                                              filteredEntries[i].value,
                                            ),
                                    icon: const Icon(Icons.more_vert),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '📅 ${DateFormat('dd.MM.yyyy').format(filteredEntries[i].value.dateTime)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.session_detail_saved_session_summary(
                              filteredEntries[i].value.durationMinutes,
                              filteredEntries[i].value.birdsSeen,
                              filteredEntries[i].value.points,
                              filteredEntries[i].value.secondaryPoints,
                              filteredEntries[i].value.tomstandCount,
                              filteredEntries[i].value.flushes,
                            ),
                          ),
                          _buildSessionMediaPreview(
                            filteredEntries[i].value.mediaPaths,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.file_upload),
                              label: Text(
                                _isPickingGpx
                                    ? l10n.gpx_importing_ellipsis
                                    : l10n.session_gpx_import_label,
                              ),
                              onPressed: _isPickingGpx
                                  ? null
                                  : () => _importGpxForExistingSession(
                                        filteredEntries[i].key,
                                        filteredEntries[i].value,
                                      ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.map),
                              label: Text(l10n.session_map_label),
                              onPressed: _anyBusy
                                  ? null
                                  : (filteredEntries[i].value.trackId == null
                                      ? null
                                      : () => _openMapForSession(
                                            filteredEntries[i].key,
                                            filteredEntries[i].value,
                                          )),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.file_download),
                              label: Text(
                                _isExportingGpx
                                    ? l10n.session_detail_button_exporting
                                    : l10n.session_detail_button_export_gpx,
                              ),
                              onPressed: (_anyBusy || _isExportingGpx)
                                  ? null
                                  : () => _exportGpxForSession(
                                        filteredEntries[i].value,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

_TrackSummary? _summaryFromPoints(List<GpsPoint> points) {
  if (points.isEmpty) return null;

  final sorted = List<GpsPoint>.from(points)
    ..sort((a, b) => a.time.compareTo(b.time));

  final distance = _computeDistance(sorted);

  return _TrackSummary(
    count: sorted.length,
    start: sorted.first.time,
    end: sorted.last.time,
    distanceMeters: distance,
  );
}

_TrackSummary? _getSummaryForSession(
  String sessionId,
  HuntSession session,
  Box<Track> tracksStore,
  Map<String, List<GpsPoint>> previewMap,
) {
  final preview = previewMap[sessionId];
  if (preview != null && preview.isNotEmpty) {
    return _summaryFromPoints(preview);
  }

  final trackId = session.trackId;
  if (trackId == null) return null;

  final stored = tracksStore.get(trackId);
  if (stored == null || stored.points.isEmpty) return null;

  return _summaryFromPoints(stored.points);
}

String _formatDuration(
  Duration duration,
  AppLocalizations l10n,
) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return l10n.session_detail_helper_duration_hours_minutes(
      hours,
      minutes,
    );
  }
  if (minutes > 0) {
    return l10n.session_detail_helper_duration_minutes_seconds(
      minutes,
      seconds,
    );
  }
  return l10n.session_detail_helper_duration_seconds(seconds);
}

class _TrackSummaryWidget extends StatelessWidget {
  const _TrackSummaryWidget({
    required this.summary,
    required this.timeFormat,
  });

  final _TrackSummary summary;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final duration = summary.duration;
    final color = Theme.of(context).colorScheme.primary;
    final distance = summary.distanceMeters;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.session_detail_track_summary_points(summary.count),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        if (summary.start != null)
          Text(
            l10n.session_detail_track_summary_start(
              timeFormat.format(summary.start!),
            ),
          ),
        if (summary.end != null)
          Text(
            l10n.session_detail_track_summary_end(
              timeFormat.format(summary.end!),
            ),
          ),
        if (distance != null)
          Text(
            distance >= 1000
                ? l10n.session_detail_track_summary_distance_km(
                    (distance / 1000).toStringAsFixed(2),
                  )
                : l10n.session_detail_track_summary_distance_meters(
                    distance.toStringAsFixed(0),
                  ),
          ),
        if (duration != null)
          Text(
            l10n.session_detail_track_summary_duration(
              _formatDuration(duration, l10n),
            ),
          ),
      ],
    );
  }
}

class _TrackSummary {
  _TrackSummary({
    required this.count,
    this.start,
    this.end,
    this.distanceMeters,
  });

  final int count;
  final DateTime? start;
  final DateTime? end;
  final double? distanceMeters;

  Duration? get duration =>
      (start != null && end != null) ? end!.difference(start!) : null;
}

double _computeDistance(List<GpsPoint> points) {
  double total = 0;
  for (var i = 1; i < points.length; i++) {
    total += _haversine(points[i - 1], points[i]);
  }
  return total;
}

double _haversine(GpsPoint a, GpsPoint b) {
  const earthRadius = 6371000.0;
  final dLat = _toRadians(b.lat - a.lat);
  final dLon = _toRadians(b.lon - a.lon);
  final lat1 = _toRadians(a.lat);
  final lat2 = _toRadians(b.lat);

  final hav = math.pow(math.sin(dLat / 2), 2) +
      math.pow(math.sin(dLon / 2), 2) * math.cos(lat1) * math.cos(lat2);
  final c = 2 * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
