import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/local/sync_outbox_service.dart';
import '../models/gps_point.dart';
import '../models/hunt_session.dart';
import '../models/track.dart';
import '../repositories/session_track_edit_repository.dart';
import '../services/effective_track_resolver.dart';
import '../services/session_track_edit_save_service.dart';
import '../services/user_identity_service.dart';

class SessionTrackEditPage extends StatefulWidget {
  const SessionTrackEditPage({
    super.key,
    required this.sessionKey,
    required this.session,
    required this.rawTrack,
    required this.canEdit,
    this.editRepository,
    this.outboxService,
  });

  final Object sessionKey;
  final HuntSession session;
  final Track rawTrack;
  final bool canEdit;
  final SessionTrackEditRepository? editRepository;
  final SyncOutboxService? outboxService;

  @override
  State<SessionTrackEditPage> createState() => _SessionTrackEditPageState();
}

class _SessionTrackEditPageState extends State<SessionTrackEditPage> {
  late final SessionTrackEditRepository _repository;
  late final SyncOutboxService _outbox;
  late final SessionTrackEditSaveService _saveService;
  late final String _sessionId;
  late RangeValues _range;
  bool _saving = false;

  int get _pointCount => widget.rawTrack.points.length;
  int get _start => _range.start.round().clamp(0, _pointCount - 1);
  int get _endInclusive => _range.end.round().clamp(_start, _pointCount - 1);
  List<GpsPoint> get _preview => widget.rawTrack.points
      .sublist(_start, _endInclusive + 1)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _repository = widget.editRepository ?? SessionTrackEditRepository();
    _outbox = widget.outboxService ?? SyncOutboxService();
    _sessionId = widget.session.sessionId?.trim().isNotEmpty == true
        ? widget.session.sessionId!.trim()
        : widget.sessionKey.toString();
    _saveService = SessionTrackEditSaveService(
      editRepository: _repository,
      outboxService: _outbox,
    );
    final existing = _repository.get(_sessionId);
    final valid = existing == null
        ? null
        : const EffectiveTrackResolver()
            .validationError(widget.rawTrack, existing);
    final start =
        valid == null && existing != null ? existing.startIndexInclusive : 0;
    final end = valid == null && existing != null
        ? existing.endIndexExclusive - 1
        : _pointCount - 1;
    _range = RangeValues(start.toDouble(), end.toDouble());
  }

  Future<void> _save() async {
    if (!widget.canEdit || _saving) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc();
      await _saveService.save(
        sessionKey: widget.sessionKey,
        session: widget.session,
        rawTrack: widget.rawTrack,
        startIndexInclusive: _start,
        endIndexExclusive: _endInclusive + 1,
        now: now,
        updatedByUserId: _currentUserId(),
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    if (!widget.canEdit || _saving) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc();
      await _saveService.reset(
        sessionKey: widget.sessionKey,
        session: widget.session,
        now: now,
      );
      if (!mounted) return;
      setState(() {
        _range = RangeValues(0, (_pointCount - 1).toDouble());
        _saving = false;
      });
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  String? _currentUserId() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid.trim();
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {}
    final local = UserIdentityService().getCurrentUserId().trim();
    return local.isEmpty ? null : local;
  }

  @override
  Widget build(BuildContext context) {
    final points = _preview;
    final start = points.first.time.toLocal();
    final end = points.last.time.toLocal();
    final duration = end.difference(start);
    final distance = _distanceMeters(points);
    final time = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Rediger økt')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 280,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  key: ValueKey('track-preview-${points.length}'),
                  painter: _TrackPreviewPainter(points),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Start: ${time.formatTimeOfDay(TimeOfDay.fromDateTime(start))}'),
                Text(
                    'Slutt: ${time.formatTimeOfDay(TimeOfDay.fromDateTime(end))}'),
              ],
            ),
            const SizedBox(height: 12),
            if (_pointCount > 1)
              RangeSlider(
                values: _range,
                min: 0,
                max: (_pointCount - 1).toDouble(),
                divisions: _pointCount - 1,
                labels: RangeLabels('${_start + 1}', '${_endInclusive + 1}'),
                onChanged: widget.canEdit && !_saving
                    ? (value) => setState(() => _range = value)
                    : null,
              ),
            Text('GPS-varighet: ${_durationText(duration)}'),
            Text('GPS-distanse: ${(distance / 1000).toStringAsFixed(2)} km'),
            Text('Punkter: ${points.length} av $_pointCount'),
            if (!widget.canEdit) ...[
              const SizedBox(height: 12),
              const Text('Du har lesetilgang, men kan ikke redigere sporet.'),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Avbryt'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.canEdit && !_saving ? _reset : null,
                    child: const Text('Tilbakestill'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.canEdit && !_saving ? _save : null,
                    child: Text(_saving ? 'Lagrer…' : 'Lagre'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _durationText(Duration value) {
  final duration = value.isNegative ? Duration.zero : value;
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours > 0
      ? '$hours t ${minutes.toString().padLeft(2, '0')} min'
      : '$minutes min';
}

double _distanceMeters(List<GpsPoint> points) {
  const earthRadius = 6371000.0;
  var total = 0.0;
  for (var index = 1; index < points.length; index++) {
    final a = points[index - 1];
    final b = points[index];
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLon = (b.lon - a.lon) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    total += earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }
  return total;
}

class _TrackPreviewPainter extends CustomPainter {
  _TrackPreviewPainter(this.points);

  final List<GpsPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xffe8efe7));
    if (points.isEmpty) return;
    final minLat = points.map((p) => p.lat).reduce(math.min);
    final maxLat = points.map((p) => p.lat).reduce(math.max);
    final minLon = points.map((p) => p.lon).reduce(math.min);
    final maxLon = points.map((p) => p.lon).reduce(math.max);
    const padding = 20.0;
    Offset project(GpsPoint point) {
      final xRange = maxLon - minLon;
      final yRange = maxLat - minLat;
      final x = xRange == 0
          ? size.width / 2
          : padding +
              (point.lon - minLon) / xRange * (size.width - padding * 2);
      final y = yRange == 0
          ? size.height / 2
          : size.height -
              padding -
              (point.lat - minLat) / yRange * (size.height - padding * 2);
      return Offset(x, y);
    }

    final path = Path()
      ..moveTo(project(points.first).dx, project(points.first).dy);
    for (final point in points.skip(1)) {
      final offset = project(point);
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xff245d38)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(project(points.first), 7, Paint()..color = Colors.green);
    canvas.drawCircle(project(points.last), 7, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant _TrackPreviewPainter oldDelegate) =>
      oldDelegate.points != points;
}
