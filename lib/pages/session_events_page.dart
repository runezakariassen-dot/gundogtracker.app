import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import '../models/gps_point.dart';
import '../models/hunt_event.dart';
import '../models/hunt_session.dart';
import '../models/session_track_edit.dart';
import '../models/track.dart';
import '../repositories/hunt_event_repository.dart';
import '../services/hunt_event_track_resolver.dart';
import '../services/user_identity_service.dart';
import '../ui/hunt_event_labels.dart';
import '../l10n/app_localizations.dart';

class SessionEventsPage extends StatefulWidget {
  const SessionEventsPage({
    super.key,
    required this.sessionKey,
    required this.session,
    required this.canEdit,
    this.repository,
    this.currentUserId,
  });

  final Object sessionKey;
  final HuntSession session;
  final bool canEdit;
  final HuntEventRepository? repository;
  final String Function()? currentUserId;

  @override
  State<SessionEventsPage> createState() => _SessionEventsPageState();
}

class _SessionEventsPageState extends State<SessionEventsPage> {
  late final HuntEventRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HuntEventRepository();
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
          rawTrack: track,
          trackEdit: _trackEdit,
          event: event,
          canEdit: widget.canEdit,
          repository: _repository,
          currentUserId: widget.currentUserId,
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
                final outside =
                    track != null &&
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
    required this.rawTrack,
    required this.trackEdit,
    required this.canEdit,
    required this.repository,
    this.currentUserId,
    this.event,
  });

  final HuntSession session;
  final String sessionId;
  final Track rawTrack;
  final SessionTrackEdit? trackEdit;
  final HuntEvent? event;
  final bool canEdit;
  final HuntEventRepository repository;
  final String Function()? currentUserId;

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

  @override
  void initState() {
    super.initState();
    _selection = const HuntEventTrackResolver().selection(
      widget.rawTrack,
      widget.trackEdit,
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

  void _onTrackTap(TapDownDetails details, Size size) {
    if (!widget.canEdit || _selection.points.isEmpty) return;
    final layout = _EventTrackLayout(points: _selection.points, size: size);
    final nearestIndex = layout.nearestIndexForTap(
      details.localPosition,
      pointSnapRadiusPx: 44,
      lineSnapRadiusPx: 28,
      maxSnapDistancePx: 84,
    );
    if (nearestIndex == null) return;
    setState(() => _index = nearestIndex.toDouble());
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
      id: existing?.id ?? const Uuid().v4(),
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
    await widget.repository.upsert(event);
    if (mounted) Navigator.pop(context);
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _species.dispose();
    _note.dispose();
    super.dispose();
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<HuntEventType>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l10n.hunt_event_field_type),
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
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      key: const ValueKey('hunt-event-track-preview-tap-area'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: readOnly
                          ? null
                          : (details) => _onTrackTap(details, size),
                      child: CustomPaint(
                        key: ValueKey('event-track-preview-${_index.round()}'),
                        painter: _EventTrackPainter(
                          _selection.points,
                          _index.round(),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    );
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
              onChanged: readOnly
                  ? null
                  : (value) => setState(() => _index = value),
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
          if (!readOnly) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.common_cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('save-hunt-event'),
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving ? l10n.hunt_event_saving : l10n.hunt_event_save,
                  ),
                ),
              ],
            ),
          ],
        ],
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

class _EventTrackPainter extends CustomPainter {
  const _EventTrackPainter(this.points, this.selectedIndex);
  final List<GpsPoint> points;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || selectedIndex < 0 || selectedIndex >= points.length) {
      return;
    }
    final layout = _EventTrackLayout(points: points, size: size);
    final path = Path()
      ..moveTo(
        layout.offsetForPoint(points.first).dx,
        layout.offsetForPoint(points.first).dy,
      );
    for (final point in points.skip(1)) {
      final value = layout.offsetForPoint(point);
      path.lineTo(value.dx, value.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      layout.offsetForPoint(points[selectedIndex]),
      8,
      Paint()..color = Colors.red,
    );
  }

  @override
  bool shouldRepaint(_EventTrackPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.points != points;
}

class _EventTrackLayout {
  const _EventTrackLayout({required this.points, required this.size});

  final List<GpsPoint> points;
  final Size size;
  static const double _padding = 16;

  Offset offsetForPoint(GpsPoint point) {
    final minLat = points.map((p) => p.lat).reduce(math.min);
    final maxLat = points.map((p) => p.lat).reduce(math.max);
    final minLon = points.map((p) => p.lon).reduce(math.min);
    final maxLon = points.map((p) => p.lon).reduce(math.max);
    return Offset(
      _padding +
          (point.lon - minLon) /
              ((maxLon - minLon).abs() + 0.0000001) *
              (size.width - (_padding * 2)),
      size.height -
          _padding -
          (point.lat - minLat) /
              ((maxLat - minLat).abs() + 0.0000001) *
              (size.height - (_padding * 2)),
    );
  }

  int? nearestIndexForTap(
    Offset tap, {
    required double pointSnapRadiusPx,
    required double lineSnapRadiusPx,
    required double maxSnapDistancePx,
  }) {
    if (points.isEmpty) return null;
    int nearestIndex = 0;
    var nearestPointDistanceSquared = double.infinity;
    final projected = points.map(offsetForPoint).toList(growable: false);
    for (var index = 0; index < projected.length; index++) {
      final distanceSquared = (projected[index] - tap).distanceSquared;
      if (distanceSquared < nearestPointDistanceSquared) {
        nearestPointDistanceSquared = distanceSquared;
        nearestIndex = index;
      }
    }

    final pointSnapRadiusSquared = pointSnapRadiusPx * pointSnapRadiusPx;
    if (nearestPointDistanceSquared <= pointSnapRadiusSquared) {
      return nearestIndex;
    }

    var nearestLineDistanceSquared = double.infinity;
    for (var index = 1; index < projected.length; index++) {
      final segmentDistanceSquared = _distanceSquaredToSegment(
        point: tap,
        start: projected[index - 1],
        end: projected[index],
      );
      if (segmentDistanceSquared < nearestLineDistanceSquared) {
        nearestLineDistanceSquared = segmentDistanceSquared;
      }
    }
    final lineSnapRadiusSquared = lineSnapRadiusPx * lineSnapRadiusPx;
    if (nearestLineDistanceSquared <= lineSnapRadiusSquared) {
      return nearestIndex;
    }

    final maxSnapDistanceSquared = maxSnapDistancePx * maxSnapDistancePx;
    if (nearestPointDistanceSquared <= maxSnapDistanceSquared) {
      return nearestIndex;
    }
    return null;
  }

  double _distanceSquaredToSegment({
    required Offset point,
    required Offset start,
    required Offset end,
  }) {
    final segment = end - start;
    final segmentLengthSquared =
        segment.dx * segment.dx + segment.dy * segment.dy;
    if (segmentLengthSquared == 0) {
      return (point - start).distanceSquared;
    }
    final t =
        (((point.dx - start.dx) * segment.dx) +
            ((point.dy - start.dy) * segment.dy)) /
        segmentLengthSquared;
    final clampedT = t.clamp(0.0, 1.0);
    final projection = Offset(
      start.dx + (segment.dx * clampedT),
      start.dy + (segment.dy * clampedT),
    );
    return (point - projection).distanceSquared;
  }
}
