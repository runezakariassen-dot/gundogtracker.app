import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/services/media_storage.dart';

void main() {
  late Directory documents;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('media_storage_');
    MediaStorage.setDocumentsDirectoryForTesting(documents.path);
  });

  tearDown(() async {
    MediaStorage.setDocumentsDirectoryForTesting(null);
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  for (final extension in ['heic', 'jpeg', 'png', 'mov', 'mp4']) {
    test('picker .$extension is copied to a durable canonical session path',
        () async {
      final pickerDirectory =
          await Directory.systemTemp.createTemp('picker_source_');
      addTearDown(() async {
        if (await pickerDirectory.exists()) {
          await pickerDirectory.delete(recursive: true);
        }
      });
      final source =
          File('${pickerDirectory.path}/iOS picked media.$extension');
      await source.writeAsBytes(List<int>.generate(64, (index) => index));

      final stored = await MediaStorage.ensurePickedMediaPersisted(
        dogId: 'dog-1',
        sessionId: 'session-1',
        sourcePath: source.path,
      );

      expect(stored, startsWith('media/dogs/dog-1/sessions/session-1/'));
      expect(stored, endsWith('.$extension'));
      expect(stored, isNot(source.path));
      final firstValidation = await MediaStorage.validatePersistedMedia(stored);
      expect(firstValidation?.exists, isTrue);
      expect(firstValidation?.length, 64);
      expect(firstValidation?.resolvedPath, startsWith(documents.path));
      expect(firstValidation?.resolvedPath, isNot(stored));

      // Simulate a repository/widget reinitialization and app restart while
      // retaining the application documents directory.
      MediaStorage.setDocumentsDirectoryForTesting(null);
      MediaStorage.setDocumentsDirectoryForTesting(documents.path);
      final reopenedValidation =
          await MediaStorage.validatePersistedMedia(stored);
      expect(reopenedValidation?.exists, isTrue);
      expect(reopenedValidation?.length, 64);
    });
  }

  test('already canonical media is reused rather than copied again', () async {
    final source = File('${documents.path}/picker.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    final stored = await MediaStorage.ensurePickedMediaPersisted(
      dogId: 'dog-1',
      sessionId: 'session-1',
      sourcePath: source.path,
    );

    final reused = await MediaStorage.ensurePickedMediaPersisted(
      dogId: 'dog-1',
      sessionId: 'session-1',
      sourcePath: stored,
    );

    expect(reused, stored);
  });

  test('missing picker file fails safely without creating media', () async {
    expect(
      () => MediaStorage.ensurePickedMediaPersisted(
        dogId: 'dog-1',
        sessionId: 'session-1',
        sourcePath: '${documents.path}/missing.jpg',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('empty picker file gives a controlled failure', () async {
    final source = File('${documents.path}/empty.heic')..createSync();
    expect(
      () => MediaStorage.ensurePickedMediaPersisted(
        dogId: 'dog-1',
        sessionId: 'session-1',
        sourcePath: source.path,
      ),
      throwsA(isA<FileSystemException>()),
    );
  });
}
