import 'dart:io';

import 'package:flutter/material.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';

class SessionImageViewerPage extends StatelessWidget {
  const SessionImageViewerPage({
    super.key,
    required this.imagePath,
    this.title,
    this.watermarkDogTitle,
    this.watermarkDogName,
    this.watermarkShowTitle,
    this.watermarkShowName,
  });

  final String imagePath;
  final String? title;
  final String? watermarkDogTitle;
  final String? watermarkDogName;
  final bool? watermarkShowTitle;
  final bool? watermarkShowName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayTitle = title ?? l10n.session_media_section_title;
    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: l10n.common_close,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 5.0,
                clipBehavior: Clip.hardEdge,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(context, l10n),
                ),
              ),
            ),
            _buildWatermarkOverlay(context),
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

  Widget _buildWatermarkOverlay(BuildContext context) {
    final titleText = watermarkDogTitle?.trim();
    final nameText = watermarkDogName?.trim();
    final theme = Theme.of(context);
    final showTitleToggle = watermarkShowTitle ?? true;
    final showNameToggle = watermarkShowName ?? true;
    var showTitle = showTitleToggle && (titleText?.isNotEmpty ?? false);
    var showName = showNameToggle && (nameText?.isNotEmpty ?? false);
    if (!showTitle && !showName && (nameText?.isNotEmpty ?? false)) {
      showName = true;
    }
    if (!showTitle && !showName) {
      return const SizedBox.shrink();
    }

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: Colors.white,
      letterSpacing: 0.8,
    );
    final nameStyle = theme.textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final stampStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white70,
      letterSpacing: 0.6,
    );

    return Positioned(
      bottom: 16,
      right: 16,
      left: 16,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.42),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTitle)
                  Text(
                    titleText!,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (showName)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      nameText!,
                      style: nameStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '@gundogtracker',
                    style: stampStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
