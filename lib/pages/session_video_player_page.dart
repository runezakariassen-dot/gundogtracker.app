import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';

class SessionVideoPlayerPage extends StatefulWidget {
  const SessionVideoPlayerPage({
    super.key,
    required this.videoPath,
    this.displayName,
  });

  final String videoPath;
  final String? displayName;

  @override
  State<SessionVideoPlayerPage> createState() => _SessionVideoPlayerPageState();
}

class _SessionVideoPlayerPageState extends State<SessionVideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeController());
  }

  Future<void> _initializeController() async {
    final file = File(widget.videoPath);
    try {
      final controller = VideoPlayerController.file(file);
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
      await controller.play();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[SESSION_MEDIA] kind=video stage=controller-initialize '
          'resolved=${widget.videoPath} exists=${file.existsSync()} '
          'size=${file.existsSync() ? file.lengthSync() : 0} '
          'error=$error stackTrace=$stackTrace',
        );
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _initializing = false;
        _errorMessage = l10n.session_media_video_open_failed;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.session_media_video_open_failed)),
        );
      });
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
    } else {
      unawaited(controller.play());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.displayName ?? l10n.session_media_section_title;
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: _errorMessage != null
            ? Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              )
            : _initializing
                ? const CircularProgressIndicator()
                : controller == null || !controller.value.isInitialized
                    ? Text(l10n.session_media_video_open_failed)
                    : AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            VideoPlayer(controller),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: VideoProgressIndicator(
                                controller,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
      floatingActionButton: _errorMessage != null || _initializing
          ? null
          : FloatingActionButton(
              onPressed: _togglePlayPause,
              child: Icon(
                controller?.value.isPlaying == true
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            ),
    );
  }
}
