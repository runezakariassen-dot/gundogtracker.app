import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/pages/session_media_opening.dart';
import 'package:jakthund_app/services/media_storage.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory documents;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('session_media_open_');
    MediaStorage.setDocumentsDirectoryForTesting(documents.path);
  });

  tearDown(() async {
    MediaStorage.setDocumentsDirectoryForTesting(null);
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  for (final entry in const {
    'jpg': 'image',
    'png': 'image',
    'heic': 'image',
    'mov': 'video',
    'mp4': 'video',
  }.entries) {
    test('relative ${entry.key} resolves to an absolute non-empty file',
        () async {
      final relative = 'media/dogs/dog/sessions/session/media.${entry.key}';
      final file = File(p.joinAll([documents.path, ...relative.split('/')]));
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1, 2, 3]);

      final result = await resolveSessionMediaForOpening(
        storedPath: relative,
        mediaKind: entry.value,
      );

      expect(result, isNotNull);
      expect(result!.resolvedPath, file.path);
      expect(p.isAbsolute(result.resolvedPath), isTrue);
      expect(result.length, 3);
    });
  }

  test('legacy absolute iOS media path rebases to the current sandbox',
      () async {
    const relative = 'media/dogs/dog/sessions/session/legacy.jpg';
    final currentFile =
        File(p.joinAll([documents.path, ...relative.split('/')]));
    await currentFile.parent.create(recursive: true);
    await currentFile.writeAsBytes([1]);

    final result = await resolveSessionMediaForOpening(
      storedPath:
          '/private/var/mobile/Containers/Data/Application/OLD/Documents/$relative',
      mediaKind: 'image',
    );

    expect(result?.resolvedPath, currentFile.path);
  });

  test('canonical path resolves against a changed documents root', () async {
    const relative = 'media/dogs/dog/sessions/session/restarted.png';
    final newDocuments =
        await Directory.systemTemp.createTemp('session_media_restarted_');
    addTearDown(() async {
      if (await newDocuments.exists()) {
        await newDocuments.delete(recursive: true);
      }
    });
    final newFile =
        File(p.joinAll([newDocuments.path, ...relative.split('/')]));
    await newFile.parent.create(recursive: true);
    await newFile.writeAsBytes([1]);

    MediaStorage.setDocumentsDirectoryForTesting(newDocuments.path);
    final result = await resolveSessionMediaForOpening(
      storedPath: relative,
      mediaKind: 'image',
    );

    expect(result?.resolvedPath, newFile.path);
  });

  test('missing and zero-byte files return controlled failures', () async {
    const missing = 'media/dogs/dog/sessions/session/missing.mov';
    const empty = 'media/dogs/dog/sessions/session/empty.mp4';
    final emptyFile = File(p.joinAll([documents.path, ...empty.split('/')]));
    await emptyFile.parent.create(recursive: true);
    await emptyFile.create();

    expect(
      await resolveSessionMediaForOpening(
        storedPath: missing,
        mediaKind: 'video',
      ),
      isNull,
    );
    expect(
      await resolveSessionMediaForOpening(
        storedPath: empty,
        mediaKind: 'video',
      ),
      isNull,
    );
  });
}
