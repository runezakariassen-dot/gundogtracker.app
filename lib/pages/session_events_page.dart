import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../data/hive_boxes.dart';
import '../models/gps_point.dart';
import '../models/dog_media_asset.dart';
import '../models/hunt_event.dart';
import '../models/hunt_session.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';
import '../repositories/hunt_event_repository.dart';
import '../repositories/hunt_event_media_repository.dart';
import '../services/media_storage.dart';
import '../services/hunt_event_track_resolver.dart';
import '../services/user_identity_service.dart';
import '../ui/hunt_event_labels.dart';
import '../l10n/app_localizations.dart';
import '../features/map/map_tile_sources.dart';
import 'session_media_image_helper.dart';
import 'session_media_image.dart';
import 'session_media_video_helper.dart';

class SessionEventsPage extends StatefulWidget {
  const SessionEventsPage({
    super.key,
    required this.sessionKey,
    required this.session,
    required this.canEdit,
    this.repository,
    this.currentUserId,
    this.eventMapTileProvider,
    this.mediaRepository,
    this.pickMedia,
  });

  final Object sessionKey;
  final HuntSession session;
  final bool canEdit;
  final HuntEventRepository? repository;
  final String Function()? currentUserId;
  final TileProvider? eventMapTileProvider;
  final HuntEventMediaRepository? mediaRepository;
  final Future<String?> Function(bool video)? pickMedia;

  @override
  State<SessionEventsPage> createState() => _SessionEventsPageState();
}

class _SessionEventsPageState extends State<SessionEventsPage> {
  late final HuntEventRepository _repository;
  late final HuntEventMediaRepository _mediaRepository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HuntEventRepository();
    _mediaRepository = widget.mediaRepository ?? HuntEventMediaRepository();
  }

  String get _sessionId {
    final stable = widget.session.sessionId?.trim();
    return stable == null || stable.isEmpty
        ? widget.sessionKey.toString()
        : stable;
  }

  List<HuntEvent> get _events => _repository.listForSession(_sessionId);

  Track? get _track {
    final id = widget.session.trackId?.trim();
    return id == null || id.isEmpty ? null : tracksBox().get(id);
  }

  SessionTrackEdit? get _trackEdit => sessionTrackEditsBox().get(_sessionId);

  Future<void> _openEditor([HuntEvent? event]) async {
    final track = _track;
    if (track == null || track.points.isEmpty) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => HuntEventEditPage(
          session: widget.session,
          sessionId: _sessionId,
          sessionKey: widget.sessionKey,
          rawTrack: track,
          trackEdit: _trackEdit,
          event: event,
          canEdit: widget.canEdit,
          repository: _repository,
          currentUserId: widget.currentUserId,
          mapTileProvider: widget.eventMapTileProvider,
          mediaRepository: _mediaRepository,
          pickMedia: widget.pickMedia,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(HuntEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.hunt_events_delete_title),
        content: Text(l10n.hunt_events_delete_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.hunt_events_delete_action),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.softDelete(
      event.id,
      deletedAt: DateTime.now().toUtc(),
      updatedByUserId: (widget.currentUserId ?? _currentUserId)(),
    );
    await _mediaRepository.deleteLinksForEvent(event.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final events = _events;
    final track = _track;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hunt_events_title)),
      floatingActionButton:
          widget.canEdit && track != null && track.points.isNotEmpty
              ? FloatingActionButton.extended(
                  key: const ValueKey('add-hunt-event'),
                  onPressed: _openEditor,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.hunt_events_add),
                )
              : null,
      body: events.isEmpty
          ? Center(child: Text(l10n.hunt_events_none))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = events[index];
                final outside = track != null &&
                    !const HuntEventTrackResolver().isVisibleOnEffectiveTrack(
                      event: event,
                      rawTrack: track,
                      edit: _trackEdit,
                    );
                return Card(
                  child: ListTile(
                    key: ValueKey('hunt-event-${event.id}'),
                    minVerticalPadding: 14,
                    leading: Icon(huntEventTypeIcon(event.type), size: 30),
                    title: Text(huntEventTypeLabel(context, event.type)),
                    subtitle: Text(
                      [
                        DateFormat(
                          'HH:mm:ss',
                        ).format(event.occurredAt.toLocal()),
                        if (event.birdSpecies?.isNotEmpty == true)
                          event.birdSpecies!,
                        if (outside) l10n.hunt_events_outside_track,
                      ].join(' · '),
                    ),
                    onTap: () => _openEditor(event),
                    trailing: widget.canEdit
                        ? IconButton(
                            key: ValueKey('delete-hunt-event-${event.id}'),
                            onPressed: () => _delete(event),
                            icon: const Icon(Icons.delete_outline),
                          )
                        : const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
    );
  }
}

class HuntEventEditPage extends StatefulWidget {
  const HuntEventEditPage({
    super.key,
    required this.session,
    required this.sessionId,
    this.sessionKey,
    required this.rawTrack,
    required this.trackEdit,
    required this.canEdit,
    required this.repository,
    this.currentUserId,
    this.mapTileProvider,
    this.event,
    this.mediaRepository,
    this.pickMedia,
  });

  final HuntSession session;
  final String sessionId;
  final Object? sessionKey;
  final Track rawTrack;
  final SessionTrackEdit? trackEdit;
  final HuntEvent? event;
  final bool canEdit;
  final HuntEventRepository repository;
  final String Function()? currentUserId;
  final TileProvider? mapTileProvider;
  final HuntEventMediaRepository? mediaRepository;
  final Future<String?> Function(bool video)? pickMedia;

  @override
  State<HuntEventEditPage> createState() => _HuntEventEditPageState();
}

class _HuntEventEditPageState extends State<HuntEventEditPage> {
  late final HuntEventTrackSelection _selection;
  late HuntEventType _type;
  late double _index;
  late final TextEditingController _species;
  late final TextEditingController _note;
  bool _saving = false;
  late final String _eventId;
  late final HuntEventMediaRepository _mediaRepository;
  late final List<DogMediaAsset> _eventMedia;
  final Set<String> _removedMediaIds = <String>{};
  final Set<String> _linksCreatedByEditor = <String>{};
  bool _saved = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool _addingMedia = false;

  @override
  void initState() {
    super.initState();
    _selection = const HuntEventTrackResolver().selection(
      widget.rawTrack,
      widget.trackEdit,
    );
    _eventId = widget.event?.id ?? const Uuid().v4();
    _mediaRepository = widget.mediaRepository ?? HuntEventMediaRepository();
    _eventMedia = List<DogMediaAsset>.of(
      _mediaRepository.mediaForEvent(_eventId),
    );
    _type = widget.event?.type ?? HuntEventType.stand;
    if (_selection.points.isEmpty) {
      _index = 0;
    } else {
      final rawIndex =
          widget.event?.trackPointIndex ?? _selection.rawStartIndex;
      _index = (rawIndex - _selection.rawStartIndex)
          .clamp(0, _selection.points.length - 1)
          .toDouble();
    }
    _species = TextEditingController(text: widget.event?.birdSpecies ?? '');
    _note = TextEditingController(text: widget.event?.note ?? '');
  }

  GpsPoint? get _point {
    if (_selection.points.isEmpty) return null;
    return _selection.points[_index.round()];
  }

  Future<void> _save() async {
    if (!widget.canEdit || _saving) return;
    final point = _point;
    if (point == null) return;
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final userId = (widget.currentUserId ?? _currentUserId)();
    final existing = widget.event;
    final event = HuntEvent(
      id: _eventId,
      sessionId: widget.sessionId,
      dogId: widget.session.dogId,
      dogKey: widget.session.dogKey,
      type: _type,
      occurredAt: point.time.toUtc(),
      sourceTrackId: widget.rawTrack.id,
      trackPointIndex: _selection.rawIndexForEffectiveIndex(_index.round()),
      latitude: point.lat,
      longitude: point.lon,
      birdSpecies: _nullable(_species.text),
      note: _nullable(_note.text),
      source: existing?.source ?? HuntEventSource.manual,
      sourceWaypointName: existing?.sourceWaypointName,
      sourceWaypointSymbol: existing?.sourceWaypointSymbol,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      createdByUserId: existing?.createdByUserId ?? userId,
      updatedByUserId: userId,
    );
    try {
      await widget.repository.upsert(event);
      await _mediaRepository.replaceLinks(
        _eventId,
        _eventMedia.map((asset) => asset.mediaId),
        sessionKey: widget.sessionKey,
        sessionId: widget.sessionId,
      );
      _saved = true;
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kunne ikke lagre hendelsen. Prøv igjen.')),
      );
    }
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _addMedia({required bool video}) async {
    if (!widget.canEdit || _addingMedia) return;
    setState(() => _addingMedia = true);
    var stage = 'hunt_event_media.pick';
    String? sourcePath;
    String? canonicalPath;
    try {
      if (widget.pickMedia != null) {
        sourcePath = await widget.pickMedia!(video);
      } else {
        final picked = video
            ? await _imagePicker.pickVideo(source: ImageSource.gallery)
            : await _imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 90,
              );
        if (picked == null) return;
        sourcePath = picked.path;
      }
      if (sourcePath == null || sourcePath.trim().isEmpty) return;
      stage = 'hunt_event_media.persist';
      canonicalPath = await MediaStorage.ensurePickedMediaPersisted(
        dogId: widget.session.dogId,
        sessionId: widget.sessionId,
        sourcePath: sourcePath,
      );
      stage = 'hunt_event_media.resolve';
      final persisted =
          await MediaStorage.validatePersistedMedia(canonicalPath);
      if (persisted?.exists != true || persisted!.length <= 0) {
        throw FileSystemException(
          'Canonical HuntEvent media is missing or empty',
          canonicalPath,
        );
      }
      final pathWasAlreadyInSession =
          await _sessionContainsCanonicalPath(canonicalPath);
      stage = 'hunt_event_media.asset';
      final asset = await _canonicalAssetForPath(
        canonicalPath,
        video: video,
        createdByEvent: true,
        pathWasAlreadyInSession: pathWasAlreadyInSession,
      );
      stage = 'hunt_event_media.session_append';
      await _appendPathToSession(canonicalPath);
      if (_eventMedia.any((item) => item.mediaId == asset.mediaId)) return;
      stage = 'hunt_event_media.link';
      final link = await _mediaRepository.link(
        huntEventId: _eventId,
        mediaId: asset.mediaId,
        sortOrder: _eventMedia.length,
      );
      if (kDebugMode) {
        final sessionEntry = sessionsBox().toMap().entries.firstWhere(
              (entry) =>
                  entry.value.sessionId == widget.sessionId ||
                  entry.key.toString() == widget.sessionId,
            );
        final persistedAsset = dogMediaAssetsBox().get(asset.mediaId);
        debugPrint(
          '[HUNT_EVENT_MEDIA][add-result] eventId=$_eventId '
          'linkId=${link.id} linkEventId=${link.huntEventId} '
          'mediaId=${link.mediaId} assetMediaId=${persistedAsset?.mediaId} '
          'createdByHuntEventId=${persistedAsset?.createdByHuntEventId} '
          'sessionId=${sessionEntry.value.sessionId} '
          'sessionHiveKey=${sessionEntry.key} '
          'mediaPaths=${sessionEntry.value.mediaPaths}',
        );
      }
      _linksCreatedByEditor.add(asset.mediaId);
      _removedMediaIds.remove(asset.mediaId);
      stage = 'hunt_event_media.preview';
      if (mounted) {
        setState(() => _eventMedia.add(asset));
      }
    } catch (error, stackTrace) {
      final sourceValidation = await _safeMediaValidation(sourcePath);
      final canonicalValidation = await _safeMediaValidation(canonicalPath);
      final resolvedPath = canonicalValidation?.resolvedPath;
      debugPrint(
        '[HUNT_EVENT_MEDIA][FAIL] stage=$stage video=$video '
        'source=$sourcePath sourceExists=${sourceValidation?.exists} '
        'sourceSize=${sourceValidation?.length} canonical=$canonicalPath '
        'resolved=$resolvedPath '
        'sourceExtension=${p.extension(sourcePath ?? '').toLowerCase()} '
        'canonicalExtension=${p.extension(canonicalPath ?? '').toLowerCase()} '
        'canonicalExists=${canonicalValidation?.exists} '
        'canonicalSize=${canonicalValidation?.length} '
        'sessionsOpen=${Hive.isBoxOpen(sessionsBoxName)} '
        'assetsOpen=${Hive.isBoxOpen(dogMediaAssetsBoxName)} '
        'linksOpen=${Hive.isBoxOpen(huntEventMediaLinksBoxName)} '
        'error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.hunt_event_media_add_error,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingMedia = false);
    }
  }

  Future<MediaStorageValidation?> _safeMediaValidation(String? path) async {
    if (path == null) return null;
    try {
      return await MediaStorage.validatePersistedMedia(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _appendPathToSession(String path) async {
    for (final entry in sessionsBox().toMap().entries) {
      final sessionId = entry.value.sessionId?.trim();
      if (sessionId != widget.sessionId &&
          entry.key.toString() != widget.sessionId) {
        continue;
      }
      final normalizedPaths =
          await MediaStorage.normalizeMediaPaths(entry.value.mediaPaths);
      final normalizedPath =
          (await MediaStorage.normalizeMediaPaths([path])).single;
      if (normalizedPaths.contains(normalizedPath)) return;
      await sessionsBox().put(
        entry.key,
        entry.value.copyWith(mediaPaths: [...entry.value.mediaPaths, path]),
      );
      return;
    }
  }

  Future<bool> _sessionContainsCanonicalPath(String path) async {
    final normalizedPath =
        (await MediaStorage.normalizeMediaPaths([path])).single;
    for (final entry in sessionsBox().toMap().entries) {
      final sessionId = entry.value.sessionId?.trim();
      if (sessionId != widget.sessionId &&
          entry.key.toString() != widget.sessionId) {
        continue;
      }
      final normalizedPaths =
          await MediaStorage.normalizeMediaPaths(entry.value.mediaPaths);
      return normalizedPaths.contains(normalizedPath);
    }
    return false;
  }

  Future<DogMediaAsset> _canonicalAssetForPath(
    String path, {
    required bool video,
    required bool createdByEvent,
    bool pathWasAlreadyInSession = false,
  }) async {
    for (final asset in dogMediaAssetsBox().values) {
      if (asset.sessionId == widget.sessionId && asset.localPath == path) {
        if (createdByEvent &&
            !pathWasAlreadyInSession &&
            (asset.createdByHuntEventId == null ||
                asset.createdByHuntEventId!.isEmpty)) {
          final eventOwnedAsset = asset.copyWith(
            createdByHuntEventId: _eventId,
          );
          await dogMediaAssetsBox().put(asset.mediaId, eventOwnedAsset);
          return eventOwnedAsset;
        }
        return asset;
      }
    }
    final validation = await MediaStorage.validatePersistedMedia(path);
    if (validation?.exists != true || validation!.length <= 0) {
      throw FileSystemException(
        'Cannot create DogMediaAsset for missing or empty media',
        path,
      );
    }
    final extension = p.extension(path).replaceFirst('.', '');
    final asset = DogMediaAsset(
      mediaId: const Uuid().v4(),
      dogCloudId: widget.session.dogId,
      dogKey: widget.session.dogKey ?? widget.session.dogId,
      sessionId: widget.sessionId,
      kind: video ? DogMediaKind.sessionVideo : DogMediaKind.sessionImage,
      localPath: path,
      contentType: '${video ? 'video' : 'image'}/$extension',
      sizeBytes: validation.length,
      status: DogMediaStatus.active,
      syncStatus: DogMediaSyncStatus.localOnly,
      createdByUid: (widget.currentUserId ?? _currentUserId)(),
      createdAt: DateTime.now().toUtc(),
      createdByHuntEventId: createdByEvent ? _eventId : null,
    );
    await dogMediaAssetsBox().put(asset.mediaId, asset);
    return asset;
  }

  Future<void> _chooseFromSession() async {
    final choices = <DogMediaAsset>[];
    for (final path in widget.session.mediaPaths) {
      final asset = await _canonicalAssetForPath(
        path,
        video: _isVideo(path),
        createdByEvent: false,
      );
      if (!_eventMedia.any((item) => item.mediaId == asset.mediaId)) {
        choices.add(asset);
      }
    }
    if (!mounted || choices.isEmpty) return;
    final selected = await showModalBottomSheet<DogMediaAsset>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: choices
              .map(
                (asset) => ListTile(
                  leading: Icon(
                    asset.kind == DogMediaKind.sessionVideo
                        ? Icons.videocam
                        : Icons.image,
                  ),
                  title: Text(p.basename(asset.localPath ?? asset.mediaId)),
                  onTap: () => Navigator.pop(context, asset),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _removedMediaIds.remove(selected.mediaId);
        _eventMedia.add(selected);
      });
    }
  }

  void _removeMedia(DogMediaAsset asset) {
    setState(() {
      _eventMedia.remove(asset);
      _removedMediaIds.add(asset.mediaId);
    });
  }

  bool _isVideo(String path) {
    final extension = p.extension(path).toLowerCase();
    return const {'.mp4', '.mov', '.m4v', '.avi', '.webm', '.mkv'}
        .contains(extension);
  }

  Future<void> _openMedia(DogMediaAsset asset) async {
    final path = asset.localPath;
    if (path == null) return;
    if (asset.kind == DogMediaKind.sessionVideo) {
      await openSessionVideo(context: context, storedPath: path);
    } else {
      await openSessionImage(context: context, storedPath: path);
    }
  }

  Widget _imagePreview(String? path) {
    if (path == null) {
      return const Icon(Icons.broken_image_outlined, size: 36);
    }
    final validation = MediaStorage.resolveAndValidateMedia(path);
    if (validation?.exists != true) {
      return const Icon(Icons.broken_image_outlined, size: 36);
    }
    return SessionMediaImage(
      storedPath: path,
      displayWidth: 88,
      displayHeight: 88,
      fit: BoxFit.cover,
      placeholder: const Icon(Icons.broken_image_outlined, size: 36),
    );
  }

  Widget _buildMediaSection(AppLocalizations l10n, bool readOnly) {
    return Column(
      key: const ValueKey('hunt-event-media-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.hunt_event_media_title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_eventMedia.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final asset in _eventMedia)
                Stack(
                  children: [
                    InkWell(
                      key: ValueKey('hunt-event-media-${asset.mediaId}'),
                      onTap: () => _openMedia(asset),
                      child: Container(
                        width: 88,
                        height: 88,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: asset.kind == DogMediaKind.sessionVideo
                            ? const Icon(Icons.play_circle_outline, size: 40)
                            : _imagePreview(asset.localPath),
                      ),
                    ),
                    if (!readOnly)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton.filledTonal(
                          key: ValueKey(
                            'unlink-hunt-event-media-${asset.mediaId}',
                          ),
                          tooltip: l10n.hunt_event_media_remove,
                          onPressed: () => _removeMedia(asset),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
        if (!readOnly) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('add-hunt-event-image'),
                onPressed: _addingMedia ? null : () => _addMedia(video: false),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(l10n.hunt_event_media_add_image),
              ),
              OutlinedButton.icon(
                key: const ValueKey('add-hunt-event-video'),
                onPressed: _addingMedia ? null : () => _addMedia(video: true),
                icon: const Icon(Icons.video_call_outlined),
                label: Text(l10n.hunt_event_media_add_video),
              ),
              if (widget.session.mediaPaths.isNotEmpty)
                OutlinedButton.icon(
                  key: const ValueKey('choose-hunt-event-session-media'),
                  onPressed: _addingMedia ? null : _chooseFromSession,
                  icon: const Icon(Icons.collections_outlined),
                  label: Text(l10n.hunt_event_media_choose_session),
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    if (!_saved && _linksCreatedByEditor.isNotEmpty) {
      unawaited(_rollbackUnsavedMedia());
    }
    _species.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _rollbackUnsavedMedia() async {
    for (final mediaId in _linksCreatedByEditor) {
      await _mediaRepository.unlink(_eventId, mediaId);
      await _mediaRepository.deleteEventCreatedMediaIfUnreferenced(mediaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final readOnly = !widget.canEdit;
    final point = _point;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          readOnly ? l10n.hunt_event_view_title : l10n.hunt_event_edit_title,
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('hunt-event-editor-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            DropdownButtonFormField<HuntEventType>(
              initialValue: _type,
              decoration:
                  InputDecoration(labelText: l10n.hunt_event_field_type),
              items: HuntEventType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(huntEventTypeLabel(context, type)),
                    ),
                  )
                  .toList(),
              onChanged: readOnly
                  ? null
                  : (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 16),
            if (point != null) ...[
              SizedBox(
                height: 220,
                child: Card(
                  key: ValueKey('event-track-preview-${_index.round()}'),
                  clipBehavior: Clip.antiAlias,
                  child: HuntEventTrackMap(
                    key: const ValueKey('hunt-event-track-preview-tap-area'),
                    points: _selection.points,
                    selectedIndex: _index.round(),
                    enabled: !readOnly,
                    tileProvider: widget.mapTileProvider,
                    onPointSelected: (index) {
                      if (!readOnly) setState(() => _index = index.toDouble());
                    },
                  ),
                ),
              ),
              if (!readOnly) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.hunt_event_track_tap_hint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l10n.session_map_error_no_tracks),
              ),
            const SizedBox(height: 12),
            if (point != null) ...[
              Text(
                '${l10n.hunt_event_field_time}: '
                '${DateFormat('HH:mm:ss').format(point.time.toLocal())}',
              ),
              Slider(
                key: const ValueKey('hunt-event-track-slider'),
                value: _index,
                min: 0,
                max: (_selection.points.length - 1).toDouble(),
                divisions: _selection.points.length > 1
                    ? _selection.points.length - 1
                    : null,
                onChanged:
                    readOnly ? null : (value) => setState(() => _index = value),
              ),
            ],
            TextField(
              controller: _species,
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: l10n.hunt_event_field_bird_species_optional,
              ),
            ),
            TextField(
              controller: _note,
              enabled: !readOnly,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.hunt_event_field_note_optional,
              ),
            ),
            _buildMediaSection(l10n, readOnly),
            if (!readOnly) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const ValueKey('save-hunt-event'),
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving ? l10n.hunt_event_saving : l10n.hunt_event_save,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _currentUserId() {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();
    if (uid != null && uid.isNotEmpty) return uid;
  } catch (_) {
    // Firebase may be unavailable in local tests; retain the local identity.
  }
  return UserIdentityService().getCurrentUserId();
}

class HuntEventTrackMap extends StatelessWidget {
  const HuntEventTrackMap({
    super.key,
    required this.points,
    required this.selectedIndex,
    required this.enabled,
    required this.onPointSelected,
    this.tileProvider,
  });

  final List<GpsPoint> points;
  final int selectedIndex;
  final bool enabled;
  final ValueChanged<int> onPointSelected;
  final TileProvider? tileProvider;

  LatLng _latLng(GpsPoint point) => LatLng(point.lat, point.lon);

  int _nearestIndex(LatLng tappedPoint) {
    var nearest = 0;
    var nearestDistance = double.infinity;
    const distance = Distance();
    for (var index = 0; index < points.length; index++) {
      final candidate = distance.as(
        LengthUnit.Meter,
        tappedPoint,
        _latLng(points[index]),
      );
      if (candidate < nearestDistance) {
        nearest = index;
        nearestDistance = candidate;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    final mapPoints = points.map(_latLng).toList(growable: false);
    final selectedPoint = mapPoints[selectedIndex];
    return FlutterMap(
      key: const ValueKey('hunt-event-flutter-map'),
      options: MapOptions(
        initialCenter: selectedPoint,
        initialZoom: 15,
        initialCameraFit: mapPoints.length > 1
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(mapPoints),
                padding: const EdgeInsets.all(24),
              )
            : null,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
        onTap: enabled
            ? (_, point) => onPointSelected(_nearestIndex(point))
            : null,
      ),
      children: [
        TileLayer(
          key: const ValueKey('hunt-event-basemap-layer'),
          urlTemplate: standardTileSource.urlTemplate,
          userAgentPackageName: 'com.example.jakthund_app',
          tileProvider: tileProvider,
        ),
        PolylineLayer(
          key: const ValueKey('hunt-event-track-layer'),
          polylines: [
            Polyline(
              points: mapPoints,
              strokeWidth: 4,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        MarkerLayer(
          key: const ValueKey('hunt-event-marker-layer'),
          markers: [
            Marker(
              point: selectedPoint,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 36,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
