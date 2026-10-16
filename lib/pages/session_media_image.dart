import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:jakthund_app/services/media_storage.dart';

@immutable
class SessionMediaDecodeSize {
  const SessionMediaDecodeSize({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}

class SessionMediaImagePolicy {
  const SessionMediaImagePolicy._();

  static const int thumbnailMaxDimension = 512;
  static const int fullScreenMaxDimension = 2560;

  static SessionMediaDecodeSize decodeSize({
    required double logicalWidth,
    required double logicalHeight,
    required double devicePixelRatio,
    required bool fullScreen,
  }) {
    final safeWidth = logicalWidth.isFinite ? math.max(1.0, logicalWidth) : 1.0;
    final safeHeight =
        logicalHeight.isFinite ? math.max(1.0, logicalHeight) : 1.0;
    final safeDpr =
        devicePixelRatio.isFinite ? devicePixelRatio.clamp(1.0, 4.0) : 1.0;
    var width = safeWidth * safeDpr;
    var height = safeHeight * safeDpr;
    final maxDimension =
        fullScreen ? fullScreenMaxDimension : thumbnailMaxDimension;
    final longest = math.max(width, height);
    if (longest > maxDimension) {
      final scale = maxDimension / longest;
      width *= scale;
      height *= scale;
    }
    return SessionMediaDecodeSize(
      width: math.max(1, width.round()),
      height: math.max(1, height.round()),
    );
  }
}

/// Memory-bounded, file-backed image for persisted session media.
///
/// The stored path is resolved through [MediaStorage]. The compressed file is
/// never copied into a Dart byte buffer, and every decode has explicit target
/// dimensions based on its rendered size and the device pixel ratio.
class SessionMediaImage extends StatefulWidget {
  const SessionMediaImage({
    super.key,
    required this.storedPath,
    required this.displayWidth,
    required this.displayHeight,
    this.fullScreen = false,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.evictOnDispose = false,
  });

  final String storedPath;
  final double displayWidth;
  final double displayHeight;
  final bool fullScreen;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Widget? placeholder;
  final bool evictOnDispose;

  @override
  State<SessionMediaImage> createState() => _SessionMediaImageState();
}

class _SessionMediaImageState extends State<SessionMediaImage> {
  ImageProvider? _provider;
  String? _providerPath;
  SessionMediaDecodeSize? _providerSize;

  @override
  Widget build(BuildContext context) {
    final validation = MediaStorage.resolveAndValidateMedia(widget.storedPath);
    if (validation?.exists != true || validation!.length <= 0) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    final decodeSize = SessionMediaImagePolicy.decodeSize(
      logicalWidth: widget.displayWidth,
      logicalHeight: widget.displayHeight,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      fullScreen: widget.fullScreen,
    );
    if (_provider == null ||
        _providerPath != validation.resolvedPath ||
        _providerSize?.width != decodeSize.width ||
        _providerSize?.height != decodeSize.height) {
      _evictProvider();
      _providerPath = validation.resolvedPath;
      _providerSize = decodeSize;
      _provider = ResizeImage.resizeIfNeeded(
        decodeSize.width,
        decodeSize.height,
        FileImage(File(validation.resolvedPath)),
      );
    }
    return Image(
      image: _provider!,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder: (_, __, ___) =>
          widget.placeholder ?? const SizedBox.shrink(),
    );
  }

  void _evictProvider() {
    if (widget.evictOnDispose) _provider?.evict();
  }

  @override
  void dispose() {
    _evictProvider();
    super.dispose();
  }
}
