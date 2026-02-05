// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/data/local/local_hunt_session_repository.dart';
import 'package:jakthund_app/data/repositories/local_active_session_draft_repository.dart';
import 'package:jakthund_app/domain/milestones/milestone_evaluator.dart';
import 'package:jakthund_app/domain/milestones/milestone_service.dart';
import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';
import 'package:jakthund_app/domain/services/active_session_autosave_service.dart';
import 'package:jakthund_app/features/session/active_session_controller.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/gps_point.dart';
import 'package:jakthund_app/models/gps_track.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type.dart';
import 'package:jakthund_app/models/track.dart';
import 'package:jakthund_app/pages/dog_detail_page.dart';
import 'package:jakthund_app/pages/session_map_page.dart';
import 'package:jakthund_app/pages/session_media_image_helper.dart';
import 'package:jakthund_app/pages/session_media_video_helper.dart';
import 'package:jakthund_app/repositories/session_repository.dart';
import 'package:jakthund_app/repositories/track_repository.dart';
import 'package:jakthund_app/services/dog_photo_storage.dart';
import 'package:jakthund_app/services/gpx_file_loader.dart';
import 'package:jakthund_app/services/gpx_importer.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/services/media_permission_service.dart';
import 'package:jakthund_app/services/media_storage.dart';
import 'package:jakthund_app/ui/components/meta_chip.dart';
import 'package:jakthund_app/ui/milestones/milestone_celebration_presenter.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/ui/text/text_helpers.dart';
import 'package:jakthund_app/utils/dog_label_resolver.dart';
import 'package:jakthund_app/utils/gpx_exporter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

// ignore: unused_element
const bool _gpsAdvancedEnabled = false;

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

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '${hours}t ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
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

class _TrackSummaryWidget extends StatelessWidget {
  // ignore: unused_element_parameter
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spor: ${summary.count} punkter',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        if (summary.start != null)
          Text('Start: ${timeFormat.format(summary.start!)}'),
        if (summary.end != null)
          Text('Slutt: ${timeFormat.format(summary.end!)}'),
        if (distance != null)
          Text(
            distance >= 1000
                ? 'Distanse: ${(distance / 1000).toStringAsFixed(2)} km'
                : 'Distanse: ${distance.toStringAsFixed(0)} m',
          ),
        if (duration != null) Text('Varighet: ${_formatDuration(duration)}'),
      ],
    );
  }
}

// ignore: unused_element
const List<String> _birdShotSpeciesOptions = [
  'Rype',
  'Orrfugl',
  'Tiur',
  'Rugde',
  'And',
  'Gås',
  'Annet',
];

class HuntSessionPage extends StatefulWidget {
  const HuntSessionPage({
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
  State<HuntSessionPage> createState() => _HuntSessionPageState();
}

class _HuntSessionPageState extends State<HuntSessionPage>
    with WidgetsBindingObserver {
  final TrackRepository _trackRepository = TrackRepository();
  final SessionRepository _sessionRepository = SessionRepository();
  late final LocalHuntSessionRepository _huntSessionRepository;
  late final DogMilestoneStateRepository _dogMilestoneStateRepository;
  late final MilestoneService _milestoneService;
  final Uuid _uuid = const Uuid();
  final DateFormat _trackTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  late final MilestoneCelebrationPresenter _milestoneCelebrationPresenter;
  late final ActiveSessionAutosaveService _autosaveService;
  late final LocalActiveSessionDraftRepository _draftRepository;
  late final ActiveSessionController _activeSessionController;
  bool _isApplyingControllerState = false;
  bool _showNewSessionForm = false;
  static const int _kMaxGpxPoints = 50000;

  // Controllers
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _birdsController = TextEditingController();
  final _pointsController = TextEditingController();
  final _secondaryPointsController = TextEditingController();
  final _flushesController = TextEditingController();
  final _notesController = TextEditingController();
  SessionType _sessionType = SessionType.training;
  int _birdsShotCount = 0;
  String? _birdsShotSpecies;

  // Hive
  late final Box<HuntSession> _sessionsBox;
  late final Box<Dog> _dogsBox;
  late final Box<GpsTrack> _tracksBox;
  late final Box<Track> _tracksStore;
  late final Box<String> _birdSpeciesBox;
  late final Box<dynamic> _settingsBox;

  // Selection
  String? _selectedDogId;
  DateTime? _selectedDateTime;
  final List<String> _selectedBirdSpecies = [];
  final List<String> _mediaPaths = [];
  String? _pendingMediaSessionId;
  String? _sessionMediaId;
  final ImagePicker _imagePicker = ImagePicker();
  final MediaPermissionService _mediaPermissionService = MediaPermissionService();
  HuntSession? _editingSession;
  int? _editingSessionKey;
  bool get _isEditMode => _editingSession != null && _editingSessionKey != null;
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

  // --- UI guards / loading states (Pakke A) ---
  bool _isSavingSession = false;
  bool _isStartingGps = false;
  bool _isStoppingGps = false;
  bool _isExportingGpx = false;

  bool get _gpsBusy => _isStartingGps || _isStoppingGps;
  bool get _anyBusy =>
      _isSavingSession || _gpsBusy || _isPickingGpx || _isExportingGpx;

  Future<void> _hapticSuccess() async {
    // Only call on actual success.
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
    debugPrint(
      '[Hive][HuntSessionPage] open sessions=${Hive.isBoxOpen("sessionsBox_v2")} '
      'dogs=${Hive.isBoxOpen("dogsBox_v2")} '
      'gpsTracks=${Hive.isBoxOpen("gpsTracksBox_v1")} '
      'tracks=${Hive.isBoxOpen("tracks")} '
      'birdSpecies=${Hive.isBoxOpen("birdSpeciesBox")}',
    );

    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _tracksBox = HiveLifecycleService.getBox<GpsTrack>(gpsTracksBoxName);
    _tracksStore = HiveLifecycleService.getBox<Track>(tracksBoxName);
    _birdSpeciesBox = HiveLifecycleService.getBox<String>(birdSpeciesBoxName);
    _settingsBox = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);

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
        _flushesController.text = session.flushes.toString();
        _notesController.text = session.notes;
        _selectedBirdSpecies
          ..clear()
          ..addAll(session.birdSpecies);
        _mediaPaths
          ..clear()
          ..addAll(session.mediaPaths);
        _sessionMediaId = MediaStorage.sessionIdFromPaths(session.mediaPaths);
        _sessionType = session.sessionType;
        _birdsShotCount = session.birdsShotCount;
        _birdsShotSpecies = session.birdsShotSpecies;

        String? matchedDogId;
        for (final d in _dogsBox.values) {
          if (d.id == session.dogId || d.name == session.dogId) {
            matchedDogId = d.id;
            break;
          }
        }
        _selectedDogId = matchedDogId ?? _selectedDogId;

        if (session.trackId != null) {
          _loadDurationFromTrack(session.trackId!);
        }
      }
    }

    if (_selectedDogId == null && _dogsBox.isNotEmpty) {
      _selectedDogId = _dogsBox.values.first.id;
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

    if (_isEditMode || widget.autoStartNow || widget.initialDraft != null) {
      _showNewSessionForm = true;
    }
  }

  bool get _isDraftEnabled => widget.autoStartNow && !_isEditMode;

  void _attachDraftListeners() {
    _locationController.addListener(_onLocationChanged);
    _durationController.addListener(_onDurationChanged);
    _birdsController.addListener(_onBirdsChanged);
    _pointsController.addListener(_onPointsChanged);
    _secondaryPointsController.addListener(_onSecondaryPointsChanged);
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
      flushCount: _parseNonNegative(_flushesController.text),
      notes: _notesController.text,
      locationName: _locationController.text,
      trackId: _importedTrackId,
    );
  }

  void _restoreDraft(ActiveSessionDraft draft) {
    final dog = _dogById(draft.dogId);
    if (dog == null) {
      return;
    }
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
    _flushesController.text = state.flushCount.toString();
    _notesController.text = state.notes ?? '';
    _importedTrackId = state.trackId;
    _isApplyingControllerState = false;
  }

  void _applySessionType(SessionType type) {
    setState(() {
      _sessionType = type;
      if (type == SessionType.training) {
        _birdsShotCount = 0;
        _birdsShotSpecies = null;
      } else if (_birdsShotCount < 0) {
        _birdsShotCount = 0;
      }
    });
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

  Future<void> _showDogPickerSheet() async {
    final dogs = _dogsBox.values.toList();
    final dogLabelResolver = DogLabelResolver(dogs);
    if (dogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingen hunder registrert')),
      );
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
    for (final dog in _dogsBox.values) {
      if (dog.id == dogId) {
        return dog;
      }
    }
    return null;
  }

  Dog? get _selectedDog => _dogById(_selectedDogId);
  String get _mediaSessionId {
    if (_sessionMediaId != null) return _sessionMediaId!;
    final fromPaths = MediaStorage.sessionIdFromPaths(_mediaPaths);
    if (fromPaths != null) {
      return _sessionMediaId = fromPaths;
    }
    final fromSession = MediaStorage.sessionIdFromPaths(
      _editingSession?.mediaPaths,
    );
    if (fromSession != null) {
      return _sessionMediaId = fromSession;
    }
    final generated = _pendingMediaSessionId ??= _uuid.v4();
    _sessionMediaId = generated;
    return generated;
  }

  void _setSelectedDogId(String? dogId, {bool notify = true}) {
    _selectedDogId = dogId;
    _activeSessionController.setDogId(dogId);
    if (notify && mounted) {
      setState(() {});
    }
  }

  void _setSelectedDateTime(DateTime? dateTime, {bool notify = true}) {
    _selectedDateTime = dateTime;
    _activeSessionController.setStartedAt(dateTime);
    if (notify && mounted) {
      setState(() {});
    }
  }

  // ignore: unused_element
  void _setImportedTrackId(String? trackId, {bool notify = true}) {
    _importedTrackId = trackId;
    _activeSessionController.setTrackId(trackId);
    if (notify && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final base = 'v${info.version}';
      final build = kDebugMode ? ' (build ${info.buildNumber})' : '';
      if (!mounted) return;
      setState(() {
        _versionText = '$base$build';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionText = null;
      });
    }
  }

  Future<void> _loadDurationFromTrack(String trackId) async {
    final track = await _trackRepository.getTrack(trackId);
    if (track == null || track.points.isEmpty) return;
    _setDurationFromPoints(track.points);
  }

  // ---------- Date/time pickers ----------
  // ignore: unused_element
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

  // ignore: unused_element
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
    final l10n = AppLocalizations.of(context)!;

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
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
                        l10n.session_species_picker_title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: existing.isEmpty
                          ? Center(child: Text(l10n.session_species_picker_empty))
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
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green)
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
                                setSheetState(() {
                                  selected.add(created);
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: Text(l10n.session_species_picker_add),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, selected.toList()..sort()),
                              child: Text(l10n.session_species_picker_done),
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
          title: const Text('Ny fugleart'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Navn'),
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
    final exists = _birdSpeciesBox.values
        .any((entry) => entry.trim().toLowerCase() == result.toLowerCase());
    if (!exists) {
      await _birdSpeciesBox.add(result);
    }
    return result;
  }

  // ---------- Media ----------
  Future<void> _showAddMediaSheet({int? sessionKey}) async {
    if (_anyBusy) return;
    final l10n = AppLocalizations.of(context)!;
    final dogKey = _selectedDog?.dogKey;
    final access = await _mediaPermissionService.resolveAccess(dogKey);
    if (kDebugMode) {
      final roleName = access.role?.name ?? 'none';
      debugPrint(
        '[MEDIA] add button tapped canEdit=${access.canEdit} role=$roleName',
      );
    }
    if (!access.canEdit) {
      _showPermissionDeniedSnackBar(l10n);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.session_media_gallery_label),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery, sessionKey: sessionKey);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(l10n.session_media_camera_label),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera, sessionKey: sessionKey);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: Text(l10n.session_media_video_label),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(sessionKey: sessionKey);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPermissionDeniedSnackBar(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.common_no_permission)),
    );
  }

  Future<void> _pickImage(ImageSource source, {int? sessionKey}) async {
    if (_anyBusy) return;
    try {
      final file =
          await _imagePicker.pickImage(source: source, imageQuality: 90);
      if (file == null) return;
      FocusManager.instance.primaryFocus?.unfocus();
      await _storePickedFile(file, sessionKey: sessionKey);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke legge til bilde')),
      );
    }
  }

  Future<void> _pickVideo({int? sessionKey}) async {
    if (_anyBusy) return;
    try {
      final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      FocusManager.instance.primaryFocus?.unfocus();
      await _storePickedFile(file, sessionKey: sessionKey);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke legge til video')),
      );
    }
  }

  Future<void> _storePickedFile(XFile file, {int? sessionKey}) async {
    if (_selectedDog == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Velg en hund først')),
      );
      return;
    }
    try {
      final newPath = await MediaStorage.persistPickedMedia(
        dogId: _selectedDog!.id,
        sessionId: _mediaSessionId,
        sourcePath: file.path,
        hiveKey: sessionKey?.toString(),
      );
      final validation =
          await MediaStorage.validatePersistedMedia(newPath);
      final exists = validation?.exists ?? false;
      final size = validation?.length ?? 0;
      final type = _isVideoPath(newPath) ? 'video' : 'image';
      if (kDebugMode) {
        debugPrint(
          '[MEDIA] add type=$type source=${file.path} target=$newPath exists=$exists size=$size',
        );
      }
      if (!exists || size == 0) {
        throw StateError('Persisted media missing or empty');
      }
      if (!mounted) return;
      final derivedSessionId =
          MediaStorage.extractSessionIdFromPath(newPath);
      setState(() {
        _mediaPaths.add(newPath);
        if (_sessionMediaId == null && derivedSessionId != null) {
          _sessionMediaId = derivedSessionId;
        }
      });
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[MEDIA] failed to store media=${file.path} error=$error stackTrace=$stackTrace',
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke lagre mediafilen')),
      );
    }
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
    setState(() {
      _durationFromTrack = true;
    });
  }

  Widget _buildDogFilterChips(List<Dog> dogs, DogLabelResolver labelResolver) {
    if (dogs.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.session_all_dogs_label),
            selected: _sessionDogFilterId == null,
            onSelected: (_) {
              setState(() {
                _sessionDogFilterId = null;
              });
            },
          ),
          const SizedBox(width: 8),
          for (final dog in dogs) ...[
            ChoiceChip(
              label: labelResolver.chipLabelForDog(context, dog),
              selected: _sessionDogFilterId == dog.id,
              onSelected: (_) {
                setState(() {
                  _sessionDogFilterId = dog.id;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Future<void> _importGpxForNewSession() async {
    if (_isPickingGpx) return;

    if (_importedTrackId != null) {
      final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx)!;
              return AlertDialog(
                title: Text(l10n.session_detail_gpx_replace_title),
                content:
                    Text(l10n.session_detail_gpx_replace_body),
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

    setState(() => _isPickingGpx = true);

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
      final rawPoints = GpxImporter.parse(gpxFile.xml);
      parsedPoints = rawPoints.length;
      _logGpxImportInfo('new-session-parse', gpxFile, rawPoints.length);
      if (rawPoints.length < 2) {
        throw const FormatException('Fant for få GPX-punkter i filen');
      }

      final processedPoints = _limitGpxPoints(rawPoints);
      final wasDownsampled = processedPoints.length != rawPoints.length;
      if (wasDownsampled) {
        debugPrint(
          '[GPX] downsampled new session from ${rawPoints.length} to '
          '${processedPoints.length} points',
        );
      }

      if (_importedTrackId != null) {
        await _trackRepository.deleteTrack(_importedTrackId!);
      }

      final track = Track(
        id: _uuid.v4(),
        createdAt: DateTime.now().toUtc(),
        source: 'gpx_import',
        points: processedPoints,
      );

      await _trackRepository.upsertTrack(track, downsampled: wasDownsampled);

      if (!mounted) return;
      setState(() {
        _importedTrackId = track.id;
        _importedTrackPoints = processedPoints.length;
        _importedTrackPreview = processedPoints
            .map((p) => GpsPoint(lat: p.lat, lon: p.lon, time: p.time))
            .toList();
        _selectedDateTime ??= processedPoints.first.time;
      });

      _activeSessionController.setTrackId(_importedTrackId);
      _activeSessionController.setStartedAt(_selectedDateTime);
      _setDurationFromPoints(processedPoints);

      await _hapticSuccess();

      final message = wasDownsampled
          ? 'GPX importert: ${processedPoints.length} punkter (redusert fra ${rawPoints.length})'
          : 'GPX importert: ${processedPoints.length} punkter';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (kDebugMode) {
        final stored = await _trackRepository.getTrack(track.id);
        if (stored == null) {
          debugPrint(
              'New session import ERROR: trackId=${track.id} not stored');
        } else {
          debugPrint(
            'Imported GPX points: ${processedPoints.length}, trackId: ${track.id}, points=${stored.points.length}',
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
            ),
          );
        }
    } catch (e, stackTrace) {
      _logGpxImportError(
        'new-session-parse',
        gpxFile,
        e,
        stackTrace,
        parsedPoints,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPX-import feilet. Se logg.')),
        );
      }
    }
  }

  Future<void> _importGpxForExistingSession(
      int sessionKey, HuntSession session) async {
    if (_isPickingGpx) return;

    if (session.trackId != null) {
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

    setState(() => _isPickingGpx = true);

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
      final rawPoints = GpxImporter.parse(gpxFile.xml);
      parsedPoints = rawPoints.length;
      _logGpxImportInfo('existing-session-parse', gpxFile, rawPoints.length);
      if (rawPoints.length < 2) {
        throw const FormatException('Fant for få GPX-punkter i filen');
      }

      final processedPoints = _limitGpxPoints(rawPoints);
      final wasDownsampled = processedPoints.length != rawPoints.length;
      if (wasDownsampled) {
        debugPrint(
          '[GPX] downsampled existing session from ${rawPoints.length} to '
          '${processedPoints.length} points',
        );
      }

      final sessionId = sessionKey.toString();

      await _sessionRepository.replaceTrackForSession(
        sessionId,
        processedPoints,
        source: 'gpx_import',
      );

      final updatedSession = _sessionsBox.get(sessionKey);
      if (updatedSession != null) {
        final minutes = _durationMinutesFromPoints(processedPoints);
        await _sessionsBox.put(
          sessionKey,
          updatedSession.copyWith(
            durationMinutes: minutes ?? updatedSession.durationMinutes,
          ),
        );
      }

      final track = updatedSession?.trackId != null
          ? await _trackRepository.getTrack(updatedSession!.trackId!)
          : null;
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
        if (updatedSession?.trackId == null || track == null) {
          debugPrint(
            'Existing session import ERROR: sessionId=$sessionId, trackId=${updatedSession?.trackId}, trackStored=${track != null}',
          );
        } else {
          debugPrint(
            'Existing session import: sessionId=$sessionId, trackId=${updatedSession?.trackId}, '
            'trackStored=true, points=${track.points.length}',
          );
        }
      }
      final message = wasDownsampled
          ? 'Spor erstattet: ${processedPoints.length} punkter (redusert fra ${rawPoints.length})'
          : 'Spor erstattet: ${processedPoints.length} punkter';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on FormatException catch (e, stackTrace) {
      _logGpxImportError(
        'existing-session-parse',
        gpxFile,
        e,
        stackTrace,
        parsedPoints,
      );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
            ),
          );
        }
    } catch (e, stackTrace) {
      _logGpxImportError(
        'existing-session-parse',
        gpxFile,
        e,
        stackTrace,
        parsedPoints,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPX-import feilet. Se logg.')),
        );
      }
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

  List<GpsPoint> _limitGpxPoints(List<GpsPoint> points) {
    if (points.length <= _kMaxGpxPoints) return points;
    final step = points.length / _kMaxGpxPoints;
    final sampled = <GpsPoint>[];
    double index = 0;
    while (sampled.length < _kMaxGpxPoints && index < points.length) {
      sampled.add(points[index.toInt()]);
      index += step;
    }
    if (sampled.length < _kMaxGpxPoints && points.isNotEmpty) {
      sampled.add(points.last);
    }
    return sampled;
  }

  String _safePreview(String input) {
    final normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 200) return normalized;
    return normalized.substring(0, 200);
  }

  // ---------- GPS tracking ----------
  // ignore: unused_element
  Future<void> _startTracking() async {
    if (_isTracking || _gpsBusy) return;

    setState(() {
      _isStartingGps = true;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gps_services_disabled)),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gps_no_permission)),
        );
        return;
      }

      _currentTrack.clear();

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        final now = DateTime.now();
        if (_selectedDateTime == null) {
          _selectedDateTime = now;
          _activeSessionController.setStartedAt(_selectedDateTime);
        }

        _currentTrack.add(
          GpsPoint(lat: pos.latitude, lon: pos.longitude, time: now),
        );
        if (mounted) setState(() {});
      });

      // Mark success only after we have a subscription and tracking is on.
      _isTracking = true;
      if (mounted) setState(() {});
      await _hapticSuccess();
    } catch (e) {
      debugPrint('GPS ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feil fra GPS: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingGps = false;
        });
      } else {
        _isStartingGps = false;
      }
    }
  }

  Future<void> _stopTracking() async {
    if (!_isTracking || _gpsBusy) return;

    setState(() {
      _isStoppingGps = true;
    });

    try {
      await _positionSub?.cancel();
      _positionSub = null;
      _isTracking = false;
      if (mounted) setState(() {});
      await _hapticSuccess();
    } catch (e) {
      debugPrint('GPS stop ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klarte ikke stoppe GPS')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStoppingGps = false;
        });
      } else {
        _isStoppingGps = false;
      }
    }
  }

  // ---------- Save session ----------
  Future<void> _saveSession() async {
    if (_isSavingSession) return;

    setState(() {
      _isSavingSession = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;

      if (_selectedDog == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Velg en hund først')),
        );
        return;
      }

      final selectedDog = _selectedDog!;
      final isHunting = _sessionType == SessionType.hunting;
      final shotCount = isHunting ? _birdsShotCount : 0;
      final shotSpecies =
          (isHunting && shotCount > 0) ? _birdsShotSpecies : null;

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
          flushes: _parseNonNegative(_flushesController.text),
          notes: _notesController.text,
          birdSpecies: List<String>.from(_selectedBirdSpecies),
          mediaPaths: List<String>.from(_mediaPaths),
          sessionType: _sessionType,
          birdsShotCount: shotCount,
          birdsShotSpecies: shotSpecies,
        );

        await _sessionsBox.put(_editingSessionKey, updated);
        await _hapticSuccess();

        if (!mounted) return;

        final newMilestoneIds = await _handleMilestones(
          updated.dogId,
          updated.dateTime,
        );
        await _presentMilestoneFeedback(
          dogId: updated.dogId,
          milestoneIds: newMilestoneIds,
          achievedAt: updated.dateTime,
          fallbackMessage: 'Endringer lagret',
        );
        Navigator.of(context).pop(updated);
        return;
      }

      int? trackKey;
      if (_currentTrack.isNotEmpty) {
        final track = GpsTrack(
          dogId: selectedDog.id,
          startTime: _currentTrack.first.time,
          endTime: _currentTrack.last.time,
          points: List<GpsPoint>.from(_currentTrack),
        );
        trackKey = await _tracksBox.add(track);
      }

      final trackId = _importedTrackId;

      final session = HuntSession(
        dogId: selectedDog.id,
        dateTime: _selectedDateTime ?? DateTime.now(),
        location: _locationController.text,
        durationMinutes: _parseNonNegative(_durationController.text),
        birdsSeen: _parseNonNegative(_birdsController.text),
        points: _parseNonNegative(_pointsController.text),
        secondaryPoints: _parseNonNegative(_secondaryPointsController.text),
        flushes: _parseNonNegative(_flushesController.text),
        notes: _notesController.text,
        trackKey: trackKey,
        trackId: trackId,
        birdSpecies: List<String>.from(_selectedBirdSpecies),
        mediaPaths: List<String>.from(_mediaPaths),
        sessionType: _sessionType,
        birdsShotCount: shotCount,
        birdsShotSpecies: shotSpecies,
      );

      final sessionKey = await _sessionsBox.add(session);
      final sessionId = sessionKey.toString();
      final newMilestoneIds = await _handleMilestones(
        session.dogId,
        session.dateTime,
      );

      final savedMessage = trackId != null
          ? 'Økt lagret med importert GPX ($_importedTrackPoints punkter)'
          : trackKey == null
              ? 'Økt lagret'
              : l10n.hunt_session_snackbar_saved_with_gps_track(
                  _currentTrack.length,
                );

      if (kDebugMode) {
        final storedTrack = session.trackId != null
            ? await _trackRepository.getTrack(session.trackId!)
            : null;
        if (session.trackId == null || storedTrack == null) {
          debugPrint(
              'Saved sessionId: $sessionKey, trackId missing or track not found');
        } else {
          debugPrint(
            'Saved sessionId: $sessionKey, trackId: ${session.trackId}, points=${storedTrack.points.length}',
          );
          final cloned = storedTrack.points
              .map((p) => GpsPoint(lat: p.lat, lon: p.lon, time: p.time))
              .toList();
          setState(() {
            _sessionTrackPreview[sessionId] = cloned;
          });
        }
      }

      await _hapticSuccess();

      if (mounted) {
        setState(() {
          _showNewSessionForm = false;
          _pendingMediaSessionId = null;
        });
        await _presentMilestoneFeedback(
          dogId: session.dogId,
          milestoneIds: newMilestoneIds,
          achievedAt: session.dateTime,
          fallbackMessage: savedMessage,
        );
        if (!mounted) return;
        if (!_isEditMode && !widget.detailMode) {
          await _navigateToDogDetail(selectedDog);
          return;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSession = false;
        });
      } else {
        _isSavingSession = false;
      }
    }
  }

  Future<List<String>> _handleMilestones(
    String dogId,
    DateTime sessionDateTime,
  ) async {
    // Trygg lesing fra settings uten å være avhengig av en manglende ...Key-constant.
    final settingsBox = _settingsBox;
    final milestonesEnabled =
        (settingsBox.get('milestonesEnabled') as bool?) ?? true;

    if (!milestonesEnabled) {
      return const [];
    }

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
    if (!mounted) {
      return false;
    }

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallbackMessage)),
    );
    return false;
  }

  Future<void> _navigateToDogDetail(Dog dog) async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DogDetailPage(dog: dog),
      ),
    );
  }

  void _openMapForNewSession() {
    final l10n = AppLocalizations.of(context)!;
    if (_importedTrackPreview.isEmpty) return;
    final labelResolver = DogLabelResolver(_dogsBox.values.toList());
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final titleSpan = _selectedDog == null
        ? null
        : TextSpan(
            children: [
              TextSpan(text: '${l10n.session_map_label} – ', style: titleStyle),
              labelResolver.spanForDog(
                context,
                _selectedDog!,
                style: titleStyle,
              ),
            ],
          );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionMapPage(
          trackId: _importedTrackId,
          previewPoints: _importedTrackPreview,
          title: l10n.session_map_label,
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
    final l10n = AppLocalizations.of(context)!;
    if (session.trackId == null) return;
    final sessionId = sessionKey.toString();
    final preview = _sessionTrackPreview[sessionId];
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final titleSpan = TextSpan(
      children: [
        TextSpan(text: '${l10n.session_map_label} – ', style: titleStyle),
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
          title: l10n.session_map_label,
          titleSpan: titleSpan,
        ),
      ),
    );
  }

  // ---------- Edit/delete ----------
  // ignore: unused_element
  Future<void> _editSession(int index, HuntSession session) async {
    if (_anyBusy) return;
    final loc = TextEditingController(text: session.location);
    final dur = TextEditingController(text: session.durationMinutes.toString());
    final birds = TextEditingController(text: session.birdsSeen.toString());
    final pts = TextEditingController(text: session.points.toString());
    final secs =
        TextEditingController(text: session.secondaryPoints.toString());
    final fls = TextEditingController(text: session.flushes.toString());
    final notes = TextEditingController(text: session.notes);
    DateTime dt = session.dateTime;

    await showDialog(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (ctx, setSB) {
            return AlertDialog(
              title: Text(dialogL10n.hunt_session_title_edit),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          text: 'Hund: ',
                          children: [
                            DogLabelResolver(_dogsBox.values.toList())
                                .spanForId(
                              context,
                              session.dogId,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: dt,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (d == null) return;
                              dt = DateTime(
                                  d.year, d.month, d.day, dt.hour, dt.minute);
                              setSB(() {});
                            },
                            child: Text(
                              '${dt.day.toString().padLeft(2, '0')}.'
                              '${dt.month.toString().padLeft(2, '0')}.'
                              '${dt.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: TimeOfDay.fromDateTime(dt),
                              );
                              if (t == null) return;
                              dt = DateTime(
                                  dt.year, dt.month, dt.day, t.hour, t.minute);
                              setSB(() {});
                            },
                            child: Text(
                              '${dt.hour.toString().padLeft(2, '0')}:'
                              '${dt.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: loc,
                        decoration: InputDecoration(
                            labelText:
                                dialogL10n.hunt_session_field_location_label)),
                    TextField(
                        controller: dur,
                        decoration: InputDecoration(
                            labelText: dialogL10n
                                .hunt_session_field_duration_minutes_label),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: birds,
                        decoration: InputDecoration(
                            labelText:
                                dialogL10n.hunt_session_field_birds_seen_label),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: pts,
                        decoration: InputDecoration(
                            labelText:
                                dialogL10n.hunt_session_field_points_label),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: secs,
                        decoration: InputDecoration(
                            labelText: dialogL10n
                                .hunt_session_field_secondary_points_label),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: fls,
                        decoration: InputDecoration(
                            labelText:
                                dialogL10n.hunt_session_field_flushes_label),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: notes,
                        decoration: InputDecoration(
                            labelText:
                                dialogL10n.hunt_session_field_notes_label),
                        maxLines: 3),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final key = session.trackKey;
                    if (key != null) await _tracksBox.delete(key);
                    await _sessionsBox.deleteAt(index);
                    if (mounted) setState(() {});
                    Navigator.pop(ctx);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(dialogL10n.hunt_session_action_delete),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(dialogL10n.hunt_session_action_cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final updated = session.copyWith(
                      dateTime: dt,
                      location: loc.text,
                      durationMinutes: int.tryParse(dur.text) ?? 0,
                      birdsSeen: _parseNonNegative(birds.text),
                      points: _parseNonNegative(pts.text),
                      secondaryPoints: _parseNonNegative(secs.text),
                      flushes: _parseNonNegative(fls.text),
                      notes: notes.text,
                    );
                    await _sessionsBox.putAt(index, updated);
                    await _hapticSuccess();
                    if (mounted) setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Text(dialogL10n.hunt_session_action_save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportGpxForSession(HuntSession session) async {
    if (_isExportingGpx) return;
    setState(() => _isExportingGpx = true);

    final l10n = AppLocalizations.of(context)!;
    try {
      final key = session.trackKey;
      if (key == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.session_export_no_track),
            ),
          );
        }
        return;
      }

      final track = _tracksBox.get(key);
      if (track == null || track.points.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.session_error_track_empty)),
          );
        }
        return;
      }

      final dogLabel = _dogLabelForId(session.dogId);
      final gpx = GPXExporter.exportToGpx(
        trackName: '${dogLabel}_${session.dateTime.toIso8601String()}',
        points: track.points,
      );

      final tempDir = await getTemporaryDirectory();
      final exportsDir = Directory(p.join(tempDir.path, 'exports'));
      await exportsDir.create(recursive: true);

      final safeDog = dogLabel.replaceAll(' ', '_');
      final filename =
          'fuglehund_${safeDog}_${session.dateTime.millisecondsSinceEpoch}.gpx';
      final file = File(p.join(exportsDir.path, filename));

      await file.writeAsString(gpx, encoding: utf8);
      final bytes = await file.length();

      debugPrint(
        '[GPX][EXPORT] path=${file.path} bytes=$bytes points=${track.points.length}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.hunt_session_snackbar_export_ready_opening_share,
            ),
          ),
        );
      }

      await _hapticSuccess();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'GPX fra $dogLabel (${session.dateTime.toIso8601String()})',
      );
    } catch (error, stackTrace) {
      debugPrint('[GPX][EXPORT] error: $error');
      debugPrint(stackTrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                l10n.hunt_session_snackbar_gpx_export_failed_see_log),
          ),
        );
      }
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
                    ? l10n.session_gpx_exporting_ellipsis
                    : l10n.session_gpx_export_label),
                onTap: _isExportingGpx
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _exportGpxForSession(session);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.session_menu_edit),
                onTap: () {
                  Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HuntSessionPage(
                            showNewSessionSection: false,
                            showSessionList: false,
                            editSessionKey: sessionKey,
                            pageTitle: l10n.hunt_session_title_edit,
                          ),
                        ),
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(l10n.session_menu_delete),
                onTap: () async {
                  final key = session.trackKey;
                  if (key != null) await _tracksBox.delete(key);
                  await _sessionsBox.delete(sessionKey);
                  if (mounted) setState(() {});
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
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
    if (widget.detailMode) {
      if (widget.editSessionKey == null) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: const SizedBox.shrink(),
            title: Text(widget.pageTitle ?? 'Økt'),
          ),
          body: const Center(child: Text('Fant ikke økt')),
        );
      }
      final int editKey = widget.editSessionKey!;
      final session = _sessionsBox.get(editKey);
      if (session == null) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: const SizedBox.shrink(),
            title: Text(widget.pageTitle ?? 'Økt'),
          ),
          body: const Center(child: Text('Fant ikke økt')),
        );
      }
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const SizedBox.shrink(),
          title: Text(widget.pageTitle ?? 'Økt'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildDetailView(session, editKey),
          ),
        ),
      );
    }

    final canShowNewSessionSection =
        widget.showNewSessionSection || _isEditMode;
    final showForm = canShowNewSessionSection &&
        (_showNewSessionForm || _isEditMode || widget.autoStartNow);
    final showTracking = showForm && !_isEditMode;
    final l10n = AppLocalizations.of(context)!;
    final sessions = _sessionsBox.values.toList().cast<HuntSession>();
    final latestSession = sessions.isEmpty
        ? null
        : (List<HuntSession>.from(sessions)
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime)))
            .first;

    final sessionKeys = _sessionsBox.keys.cast<int>().toList();
    final sessionEntries = List<MapEntry<int, HuntSession>>.generate(
      sessions.length,
      (i) => MapEntry(sessionKeys[i], sessions[i]),
    );
    final dogs = _dogsBox.values.toList();
    final dogLabelResolver = DogLabelResolver(dogs);
    final birdSpeciesOptions = _birdSpeciesBox.values.toList()..sort();
    final birdSpeciesDropdownOptions = [
      if (_birdsShotSpecies != null &&
          !birdSpeciesOptions.contains(_birdsShotSpecies))
        _birdsShotSpecies!,
      ...birdSpeciesOptions,
    ];
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
    final totalFlushes = dogSessions.fold<int>(0, (sum, s) => sum + s.flushes);

    if (widget.homeCompact &&
        widget.showNewSessionSection &&
        !widget.showSessionList &&
        !_isEditMode) {
      final lastInfoStyle = const TextStyle(fontSize: 14);
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: null,
          title: Text(widget.pageTitle ?? 'Hjem'),
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
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _selectedDog == null
                                ? Text(
                                    'Velg hund',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.65),
                                        ),
                                  )
                                : DefaultTextStyle(
                                    style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.65),
                                            ) ??
                                        const TextStyle(fontSize: 13),
                                    child: Text.rich(
                                      dogLabelResolver.spanForDog(
                                        context,
                                        _selectedDog!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.normal,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.65),
                                            ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                              ? Text('Ingen økter ennå', style: lastInfoStyle)
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
                                    final idx = sessions.indexOf(latestSession);
                                    if (idx == -1) return;
                                    final key = _sessionsBox.keyAt(idx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HuntSessionPage(
                                          showNewSessionSection: false,
                                          showSessionList: false,
                                          editSessionKey: key,
                                          detailMode: true,
                                          pageTitle: 'Økt',
                                        ),
                                      ),
                                    );
                                  },
                            child: const Text('Åpne'),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                            builder: (_) => HuntSessionPage(
                              showNewSessionSection: true,
                              showSessionList: false,
                              homeCompact: false,
                              autoStartNow: true,
                              pageTitle: l10n.session_detail_title_active_session,
                            ),
                          ),
                        );
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(l10n.home_startNewSession),
                        ),
                      ),
                    ),
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
                            ? l10n.session_gpx_importing_ellipsis
                            : l10n.session_gpx_import_label),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _anyBusy ? null : () {},
                        child: Text(l10n.home_settings_button_label),
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
                                  .withOpacity(0.6),
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
        automaticallyImplyLeading: false,
        leading: null,
        title: Text(widget.pageTitle ?? l10n.session_log_title),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        children: [
          if (widget.showNewSessionSection && !_isEditMode && !showForm) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _anyBusy
                        ? null
                        : () => setState(() {
                              _showNewSessionForm = true;
                            }),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.home_startNewSession),
                  ),
                ),
              ),
            ),
          ],
          if (showForm) ...[
            // --- Hund (Section card) ---
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.session_form_dog_section_title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (dogs.isEmpty)
                    const Text('Ingen hunder registrert.')
                  else
                    Builder(
                      builder: (context) {
                        final dogIds = dogs.map((d) => d.id).toSet();
                        String? selectedDogId = _selectedDogId;
                        if (selectedDogId != null &&
                            !dogIds.contains(selectedDogId)) {
                          selectedDogId =
                              dogs.isNotEmpty ? dogs.first.id : null;
                          if (selectedDogId != _selectedDogId) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _setSelectedDogId(selectedDogId);
                              }
                            });
                          }
                        }

                        final selectedStyle = Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 16) ??
                            const TextStyle(fontSize: 16);

                        final itemStyle =
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ) ??
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
                          onChanged:
                              _anyBusy ? null : (id) => _setSelectedDogId(id),
                        );
                      },
                    ),

                  // ---- Hund-info / statistikk (skal være INNI kortet) ----
                  if (_selectedDog != null) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final nameStyle =
                            Theme.of(context).textTheme.titleMedium;
                        final nameColor = nameStyle?.color;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: l10n.session_form_dog_prefix,
                                children: [
                                  dogLabelResolver.spanForDog(
                                    context,
                                    _selectedDog!,
                                    style: (nameStyle ??
                                            const TextStyle(fontSize: 16))
                                        .copyWith(color: nameColor),
                                  ),
                                ],
                              ),
                              style:
                                  (nameStyle ?? const TextStyle(fontSize: 16))
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
                        '${l10n.session_summary_sessions_label} ${dogSessions.length}'),
                    Text(
                        '${l10n.session_summary_total_time_label} $totalDuration min'),
                    Text(
                        '${l10n.session_summary_total_bird_contacts_label} $totalBirds'),
                    Text(
                        '${l10n.session_summary_total_points_label} $totalPoints'),
                    Text(
                        '${l10n.session_summary_total_secondary_points_label} $totalSecondaryPoints'),
                    Text(
                        '${l10n.session_summary_total_flushes_label} $totalFlushes'),
                  ],
                ],
              ),
            ),

            // --- Ny økt (egen section card) ---
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isEditMode
                                      ? Icons.edit
                                      : Icons.add_circle_outline,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditMode
                                      ? l10n.hunt_session_title_edit
                                      : l10n.session_action_add_new_session,
                                  style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600) ??
                                      const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            if (showForm &&
                                !_isEditMode &&
                                !widget.autoStartNow)
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _showNewSessionForm = false;
                                }),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(64, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                child: Text(
                                  l10n.session_action_cancel,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                          ],
                        ),
                        if (showForm && !_isEditMode && !widget.autoStartNow)
                          const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  if (!_isEditMode) const SizedBox(height: 12),

                  if (showForm) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.session_type_title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.session_type_training),
                          selected: _sessionType == SessionType.training,
                          onSelected: (_) =>
                              _applySessionType(SessionType.training),
                        ),
                        ChoiceChip(
                          label: Text(l10n.session_type_hunt),
                          selected: _sessionType == SessionType.hunting,
                          onSelected: (_) =>
                              _applySessionType(SessionType.hunting),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_sessionType == SessionType.hunting) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/bird_rype.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Fugl felt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Antall',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _birdsShotCount > 0
                              ? () => setState(() {
                                    _birdsShotCount -= 1;
                                    if (_birdsShotCount <= 0) {
                                      _birdsShotCount = 0;
                                      _birdsShotSpecies = null;
                                    }
                                  })
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          child: Text(
                            '$_birdsShotCount',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() {
                            _birdsShotCount += 1;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Art',
                        isDense: true,
                      ),
                      isExpanded: true,
                      initialValue:
                          birdSpeciesDropdownOptions.contains(_birdsShotSpecies)
                              ? _birdsShotSpecies
                              : null,
                      hint: const Text('Velg art'),
                      items: birdSpeciesDropdownOptions
                          .map(
                            (species) => DropdownMenuItem<String>(
                              value: species,
                              child: Text(species),
                            ),
                          )
                          .toList(),
                      onChanged: _anyBusy
                          ? null
                          : (value) {
                              setState(() {
                                _birdsShotSpecies = value;
                              });
                            },
                    ),
                    if (birdSpeciesOptions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Legg til fuglearter via "Velg fuglearter" først.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (showTracking) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _isPickingGpx ? null : _importGpxForNewSession,
                        icon: const Icon(Icons.file_upload),
                        label: Text(_isPickingGpx
                            ? l10n.session_gpx_importing_ellipsis
                            : l10n.session_gpx_import_label),
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
                        label: Text(l10n.session_map_label),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  // “Avansert: GPS-sporing” skjules i V1 – ingen widget her.

                  if (showForm) ...[
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                          labelText: l10n.hunt_session_field_location_label),
                      enabled: !_anyBusy,
                    ),
                    TextField(
                      controller: _durationController,
                      decoration: InputDecoration(
                          labelText:
                              l10n.hunt_session_field_duration_minutes_label),
                      keyboardType: TextInputType.number,
                      enabled: !_anyBusy,
                      onChanged: (_) {
                        if (_settingDurationProgrammatically) return;
                        if (_durationFromTrack) {
                          setState(() {
                            _durationFromTrack = false;
                          });
                        }
                      },
                    ),
                    if (_durationFromTrack)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.session_detail_label_duration_from_track,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    TextField(
                      controller: _birdsController,
                      decoration: InputDecoration(
                          labelText:
                              l10n.hunt_session_field_birds_seen_label),
                      keyboardType: TextInputType.number,
                      enabled: !_anyBusy,
                    ),
                    TextField(
                      controller: _pointsController,
                      decoration: InputDecoration(
                          labelText: l10n.hunt_session_field_points_label),
                      keyboardType: TextInputType.number,
                      enabled: !_anyBusy,
                    ),
                    TextField(
                      controller: _secondaryPointsController,
                      decoration: InputDecoration(
                          labelText:
                              l10n.hunt_session_field_secondary_points_label),
                      keyboardType: TextInputType.number,
                      enabled: !_anyBusy,
                    ),
                    TextField(
                      controller: _flushesController,
                      decoration: InputDecoration(
                          labelText: l10n.hunt_session_field_flushes_label),
                      keyboardType: TextInputType.number,
                      enabled: !_anyBusy,
                    ),
                  ],
                  if (showForm) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.session_birds_section_title,
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _anyBusy ? null : _showBirdSpeciesPicker,
                      icon: const Icon(Icons.list),
                      label: Text(l10n.session_birds_select_species),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedBirdSpecies.isEmpty)
                      Text(l10n.session_birds_none_selected),
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
                      l10n.session_media_section_title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _anyBusy
                          ? null
                          : () => _showAddMediaSheet(
                                sessionKey: _editingSessionKey,
                              ),
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(l10n.session_media_add_photo_video),
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
                      l10n.session_notes_section_title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
                        labelText: l10n.hunt_session_field_notes_label,
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
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
                                : l10n.session_save_button),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ], // ✅ LUKKER: if (showForm) ...[

          // --- Lagrede økter (egen section card) ---
          if (widget.showSessionList) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.session_saved_list_title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDogFilterChips(dogs, dogLabelResolver),
                  const SizedBox(height: 12),
                  if (filteredEntries.isEmpty)
                    const Text('Ingen økter for valgt hund')
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
                                      builder: (_) => HuntSessionPage(
                                        showNewSessionSection: false,
                                        showSessionList: false,
                                        editSessionKey: sessionKey,
                                        detailMode: true,
                                        pageTitle: 'Økt',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                      filteredEntries[i]
                                                          .value
                                                          .dogId,
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
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: _TrackSummaryWidget(
                                                    summary: summary,
                                                    timeFormat:
                                                        _trackTimeFormat,
                                                  ),
                                                ),
                                            ],
                                          ),
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
                                  '⏱ ${l10n.session_unit_min}: ${filteredEntries[i].value.durationMinutes}\n'
                                  '🐦 ${l10n.session_label_birds}: ${filteredEntries[i].value.birdsSeen}   '
                                  '📍 ${l10n.session_label_points}: ${filteredEntries[i].value.points}\n'
                                  '➡️ ${l10n.session_unit_sec}: ${filteredEntries[i].value.secondaryPoints}   '
                                  '💨 ${l10n.session_label_flushes}: ${filteredEntries[i].value.flushes}',
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/bird_rype.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${l10n.session_label_birds_down}: '
                                      '${filteredEntries[i].value.birdsShotCount}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                                _buildSessionMediaPreview(
                                  filteredEntries[i].value.mediaPaths,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.file_upload),
                                    label: Text(_isPickingGpx
                                        ? l10n.session_gpx_importing_ellipsis
                                        : l10n.session_gpx_import_label),
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
                                        : (filteredEntries[i].value.trackId ==
                                                null
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
                                          ? l10n.session_gpx_exporting_ellipsis
                                          : l10n.session_gpx_export_label,
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
            ),
          ],
        ],
      ),
    );
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

  List<Widget> _buildDetailView(HuntSession session, int sessionKey) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(
        l10n.session_media_section_title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      _buildMediaGrid(session.mediaPaths),
      const SizedBox(height: 20),
      Text(
        l10n.session_notes_section_title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          session.notes.isNotEmpty
              ? session.notes
              : l10n.session_detail_empty_notes,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      const SizedBox(height: 20),
      _buildDetailsExpansion(session, sessionKey),
    ];
  }

  Widget _buildMediaGrid(List<String> mediaPaths) {
    final l10n = AppLocalizations.of(context)!;
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
    final isVideo = _isVideoPath(path);
    final validation = MediaStorage.resolveAndValidateMedia(path);
    final resolvedPath = validation?.resolvedPath;
    final exists = validation?.exists ?? false;
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
      onTap: exists && resolvedPath != null ? () => _handleMediaTap(path) : null,
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
            onPressed:
                _anyBusy ? null : () => _deleteSessionMediaAt(index),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
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
      watermarkDogName: currentDog?.displayName,
      watermarkShowTitle: currentDog?.watermarkShowTitle,
      watermarkShowName: currentDog?.watermarkShowName,
    );
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

  Widget _buildDetailsExpansion(HuntSession session, int sessionKey) {
    final l10n = AppLocalizations.of(context)!;
    final dateText = DateFormat('dd.MM.yyyy HH:mm').format(session.dateTime);
    final durationText =
        _formatDuration(Duration(minutes: session.durationMinutes));
    final birdsText = birdText(session.birdsSeen);
    final standTextValue = standText(session.points);
    final secondaryText = session.secondaryPoints.toString();
    final flushTextValue = flushText(session.flushes);
    final speciesText = session.birdSpecies.isEmpty
        ? 'Ingen arter'
        : session.birdSpecies.join(', ');

    return ExpansionTile(
      title: Text(l10n.session_detail_detail_title),
      initiallyExpanded: false,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildDetailRow(l10n.session_detail_detail_label_date, dateText),
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
          l10n.session_detail_detail_label_bird_contacts,
          birdsText,
        ),
        _buildDetailRow(
          l10n.session_detail_detail_label_points,
          standTextValue,
        ),
        _buildDetailRow(
          l10n.session_detail_detail_label_secondary_points,
          secondaryText,
        ),
        _buildDetailRow(
          l10n.session_detail_detail_label_flushes,
          flushTextValue,
        ),
        _buildDetailRow(l10n.session_detail_label_bird_species, speciesText),
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
                child: Text(l10n.hunt_session_title_edit),
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
          pageTitle: l10n.hunt_session_title_edit,
        ),
      ),
    );
  }

}
