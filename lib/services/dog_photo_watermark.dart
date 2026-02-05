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
        lines.add(WatermarkLine(text: name, isTitle: lines.isEmpty));
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
  static const double _cornerRadius = 16;
  static const double _textSpacing = 2;
  static const double _rightMargin = 16;
  static const double _bottomMargin = 16;
  static const double _maxWidthFactor = 0.7;

  WatermarkRenderer({String? fontFamily}) : _fontFamily = fontFamily;

  final String? _fontFamily;

  double _titleFontSize(double width) => _clamp(width * 0.026, 16.0, 38.0);

  TextStyle _titleStyle(double width) => TextStyle(
        color: Colors.white,
        fontSize: _titleFontSize(width),
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        fontFamily: _fontFamily,
      );

  TextStyle _nameStyle(double width) => TextStyle(
        color: Colors.white,
        fontSize: _clamp(width * 0.032, 20.0, 48.0),
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      );

  TextStyle _stampStyle(double width) => TextStyle(
        color: Colors.white.withOpacity(0.70),
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        fontSize: _clamp(width * 0.020, 14.0, 26.0),
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      );

  TextStyle _stampStrokeStyle(double width) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.black.withOpacity(0.70)
      ..strokeJoin = StrokeJoin.round;
    return TextStyle(
      foreground: paint,
      fontSize: _clamp(width * 0.020, 14.0, 26.0),
      fontWeight: FontWeight.w600,
      fontFamily: _fontFamily,
    );
  }

  Future<File> render({
    required String sourcePath,
    required List<WatermarkLine> lines,
    String? suffix,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('Watermark lines must not be empty.');
    }
    final bytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final original = frame.image;
    final width = original.width.toDouble();
    final height = original.height.toDouble();

    final sortedLines = <WatermarkLine>[]
      ..addAll(lines.where((line) => line.isTitle))
      ..addAll(lines.where((line) => !line.isTitle));

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawImage(original, Offset.zero, Paint());

    final measurement = _measure(sortedLines, width);
    final horizontalPadding = _horizontalPadding(width);
    final verticalPadding = _verticalPadding(width);
    final offset = Offset(
      math.max(width - measurement.width - _rightMargin, horizontalPadding),
      math.max(height - measurement.height - _bottomMargin, verticalPadding),
    );
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        offset.dx - horizontalPadding,
        offset.dy - verticalPadding,
        measurement.width + 2 * horizontalPadding,
        measurement.height + 2 * verticalPadding,
      ),
      const Radius.circular(_cornerRadius),
    );

    canvas.drawRRect(
      background,
      Paint()..color = Colors.black.withOpacity(0.42),
    );

    var y = offset.dy;
    for (final painter in measurement.painters) {
      painter.paint(canvas, Offset(offset.dx, y));
      y += painter.height + _textSpacing;
    }

    final picture = recorder.endRecording();
    final firstPassImage = await picture.toImage(original.width, original.height);
    final firstPassBytes = (await firstPassImage.toByteData(
            format: ui.ImageByteFormat.png))
        ?.buffer
        .asUint8List();
    if (firstPassBytes == null) {
      throw StateError('Unable to encode image');
    }

    final secondRecorder = ui.PictureRecorder();
    final secondCanvas = Canvas(secondRecorder, Rect.fromLTWH(0, 0, width, height));
    secondCanvas.drawImage(firstPassImage, Offset.zero, Paint());

    final stampText = '@gundogtracker';
    final strokePainter = TextPainter(
      text: TextSpan(text: stampText, style: _stampStrokeStyle(width)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    final fillPainter = TextPainter(
      text: TextSpan(text: stampText, style: _stampStyle(width)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    const stampMaxFactor = 0.8;
    strokePainter.layout(maxWidth: width * stampMaxFactor);
    fillPainter.layout(maxWidth: width * stampMaxFactor);
    final margin = _stampMargin(width);
    final dx = margin;
    final dy = height - strokePainter.height - margin;
    strokePainter.paint(secondCanvas, Offset(dx, dy));
    fillPainter.paint(secondCanvas, Offset(dx, dy));

    final secondPicture = secondRecorder.endRecording();
    final finalImage = await secondPicture.toImage(original.width, original.height);
    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
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

  Future<Directory> _temporaryDirectory() async {
    try {
      return await getTemporaryDirectory();
    } on MissingPluginException {
      return Directory.systemTemp;
    }
  }

  double _horizontalPadding(double width) =>
      _clamp(width * 0.010, 10.0, 18.0);

  double _verticalPadding(double width) =>
      _clamp(width * 0.008, 8.0, 16.0);

  double _stampMargin(double width) => _clamp(width * 0.010, 10.0, 18.0);

  _WatermarkMeasurement _measure(List<WatermarkLine> lines, double width) {
    final painters = <TextPainter>[];
    final maxLineWidth = math.max(120.0, width * _maxWidthFactor);
    for (final line in lines) {
      final style = line.isTitle ? _titleStyle(width) : _nameStyle(width);
      final painter = TextPainter(
        text: TextSpan(text: line.text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );
      painter.layout(maxWidth: maxLineWidth);
      painters.add(painter);
    }
    final widthResult = painters.fold<double>(
      0.0,
      (previousValue, painter) => math.max(previousValue, painter.width),
    );
    final heightResult = painters.fold<double>(
      0.0,
      (previousValue, painter) => previousValue + painter.height,
    ) + (lines.length - 1) * _textSpacing;
    return _WatermarkMeasurement(widthResult, heightResult, painters);
  }

  double _clamp(double value, double min, double max) =>
      math.min(math.max(value, min), max);
}

class _WatermarkMeasurement {
  _WatermarkMeasurement(this.width, this.height, this.painters);

  final double width;
  final double height;
  final List<TextPainter> painters;
}
