import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/services/audio_service.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

import '../../domain/milestones/milestone_models.dart';
import '../../widgets/flying_birds_widget.dart';
import '../../widgets/simple_confetti_widget.dart';
import 'milestone_strings.dart';

Future<void>? _activeCelebrationFuture;

bool _isBigMilestone(String id) {
  final normalized = id.toLowerCase();
  return normalized.contains('_100') ||
      normalized.contains('_200') ||
      normalized.contains('_300') ||
      normalized.contains('_500') ||
      normalized.contains('_1000') ||
      normalized.contains('first') ||
      normalized.contains('century');
}

bool _isCenturyMilestone(String id) {
  final normalized = id.toLowerCase();
  return normalized.contains('_1000') ||
      normalized.contains('century') ||
      (normalized.startsWith('points_') &&
          int.tryParse(normalized.substring(7)) != null &&
          int.tryParse(normalized.substring(7))! >= 1000);
}

void _logCelebration(String message) {
  debugPrint('[MILESTONE][CELEBRATION] $message');
}

@visibleForTesting
bool debugIsMilestoneCelebrationRunning() => _activeCelebrationFuture != null;

@visibleForTesting
void debugResetMilestoneCelebrationState() {
  _activeCelebrationFuture = null;
}

Future<void> showMilestoneCelebrationOverlay({
  required BuildContext context,
  required MilestoneDef def,
  required Dog dog,
  required DateTime achievedAt,
}) {
  _logCelebration('trigger requested id=${def.id}');

  final activeCelebration = _activeCelebrationFuture;
  if (activeCelebration != null) {
    _logCelebration('trigger skipped already running id=${def.id}');
    return activeCelebration;
  }

  late final Future<void> routeFuture;
  routeFuture = Navigator.of(context)
      .push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => MilestoneCelebrationOverlay(
        def: def,
        achievedAt: achievedAt,
        dog: dog,
      ),
    ),
  )
      .whenComplete(() {
    _logCelebration('complete id=${def.id}');
    if (identical(_activeCelebrationFuture, routeFuture)) {
      _activeCelebrationFuture = null;
    }
  });

  _activeCelebrationFuture = routeFuture;
  return routeFuture;
}

enum _DismissReason {
  auto,
  manual,
}

class MilestoneCelebrationOverlay extends StatefulWidget {
  const MilestoneCelebrationOverlay({
    super.key,
    required this.def,
    required this.achievedAt,
    required this.dog,
  });

  final MilestoneDef def;
  final DateTime achievedAt;
  final Dog dog;

  @override
  State<MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<MilestoneCelebrationOverlay> with TickerProviderStateMixin {
  static const Duration _celebrationDuration = Duration(milliseconds: 2200);

  late final AnimationController _birdsController;
  late final AnimationController _textController;
  late final Animation<double> _titleBounce;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _cardScale;
  late final List<Animation<double>> _starAnimations;
  late final bool _hapticsEnabled;
  late final bool _soundEnabled;
  late final bool _isBig;

  Timer? _autoCloseTimer;
  bool _isRunning = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
    _startCelebration();
  }

  @override
  void didUpdateWidget(covariant MilestoneCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.def.id != widget.def.id ||
        oldWidget.achievedAt != widget.achievedAt ||
        oldWidget.dog.id != widget.dog.id;
    if (!changed) {
      return;
    }

    if (_isRunning) {
      _logCelebration('trigger skipped already running id=${widget.def.id}');
      return;
    }

    _startCelebration();
  }

  void _initializeControllers() {
    _birdsController = AnimationController(
      duration: const Duration(milliseconds: 2100),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _titleBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.22, 1.0, curve: Curves.easeOut),
      ),
    );
    _cardScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
    );
    _starAnimations = List<Animation<double>>.generate(5, (index) {
      final delay = index * 0.09;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _textController,
          curve: Interval(delay, delay + 0.28, curve: Curves.elasticOut),
        ),
      );
    }, growable: false);
  }

  void _loadSettings() {
    _isBig = _isBigMilestone(widget.def.id);
    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    _hapticsEnabled = (settingsBox.get(hapticsEnabledKey) as bool?) ?? true;
    _soundEnabled = (settingsBox.get(soundOnMilestoneKey) as bool?) ?? false;
  }

  void _startCelebration() {
    if (_isRunning) {
      _logCelebration('trigger skipped already running id=${widget.def.id}');
      return;
    }

    _isRunning = true;
    _isDismissing = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDismissing) {
        return;
      }

      _logCelebration('start id=${widget.def.id}');

      _autoCloseTimer?.cancel();

      _birdsController
        ..stop()
        ..reset()
        ..forward();
      _textController
        ..stop()
        ..reset()
        ..forward();

      if (_hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
      if (_soundEnabled) {
        AudioService().playMilestoneSound();
      }

      _autoCloseTimer = Timer(_celebrationDuration, () {
        _safeDismiss(_DismissReason.auto);
      });
    });
  }

  void _safeDismiss(_DismissReason reason) {
    if (!mounted || _isDismissing) {
      return;
    }

    if (reason == _DismissReason.manual) {
      _logCelebration('manual dismiss id=${widget.def.id}');
    }

    _isDismissing = true;
    _isRunning = false;
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _birdsController.stop();
    _logCelebration('dispose controller birds');
    _birdsController.dispose();
    _textController.stop();
    _logCelebration('dispose controller text');
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final title = milestoneTitle(context, widget.def);
    final subtitle =
        milestoneSubtitleText(context, widget.def, widget.dog.name);
    final dateText = _formatAchievedAt(widget.achievedAt);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 700;
            final cardMaxWidth = isTablet ? 560.0 : 420.0;
            final majorBirdCount = _isBig ? 28 : 22;
            final minorBirdCount = _isBig ? 20 : 16;
            final majorForce = _isBig ? 280.0 : 220.0;
            final minorForce = _isBig ? 230.0 : 180.0;
            final birdSize = isTablet ? 38.0 : 30.0;

            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: _CelebrationBackdrop(
                      controller: _textController,
                      isBig: _isBig,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FlyingBirdsWidget(
                          controller: _birdsController,
                          origin: const Alignment(-0.88, 0.96),
                          blastDirection: -math.pi / 3.2,
                          numberOfBirds: majorBirdCount,
                          maxBlastForce: majorForce,
                          minBlastForce: majorForce * 0.55,
                          gravity: 46,
                          birdSize: birdSize,
                          spawnSpreadX: 70,
                          spawnSpreadY: 16,
                        ),
                        FlyingBirdsWidget(
                          controller: _birdsController,
                          origin: const Alignment(-0.42, 0.9),
                          blastDirection: -math.pi / 2.35,
                          numberOfBirds: minorBirdCount,
                          maxBlastForce: minorForce,
                          minBlastForce: minorForce * 0.55,
                          gravity: 42,
                          birdSize: birdSize - 2,
                          spawnSpreadX: 54,
                          spawnSpreadY: 14,
                        ),
                        FlyingBirdsWidget(
                          controller: _birdsController,
                          origin: const Alignment(0, 0.98),
                          blastDirection: -math.pi / 2,
                          numberOfBirds: majorBirdCount + 4,
                          maxBlastForce: majorForce * 1.08,
                          minBlastForce: majorForce * 0.6,
                          gravity: 48,
                          birdSize: birdSize + 2,
                          spawnSpreadX: 64,
                          spawnSpreadY: 18,
                        ),
                        FlyingBirdsWidget(
                          controller: _birdsController,
                          origin: const Alignment(0.42, 0.9),
                          blastDirection: -math.pi * 0.58,
                          numberOfBirds: minorBirdCount,
                          maxBlastForce: minorForce,
                          minBlastForce: minorForce * 0.55,
                          gravity: 42,
                          birdSize: birdSize - 2,
                          spawnSpreadX: 54,
                          spawnSpreadY: 14,
                        ),
                        FlyingBirdsWidget(
                          controller: _birdsController,
                          origin: const Alignment(0.88, 0.96),
                          blastDirection: -2 * math.pi / 3.2,
                          numberOfBirds: majorBirdCount,
                          maxBlastForce: majorForce,
                          minBlastForce: majorForce * 0.55,
                          gravity: 46,
                          birdSize: birdSize,
                          spawnSpreadX: 70,
                          spawnSpreadY: 16,
                        ),
                        if (_isCenturyMilestone(widget.def.id) || _isBig)
                          Positioned.fill(
                            child: SimpleConfettiWidget(
                              controller: _birdsController,
                              numberOfParticles: _isBig ? 140 : 90,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                                Colors.amber,
                                Colors.red,
                                Colors.blue,
                                Colors.green,
                              ],
                              gravity: 0.18,
                              wind: 0.14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 48 : 24,
                      vertical: isTablet ? 36 : 20,
                    ),
                    child: AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        final buttonScale = 1.0 +
                            (math.sin(_textController.value * 2 * math.pi) *
                                0.035);
                        return Transform.scale(
                          scale: _cardScale.value,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 36 : 28),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface
                                    .withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: _isBig ? 0.18 : 0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.shadow
                                        .withValues(alpha: 0.12),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isBig)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List<Widget>.generate(
                                        5,
                                        (index) {
                                          return AnimatedBuilder(
                                            animation: _textController,
                                            builder: (context, child) {
                                              final starAnimation =
                                                  _starAnimations[index];
                                              return Transform.scale(
                                                scale: starAnimation.value,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 4),
                                                  child: Icon(
                                                    Icons.star_rounded,
                                                    color: Colors.amber,
                                                    size: 24 *
                                                        starAnimation.value,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        growable: false,
                                      ),
                                    ),
                                  SizedBox(height: _isBig ? 18 : 6),
                                  AnimatedBuilder(
                                    animation: _textController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _titleBounce.value,
                                        child: Text(
                                          title,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: _isBig
                                                ? theme.colorScheme.primary
                                                : null,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedBuilder(
                                    animation: _textController,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _subtitleFade.value,
                                        child: Text(
                                          subtitle,
                                          style: theme.textTheme.bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedBuilder(
                                    animation: _textController,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _subtitleFade.value,
                                        child: Text(
                                          dateText,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.62),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Transform.scale(
                                    scale: buttonScale,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () =>
                                            _safeDismiss(_DismissReason.manual),
                                        child: Text(
                                          l10n.milestone_sheet_button_ok,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatAchievedAt(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}

class _CelebrationBackdrop extends StatelessWidget {
  const _CelebrationBackdrop({
    required this.controller,
    required this.isBig,
  });

  final AnimationController controller;
  final bool isBig;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final intensity = isBig ? 0.18 : 0.1;
        final opacity = controller.value * intensity;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: isBig ? 1.35 : 1.18,
              colors: [
                theme.colorScheme.primary.withValues(alpha: opacity),
                theme.colorScheme.secondary.withValues(alpha: opacity * 0.75),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}
