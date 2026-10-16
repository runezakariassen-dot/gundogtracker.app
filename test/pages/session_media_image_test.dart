import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/pages/session_media_image.dart';
import 'package:jakthund_app/services/media_storage.dart';

void main() {
  late Directory documents;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('media_image_');
    MediaStorage.setDocumentsDirectoryForTesting(documents.path);
  });

  tearDown(() async {
    MediaStorage.setDocumentsDirectoryForTesting(null);
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  test('thumbnail decode is DPR-aware and bounded', () {
    final size = SessionMediaImagePolicy.decodeSize(
      logicalWidth: 96,
      logicalHeight: 86,
      devicePixelRatio: 3,
      fullScreen: false,
    );

    expect(size.width, 288);
    expect(size.height, 258);
    expect(size.width, lessThanOrEqualTo(512));
    expect(size.height, lessThanOrEqualTo(512));
  });

  test('very large full-screen request is proportionally bounded', () {
    final size = SessionMediaImagePolicy.decodeSize(
      logicalWidth: 430,
      logicalHeight: 932,
      devicePixelRatio: 4,
      fullScreen: true,
    );

    expect(size.height, 2560);
    expect(size.width, closeTo(1181, 1));
  });

  testWidgets('missing file renders a controlled placeholder', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(devicePixelRatio: 3),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SessionMediaImage(
            storedPath: 'missing.heic',
            displayWidth: 88,
            displayHeight: 88,
            placeholder: Text('missing'),
          ),
        ),
      ),
    );

    expect(find.text('missing'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
