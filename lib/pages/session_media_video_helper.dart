import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/pages/session_video_player_page.dart';
import 'package:jakthund_app/services/media_storage.dart';

Future<void> openSessionVideo({
  required BuildContext context,
  required String storedPath,
  String? displayName,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final validation = await MediaStorage.validatePersistedMedia(storedPath);
  final resolved = validation?.resolvedPath;
  final exists = validation?.exists ?? false;
  final size = validation?.length ?? 0;
  if (kDebugMode) {
    debugPrint(
      '[VIDEO] open requested path=$storedPath resolved=$resolved exists=$exists size=$size',
    );
  }
  if (resolved == null || !exists || size == 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.session_media_video_missing)),
      );
    }
    return;
  }
  if (!context.mounted) return;
  final name = displayName ?? p.basename(resolved);
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SessionVideoPlayerPage(
        videoPath: resolved,
        displayName: name,
      ),
    ),
  );
}
