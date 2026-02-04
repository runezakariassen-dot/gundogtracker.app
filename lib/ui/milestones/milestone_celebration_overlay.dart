import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

import '../../domain/milestones/milestone_models.dart';
import 'milestone_strings.dart';

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

Future<void> showMilestoneCelebrationOverlay({
  required BuildContext context,
  required MilestoneDef def,
  required Dog dog,
  required DateTime achievedAt,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MilestoneCelebrationOverlay(
        def: def,
        achievedAt: achievedAt,
        dog: dog,
      ),
    ),
  );
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
    extends State<MilestoneCelebrationOverlay> {
  late final ConfettiController _leftConfettiController;
  late final ConfettiController _rightConfettiController;
  Timer? _autoCloseTimer;
  late final bool _hapticsEnabled;
  late final bool _isBig;
  static const _salvoDuration = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _leftConfettiController = ConfettiController(duration: _salvoDuration);
    _rightConfettiController = ConfettiController(duration: _salvoDuration);
    _isBig = _isBigMilestone(widget.def.id);
    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    _hapticsEnabled = (settingsBox.get(hapticsEnabledKey) as bool?) ?? true;
    if (_hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    _leftConfettiController.play();
    _rightConfettiController.play();
    _autoCloseTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _leftConfettiController.dispose();
    _rightConfettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd.MM.yyyy HH:mm').format(widget.achievedAt);
    final subtitle =
        milestoneSubtitleText(context, widget.def, widget.dog.name);
    final title = milestoneTitle(context, widget.def);
    final l10n = AppLocalizations.of(context)!;
    final particleCount = _isBig ? 18 : 12;
    final blastForce = _isBig ? 30.0 : 20.0;
    final minForce = _isBig ? 10.0 : 8.0;
    final emission = _isBig ? 0.2 : 0.3;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _leftConfettiController,
                blastDirection: -math.pi / 4,
                emissionFrequency: emission,
                numberOfParticles: particleCount,
                maxBlastForce: blastForce,
                minBlastForce: minForce,
                gravity: 0.35,
                shouldLoop: false,
                colors: const [
                  Color(0xFFF7F3E9),
                  Color(0xFFE9DFCF),
                  Color(0xFFB26A3D),
                  Color(0xFF6F7B67),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _rightConfettiController,
                blastDirection: -3 * math.pi / 4,
                emissionFrequency: emission,
                numberOfParticles: particleCount,
                maxBlastForce: blastForce,
                minBlastForce: minForce,
                gravity: 0.35,
                shouldLoop: false,
                colors: const [
                  Color(0xFFF7F3E9),
                  Color(0xFFE9DFCF),
                  Color(0xFFB26A3D),
                  Color(0xFF6F7B67),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.milestone_sheet_button_ok),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
