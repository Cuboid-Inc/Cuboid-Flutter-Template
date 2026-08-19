import 'dart:async';

import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.logger.dart';
import 'package:cuboid_flutter_template/app/app_root.dart';
import 'package:cuboid_flutter_template/core/constants/asset_paths.dart';
import 'package:flutter/material.dart';

final _logger = AppLogger('AppStartup');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startupLogoReady = _precacheStartupLogo();

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
