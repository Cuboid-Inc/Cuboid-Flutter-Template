import 'dart:io';

import 'package:cuboid/src/install/install_cuboid.dart';

/// Installs `cuboid` as a native executable, replacing `dart pub global
/// activate`'s broken shell shim. See install_cuboid.dart for why.
///
/// Usage: dart run packages/cuboid/tool/install.dart
Future<void> main() async {
  final packageRoot = Directory.fromUri(Platform.script.resolve('..')).absolute;
  final binDirectory = resolvePubCacheBinDirectory(
    environment: Platform.environment,
    isWindows: Platform.isWindows,
  );

  try {
    final result = await installCuboidExecutable(
      packageRoot: packageRoot,
      binDirectory: binDirectory,
    );
    stdout.writeln('Installed cuboid at ${result.executablePath}');
  } on InstallCuboidException catch (error) {
    stderr.writeln('Install failed: ${error.message}');
    exitCode = 1;
  }
}
