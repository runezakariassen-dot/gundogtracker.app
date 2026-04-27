// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/services/dog_photo_watermark.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

class SessionImageViewerPage extends StatefulWidget {
  const SessionImageViewerPage({
    super.key,
    required this.imagePath,
    this.title,
    this.watermarkDogTitle,
    this.watermarkDogOfficialName,
    this.watermarkDogNickname,
    this.watermarkShowTitle,
    this.watermarkShowOfficialName,
    this.watermarkShowNickname,
    this.watermarkUseDarkText,
    this.dogId,
  });

  final String imagePath;
  final String? title;
  final String? watermarkDogTitle;
  final String? watermarkDogOfficialName;
  final String? watermarkDogNickname;
  final bool? watermarkShowTitle;
  final bool? watermarkShowOfficialName;
  final bool? watermarkShowNickname;
  final bool? watermarkUseDarkText;
  final String? dogId;

  @override
  State<SessionImageViewerPage> createState() => _SessionImageViewerPageState();
}

enum _WatermarkPreset {
  discreet,
  clear,
  contrast,
}

class _SessionImageViewerPageState extends State<SessionImageViewerPage> {
  static const double _overlayInset = 12.0;
  static const double _maxPlateWidth = 280.0;

  bool _colorPrefInitialized = false;
  late bool _showTitle;
  late bool _showOfficialName;
  late bool _showNickname;
  late bool _useDarkText;
  late final Future<ui.Image> _imageInfoFuture;

  Color get _wmFillColor => _useDarkText ? Colors.black : Colors.white;
  double get _wmFillOpacity => _useDarkText ? 0.82 : 0.92;
  Color get _wmStrokeColor => _useDarkText ? Colors.white : Colors.black;
  double get _wmStrokeOpacity => _useDarkText ? 0.55 : 0.45;
  Color get _wmShadowColor =>
      Colors.black.withOpacity(_useDarkText ? 0.18 : 0.35);

  @override
  void initState() {
    super.initState();
    _showTitle = widget.watermarkShowTitle ?? true;
    _showOfficialName = widget.watermarkShowOfficialName ?? true;
    _showNickname = widget.watermarkShowNickname ?? true;
    _useDarkText = widget.watermarkUseDarkText ?? false;
    _imageInfoFuture = _loadImageInfo();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadDogColorPreference());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.title ?? l10n.session_media_section_title;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.dog_detail_watermark_section_title,
            onPressed: _showWatermarkSettings,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.common_close,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: FutureBuilder<ui.Image>(
        future: _imageInfoFuture,
        builder: (context, snapshot) =>
            _buildFutureContent(context, snapshot, l10n),
      ),
    );
  }

  Widget _buildFutureContent(
    BuildContext context,
    AsyncSnapshot<ui.Image> snapshot,
    AppLocalizations l10n,
  ) {
    if (snapshot.hasError || !snapshot.hasData) {
      return _buildPlaceholder(context, l10n);
    }
    final imageInfo = snapshot.data!;
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildInteractiveViewer(context, imageInfo, constraints, l10n),
    );
  }

  Widget _buildInteractiveViewer(
    BuildContext context,
    ui.Image imageInfo,
    BoxConstraints constraints,
    AppLocalizations l10n,
  ) {
    final availWidth = constraints.maxWidth;
    final availHeight = constraints.maxHeight;
    final imageRect = _calculateContainRect(
      availWidth,
      availHeight,
      imageInfo.width.toDouble(),
      imageInfo.height.toDouble(),
    );
    final bottomInset = (availHeight - imageRect.bottom) + _overlayInset;
    final leftInset = imageRect.left + _overlayInset;
    final rightInset = (availWidth - imageRect.right) + _overlayInset + 2;
    final plateMaxWidth = math.min(_maxPlateWidth, imageRect.width * 0.60);
    final stamp = _buildWatermarkStamp(context);
    final plate = _buildWatermarkPlate(context, maxWidth: plateMaxWidth);

    return InteractiveViewer(
      panEnabled: true,
      minScale: 1.0,
      maxScale: 5.0,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: availWidth,
        height: availHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRect(
              rect: imageRect,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => _buildPlaceholder(context, l10n),
              ),
            ),
            Positioned(
              left: leftInset,
              bottom: bottomInset,
              child: IgnorePointer(child: stamp),
            ),
            if (plate != null)
              Positioned(
                right: rightInset,
                bottom: bottomInset,
                child: IgnorePointer(child: plate),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image, size: 48),
        const SizedBox(height: 12),
        Text(
          l10n.session_detail_media_empty_placeholder,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _showWatermarkSettings() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void applyPreset(_WatermarkPreset preset) {
              // Preset definitions (as approved):
              // 1) Discreet: nickname only, light
              // 2) Clear: title + official, light
              // 3) Contrast: title + official, dark
              setSheetState(() {
                switch (preset) {
                  case _WatermarkPreset.discreet:
                    _showTitle = false;
                    _showOfficialName = false;
                    _showNickname = true;
                    _useDarkText = false;
                    break;
                  case _WatermarkPreset.clear:
                    _showTitle = true;
                    _showOfficialName = true;
                    _showNickname = false;
                    _useDarkText = false;
                    break;
                  case _WatermarkPreset.contrast:
                    _showTitle = true;
                    _showOfficialName = true;
                    _showNickname = false;
                    _useDarkText = true;
                    break;
                }
              });

              setState(() {});
              _persistWatermarkPreference();
              HapticFeedback.selectionClick();
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.session_image_viewer_watermark_presets_title,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PresetChip(
                            label: l10n
                                .session_image_viewer_watermark_preset_discreet,
                            icon: Icons.visibility_off,
                            onTap: () => applyPreset(_WatermarkPreset.discreet),
                          ),
                          _PresetChip(
                            label:
                                l10n.session_image_viewer_watermark_preset_clear,
                            icon: Icons.visibility,
                            onTap: () => applyPreset(_WatermarkPreset.clear),
                          ),
                          _PresetChip(
                            label: l10n
                                .session_image_viewer_watermark_preset_contrast,
                            icon: Icons.tonality,
                            onTap: () => applyPreset(_WatermarkPreset.contrast),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                        dense: true,
                        title: Text(
                            l10n.session_image_viewer_watermark_toggle_title),
                        value: _showTitle,
                        onChanged: (value) {
                          setSheetState(() => _showTitle = value);
                          setState(() {});
                          _persistWatermarkPreference();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                        dense: true,
                        title: Text(l10n
                            .session_image_viewer_watermark_toggle_official_name),
                        value: _showOfficialName,
                        onChanged: (value) {
                          setSheetState(() => _showOfficialName = value);
                          setState(() {});
                          _persistWatermarkPreference();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                        dense: true,
                        title: Text(
                            l10n.session_image_viewer_watermark_toggle_nickname),
                        value: _showNickname,
                        onChanged: (value) {
                          setSheetState(() => _showNickname = value);
                          setState(() {});
                          _persistWatermarkPreference();
                        },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.share),
                        label: Text(l10n.dog_detail_watermark_share_button),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _shareWatermarkedImage(l10n);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _persistWatermarkPreference() async {
    final dogId = widget.dogId;
    if (dogId == null) return;
    final box = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    dynamic targetKey;
    Dog? targetDog;
    for (final entry in box.toMap().entries) {
      if (entry.value.id == dogId) {
        targetKey = entry.key;
        targetDog = entry.value;
        break;
      }
    }
    if (targetKey == null || targetDog == null) return;
    final updated = targetDog.copyWith(
      watermarkShowTitle: _showTitle,
      watermarkShowOfficialName: _showOfficialName,
      watermarkShowNickname: _showNickname,
      watermarkUseDarkText: _useDarkText,
      updatedAt: DateTime.now(),
    );
    await box.put(targetKey, updated);
  }

  Future<void> _loadDogColorPreference() async {
    if (_colorPrefInitialized) return;
    final dogId = widget.dogId;
    if (dogId == null) return;
    final box = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    Dog? dog;
    for (final entry in box.toMap().entries) {
      if (entry.value.id == dogId) {
        dog = entry.value;
        break;
      }
    }
    _colorPrefInitialized = true;
    final dogEntry = dog;
    if (dogEntry == null || !mounted) return;
    setState(() => _useDarkText = dogEntry.watermarkUseDarkText);
  }

  Future<void> _shareWatermarkedImage(AppLocalizations l10n) async {
    final file = File(widget.imagePath);
    if (!file.existsSync() || file.lengthSync() == 0) {
      _showShareMissingPhoto(l10n);
      return;
    }
    final lines = _watermarkLines();
    try {
      final rendered = await DogPhotoWatermark().render(
        sourcePath: widget.imagePath,
        lines: lines,
        suffix: '_session_image_share',
      );
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final originRect =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      final origin = (originRect != null &&
              originRect.size.width > 0 &&
              originRect.size.height > 0)
          ? originRect
          : const Rect.fromLTWH(0, 0, 1, 1);
      await Share.shareXFiles(
        [XFile(rendered.path)],
        subject: l10n.dog_detail_watermark_share_subject,
        text: l10n.dog_detail_watermark_share_message,
        sharePositionOrigin: origin,
      );
      HapticFeedback.lightImpact();
    } catch (error, stackTrace) {
      debugPrint('Session image share failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dog_detail_watermark_share_error)),
      );
    }
  }

  void _showShareMissingPhoto(AppLocalizations l10n) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.dog_detail_watermark_share_missing_photo)),
    );
  }

  List<WatermarkLine> _watermarkLines() {
    final lines = <WatermarkLine>[];
    final titleText = widget.watermarkDogTitle?.trim();
    final officialText = widget.watermarkDogOfficialName?.trim();
    final nicknameText = widget.watermarkDogNickname?.trim();
    if (_showTitle && titleText?.isNotEmpty == true) {
      lines.add(WatermarkLine(text: titleText!, isTitle: true));
    }
    if (_showOfficialName && officialText?.isNotEmpty == true) {
      lines.add(WatermarkLine(text: officialText!, isTitle: false));
    }
    if (_showNickname && nicknameText?.isNotEmpty == true) {
      lines.add(WatermarkLine(text: nicknameText!, isTitle: false));
    }
    return lines;
  }

  Widget _buildWatermarkStamp(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontSize: 11,
      height: 1.02,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w600,
    );
    return _stampText(
      '@gundogtracker',
      baseStyle,
      maxLines: 1,
      textAlign: TextAlign.left,
    );
  }

  Widget? _buildWatermarkPlate(BuildContext context,
      {required double maxWidth}) {
    final titleText = widget.watermarkDogTitle?.trim();
    final officialText = widget.watermarkDogOfficialName?.trim();
    final nicknameText = widget.watermarkDogNickname?.trim();
    final showTitleLine = _showTitle && (titleText?.isNotEmpty ?? false);
    final showOfficialLine =
        _showOfficialName && (officialText?.isNotEmpty ?? false);
    final showNicknameLine =
        _showNickname && (nicknameText?.isNotEmpty ?? false);
    if (!showTitleLine && !showOfficialLine && !showNicknameLine) return null;

    final theme = Theme.of(context);
    final titleBaseStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
      fontSize: 12,
      height: 1.05,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w700,
    );
    final nameBaseStyle =
        (theme.textTheme.headlineSmall ?? const TextStyle()).copyWith(
      fontSize: 18,
      height: 1.05,
      fontWeight: FontWeight.w600,
    );
    final nicknameStyle = nameBaseStyle.copyWith(fontSize: 15);

    final plateChildren = <Widget>[];
    if (showTitleLine) {
      final titleFit = _fitText(
        text: titleText!,
        baseStyle: titleBaseStyle,
        maxWidth: maxWidth,
        maxLines: 1,
        minFontSize: 9,
      );
      plateChildren.add(_stampText(
        titleText,
        titleFit.style,
        maxLines: titleFit.maxLines,
        textAlign: TextAlign.end,
      ));
    }
    if (showOfficialLine) {
      final official = officialText!;
      final balanced = _balanceTwoLines(official);
      for (var index = 0; index < balanced.length; index++) {
        if (plateChildren.isNotEmpty)
          plateChildren.add(const SizedBox(height: 1));
        final lineFit = _fitText(
          text: balanced[index],
          baseStyle: nameBaseStyle,
          maxWidth: maxWidth,
          maxLines: 1,
          minFontSize: 12,
        );
        plateChildren.add(_stampText(
          balanced[index],
          lineFit.style,
          maxLines: lineFit.maxLines,
          textAlign: TextAlign.end,
        ));
      }
    }
    if (showNicknameLine) {
      final nickname = nicknameText!;
      if (plateChildren.isNotEmpty)
        plateChildren.add(const SizedBox(height: 1));
      final nicknameFit = _fitText(
        text: nickname,
        baseStyle: nicknameStyle,
        maxWidth: maxWidth,
        maxLines: 1,
        minFontSize: 12,
      );
      plateChildren.add(_stampText(
        nickname,
        nicknameFit.style,
        maxLines: nicknameFit.maxLines,
        textAlign: TextAlign.end,
      ));
    }

    final plate = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: plateChildren,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: math.max(1.0, maxWidth)),
      child: plate,
    );
  }

  Widget _stampText(
    String text,
    TextStyle baseStyle, {
    TextAlign? textAlign,
    int? maxLines,
  }) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _wmStrokeColor.withOpacity(_wmStrokeOpacity)
      ..strokeJoin = StrokeJoin.round;
    final strokeStyle = baseStyle.copyWith(
      color: null,
      foreground: strokePaint,
    );
    final fillStyle = baseStyle.copyWith(
      color: _wmFillColor.withOpacity(_wmFillOpacity),
      shadows: [
        Shadow(
            color: _wmShadowColor, offset: const Offset(0, 1), blurRadius: 2.2),
      ],
    );
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Text(
          text,
          style: strokeStyle,
          maxLines: maxLines,
          overflow: TextOverflow.visible,
          softWrap: true,
          textAlign: textAlign,
        ),
        Text(
          text,
          style: fillStyle,
          maxLines: maxLines,
          overflow: TextOverflow.visible,
          softWrap: true,
          textAlign: textAlign,
        ),
      ],
    );
  }

  _TextFitResult _fitText({
    required String text,
    required TextStyle baseStyle,
    required double maxWidth,
    required int maxLines,
    required double minFontSize,
  }) {
    var fontSize = baseStyle.fontSize ?? 14.0;
    var candidate = baseStyle.copyWith(fontSize: fontSize);
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );
    while (true) {
      painter.text = TextSpan(text: text, style: candidate);
      painter.layout(maxWidth: math.max(1.0, maxWidth));
      final exceedsWidth = painter.width > maxWidth;
      if (!exceedsWidth && !painter.didExceedMaxLines) {
        break;
      }
      final nextSize = math.max(minFontSize, fontSize - 0.8);
      if (nextSize >= fontSize) {
        break;
      }
      fontSize = nextSize;
      candidate = baseStyle.copyWith(fontSize: fontSize);
    }
    return _TextFitResult(candidate, maxLines);
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

  Future<ui.Image> _loadImageInfo() async {
    final file = File(widget.imagePath);
    if (!file.existsSync()) {
      throw FileSystemException('Image not found', widget.imagePath);
    }
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Rect _calculateContainRect(
    double availWidth,
    double availHeight,
    double imageWidth,
    double imageHeight,
  ) {
    if (imageWidth <= 0 || imageHeight <= 0) {
      return Rect.fromLTWH(0, 0, availWidth, availHeight);
    }
    final scale = math.min(availWidth / imageWidth, availHeight / imageHeight);
    final displayWidth = imageWidth * scale;
    final displayHeight = imageHeight * scale;
    final dx = (availWidth - displayWidth) / 2;
    final dy = (availHeight - displayHeight) / 2;
    return Rect.fromLTWH(dx, dy, displayWidth, displayHeight);
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _TextFitResult {
  const _TextFitResult(this.style, this.maxLines);

  final TextStyle style;
  final int maxLines;
}
