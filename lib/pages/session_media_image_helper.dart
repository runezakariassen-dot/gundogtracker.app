import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/pages/session_image_viewer_page.dart';
import 'package:jakthund_app/services/media_storage.dart';

Future<void> openSessionImage({
  required BuildContext context,
  required String storedPath,
  String? displayName,
  String? watermarkDogTitle,
  String? watermarkDogOfficialName,
  String? watermarkDogNickname,
  bool? watermarkShowTitle,
  bool? watermarkShowOfficialName,
  bool? watermarkShowNickname,
  bool? watermarkUseDarkText,
  String? dogId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final validation = MediaStorage.resolveAndValidateMedia(storedPath);
  final resolved = validation?.resolvedPath;
  final exists = validation?.exists ?? false;
  final size = validation?.length ?? 0;
  if (kDebugMode) {
    debugPrint(
      '[IMAGE] open requested path=$storedPath resolved=$resolved exists=$exists size=$size',
    );
  }
  if (resolved == null || !exists || size == 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.session_detail_media_empty_placeholder)),
      );
    }
    return;
  }
  if (!context.mounted) return;
  final name = displayName ?? p.basename(resolved);
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SessionImageViewerPage(
        imagePath: resolved,
        title: name,
        watermarkDogTitle: watermarkDogTitle,
        watermarkDogOfficialName: watermarkDogOfficialName,
        watermarkDogNickname: watermarkDogNickname,
        watermarkShowTitle: watermarkShowTitle,
        watermarkShowOfficialName: watermarkShowOfficialName,
        watermarkShowNickname: watermarkShowNickname,
        watermarkUseDarkText: watermarkUseDarkText,
        dogId: dogId,
      ),
    ),
  );
}
