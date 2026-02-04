import 'dart:io';

import 'package:flutter/material.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';

class SessionImageViewerPage extends StatelessWidget {
  const SessionImageViewerPage({
    super.key,
    required this.imagePath,
    this.title,
  });

  final String imagePath;
  final String? title;

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
        child: Center(
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
}
