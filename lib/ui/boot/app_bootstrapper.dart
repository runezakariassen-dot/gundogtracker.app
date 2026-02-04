import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/hive_boxes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/hive_lifecycle_service.dart';

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

class FuglehundApp extends StatelessWidget {
  const FuglehundApp({
    super.key,
    required this.localeController,
  });

  final LocaleController localeController;

  static bool _firstFrameLogged = false;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_firstFrameLogged) {
        _firstFrameLogged = true;
        debugPrint('[UI] first frame rendered');
      }
    });

    final settingsBox = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);

    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return ValueListenableBuilder(
          valueListenable: settingsBox.listenable(),
          builder: (context, Box<dynamic> box, _) {
            final mode = box.get('themeMode') ?? 'dark';

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
              locale: localeController.locale,
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
