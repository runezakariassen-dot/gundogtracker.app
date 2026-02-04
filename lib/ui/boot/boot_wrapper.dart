import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import '../../domain/restore/restore_guard.dart';

/// Wrapper som sørger for at vi ALDRI blir stående på hvit skjerm uten forklaring.
/// - Viser en enkel "Starter..."-skjerm med watchdog-timer
/// - Legger på overlay når RestoreGuard.inProgress = true
/// - Når RestoreGuard.restartRequested = true: viser restart-overlay og lukker appen
///
/// Viktig:
/// Denne wrapperen kan ligge OVER MaterialApp i treet.
/// Derfor legger vi eksplisitt Directionality her.
class BootWrapper extends StatefulWidget {
  const BootWrapper({
    super.key,
    required this.child,
    this.watchdogSeconds = 20, // litt snillere enn 8 sek
    this.initFuture,
  });

  final Widget child;
  final int watchdogSeconds;
  final Future<Object?>? initFuture;

  @override
  State<BootWrapper> createState() => _BootWrapperState();
}

class _BootWrapperState extends State<BootWrapper> {
  bool _watchdogFired = false;
  bool _didTriggerRestart = false;
  bool _bootReady = false;
  bool _bootFailed = false;
  Object? _bootError;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _runBootOnce();
  }

  @override
  void dispose() {
    _stopWatchdog();
    super.dispose();
  }

  void _triggerRestartOnce() {
    if (_didTriggerRestart) return;
    _didTriggerRestart = true;

    // La overlayen tegne først, så lukk appen kontrollert.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      try {
        await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
      } catch (_) {
        // fallback (shouldn't usually be needed)
        SystemNavigator.pop();
      }
    });
  }

  Future<void> _runBootOnce() async {
    debugPrint('[UI][BOOT_WRAPPER] init begin');
    _startWatchdog();
    final future = widget.initFuture ?? Future.value();
    try {
      await future;
      debugPrint('[UI][BOOT_WRAPPER] init success');
      if (!mounted) return;
      setState(() {
        _bootReady = true;
        _bootFailed = false;
        _bootError = null;
        _watchdogFired = false;
      });
      debugPrint(
        '[UI][BOOT_WRAPPER] state ready=$_bootReady bootFailed=$_bootFailed',
      );
    } catch (error, stackTrace) {
      debugPrint('[UI][BOOT_WRAPPER] init FAIL $error');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      setState(() {
        _bootReady = false;
        _bootFailed = true;
        _bootError = error;
      });
      debugPrint(
        '[UI][BOOT_WRAPPER] state ready=$_bootReady bootFailed=$_bootFailed',
      );
    } finally {
      debugPrint('[UI][BOOT_WRAPPER] init finally');
      _stopWatchdog();
    }
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(Duration(seconds: widget.watchdogSeconds), () {
      if (!mounted) return;
      debugPrint('[UI][BOOT_WRAPPER] watchdog timer fired');
      setState(() {
        _watchdogFired = true;
        _bootFailed = true;
        _bootError ??= StateError('Boot watchdog fired');
      });
    });
    debugPrint('[UI][BOOT_WRAPPER] watchdog timer started');
  }

  void _stopWatchdog() {
    if (_watchdog == null) return;
    _watchdog?.cancel();
    _watchdog = null;
    debugPrint('[UI][BOOT_WRAPPER] watchdog timer cancelled');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_bootReady) {
      return Stack(
        children: [
          widget.child,
          ValueListenableBuilder<bool>(
            valueListenable: RestoreGuard.inProgress,
            builder: (context, restoring, _) {
              debugPrint(
                '[UI][BOOT_WRAPPER] restore overlay build restoring=$restoring',
              );
              if (!restoring) return const SizedBox.shrink();
              return _buildRestoreOverlay(context);
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: RestoreGuard.restartRequested,
            builder: (context, restart, _) {
              if (!restart) return const SizedBox.shrink();
              return _buildRestartOverlay(context);
            },
          ),
        ],
      );
    }

    if (_bootFailed) {
      return _buildErrorScreen(context);
    }

    return _buildLoadingScreen();
  }

  Widget _buildLoadingScreen() {
    final title =
        _watchdogFired ? 'Starter… (tar uvanlig lang tid)' : 'Starter…';
    final body = _watchdogFired
        ? 'Appen har brukt uvanlig lang tid på å vise UI.\n\n'
            'Sjekk terminalen for første exception / init som henger.'
        : 'Vi gjør siste forberedelser før du kan bruke appen.';
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: _BootCard(title: title, body: body),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = _bootError?.toString() ?? l10n.boot_error_unknown;
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: _BootCard(
        title: l10n.boot_error_title,
        body: l10n.boot_error_body(message),
      ),
    );
  }

  Widget _buildRestoreOverlay(BuildContext context) {
    debugPrint('[UI][BOOT_WRAPPER] restore overlay build restoring=true');
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withOpacity(0.45),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: _BootCard(
            title: l10n.boot_restore_title,
            body: l10n.boot_restore_body,
          ),
        ),
      ),
    );
  }

  Widget _buildRestartOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    debugPrint('[UI][BOOT_WRAPPER] restart overlay visible');
    _triggerRestartOnce();
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: _BootCard(
          title: l10n.boot_restart_title,
          body: l10n.boot_restart_body,
        ),
      ),
    );
  }
}

class _BootCard extends StatelessWidget {
  const _BootCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
