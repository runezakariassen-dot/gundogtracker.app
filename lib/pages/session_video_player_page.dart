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
  late final VideoPlayerController _controller;
  bool _initializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initializing = false);
      _controller.play();
    }).catchError((error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VIDEO] controller init failed path=${widget.videoPath} error=$error stackTrace=$stackTrace',
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
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.displayName ?? l10n.session_media_section_title;
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
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoPlayer(_controller),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: VideoProgressIndicator(
                            _controller,
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
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
    );
  }
}
