import 'dart:async';

import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.dialogs.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/config/app_config.dart';
import 'package:cuboid_flutter_template/core/supabase/env.dart';
import 'package:cuboid_flutter_template/core/supabase/secure_local_storage.dart';
import 'package:cuboid_flutter_template/main.logger.dart';
import 'package:cuboid_flutter_template/ui/common/app_theme.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upgrader/upgrader.dart';

final _logger = AppLogger('AppStartup');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startupLogoReady = _precacheStartupLogo();

  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(),
      ),
    );
    _logger.i('Supabase initialized');
  } else if (kReleaseMode) {
    // Fail fast: a release build must never silently run in demo mode.
    final error = StateError(
      'Cuboid Flutter Template release build without Supabase config. '
      'Build with --dart-define-from-file=env/prod.json.',
    );
    _logger.e(
      'Startup failed because Supabase configuration is missing',
      error: error,
    );
    throw error;
  } else {
    _logger.w('Starting in unconfigured development mode');
  }

  await setupLocator();
  setupBottomSheetUi();
  setupDialogUi();
  setupSnackbarUi();

  await startupLogoReady;
  _logger.i('Startup assets and services ready');
  runApp(const MyApp());
}

Future<void> _precacheStartupLogo() async {
  final stream = const AssetImage(
    'assets/splash/logo_tile.png',
  ).resolve(ImageConfiguration.empty);
  final ready = Completer<void>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, _) => ready.complete(),
    onError: (error, stackTrace) {
      _logger.e(
        'Startup logo precache failed',
        error: error,
        stackTrace: stackTrace,
      );
      ready.completeError(error, stackTrace);
    },
  );
  stream.addListener(listener);
  try {
    await ready.future;
  } finally {
    stream.removeListener(listener);
  }
}

@StackedApp(
  routes: [],
  logger: StackedLogger(logHelperName: "AppLogger"),
)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      navigatorKey: StackedService.navigatorKey,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      initialRoute: Routes.startupView,
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          UpgradeAlert(child: child ?? const SizedBox()),
    );
  }
}
