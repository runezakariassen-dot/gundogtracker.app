// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../models/gps_point.dart';
import '../../models/offline_region_metadata.dart';
import '../../widgets/big_action_button.dart';
import 'map_tile_sources.dart';
import 'offline_tiles/offline_download_controller.dart';
import 'offline_tiles/offline_region_service.dart';
import 'offline_tiles/tile_cache_service.dart';
import '../../l10n/app_localizations.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.points,
    this.title,
    this.titleSpan,
  });

  final List<GpsPoint> points;
  final String? title;
  final InlineSpan? titleSpan;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final OfflineRegionService _offlineRegionService = OfflineRegionService();

  late final List<LatLng> _trackPoints;
  late final List<LatLng> _displayPoints;
  late final LatLngBounds? _trackBounds;
  late final LatLng? _trackCenter;

  MapTileSource _tileSource = standardTileSource;
  FMTCTileProvider? _tileProvider;
  final List<OfflineRegionMetadata> _offlineRegions = [];
  bool _didFit = false;
  bool _isDownloading = false;
  Object? _downloadInstanceId;
  double? _downloadProgress;
  bool _isViewportOffline = false;
  LatLngBounds? _viewportBounds;
  DateTime? _lastTileErrorAt;
  StreamSubscription<MapEvent>? _mapEventSubscription;
  StreamSubscription<Position>? _positionSub;
  bool _followMe = false;
  DateTime? _lastFollowUpdateAt;
  bool _isAutoMoving = false;

  final List<_AreaOption> _areaOptions = const [
    _AreaOption(label: '2 km', radiusKm: 2),
    _AreaOption(label: '5 km', radiusKm: 5),
    _AreaOption(label: '10 km', radiusKm: 10),
  ];
  final List<_DetailOption> _detailOptions = const [
    _DetailOption(label: 'Lav (12-14)', minZoom: 12, maxZoom: 14),
    _DetailOption(label: 'Middels (12-15)', minZoom: 12, maxZoom: 15),
    _DetailOption(label: 'Høy (12-16)', minZoom: 12, maxZoom: 16),
  ];

  @override
  void initState() {
    super.initState();
    _trackPoints = widget.points.map(_toLatLng).toList(growable: false);
    _displayPoints = _downsampleIfNeeded(_trackPoints);
    final bounds = _trackPoints.isEmpty ? null : calcBounds(_trackPoints);
    _trackBounds = bounds;
    _trackCenter = bounds == null ? null : calcCenter(bounds);
    _initTileCache(_tileSource);
    _loadOfflineRegions();
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      _updateViewportStatus();
      _handleManualMapInteraction(event);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  @override
  void dispose() {
    _mapEventSubscription?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _initTileCache(MapTileSource source) async {
    await TileCacheService.ensureStoreReady(source);
    if (!mounted) return;
    _refreshTileProvider();
  }

  void _fitBounds() {
    if (_didFit) return;
    final bounds = _trackBounds;
    if (bounds == null) return;
    if (_trackPoints.length == 1) {
      _mapController.move(_trackPoints.first, 15);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
        ),
      );
    }
    _didFit = true;
  }

  void _fitToTrack() {
    final bounds = _trackBounds;
    if (bounds == null) {
      _logMapUi('focus_track', 'empty');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.map_page_snackbar_no_tracks_to_focus)),
        );
      }
      return;
    }
    _logMapUi('focus_track');
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }

  Future<void> _centerOnUser({bool fromFollow = false}) async {
    if (!await _ensureLocationPermission()) {
      _logMapUi('center_user', 'no_permission');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fant ikke posisjon')),
      );
      return;
    }

    Position? pos = await Geolocator.getLastKnownPosition();
    try {
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      // Ignore and fall back to last known.
    }

    if (!mounted) return;
    if (pos == null) {
      _logMapUi('center_user', 'no_position');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fant ikke posisjon')),
      );
      return;
    }

    final target = LatLng(pos.latitude, pos.longitude);
    final zoom = _mapController.camera.zoom;
    _moveMap(target, zoom);
    if (!fromFollow) {
      _logMapUi(
        'center_user',
        'lat=${target.latitude.toStringAsFixed(5)} '
            'lon=${target.longitude.toStringAsFixed(5)}',
      );
    }
  }

  Future<void> _toggleFollow() async {
    final next = !_followMe;
    setState(() {
      _followMe = next;
    });
    _logMapUi(next ? 'follow_on' : 'follow_off');
    if (next) {
      await _startFollowStream();
    } else {
      await _positionSub?.cancel();
      _positionSub = null;
    }
  }

  Future<void> _startFollowStream() async {
    if (!await _ensureLocationPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fant ikke posisjon')),
      );
      setState(() {
        _followMe = false;
      });
      return;
    }

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!_followMe) return;
      final now = DateTime.now();
      if (_lastFollowUpdateAt != null &&
          now.difference(_lastFollowUpdateAt!) < const Duration(seconds: 2)) {
        return;
      }
      _lastFollowUpdateAt = now;
      final target = LatLng(pos.latitude, pos.longitude);
      final zoom = _mapController.camera.zoom;
      _moveMap(target, zoom);
    });
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  void _toggleTerrain() {
    final next = _tileSource.key == terrainTileSource.key
        ? standardTileSource
        : terrainTileSource;
    setState(() {
      _tileSource = next;
      _tileProvider = null;
    });
    _initTileCache(next);
  }

  void _loadOfflineRegions() {
    final regions = _offlineRegionService.loadAll();
    _offlineRegions
      ..clear()
      ..addAll(regions);
    _refreshTileProvider();
    _updateViewportStatus();
    _logOffline('regions-loaded', 'count=${regions.length}');
  }

  void _refreshTileProvider() {
    if (!mounted) return;
    final extraStores = _offlineRegionStoresForStyle(_tileSource.key);
    setState(() {
      _tileProvider = TileCacheService.tileProviderFor(
        _tileSource,
        extraStores: extraStores,
      );
    });
  }

  List<String> _offlineRegionStoresForStyle(String styleKey) {
    final stores = <String>{};
    for (final region in _offlineRegions) {
      if (region.tileSourceKey != styleKey) continue;
      final storeName =
          region.storeName ?? TileCacheService.storeFor(_tileSource).storeName;
      stores.add(storeName);
    }
    return stores.toList(growable: false);
  }

  void _updateViewportStatus() {
    if (!mounted) return;
    LatLngBounds? bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return;
    }
    final isOffline = _isBoundsOffline(bounds, _tileSource.key);
    final changed = isOffline != _isViewportOffline ||
        _viewportBounds == null ||
        !_viewportBounds!.isOverlapping(bounds);
    if (!changed) return;
    setState(() {
      _viewportBounds = bounds;
      _isViewportOffline = isOffline;
    });
    _logOffline(
      'viewport',
      'offline=$isOffline bounds=S:${bounds.south},W:${bounds.west},N:${bounds.north},E:${bounds.east}',
    );
  }

  bool _isBoundsOffline(LatLngBounds bounds, String styleKey) {
    for (final region in _offlineRegions) {
      if (region.tileSourceKey != styleKey) continue;
      final regionBounds = LatLngBounds(
        LatLng(region.minLat, region.minLon),
        LatLng(region.maxLat, region.maxLon),
      );
      if (regionBounds.isOverlapping(bounds)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _showDownloadOptions() async {
    final trackCenter = _trackCenter;
    if (trackCenter == null || _isDownloading) return;
    final selection = await showDialog<_DownloadSelection>(
      context: context,
      builder: (context) {
        var area = _areaOptions.first;
        var detail = _detailOptions[1];
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            final estimate = _estimateWorkload(
              area: area,
              detail: detail,
            );
            final tooLarge = estimate != null && estimate > 20000;
            return AlertDialog(
              title: Text(l10n.map_download_title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.map_download_area_label),
                    ),
                    const SizedBox(height: 8),
                    ..._areaOptions.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _optionButton(
                          label: option.label,
                          selected: option == area,
                          onPressed: () => setState(() => area = option),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Detalj'),
                    ),
                    const SizedBox(height: 8),
                    ..._detailOptions.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _optionButton(
                          label: option.label,
                          selected: option == detail,
                          onPressed: () => setState(() => detail = option),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        estimate == null
                            ? 'Estimert: n/a'
                            : 'Estimert: ca. $estimate tiles',
                        style: TextStyle(
                          color: tooLarge ? Colors.red : null,
                        ),
                      ),
                    ),
                    if (tooLarge)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'For stort omrade/detalj. Velg mindre.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.map_download_cancel),
                ),
                TextButton(
                  onPressed: tooLarge
                      ? null
                      : () => Navigator.pop(
                            context,
                            _DownloadSelection(area: area, detail: detail),
                          ),
                  child: Text(l10n.map_download_start),
                ),
              ],
            );
          },
        );
      },
    );
    if (selection == null) return;
    await _downloadOfflineRegion(selection);
  }

  Future<void> _showOfflineRegionsSheet() async {
    final l10n = AppLocalizations.of(context)!;
    _loadOfflineRegions();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.map_downloaded_maps_title),
              const SizedBox(height: 12),
              if (_offlineRegions.isEmpty)
                Text(l10n.map_downloaded_maps_empty)
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _offlineRegions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final region = _offlineRegions[index];
                      return _regionCard(region);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadOfflineRegion(_DownloadSelection selection) async {
    if (_trackCenter == null || _isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    await _runDownloadWithLogging(
      area: selection.area,
      detail: selection.detail,
    );
  }

  Future<void> _runDownloadWithLogging({
    required _AreaOption area,
    required _DetailOption detail,
  }) async {
    final trackCenter = _trackCenter;
    if (trackCenter == null) return;
    final startTime = DateTime.now();
    await TileCacheService.ensureStoreReady(_tileSource);
    final regionStoreName = 'offline_${_tileSource.key}_${const Uuid().v4()}';
    await TileCacheService.ensureStoreReadyByName(regionStoreName);
    final controller = OfflineDownloadController(
      store: FMTCStore(regionStoreName),
      tileSourceKey: _tileSource.key,
      tileLayer: _buildTileLayer(_tileSource),
    );
    final bounds = controller.buildBoundsFromCenter(
      trackCenter,
      area.radiusKm,
    );
    final estimatedTiles = controller.estimateWorkload(
      bounds,
      detail.minZoom,
      detail.maxZoom,
    );

    if (estimatedTiles > 20000) {
      _logMapDownload(
        'too-large',
        bounds: bounds,
        minZoom: detail.minZoom,
        maxZoom: detail.maxZoom,
        estimatedTiles: estimatedTiles,
        tileSourceKey: _tileSource.key,
        radiusKm: area.radiusKm,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('For stort område/detaljnivå, velg mindre.'),
          ),
        );
        setState(() {
          _isDownloading = false;
          _downloadInstanceId = null;
        });
      }
      return;
    }

    _logMapDownload(
      'start',
      bounds: bounds,
      minZoom: detail.minZoom,
      maxZoom: detail.maxZoom,
      estimatedTiles: estimatedTiles,
      tileSourceKey: _tileSource.key,
      radiusKm: area.radiusKm,
      startedAt: startTime,
    );

    final progressNotifier = ValueNotifier<double>(0);
    setState(() {
      _downloadProgress = 0;
    });
    _downloadInstanceId = DateTime.now().microsecondsSinceEpoch;
    unawaited(_showDownloadDialog(progressNotifier, onCancel: _cancelDownload));

    await runZonedGuarded(() async {
      final download = controller.startDownload(
        bounds: bounds,
        minZoom: detail.minZoom,
        maxZoom: detail.maxZoom,
        parallelThreads: 2,
        maxBufferLength: 60,
        skipExistingTiles: true,
      );

      _downloadInstanceId = controller.instanceId;

      final completer = Completer<void>();
      late StreamSubscription<DownloadProgress> subscription;
      subscription = download.progress.listen(
        (progress) {
          progressNotifier.value = progress.percentageProgress;
          setState(() {
            _downloadProgress = progress.percentageProgress;
          });
          _logMapDownload(
            'progress',
            bounds: bounds,
            minZoom: detail.minZoom,
            maxZoom: detail.maxZoom,
            tileSourceKey: _tileSource.key,
            estimatedTiles: estimatedTiles,
            progressPercent: progress.percentageProgress,
            radiusKm: area.radiusKm,
          );
        },
        onError: (error, stackTrace) {
          _logMapDownload(
            'stream-error',
            error: error,
            stackTrace: stackTrace,
            bounds: bounds,
            minZoom: detail.minZoom,
            maxZoom: detail.maxZoom,
            tileSourceKey: _tileSource.key,
            estimatedTiles: estimatedTiles,
            radiusKm: area.radiusKm,
          );
          completer.completeError(error, stackTrace);
        },
        onDone: () {
          completer.complete();
        },
      );

      try {
        await completer.future;
        final metadata = OfflineRegionMetadata(
          id: const Uuid().v4(),
          name: 'Kart ${area.label} (${detail.label}, ${_tileSource.label})',
          createdAt: DateTime.now(),
          minLat: bounds.south,
          minLon: bounds.west,
          maxLat: bounds.north,
          maxLon: bounds.east,
          minZoom: detail.minZoom,
          maxZoom: detail.maxZoom,
          tileSourceKey: _tileSource.key,
          radiusKm: area.radiusKm,
          storeName: regionStoreName,
        );
        await _offlineRegionService.add(metadata);
        _loadOfflineRegions();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ferdig')),
        );
        _logMapDownload(
          'done',
          bounds: bounds,
          minZoom: detail.minZoom,
          maxZoom: detail.maxZoom,
          tileSourceKey: _tileSource.key,
          estimatedTiles: estimatedTiles,
          radiusKm: area.radiusKm,
          startedAt: startTime,
          endedAt: DateTime.now(),
        );
      } catch (e, stackTrace) {
        _logMapDownload(
          'failed',
          error: e,
          stackTrace: stackTrace,
          bounds: bounds,
          minZoom: detail.minZoom,
          maxZoom: detail.maxZoom,
          tileSourceKey: _tileSource.key,
          estimatedTiles: estimatedTiles,
          radiusKm: area.radiusKm,
          startedAt: startTime,
          endedAt: DateTime.now(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke laste ned kart')),
        );
      } finally {
        await subscription.cancel();
        progressNotifier.dispose();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() {
            _isDownloading = false;
            _downloadInstanceId = null;
            _downloadProgress = null;
          });
        }
      }
    }, (error, stackTrace) {
      _logMapDownload(
        'zone-error',
        error: error,
        stackTrace: stackTrace,
        bounds: bounds,
        minZoom: detail.minZoom,
        maxZoom: detail.maxZoom,
        tileSourceKey: _tileSource.key,
        estimatedTiles: estimatedTiles,
        radiusKm: area.radiusKm,
        startedAt: startTime,
        endedAt: DateTime.now(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke laste ned kart')),
        );
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isDownloading = false;
          _downloadInstanceId = null;
          _downloadProgress = null;
        });
      }
      progressNotifier.dispose();
    });
  }

  Future<void> _cancelDownload() async {
    if (_downloadInstanceId == null) return;
    try {
      await TileCacheService.storeFor(_tileSource)
          .download
          .cancel(instanceId: _downloadInstanceId!);
      if (mounted) {
        setState(() {
          _downloadProgress = null;
        });
      }
      _logMapDownload(
        'cancelled',
        tileSourceKey: _tileSource.key,
      );
    } catch (e, stackTrace) {
      _logMapDownload(
        'cancel-error',
        error: e,
        stackTrace: stackTrace,
        tileSourceKey: _tileSource.key,
      );
    }
  }

  void _logMapDownload(
    String event, {
    LatLngBounds? bounds,
    int? minZoom,
    int? maxZoom,
    String? tileSourceKey,
    int? estimatedTiles,
    double? progressPercent,
    double? radiusKm,
    DateTime? startedAt,
    DateTime? endedAt,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final boundsText = bounds == null
        ? 'n/a'
        : 'S:${bounds.south},W:${bounds.west},N:${bounds.north},E:${bounds.east}';
    debugPrint(
      '[MAP DOWNLOAD] [$event] bounds=$boundsText '
      'zoom=${minZoom ?? 'n/a'}-${maxZoom ?? 'n/a'} '
      'source=${tileSourceKey ?? 'n/a'} tiles=${estimatedTiles ?? 'n/a'} '
      'radius=${radiusKm?.toStringAsFixed(1) ?? 'n/a'}km '
      'progress=${progressPercent?.toStringAsFixed(1) ?? 'n/a'} '
      'start=${startedAt?.toIso8601String() ?? 'n/a'} '
      'end=${endedAt?.toIso8601String() ?? 'n/a'}',
    );
    if (error != null) {
      debugPrint('MAP DOWNLOAD [$event] error: $error');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _deleteOfflineTiles() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett offline kart'),
        content:
            const Text('Dette sletter nedlastede karttiles for valgt stil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Slett'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _logOffline('delete-style-start', 'style=${_tileSource.key}');
    await TileCacheService.resetStore(_tileSource);
    await _offlineRegionService.clear(tileSourceKey: _tileSource.key);
    _loadOfflineRegions();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offline kart slettet')),
    );
    _logOffline('delete-style-done', 'style=${_tileSource.key}');
  }

  Future<void> _showDownloadDialog(
    ValueNotifier<double> progress, {
    required VoidCallback onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Laster ned kart'),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) {
            final percentage = value.isNaN ? 0 : value.clamp(0, 100);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: percentage / 100),
                const SizedBox(height: 12),
                Text('${percentage.toStringAsFixed(0)}%'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              onCancel();
            },
            child: const Text('Avbryt'),
          ),
        ],
      ),
    );
  }

  int? _estimateWorkload({
    required _AreaOption area,
    required _DetailOption detail,
  }) {
    final center = _trackCenter;
    if (center == null || _tileProvider == null) return null;
    final controller = OfflineDownloadController(
      store: TileCacheService.storeFor(_tileSource),
      tileSourceKey: _tileSource.key,
      tileLayer: _buildTileLayer(_tileSource),
    );
    final bounds = controller.buildBoundsFromCenter(
      center,
      area.radiusKm,
    );
    return controller.estimateWorkload(bounds, detail.minZoom, detail.maxZoom);
  }

  Widget _optionButton({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.black12 : null,
          minimumSize: const Size.fromHeight(44),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
      ),
    );
  }

  Widget _regionCard(OfflineRegionMetadata region) {
    final dateText =
        DateFormat('dd.MM.yyyy').format(region.createdAt.toLocal());
    final sourceLabel = tileSourceByKey(region.tileSourceKey).label;
    final radiusKm = region.radiusKm ?? _approxRadiusKm(region);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(region.name),
          const SizedBox(height: 6),
          Text('Område: ${radiusKm.toStringAsFixed(1)} km'),
          Text('Zoom: ${region.minZoom}-${region.maxZoom}'),
          Text('Stil: $sourceLabel'),
          Text('Opprettet: $dateText'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goToRegion(region),
                  child: const Text('Gå til'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmDeleteRegion(region),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Slett'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToRegion(OfflineRegionMetadata region) {
    final bounds = LatLngBounds(
      LatLng(region.minLat, region.minLon),
      LatLng(region.maxLat, region.maxLon),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
    _logOffline('goto', 'region=${region.id}');
    Navigator.of(context).pop();
  }

  Future<void> _confirmDeleteRegion(OfflineRegionMetadata region) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: const Text('Slett kart'),
          content: Text(l10n.map_page_dialog_delete_downloaded_map_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Slett'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await _deleteRegion(region);
  }

  Future<void> _deleteRegion(OfflineRegionMetadata region) async {
    final storeName = region.storeName ??
        TileCacheService.storeFor(tileSourceByKey(region.tileSourceKey))
            .storeName;
    _logOffline('delete-start', 'region=${region.id} store=$storeName');
    try {
      await TileCacheService.ensureStoreReadyByName(storeName);
      await FMTCStore(storeName).manage.reset();
      await _offlineRegionService.removeById(region.id);
      _loadOfflineRegions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kart slettet')),
      );
      _logOffline('delete-done', 'region=${region.id}');
    } catch (e, stackTrace) {
      _logOffline('delete-error', '$e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke slette kart')),
      );
    }
  }

  double _approxRadiusKm(OfflineRegionMetadata region) {
    final latDelta = (region.maxLat - region.minLat) / 2;
    return latDelta * 110.574;
  }

  void _logOffline(String event, String message) {
    debugPrint('[MAP OFFLINE] [$event] $message');
  }

  Widget _offlineStatusChip() {
    final text = _offlineStatusText();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  String _offlineStatusText() {
    if (_downloadProgress != null) {
      return 'Nedlasting: ${_downloadProgress!.toStringAsFixed(0)}%';
    }
    return _isViewportOffline ? 'Offline: Klar ✅' : 'Offline: Ikke lastet';
  }

  bool _shouldShowOfflineUnavailable() {
    if (_isViewportOffline) return false;
    if (_lastTileErrorAt == null) return false;
    return DateTime.now().difference(_lastTileErrorAt!) <=
        const Duration(seconds: 15);
  }

  Widget _offlineUnavailableBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Ikke tilgjengelig offline her',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _logMapUi(String event, [String? details]) {
    if (details == null || details.isEmpty) {
      debugPrint('[MAP UI] $event');
      return;
    }
    debugPrint('[MAP UI] $event $details');
  }

  void _moveMap(LatLng target, double zoom) {
    _isAutoMoving = true;
    _mapController.move(target, zoom);
    Future.microtask(() {
      _isAutoMoving = false;
    });
  }

  void _handleManualMapInteraction(MapEvent event) {
    if (!_followMe || _isAutoMoving) return;
    final reason = _manualReasonForEvent(event);
    if (reason == null) return;
    setState(() {
      _followMe = false;
    });
    _logMapUi('follow_off_manual', 'reason=$reason');
    _positionSub?.cancel();
    _positionSub = null;
  }

  String? _manualReasonForEvent(MapEvent event) {
    if (event is MapEventRotate) return 'rotate';
    if (event is MapEventDoubleTapZoom) return 'double_tap_zoom';
    if (event is MapEventScrollWheelZoom) return 'scroll_zoom';
    if (event is MapEventMove) return 'drag';
    return null;
  }

  TileLayer _buildTileLayer(MapTileSource source) {
    return TileLayer(
      urlTemplate: source.urlTemplate,
      userAgentPackageName: 'com.example.jakthund_app',
      tileProvider: _tileProvider!,
      errorTileCallback: (tile, error, stackTrace) {
        _lastTileErrorAt = DateTime.now();
        _logOffline(
          'tile-error',
          'z=${tile.coordinates.z} x=${tile.coordinates.x} y=${tile.coordinates.y} $error',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_trackPoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: widget.titleSpan != null
              ? Text.rich(widget.titleSpan!)
              : Text(widget.title ?? 'Kart'),
        ),
        body: Center(child: Text(l10n.session_map_error_no_tracks)),
      );
    }
    if (_tileProvider == null) {
      return Scaffold(
        appBar: AppBar(
          title: widget.titleSpan != null
              ? Text.rich(widget.titleSpan!)
              : Text(widget.title ?? 'Kart'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final title = widget.titleSpan != null
        ? Text.rich(widget.titleSpan!)
        : Text(widget.title ?? 'Kart');

    return Scaffold(
      appBar: AppBar(title: title),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _trackPoints.first,
                    initialZoom: 13,
                  ),
                  children: [
                    _buildTileLayer(_tileSource),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _displayPoints,
                          strokeWidth: 4,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _trackPoints.first,
                          width: 40,
                          height: 40,
                          child:
                              const Icon(Icons.play_arrow, color: Colors.green),
                        ),
                        if (_trackPoints.length > 1)
                          Marker(
                            point: _trackPoints.last,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.stop, color: Colors.red),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(_tileSource.attribution),
                      ],
                    ),
                    const Scalebar(
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.all(8),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _offlineStatusChip(),
                ),
                if (_shouldShowOfflineUnavailable())
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: _offlineUnavailableBanner(),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _fitToTrack,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Spor'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _centerOnUser,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Meg'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(_followMe ? 'Følg: På' : 'Følg: Av'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BigActionButton(
                    label: _tileSource.key == terrainTileSource.key
                        ? 'Terreng: På'
                        : 'Terreng: Av',
                    icon: Icons.terrain,
                    onPressed: _isDownloading ? null : _toggleTerrain,
                  ),
                  const SizedBox(height: 12),
                  BigActionButton(
                    label: 'Last ned kart',
                    icon: Icons.download,
                    onPressed: _isDownloading ? null : _showDownloadOptions,
                  ),
                  const SizedBox(height: 12),
                  BigActionButton(
                    label: 'Nedlastede kart',
                    icon: Icons.folder_open,
                    onPressed: _showOfflineRegionsSheet,
                  ),
                  const SizedBox(height: 12),
                  BigActionButton(
                    label: 'Slett offline kart',
                    icon: Icons.delete,
                    isDestructive: true,
                    onPressed: _isDownloading ? null : _deleteOfflineTiles,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaOption {
  const _AreaOption({
    required this.label,
    required this.radiusKm,
  });

  final String label;
  final double radiusKm;
}

class _DetailOption {
  const _DetailOption({
    required this.label,
    required this.minZoom,
    required this.maxZoom,
  });

  final String label;
  final int minZoom;
  final int maxZoom;
}

class _DownloadSelection {
  const _DownloadSelection({
    required this.area,
    required this.detail,
  });

  final _AreaOption area;
  final _DetailOption detail;
}

LatLng _toLatLng(GpsPoint point) => LatLng(point.lat, point.lon);

LatLngBounds calcBounds(List<LatLng> points) => LatLngBounds.fromPoints(points);

LatLng calcCenter(LatLngBounds bounds) => LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );

List<LatLng> _downsampleIfNeeded(List<LatLng> points) {
  const maxPoints = 2000;
  if (points.length <= maxPoints) return points;
  final step = (points.length / maxPoints).ceil();
  return [
    for (var i = 0; i < points.length; i += step) points[i],
  ];
}
