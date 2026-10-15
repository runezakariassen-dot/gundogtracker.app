import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/gps_point.dart';

class HuntReplayFrame {
  const HuntReplayFrame({
    required this.latitude,
    required this.longitude,
    required this.elapsed,
  });

  final double latitude;
  final double longitude;
  final Duration elapsed;
}

class HuntReplayTimeline {
  HuntReplayTimeline(List<GpsPoint> points)
      : points = UnmodifiableListView<GpsPoint>(points),
        _offsets = _buildOffsets(points);

  final UnmodifiableListView<GpsPoint> points;
  final List<Duration> _offsets;

  bool get isEmpty => points.isEmpty;
  Duration get totalDuration =>
      _offsets.isEmpty ? Duration.zero : _offsets.last;

  HuntReplayFrame? frameAt(Duration requestedElapsed) {
    if (points.isEmpty) return null;
    if (points.length == 1 || totalDuration == Duration.zero) {
      final point =
          requestedElapsed > Duration.zero ? points.last : points.first;
      return HuntReplayFrame(
        latitude: point.lat,
        longitude: point.lon,
        elapsed: Duration.zero,
      );
    }

    final elapsed = _clamp(requestedElapsed, Duration.zero, totalDuration);
    var low = 0;
    var high = _offsets.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_offsets[middle] <= elapsed) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final nextIndex = low.clamp(1, points.length - 1);
    final previousIndex = nextIndex - 1;
    final startOffset = _offsets[previousIndex];
    final endOffset = _offsets[nextIndex];
    final segmentMicros = (endOffset - startOffset).inMicroseconds;
    if (segmentMicros <= 0) {
      final point = points[nextIndex];
      return HuntReplayFrame(
        latitude: point.lat,
        longitude: point.lon,
        elapsed: elapsed,
      );
    }
    final fraction = (elapsed - startOffset).inMicroseconds / segmentMicros;
    final start = points[previousIndex];
    final end = points[nextIndex];
    return HuntReplayFrame(
      latitude: start.lat + ((end.lat - start.lat) * fraction),
      longitude: start.lon + ((end.lon - start.lon) * fraction),
      elapsed: elapsed,
    );
  }

  static List<Duration> _buildOffsets(List<GpsPoint> points) {
    if (points.isEmpty) return const [];
    final firstMicros = points.first.time.toUtc().microsecondsSinceEpoch;
    var previous = Duration.zero;
    return List<Duration>.generate(points.length, (index) {
      final micros =
          points[index].time.toUtc().microsecondsSinceEpoch - firstMicros;
      final candidate = Duration(microseconds: micros < 0 ? 0 : micros);
      if (candidate < previous) return previous;
      previous = candidate;
      return candidate;
    }, growable: false);
  }
}

class HuntReplayController extends ChangeNotifier {
  HuntReplayController(
    List<GpsPoint> points, {
    double initialSpeed = 50,
    Duration tickInterval = const Duration(milliseconds: 50),
  })  : timeline = HuntReplayTimeline(points),
        _speed = initialSpeed,
        _tickInterval = tickInterval;

  static const List<double> supportedSpeeds = [1, 10, 25, 50, 100, 250, 500];

  final HuntReplayTimeline timeline;
  final Duration _tickInterval;
  Timer? _timer;
  Stopwatch? _stopwatch;
  Duration _anchorElapsed = Duration.zero;
  Duration _elapsed = Duration.zero;
  double _speed;
  bool _playing = false;

  Duration get elapsed => _elapsed;
  Duration get totalDuration => timeline.totalDuration;
  HuntReplayFrame? get frame => timeline.frameAt(_elapsed);
  double get speed => _speed;
  bool get isPlaying => _playing;
  double get progress => totalDuration == Duration.zero
      ? 0
      : _elapsed.inMicroseconds / totalDuration.inMicroseconds;

  void play() {
    if (timeline.isEmpty || _playing) return;
    if (_elapsed >= totalDuration && totalDuration > Duration.zero) {
      _elapsed = Duration.zero;
    }
    if (totalDuration == Duration.zero) {
      notifyListeners();
      return;
    }
    _anchorElapsed = _elapsed;
    _stopwatch = Stopwatch()..start();
    _playing = true;
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) => _tick());
    notifyListeners();
  }

  void pause() {
    if (!_playing) return;
    _updateFromStopwatch();
    _stopPlayback();
    notifyListeners();
  }

  void seekToProgress(double value) {
    final progress = value.clamp(0.0, 1.0);
    _elapsed = Duration(
      microseconds: (totalDuration.inMicroseconds * progress).round(),
    );
    if (_playing) _restartClock();
    notifyListeners();
  }

  void setSpeed(double value) {
    if (!supportedSpeeds.contains(value) || value == _speed) return;
    if (_playing) _updateFromStopwatch();
    _speed = value;
    if (_playing) _restartClock();
    notifyListeners();
  }

  @visibleForTesting
  void advanceBy(Duration realTime) {
    if (!_playing) return;
    _elapsed = _clamp(
      _elapsed + _scaled(realTime, _speed),
      Duration.zero,
      totalDuration,
    );
    if (_elapsed >= totalDuration) _stopPlayback();
    notifyListeners();
  }

  void _tick() {
    if (!_playing) return;
    _updateFromStopwatch();
    if (_elapsed >= totalDuration) _stopPlayback();
    notifyListeners();
  }

  void _updateFromStopwatch() {
    final stopwatch = _stopwatch;
    if (stopwatch == null) return;
    _elapsed = _clamp(
      _anchorElapsed + _scaled(stopwatch.elapsed, _speed),
      Duration.zero,
      totalDuration,
    );
  }

  void _restartClock() {
    _anchorElapsed = _elapsed;
    _stopwatch = Stopwatch()..start();
  }

  void _stopPlayback() {
    _playing = false;
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    _stopwatch = null;
  }

  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }
}

Duration _scaled(Duration duration, double factor) => Duration(
      microseconds: (duration.inMicroseconds * factor).round(),
    );

Duration _clamp(Duration value, Duration minimum, Duration maximum) {
  if (value < minimum) return minimum;
  if (value > maximum) return maximum;
  return value;
}
