import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../features/map/map_tile_sources.dart';
import '../features/map/offline_tiles/tile_cache_service.dart';
import '../l10n/app_localizations.dart';
import '../models/hunt_event.dart';
import '../models/dog_media_asset.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';
import '../services/effective_track_resolver.dart';
import '../services/hunt_replay_controller.dart';
import '../services/hunt_replay_event_resolver.dart';
import '../services/media_storage.dart';
import '../repositories/hunt_event_media_repository.dart';
import '../ui/hunt_event_labels.dart';
import 'session_media_image_helper.dart';
import 'session_media_video_helper.dart';

class HuntReplayPage extends StatefulWidget {
  const HuntReplayPage({
    super.key,
    required this.rawTrack,
    this.trackEdit,
    this.events = const [],
    this.tileProvider,
    this.eventPauseDuration = const Duration(milliseconds: 2500),
    this.replayController,
    this.mediaRepository,
    this.openMedia,
  });

  final Track rawTrack;
  final SessionTrackEdit? trackEdit;
  final List<HuntEvent> events;
  final TileProvider? tileProvider;
  final Duration eventPauseDuration;
  final HuntReplayController? replayController;
  final HuntEventMediaRepository? mediaRepository;
  final Future<void> Function(BuildContext, DogMediaAsset)? openMedia;

  @override
  State<HuntReplayPage> createState() => _HuntReplayPageState();
}

class _HuntReplayPageState extends State<HuntReplayPage> {
  final MapController _mapController = MapController();
  late final List<LatLng> _trackPoints;
  late final Polyline _trackPolyline;
  late final HuntReplayController _replay;
  late final List<HuntReplayEvent> _events;
  TileProvider? _tileProvider;
  Timer? _eventPauseTimer;
  HuntReplayEvent? _selectedEvent;
  Duration _lastReplayElapsed = Duration.zero;
  int _nextEventIndex = 0;
  bool _handlingEventPause = false;
  bool _resumeAfterEvent = false;
  bool _following = true;
  bool _programmaticMove = false;
  LatLng? _lastFollowedPosition;
  final Map<String, List<DogMediaAsset>> _mediaByEventId = {};

  @override
  void initState() {
    super.initState();
    final effective = const EffectiveTrackResolver().resolve(
      widget.rawTrack,
      widget.trackEdit,
    );
    _replay = widget.replayController ?? HuntReplayController(effective.points);
    _replay.addListener(_onReplay);
    _events = const HuntReplayEventResolver().resolve(
      rawTrack: widget.rawTrack,
      edit: widget.trackEdit,
      events: widget.events,
    );
    _trackPoints = effective.points
        .map((point) => LatLng(point.lat, point.lon))
        .toList(growable: false);
    _trackPolyline = Polyline(
      points: _trackPoints,
      strokeWidth: 4,
      color: Colors.blue,
    );
    _tileProvider = widget.tileProvider;
    if (_tileProvider == null) _initializeTiles();
    _preloadEventMedia();
  }

  void _preloadEventMedia() {
    HuntEventMediaRepository repository;
    try {
      repository = widget.mediaRepository ?? HuntEventMediaRepository();
      for (final replayEvent in _events) {
        final available = <DogMediaAsset>[];
        for (final asset in repository.mediaForEvent(replayEvent.event.id)) {
          final path = asset.localPath;
          if (path == null) continue;
          final validation = MediaStorage.resolveAndValidateMedia(path);
          if (validation?.exists == true && validation!.length > 0) {
            available.add(asset.copyWith(localPath: validation.resolvedPath));
          }
        }
        if (available.isNotEmpty) {
          _mediaByEventId[replayEvent.event.id] = available;
        }
      }
    } catch (_) {
      // Replay and its event card remain usable if local-only media is absent
      // or its boxes are unavailable during startup.
    }
  }

  Future<void> _initializeTiles() async {
    try {
      await TileCacheService.ensureStoreReady(standardTileSource);
      if (!mounted) return;
      setState(() {
        _tileProvider = TileCacheService.tileProviderFor(standardTileSource);
      });
    } catch (_) {
      // A null provider lets TileLayer use its normal network provider.
      // Replay must remain usable even when the offline cache cannot start.
    }
  }

  void _onReplay() {
    if (!mounted) return;
    final elapsed = _replay.elapsed;
    if (!_handlingEventPause) {
      if (elapsed < _lastReplayElapsed) {
        _nextEventIndex = _firstEventAfter(elapsed);
      } else if (elapsed > _lastReplayElapsed || _replay.isPlaying) {
        _triggerCrossedEvent(_lastReplayElapsed, elapsed);
      }
    }
    _lastReplayElapsed = elapsed;
    setState(() {});
    if (_following && _replay.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _followMarker());
    }
  }

  int _firstEventAfter(Duration elapsed) {
    var low = 0;
    var high = _events.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_events[middle].elapsed <= elapsed) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  void _triggerCrossedEvent(Duration previous, Duration current) {
    if (_eventPauseTimer != null || _nextEventIndex >= _events.length) return;
    final candidate = _events[_nextEventIndex];
    if (candidate.elapsed < previous || candidate.elapsed > current) return;

    _nextEventIndex++;
    while (_nextEventIndex < _events.length &&
        (_events[_nextEventIndex].elapsed - candidate.elapsed).abs() <=
            const Duration(milliseconds: 250)) {
      _nextEventIndex++;
    }

    _handlingEventPause = true;
    _resumeAfterEvent = _replay.isPlaying;
    _selectedEvent = candidate;
    _replay.pause();
    _handlingEventPause = false;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _followMarker(force: true),
    );
    _eventPauseTimer = Timer(widget.eventPauseDuration, _finishEventPause);
  }

  void _finishEventPause() {
    _eventPauseTimer = null;
    final shouldResume = _resumeAfterEvent;
    _resumeAfterEvent = false;
    if (!mounted) return;
    setState(() => _selectedEvent = null);
    if (shouldResume) _replay.play();
  }

  void _manualPauseDuringEvent() {
    _resumeAfterEvent = false;
    setState(() {});
  }

  Future<void> _openEventMedia(DogMediaAsset asset) async {
    final shouldResume = _resumeAfterEvent;
    _eventPauseTimer?.cancel();
    _eventPauseTimer = null;
    _resumeAfterEvent = false;
    _replay.pause();
    if (mounted) setState(() {});

    if (widget.openMedia != null) {
      await widget.openMedia!(context, asset);
    } else if (asset.localPath != null) {
      if (asset.kind == DogMediaKind.sessionVideo) {
        await openSessionVideo(context: context, storedPath: asset.localPath!);
      } else {
        await openSessionImage(context: context, storedPath: asset.localPath!);
      }
    }

    if (!mounted) return;
    setState(() => _selectedEvent = null);
    if (shouldResume) _replay.play();
  }

  void _beginSeek(double _) {
    _cancelEventPause();
    _replay.pause();
  }

  void _seekToProgress(double value) {
    final target = Duration(
      microseconds:
          (_replay.totalDuration.inMicroseconds * value.clamp(0.0, 1.0))
              .round(),
    );
    _nextEventIndex = _firstEventAfter(target);
    _lastReplayElapsed = target;
    _handlingEventPause = true;
    _replay.seekToProgress(value);
    _handlingEventPause = false;
  }

  void _cancelEventPause() {
    _eventPauseTimer?.cancel();
    _eventPauseTimer = null;
    _selectedEvent = null;
    _resumeAfterEvent = false;
  }

  void _followMarker({bool force = false}) {
    if (!mounted || (!_following && !force)) return;
    final frame = _replay.frame;
    if (frame == null) return;
    final position = LatLng(frame.latitude, frame.longitude);
    if (!force && _lastFollowedPosition == position) return;
    _programmaticMove = true;
    final zoom = _mapController.camera.zoom.clamp(13.0, 17.0);
    _mapController.move(position, zoom);
    _lastFollowedPosition = position;
    Future.microtask(() => _programmaticMove = false);
  }

  void _handleMapEvent(MapEvent event) {
    if (_programmaticMove || !_following) return;
    if (event.source != MapEventSource.mapController) {
      setState(() => _following = false);
    }
  }

  void _resumeFollowing() {
    setState(() => _following = true);
    _followMarker(force: true);
  }

  @override
  void dispose() {
    _eventPauseTimer?.cancel();
    _replay
      ..removeListener(_onReplay)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_trackPoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.hunt_replay_title)),
        body: Center(
          child: Text(
            l10n.session_map_error_no_tracks,
            key: const ValueKey('hunt-replay-empty'),
          ),
        ),
      );
    }
    final frame = _replay.frame!;
    final markerPosition = LatLng(frame.latitude, frame.longitude);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hunt_replay_title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    key: const ValueKey('hunt-replay-map'),
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _trackPoints.first,
                      initialZoom: 15,
                      initialCameraFit: _trackPoints.length > 1
                          ? CameraFit.bounds(
                              bounds: LatLngBounds.fromPoints(_trackPoints),
                              padding: const EdgeInsets.all(36),
                            )
                          : null,
                      onMapEvent: _handleMapEvent,
                    ),
                    children: [
                      TileLayer(
                        key: const ValueKey('hunt-replay-basemap'),
                        urlTemplate: standardTileSource.urlTemplate,
                        userAgentPackageName: 'com.example.jakthund_app',
                        tileProvider: _tileProvider,
                      ),
                      PolylineLayer(
                        key: const ValueKey('hunt-replay-track'),
                        polylines: [_trackPolyline],
                      ),
                      MarkerLayer(
                        key: const ValueKey('hunt-replay-event-markers'),
                        markers: [
                          for (final event in _events)
                            Marker(
                              point: LatLng(event.point.lat, event.point.lon),
                              width: 38,
                              height: 38,
                              child: Icon(
                                huntEventTypeIcon(event.event.type),
                                key: ValueKey(
                                  'hunt-replay-event-${event.event.id}',
                                ),
                                color: _selectedEvent?.event.id ==
                                        event.event.id
                                    ? Colors.amber.shade800
                                    : Theme.of(context).colorScheme.secondary,
                                size: _selectedEvent?.event.id == event.event.id
                                    ? 34
                                    : 26,
                                shadows: const [
                                  Shadow(color: Colors.white, blurRadius: 5),
                                ],
                              ),
                            ),
                        ],
                      ),
                      MarkerLayer(
                        key: const ValueKey('hunt-replay-marker'),
                        markers: [
                          Marker(
                            point: markerPosition,
                            width: 48,
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.pets,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!_following)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: FilledButton.tonalIcon(
                        key: const ValueKey('hunt-replay-follow'),
                        onPressed: _resumeFollowing,
                        icon: const Icon(Icons.my_location),
                        label: Text(l10n.hunt_replay_follow),
                      ),
                    ),
                ],
              ),
            ),
            if (_selectedEvent != null)
              _ReplayEventCard(
                event: _selectedEvent!,
                media: _mediaByEventId[_selectedEvent!.event.id] ?? const [],
                onOpenMedia: _openEventMedia,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Text(
                    '${formatReplayDuration(_replay.elapsed)} / '
                    '${formatReplayDuration(_replay.totalDuration)}',
                    key: const ValueKey('hunt-replay-time'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    key: const ValueKey('hunt-replay-slider'),
                    value: _replay.progress.clamp(0.0, 1.0),
                    onChangeStart: _replay.totalDuration == Duration.zero
                        ? null
                        : _beginSeek,
                    onChanged: _replay.totalDuration == Duration.zero
                        ? null
                        : _seekToProgress,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('hunt-replay-play-pause'),
                          onPressed: _replay.totalDuration == Duration.zero
                              ? null
                              : (_eventPauseTimer != null
                                  ? _manualPauseDuringEvent
                                  : _replay.isPlaying
                                      ? _replay.pause
                                      : _replay.play),
                          icon: Icon(
                            _replay.isPlaying || _eventPauseTimer != null
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            _replay.isPlaying || _eventPauseTimer != null
                                ? l10n.hunt_replay_pause
                                : l10n.hunt_replay_play,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<double>(
                        key: const ValueKey('hunt-replay-speed'),
                        value: _replay.speed,
                        items: HuntReplayController.supportedSpeeds
                            .map(
                              (speed) => DropdownMenuItem(
                                value: speed,
                                child: Text('${speed.toInt()}x'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (speed) {
                          if (speed != null) _replay.setSpeed(speed);
                        },
                      ),
                    ],
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

class _ReplayEventCard extends StatelessWidget {
  const _ReplayEventCard({
    required this.event,
    required this.media,
    required this.onOpenMedia,
  });

  final HuntReplayEvent event;
  final List<DogMediaAsset> media;
  final ValueChanged<DogMediaAsset> onOpenMedia;

  @override
  Widget build(BuildContext context) {
    final model = event.event;
    return Card(
      key: ValueKey('hunt-replay-event-card-${model.id}'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(huntEventTypeIcon(model.type)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        huntEventTypeLabel(context, model.type),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${formatReplayDuration(event.elapsed)} · '
                        '${DateFormat.Hms().format(event.point.time.toLocal())}',
                      ),
                      if (model.birdSpecies?.trim().isNotEmpty == true)
                        Text(model.birdSpecies!.trim()),
                      if (model.note?.trim().isNotEmpty == true)
                        Text(
                          model.note!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (media.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 86,
                child: ListView.separated(
                  key: ValueKey('hunt-replay-media-${model.id}'),
                  scrollDirection: Axis.horizontal,
                  itemCount: media.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final asset = media[index];
                    final video = asset.kind == DogMediaKind.sessionVideo;
                    return InkWell(
                      key: ValueKey('hunt-replay-media-${asset.mediaId}'),
                      onTap: () => onOpenMedia(asset),
                      child: Container(
                        width: video ? 132 : 96,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: video
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_outline,
                                      size: 34),
                                  Text(
                                    '${AppLocalizations.of(context)!.hunt_replay_play} video',
                                    maxLines: 1,
                                  ),
                                ],
                              )
                            : Image.file(
                                File(asset.localPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  size: 34,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String formatReplayDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
