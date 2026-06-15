import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Spill av startup-lyd
  Future<void> playStartupSound() async {
    try {
      await _audioPlayer.play(
        AssetSource('sounds/rype.mp3'),
        volume: 0.5,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AUDIO] Feil ved avspilling av startup-lyd: $e');
      }
    }
  }

  // Spill av milepæl-lyd
  Future<void> playMilestoneSound() async {
    try {
      await _audioPlayer.play(
        AssetSource('sounds/rype.mp3'),
        volume: 0.7,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AUDIO] Feil ved avspilling av milepæl-lyd: $e');
      }
    }
  }

  // Stopp avspilling
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // Dispose
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
