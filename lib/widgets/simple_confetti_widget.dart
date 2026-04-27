import 'dart:math' as math;

import 'package:flutter/material.dart';

/// En enkel konfetti-widget som viser fallende partikler
class SimpleConfettiWidget extends StatefulWidget {
  const SimpleConfettiWidget({
    super.key,
    required this.controller,
    this.numberOfParticles = 50,
    this.colors = const [
      Colors.red,
      Colors.blue,
      Colors.yellow,
      Colors.green,
      Colors.purple,
    ],
    this.gravity = 0.3,
    this.wind = 0.1,
  });

  final AnimationController controller;
  final int numberOfParticles;
  final List<Color> colors;
  final double gravity;
  final double wind;

  @override
  State<SimpleConfettiWidget> createState() => _SimpleConfettiWidgetState();
}

class _SimpleConfettiWidgetState extends State<SimpleConfettiWidget> {
  late Animation<double> _animation;
  final List<_ConfettiParticle> _particles = <_ConfettiParticle>[];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animation = _buildAnimation(widget.controller);
    widget.controller.addStatusListener(_handleStatusChanged);
  }

  @override
  void didUpdateWidget(covariant SimpleConfettiWidget oldWidget) {
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
      _createParticles();
    }
  }

  void _createParticles() {
    _particles.clear();
    final screenWidth = MediaQuery.sizeOf(context).width;

    for (int index = 0; index < widget.numberOfParticles; index++) {
      final isCircle = _random.nextBool();
      _particles.add(
        _ConfettiParticle(
          startX: _random.nextDouble() * screenWidth,
          startY: -20.0,
          velocityX: (_random.nextDouble() - 0.5) * widget.wind * 100,
          velocityY: _random.nextDouble() * 200 + 100,
          color: widget.colors[_random.nextInt(widget.colors.length)],
          size: _random.nextDouble() * 8 + 4,
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 10,
          isCircle: isCircle,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: _particles.map((particle) {
            final time = _animation.value * 3.0;
            final x = particle.startX + particle.velocityX * time;
            final y = particle.startY +
                particle.velocityY * time +
                0.5 * widget.gravity * 1000 * time * time;
            final opacity = math.max(0.0, 1.0 - (y / screenHeight));

            if (opacity <= 0 || y > screenHeight + 50) {
              return const SizedBox.shrink();
            }

            return Positioned(
              left: x,
              top: y,
              child: Transform.rotate(
                angle: particle.rotation + particle.rotationSpeed * time,
                child: Container(
                  width: particle.size,
                  height: particle.size,
                  decoration: BoxDecoration(
                    color: particle.color.withValues(alpha: opacity),
                    shape: particle.isCircle
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius:
                        particle.isCircle ? null : BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });

  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final bool isCircle;
}
