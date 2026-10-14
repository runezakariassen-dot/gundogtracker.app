import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../features/map/map_page.dart';
import '../models/gps_point.dart';
import '../models/hunt_session.dart';
import '../models/hunt_event.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';
import '../services/effective_track_resolver.dart';
import '../services/hunt_event_track_resolver.dart';
import '../repositories/hunt_event_repository.dart';
import '../services/hive_lifecycle_service.dart';
import '../data/hive_boxes.dart';
import '../l10n/app_localizations.dart';

class SessionMapPage extends StatefulWidget {
  const SessionMapPage({
    super.key,
    this.sessionId,
    this.trackId,
    this.previewPoints,
    this.title,
    this.titleSpan,
  });

  final String? sessionId;
  final String? trackId;
  final List<GpsPoint>? previewPoints;
  final String? title;
  final InlineSpan? titleSpan;

  @override
  State<SessionMapPage> createState() => _SessionMapPageState();
}

class _SessionMapPageState extends State<SessionMapPage> {
  List<GpsPoint> _points = [];
  bool _isLoading = true;
  String? _error;
  List<HuntEvent> _events = const [];
  late final Box<HuntSession> _sessionsBox;
  late final Box<Track> _tracksBox;
  late final Box<SessionTrackEdit> _trackEditsBox;

  @override
  void initState() {
    super.initState();
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _tracksBox = HiveLifecycleService.getBox<Track>(tracksBoxName);
    _trackEditsBox = HiveLifecycleService.getBox<SessionTrackEdit>(
      sessionTrackEditsBoxName,
    );
    _loadTrack();
  }

  Future<void> _loadTrack() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      List<GpsPoint>? points = widget.previewPoints;
      String? trackId = widget.trackId;
      String? stableSessionId = widget.sessionId;

      if ((points == null || points.isEmpty) && widget.sessionId != null) {
        final sessions = _sessionsBox;
        dynamic key = widget.sessionId;
        final parsed = int.tryParse(widget.sessionId!);
        if (parsed != null) key = parsed;
        final session = sessions.get(key);
        trackId = trackId ?? session?.trackId;
        final modelSessionId = session?.sessionId?.trim();
        if (modelSessionId != null && modelSessionId.isNotEmpty) {
          stableSessionId = modelSessionId;
        }
      }

      Track? rawTrack;
      SessionTrackEdit? trackEdit;
      if ((points == null || points.isEmpty) && trackId != null) {
        final tracksBox = _tracksBox;
        final track = tracksBox.get(trackId);
        if (track != null) {
          rawTrack = track;
          trackEdit = stableSessionId == null
              ? null
              : _trackEditsBox.get(stableSessionId);
          points = const EffectiveTrackResolver()
              .resolve(track, trackEdit)
              .points;
        }
      }

      if (points == null || points.isEmpty) {
        setState(() {
          _error = l10n.session_map_error_no_tracks;
          _isLoading = false;
        });
        return;
      }

      final events = stableSessionId == null
          ? const <HuntEvent>[]
          : HuntEventRepository()
                .listForSession(stableSessionId)
                .where(
                  (event) =>
                      rawTrack == null ||
                      const HuntEventTrackResolver().isVisibleOnEffectiveTrack(
                        event: event,
                        rawTrack: rawTrack,
                        edit: trackEdit,
                      ),
                )
                .toList(growable: false);
      setState(() {
        _points = points!;
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = l10n.session_map_error_map_load_failed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: widget.titleSpan != null
              ? Text.rich(widget.titleSpan!)
              : Text(widget.title ?? l10n.map_title),
        ),
        body: Center(child: Text(_error!)),
      );
    }
    return MapPage(
      points: _points,
      title: widget.title,
      titleSpan: widget.titleSpan,
      events: _events,
    );
  }
}
