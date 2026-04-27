import 'dart:math' as math;

import 'package:flutter/material.dart';

/// En widget som viser animerte ryper som skytes opp over skjermen.
class FlyingBirdsWidget extends StatefulWidget {
  const FlyingBirdsWidget({
    super.key,
    required this.controller,
    this.origin = Alignment.bottomCenter,
    this.blastDirection = -math.pi / 2,
    this.numberOfBirds = 12,
    this.maxBlastForce = 180.0,
    this.minBlastForce = 80.0,
    this.gravity = 30.0,
    this.birdSize = 24.0,
    this.spawnSpreadX = 36.0,
    this.spawnSpreadY = 12.0,
    this.assetPath = 'assets/icons/bird_rype.png',
  });

  final AnimationController controller;
  final Alignment origin;
  final double blastDirection;
  final int numberOfBirds;
  final double maxBlastForce;
  final double minBlastForce;
  final double gravity;
  final double birdSize;
  final double spawnSpreadX;
  final double spawnSpreadY;
  final String assetPath;

  @override
  State<FlyingBirdsWidget> createState() => _FlyingBirdsWidgetState();
}

class _FlyingBirdsWidgetState extends State<FlyingBirdsWidget> {
  late Animation<double> _animation;
  final List<_FlyingBird> _birds = <_FlyingBird>[];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animation = _buildAnimation(widget.controller);
    widget.controller.addStatusListener(_handleStatusChanged);
  }

  @override
  void didUpdateWidget(covariant FlyingBirdsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeStatusListener(_handleStatusChanged);
    _animation = _buildAnimation(widget.controller);
    widget.controller.addStatusListener(_handleStatusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  Animation<double> _buildAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(controller);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _createBirds();
    }
  }

  void _createBirds() {
    _birds.clear();

    for (int index = 0; index < widget.numberOfBirds; index++) {
      final directionVariation = (_random.nextDouble() - 0.5) * math.pi / 2.8;
      final direction = widget.blastDirection + directionVariation;
      final force = widget.minBlastForce +
          _random.nextDouble() * (widget.maxBlastForce - widget.minBlastForce);
      final startDelay = _random.nextDouble() * 0.22;
      final rotation = _random.nextDouble() * 2 * math.pi;
      final drift = (_random.nextDouble() - 0.5) * 36;
      final startOffsetX =
          (_random.nextDouble() - 0.5) * widget.spawnSpreadX * 2;
      final startOffsetY =
          (_random.nextDouble() - 0.5) * widget.spawnSpreadY * 2;

      _birds.add(
        _FlyingBird(
          direction: direction,
          force: force,
          startDelay: startDelay,
          rotation: rotation,
          gravity: widget.gravity,
          drift: drift,
          startOffsetX: startOffsetX,
          startOffsetY: startOffsetY,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final originX = ((widget.origin.x + 1) / 2) * size.width;
        final originY = ((widget.origin.y + 1) / 2) * size.height;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: _birds.map((bird) {
                final progress =
                    math.max(0.0, _animation.value - bird.startDelay);
                if (progress <= 0) {
                  return const SizedBox.shrink();
                }

                final time = progress * 1.55;
                final distance = bird.force * time;
                final gravityEffect = 0.5 * bird.gravity * time * time;
                final x = originX +
                    bird.startOffsetX +
                    (distance * math.cos(bird.direction)) +
                    (bird.drift * progress);
                final y = originY +
                    bird.startOffsetY +
                    (distance * math.sin(bird.direction)) +
                    gravityEffect;
                final opacity = math.max(0.0, 1.0 - (progress * 0.86));

                if (opacity <= 0) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: x,
                  top: y,
                  child: Transform.rotate(
                    angle: bird.rotation + time * 2.4,
                    child: Opacity(
                      opacity: opacity,
                      child: Image.asset(
                        widget.assetPath,
                        width: widget.birdSize,
                        height: widget.birdSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            );
          },
        );
      },
    );
  }
}

class _FlyingBird {
  _FlyingBird({
    required this.direction,
    required this.force,
    required this.startDelay,
    required this.rotation,
    required this.gravity,
    required this.drift,
    required this.startOffsetX,
    required this.startOffsetY,
  });

  final double direction;
  final double force;
  final double startDelay;
  final double rotation;
  final double gravity;
  final double drift;
  final double startOffsetX;
  final double startOffsetY;
}
