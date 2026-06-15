import 'package:flutter/material.dart';

/// En widget som viser en statisk hund-ikon uten animasjoner.
class AnimatedDogWidget extends StatelessWidget {
  const AnimatedDogWidget({
    super.key,
    this.width = 50,
    this.height = 50,
    this.asset = 'assets/icon/stand_dog.png',
    this.duration = const Duration(seconds: 3),
    this.distance = 30,
    this.autoStart = true,
  });

  /// Bredden på hund-ikonet
  final double width;

  /// Høyden på hund-ikonet
  final double height;

  /// Asset-sti til hund-bildet
  final String asset;

  /// Ikke brukt, men beholdt for API-kompatibilitet
  final Duration duration;

  /// Ikke brukt, men beholdt for API-kompatibilitet
  final double distance;

  /// Ikke brukt, men beholdt for API-kompatibilitet
  final bool autoStart;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
