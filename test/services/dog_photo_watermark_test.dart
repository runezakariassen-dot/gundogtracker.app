import 'dart:io';
import 'package:flutter/services.dart'; // FontLoader, ByteData
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:jakthund_app/services/dog_photo_watermark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DogPhotoWatermark', () {
    test('render() produces readable text using a loaded TTF font', () async {
      // Arrange: source image
      final source = File('test/assets/dog.jpg');
      expect(source.existsSync(), isTrue,
          reason: 'Test image test/assets/dog.jpg must exist');

      // Arrange: load a real TTF font so TextPainter has glyphs in VM/tests.
      final ttf = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      expect(ttf.existsSync(), isTrue,
          reason:
              'Arial.ttf not found at expected macOS path. Point to any .ttf on your machine.');

      await _loadFontFromFile(
        fontFamily: 'WatermarkFont',
        file: ttf,
      );

      // Requires DogPhotoWatermark to support fontFamily (your Codex change).
      final watermark = DogPhotoWatermark(fontFamily: 'WatermarkFont');

      final lines = <WatermarkLine>[
        const WatermarkLine(text: 'Zoë Codex', isTitle: false),
        const WatermarkLine(text: 'NUCH', isTitle: true),
      ];

      // Act
      final outFile = await watermark.render(
        sourcePath: source.path,
        lines: lines,
        suffix: '_wm_test',
      );

      // Assert
      expect(outFile.existsSync(), isTrue,
          reason: 'Watermarked output file should exist');

      final outBytes = await outFile.readAsBytes();
      expect(outBytes, isNotEmpty);

      // Copy to a stable filename for easy opening.
      final tempCopy =
          File(p.join(Directory.systemTemp.path, 'watermarked_dog_test.jpg'));
      await tempCopy.writeAsBytes(outBytes);

      // ignore: avoid_print
      print('Watermarked image (with real font) written to: ${tempCopy.path}');
      // ignore: avoid_print
      print('Original renderer output path: ${outFile.path}');
    });
  });
}

Future<void> _loadFontFromFile({
  required String fontFamily,
  required File file,
}) async {
  final bytes = await file.readAsBytes();
  final loader = FontLoader(fontFamily);

  loader.addFont(
    Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
  );

  await loader.load();
}
