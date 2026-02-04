import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import 'firebase_options.dart';
import 'services/app_startup_service.dart';
import 'ui/boot/app_bootstrapper.dart';
import 'ui/boot/app_restart_controller.dart';
import 'ui/locale/locale_controller.dart';

Future<void> main() async {
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Firebase must be initialized before any Firebase services are used.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final localeController = await AppStartupService.ensureInitialized();

      debugPrint('[BOOT] about to call runApp');

      runApp(
        Phoenix(
          child: _RestartableRoot(localeController: localeController),
        ),
      );

      debugPrint('[BOOT] runApp called');
    },
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error');
      debugPrint(stackTrace.toString());
    },
  );
}

class _RestartableRoot extends StatelessWidget {
  const _RestartableRoot({required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppRestartController.tick,
      builder: (context, tick, _) {
        return KeyedSubtree(
          key: ValueKey<int>(tick),
          child: AppBootstrapper(localeController: localeController),
        );
      },
    );
  }
}
