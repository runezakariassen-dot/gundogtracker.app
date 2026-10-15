import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:jakthund_app/services/media_storage.dart';

/// Resolves the persisted representation of session media immediately before
/// it is handed to an image decoder or platform video player.
///
/// Callers may supply canonical relative paths or legacy absolute paths. A
/// successful result always contains an absolute, existing, non-empty file.
Future<MediaStorageValidation?> resolveSessionMediaForOpening({
  required String storedPath,
  required String mediaKind,
  String stage = 'resolve',
}) async {
  MediaStorageValidation? validation;
  try {
    validation = await MediaStorage.validatePersistedMedia(storedPath);
    final resolved = validation?.resolvedPath;
    final valid = resolved != null &&
        p.isAbsolute(resolved) &&
        validation!.exists &&
        validation.length > 0;
    if (kDebugMode) {
      debugPrint(
        '[SESSION_MEDIA] kind=$mediaKind stage=$stage stored=$storedPath '
        'resolved=$resolved extension=${p.extension(resolved ?? storedPath).toLowerCase()} '
        'exists=${validation?.exists ?? false} size=${validation?.length ?? 0} '
        'valid=$valid',
      );
    }
    return valid ? validation : null;
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        '[SESSION_MEDIA] kind=$mediaKind stage=$stage stored=$storedPath '
        'resolved=${validation?.resolvedPath} '
        'extension=${p.extension(validation?.resolvedPath ?? storedPath).toLowerCase()} '
        'exists=${validation?.exists} size=${validation?.length} '
        'error=$error stackTrace=$stackTrace',
      );
    }
    return null;
  }
}
