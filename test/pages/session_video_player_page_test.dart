import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/pages/session_video_player_page.dart';

void main() {
  testWidgets('video surface uses the initialized controller aspect ratio', (
    tester,
  ) async {
    const initializedAspectRatio = 1920 / 1080;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SessionVideoAspectRatio(
              aspectRatio: initializedAspectRatio,
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );

    final ratio = tester.widget<AspectRatio>(
      find.byKey(const ValueKey('session-video-aspect-ratio')),
    );
    expect(ratio.aspectRatio, initializedAspectRatio);

    final size = tester.getSize(
      find.byType(SessionVideoAspectRatio),
    );
    expect(size.width / size.height, closeTo(initializedAspectRatio, 0.001));
  });
}
