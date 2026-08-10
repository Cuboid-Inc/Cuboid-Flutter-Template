import 'dart:async';

import 'package:nemara_homes/app/app.locator.dart';
import 'package:nemara_homes/app/app.logger.dart';
import 'package:nemara_homes/app/app_root.dart';
import 'package:nemara_homes/core/config/env.dart';
import 'package:nemara_homes/core/constants/asset_paths.dart';
import 'package:nemara_homes/core/storage/secure_local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  await startupLogoReady;
  _logger.i('Startup assets and services ready');
  runApp(const MyApp());
}

Future<void> _precacheStartupLogo() async {
  final stream = const AssetImage(
    AssetPaths.startupLogo,
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
