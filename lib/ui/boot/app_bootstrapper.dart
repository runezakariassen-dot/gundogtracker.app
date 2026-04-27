import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/hive_boxes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/cloud/auto_sync_coordinator.dart';
import '../../services/cloud/sync_foreground_monitor.dart';
import '../../services/hive_lifecycle_service.dart';
import '../../services/audio_service.dart';

import '../app_shell.dart';
import '../auth/login_screen.dart';
import '../locale/locale_controller.dart';
import '../theme/app_theme.dart';
import '../theme/season_theme.dart';
import '../theme/season_theme_controller.dart';
import 'boot_wrapper.dart';
import 'auth_gate.dart';

// Pages
import '../../pages/dog_page.dart';
import '../../pages/statistics_page.dart';
import '../../hunt_session_page.dart';
import '../screens/home_screen.dart';

const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

class AppBootstrapper extends StatelessWidget {
  const AppBootstrapper({
    super.key,
    this.localeController,
    this.child,
    this.skipBootstrap = false,
  })  : assert(localeController != null || child != null,
            'Provide either a localeController or a child widget'),
        assert(!skipBootstrap || child != null,
            'skipBootstrap requires a child to render');

  final LocaleController? localeController;
  final Widget? child;
  final bool skipBootstrap;

  bool get _shouldSkipBootstrap => skipBootstrap || _isFlutterTest;

  Widget _buildDefaultApp() {
    return FuglehundApp(
      localeController: localeController!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveChild = child ?? _buildDefaultApp();
    if (_shouldSkipBootstrap) {
      return effectiveChild;
    }

    return BootWrapper(
      child: effectiveChild,
    );
  }
}

class FuglehundApp extends StatefulWidget {
  const FuglehundApp({
    super.key,
    required this.localeController,
  });

  final LocaleController localeController;

  @override
  State<FuglehundApp> createState() => _FuglehundAppState();
}

class _FuglehundAppState extends State<FuglehundApp>
    with WidgetsBindingObserver {
  static bool _firstFrameLogged = false;
  late final SyncForegroundMonitor _syncForegroundMonitor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncForegroundMonitor = SyncForegroundMonitor();
    _syncForegroundMonitor.start();
    // Spill av startup-lyd hvis aktivert
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_firstFrameLogged) {
        _firstFrameLogged = true;
        debugPrint('[UI] first frame rendered');

        final settingsBox =
            HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
        final soundEnabled =
            (settingsBox.get(soundOnAppStartKey) as bool?) ?? false;
        if (soundEnabled) {
          AudioService().playStartupSound();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_syncForegroundMonitor.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncForegroundMonitor.start();
      unawaited(AutoSyncCoordinator.instance.runOnResumed());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_syncForegroundMonitor.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox =
        HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);

    return AnimatedBuilder(
      animation: widget.localeController,
      builder: (context, _) {
        return ValueListenableBuilder(
          valueListenable: settingsBox.listenable(
            keys: const [
              'themeMode',
              themeSeasonOverrideKey,
            ],
          ),
          builder: (context, Box<dynamic> box, _) {
            final mode = box.get('themeMode') ?? 'light';

            final themeMode = switch (mode) {
              'light' => ThemeMode.light,
              'system' => ThemeMode.system,
              _ => ThemeMode.dark,
            };

            final seasonController = SeasonThemeController(settingsBox);
            final season = seasonController.getResolvedSeason(DateTime.now());

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)?.appName ?? 'Fuglehund',
              theme: buildSeasonTheme(season),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              locale: widget.localeController.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: AuthGate(
                loginBuilder: (_) => const LoginScreen(),
                appBuilder: (_) => AppShell(
                  builders: [
                    (_) => const HomeScreen(),
                    (_) => const HuntSessionPage(),
                    (_) => const StatisticsPage(),
                    (_) => const DogPage(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
