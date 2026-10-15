import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../features/map/map_tile_sources.dart';
import '../features/map/offline_tiles/tile_cache_service.dart';
import '../l10n/app_localizations.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';
import '../services/effective_track_resolver.dart';
import '../services/hunt_replay_controller.dart';

class HuntReplayPage extends StatefulWidget {
  const HuntReplayPage({
    super.key,
    required this.rawTrack,
    this.trackEdit,
    this.tileProvider,
  });

  final Track rawTrack;
  final SessionTrackEdit? trackEdit;
  final TileProvider? tileProvider;

  @override
  State<HuntReplayPage> createState() => _HuntReplayPageState();
}

class _HuntReplayPageState extends State<HuntReplayPage> {
  final MapController _mapController = MapController();
  late final List<LatLng> _trackPoints;
  late final Polyline _trackPolyline;
  late final HuntReplayController _replay;
  TileProvider? _tileProvider;
  bool _following = true;
  bool _programmaticMove = false;
  LatLng? _lastFollowedPosition;

  @override
  void initState() {
    super.initState();
    final effective = const EffectiveTrackResolver().resolve(
      widget.rawTrack,
      widget.trackEdit,
    );
    _replay = HuntReplayController(effective.points)..addListener(_onReplay);
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
  }

  Future<void> _initializeTiles() async {
    await TileCacheService.ensureStoreReady(standardTileSource);
    if (!mounted) return;
    setState(() {
      _tileProvider = TileCacheService.tileProviderFor(standardTileSource);
    });
  }

  void _onReplay() {
    if (!mounted) return;
    setState(() {});
    if (_following && _replay.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _followMarker());
    }
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
    final provider = _tileProvider;
    if (provider == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.hunt_replay_title)),
        body: const Center(child: CircularProgressIndicator()),
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
                        tileProvider: provider,
                      ),
                      PolylineLayer(
                        key: const ValueKey('hunt-replay-track'),
                        polylines: [_trackPolyline],
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
                    onChanged: _replay.totalDuration == Duration.zero
                        ? null
                        : _replay.seekToProgress,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('hunt-replay-play-pause'),
                          onPressed: _replay.totalDuration == Duration.zero
                              ? null
                              : (_replay.isPlaying
                                  ? _replay.pause
                                  : _replay.play),
                          icon: Icon(
                            _replay.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(
                            _replay.isPlaying
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

String formatReplayDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
