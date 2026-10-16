import 'dart:io';
import 'dart:ui' as ui;

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

  for (final dimensions in <({int width, int height, String name})>[
    (width: 120, height: 60, name: 'landscape'),
    (width: 60, height: 120, name: 'portrait'),
    (width: 80, height: 80, name: 'square'),
  ]) {
    testWidgets('${dimensions.name} image keeps its source aspect ratio', (
      tester,
    ) async {
      final file = File('${documents.path}/${dimensions.name}.png');
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            0,
            dimensions.width.toDouble(),
            dimensions.height.toDouble(),
          ),
          Paint()..color = Colors.blue,
        );
        final picture = recorder.endRecording();
        final source = await picture.toImage(
          dimensions.width,
          dimensions.height,
        );
        final bytes = await source.toByteData(format: ui.ImageByteFormat.png);
        source.dispose();
        picture.dispose();
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 300,
              height: 300,
              child: SessionMediaImage(
                storedPath: file.path,
                displayWidth: 300,
                displayHeight: 300,
                fullScreen: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
      final provider = image.image as ResizeImage;
      expect(provider.policy, ResizeImagePolicy.fit);
      expect(provider.width, 300);
      expect(provider.height, 300);

      final fitted = applyBoxFit(
        BoxFit.contain,
        Size(dimensions.width.toDouble(), dimensions.height.toDouble()),
        const Size(300, 300),
      ).destination;
      expect(
        fitted.width / fitted.height,
        closeTo(dimensions.width / dimensions.height, 0.001),
      );
    });
  }
}
