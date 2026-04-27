// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/dog.dart';

class WatermarkPreferences {
  const WatermarkPreferences({
    this.showTitle = true,
    this.showName = true,
  });

  final bool showTitle;
  final bool showName;
}

class WatermarkLine {
  const WatermarkLine({
    required this.text,
    required this.isTitle,
  });

  final String text;
  final bool isTitle;
}

class DogPhotoWatermark {
  static const String _fallbackText = 'GundogTracker';

  DogPhotoWatermark({
    WatermarkRenderer? renderer,
    String? fontFamily,
  }) : _renderer = renderer ?? WatermarkRenderer(fontFamily: fontFamily);

  final WatermarkRenderer _renderer;

  static List<WatermarkLine> linesFor({
    required Dog dog,
    required WatermarkPreferences preferences,
  }) {
    final lines = <WatermarkLine>[];

    if (preferences.showTitle) {
      final title = dog.title?.trim();
      if (title != null && title.isNotEmpty) {
        lines.add(WatermarkLine(text: title.toUpperCase(), isTitle: true));
      }
    }

    if (preferences.showName) {
      final name = dog.displayName.trim();
      if (name.isNotEmpty) {
        lines.add(WatermarkLine(text: name, isTitle: false));
      }
    }

    if (lines.isEmpty) {
      final fallback = dog.name.trim();
      final text = fallback.isNotEmpty ? fallback : _fallbackText;
      lines.add(WatermarkLine(text: text, isTitle: false));
    }

    return lines;
  }

  Future<File> render({
    required String sourcePath,
    required List<WatermarkLine> lines,
    String? suffix,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    return _renderer.render(
      sourcePath: sourcePath,
      lines: lines,
      suffix: suffix,
    );
  }
}

class WatermarkRenderer {
  WatermarkRenderer({String? fontFamily}) : _fontFamily = fontFamily;

  final String? _fontFamily;

  // Viewer "stamp" look: stroke + fill, no background plate.
  // In STEG 4 we MUST match viewer layout, and we cannot read the user's dark/light toggle
  // without UI changes. So we lock to viewer's light variant (white fill + black stroke).
  static const bool _useDarkText = false;

  Color get _wmFillColor => _useDarkText ? Colors.black : Colors.white;
  double get _wmFillOpacity => _useDarkText ? 0.82 : 0.92;
  Color get _wmStrokeColor => _useDarkText ? Colors.white : Colors.black;
  double get _wmStrokeOpacity => _useDarkText ? 0.55 : 0.45;
  Color get _wmShadowColor =>
      Colors.black.withOpacity(_useDarkText ? 0.18 : 0.35);

  // Sizing strategy for export:
  // - Viewer uses fixed dp sizes relative to on-screen imageRect width.
  // - Export must look the same when *viewed* on a phone, which means we scale text
  //   relative to the *image pixels* (NOT capped at 280px).
  //
  // We therefore use proportional sizing and only clamp to keep sane.
  double _titleFont(double w) =>
      _clamp(w * 0.022, 18.0, 70.0); // viewer-ish 12dp
  double _officialFont(double w) =>
      _clamp(w * 0.032, 26.0, 110.0); // viewer-ish 18dp
  double _nicknameFont(double w) =>
      _clamp(w * 0.028, 22.0, 96.0); // viewer-ish 15dp
  double _stampFont(double w) =>
      _clamp(w * 0.020, 18.0, 72.0); // viewer-ish 11dp

  TextStyle _baseFillStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      height: 1.05,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: _wmFillColor.withOpacity(_wmFillOpacity),
      fontFamily: _fontFamily,
      shadows: [
        Shadow(
          color: _wmShadowColor,
          offset: const Offset(0, 1),
          blurRadius: 2.2,
        ),
      ],
    );
  }

  TextStyle _baseStrokeStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
  }) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _wmStrokeColor.withOpacity(_wmStrokeOpacity)
      ..strokeJoin = StrokeJoin.round;

    return TextStyle(
      fontSize: fontSize,
      height: 1.05,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: null,
      foreground: strokePaint,
      fontFamily: _fontFamily,
    );
  }

  Future<File> render({
    required String sourcePath,
    required List<WatermarkLine> lines,
    String? suffix,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final original = frame.image;

    final width = original.width.toDouble();
    final height = original.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawImage(original, Offset.zero, Paint());

    final inset = _clamp(width * 0.012, 10.0, 24.0);
    final bottomY = height - inset;

    // Bottom-left stamp
    _paintStamp(canvas: canvas, w: width, bottomY: bottomY, leftX: inset);

    // Bottom-right plate content (no background)
    final plateMaxWidth = width * 0.60; // IMPORTANT: no absolute cap in export
    final plate = _layoutPlate(lines: lines, w: width, maxWidth: plateMaxWidth);

    if (plate.isNotEmpty) {
      final plateWidth = plate.fold<double>(
        0.0,
        (prev, e) => math.max(prev, e.lineWidth),
      );

      final lineGap = _clamp(width * 0.0025, 1.0, 6.0);

      final plateHeight = plate.fold<double>(
            0.0,
            (prev, e) => prev + e.height,
          ) +
          (plate.length - 1) * lineGap;

      final dx = math.max(0.0, width - inset - plateWidth);
      final dy = math.max(0.0, height - inset - plateHeight);

      var y = dy;
      for (final line in plate) {
        line.paintRightAligned(canvas, Offset(dx, y), plateWidth);
        y += line.height + lineGap;
      }
    }

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(original.width, original.height);

    final byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to encode image');
    }
    final outputBytes = byteData.buffer.asUint8List();

    final tempDir = await _temporaryDirectory();
    final fileName =
        suffix ?? 'dog_watermark_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(outputBytes);
    return file;
  }

  void _paintStamp({
    required Canvas canvas,
    required double w,
    required double bottomY,
    required double leftX,
  }) {
    const text = '@gundogtracker';

    final fontSize = _stampFont(w);

    final fillStyle = _baseFillStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    final strokeStyle = _baseStrokeStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    final strokePainter = TextPainter(
      text: TextSpan(text: text, style: strokeStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: null,
    )..layout(maxWidth: w * 0.80);

    final fillPainter = TextPainter(
      text: TextSpan(text: text, style: fillStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: null,
    )..layout(maxWidth: w * 0.80);

    final dy = math.max(0.0, bottomY - strokePainter.height);
    strokePainter.paint(canvas, Offset(leftX, dy));
    fillPainter.paint(canvas, Offset(leftX, dy));
  }

  List<_DualLine> _layoutPlate({
    required List<WatermarkLine> lines,
    required double w,
    required double maxWidth,
  }) {
    final cleaned = <WatermarkLine>[];
    for (final l in lines) {
      final t = l.text.trim();
      if (t.isEmpty) continue;
      cleaned.add(WatermarkLine(text: t, isTitle: l.isTitle));
    }
    if (cleaned.isEmpty) return const [];

    // Mirror viewer order: title (optional), official (optional), nickname (optional)
    final title = cleaned.where((e) => e.isTitle).map((e) => e.text).toList();
    final names = cleaned.where((e) => !e.isTitle).map((e) => e.text).toList();

    // Viewer logic for official name: balance into 1–2 lines
    // The viewer treats first name line as "official" and second as "nickname".
    final official = names.isNotEmpty ? names[0] : null;
    final nickname = names.length >= 2 ? names[1] : null;

    final result = <_DualLine>[];

    // Title (1 line)
    for (final t in title) {
      final baseSize = _titleFont(w);
      final fit = _fitSingleLine(
        text: t,
        maxWidth: maxWidth,
        baseFontSize: baseSize,
        minFontSize: _clamp(baseSize * 0.70, 10.0, baseSize),
        fontWeight: FontWeight.w700,
      );
      result.add(
        _DualLine(
          text: t,
          fontSize: fit,
          fontWeight: FontWeight.w700,
          fillStyle: _baseFillStyle(
            fontSize: fit,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          strokeStyle: _baseStrokeStyle(
            fontSize: fit,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          maxWidth: maxWidth,
        ),
      );
    }

    // Official (1–2 balanced lines, each rendered as single line)
    if (official != null && official.trim().isNotEmpty) {
      final balanced = _balanceTwoLines(official.trim());
      for (final line in balanced) {
        final baseSize = _officialFont(w);
        final fit = _fitSingleLine(
          text: line,
          maxWidth: maxWidth,
          baseFontSize: baseSize,
          minFontSize: _clamp(baseSize * 0.65, 12.0, baseSize),
          fontWeight: FontWeight.w600,
        );
        result.add(
          _DualLine(
            text: line,
            fontSize: fit,
            fontWeight: FontWeight.w600,
            fillStyle: _baseFillStyle(
              fontSize: fit,
              fontWeight: FontWeight.w600,
            ),
            strokeStyle: _baseStrokeStyle(
              fontSize: fit,
              fontWeight: FontWeight.w600,
            ),
            maxWidth: maxWidth,
          ),
        );
      }
    }

    // Nickname (1 line)
    if (nickname != null && nickname.trim().isNotEmpty) {
      final txt = nickname.trim();
      final baseSize = _nicknameFont(w);
      final fit = _fitSingleLine(
        text: txt,
        maxWidth: maxWidth,
        baseFontSize: baseSize,
        minFontSize: _clamp(baseSize * 0.65, 12.0, baseSize),
        fontWeight: FontWeight.w600,
      );
      result.add(
        _DualLine(
          text: txt,
          fontSize: fit,
          fontWeight: FontWeight.w600,
          fillStyle: _baseFillStyle(
            fontSize: fit,
            fontWeight: FontWeight.w600,
          ),
          strokeStyle: _baseStrokeStyle(
            fontSize: fit,
            fontWeight: FontWeight.w600,
          ),
          maxWidth: maxWidth,
        ),
      );
    }

    // If we only got ONE name line (no nickname), render it too (important)
    if (names.length == 1 && (official == null || official.trim().isEmpty)) {
      final txt = names.first.trim();
      final baseSize = _officialFont(w);
      final fit = _fitSingleLine(
        text: txt,
        maxWidth: maxWidth,
        baseFontSize: baseSize,
        minFontSize: _clamp(baseSize * 0.65, 12.0, baseSize),
        fontWeight: FontWeight.w600,
      );
      result.add(
        _DualLine(
          text: txt,
          fontSize: fit,
          fontWeight: FontWeight.w600,
          fillStyle: _baseFillStyle(
            fontSize: fit,
            fontWeight: FontWeight.w600,
          ),
          strokeStyle: _baseStrokeStyle(
            fontSize: fit,
            fontWeight: FontWeight.w600,
          ),
          maxWidth: maxWidth,
        ),
      );
    }

    return result;
  }

  double _fitSingleLine({
    required String text,
    required double maxWidth,
    required double baseFontSize,
    required double minFontSize,
    required FontWeight fontWeight,
  }) {
    var fontSize = baseFontSize;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: null, // never
    );

    while (true) {
      final style = TextStyle(
        fontSize: fontSize,
        height: 1.05,
        fontWeight: fontWeight,
        fontFamily: _fontFamily,
      );

      painter.text = TextSpan(text: text, style: style);
      painter.layout(maxWidth: math.max(1.0, maxWidth));

      if (painter.width <= maxWidth) break;

      final next = math.max(minFontSize, fontSize - 0.8);
      if (next >= fontSize) break;
      fontSize = next;
    }

    return fontSize;
  }

  List<String> _balanceTwoLines(String text) {
    final words =
        text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.length <= 1) return [text];

    var best = <String>[text];
    var bestDiff = double.infinity;

    for (var split = 1; split < words.length; split++) {
      final first = words.sublist(0, split).join(' ');
      final second = words.sublist(split).join(' ');
      final diff = (first.length - second.length).abs().toDouble();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = [first, second];
      }
    }

    return best;
  }

  Future<Directory> _temporaryDirectory() async {
    try {
      return await getTemporaryDirectory();
    } on MissingPluginException {
      return Directory.systemTemp;
    }
  }

  double _clamp(double value, double min, double max) =>
      math.min(math.max(value, min), max);
}

class _DualLine {
  _DualLine({
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.fillStyle,
    required this.strokeStyle,
    required this.maxWidth,
  }) {
    _strokePainter = TextPainter(
      text: TextSpan(text: text, style: strokeStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: null,
    )..layout(maxWidth: math.max(1.0, maxWidth));

    _fillPainter = TextPainter(
      text: TextSpan(text: text, style: fillStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: null,
    )..layout(maxWidth: math.max(1.0, maxWidth));
  }

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextStyle fillStyle;
  final TextStyle strokeStyle;
  final double maxWidth;

  late final TextPainter _strokePainter;
  late final TextPainter _fillPainter;

  double get height => math.max(_strokePainter.height, _fillPainter.height);
  double get lineWidth => math.max(_strokePainter.width, _fillPainter.width);

  void paintRightAligned(Canvas canvas, Offset topLeft, double plateWidth) {
    final dx = topLeft.dx + (plateWidth - lineWidth);
    final dy = topLeft.dy;
    _strokePainter.paint(canvas, Offset(dx, dy));
    _fillPainter.paint(canvas, Offset(dx, dy));
  }
}
