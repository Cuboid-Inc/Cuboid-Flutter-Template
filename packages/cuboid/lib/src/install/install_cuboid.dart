import 'dart:io';

/// Installs the `cuboid` executable without relying on `dart pub global
/// activate`'s generated POSIX shell shim.
///
/// That shim embeds the absolute path to the compiled snapshot directly into
/// an unquoted `[ -f <path> ]` test (`if [ -f $snapshotPath ]; then ...`).
/// When the source checkout lives under a path containing a space -- for
/// example `~/Cuboid Projects/Cuboid Flutter Template` -- the shell splits
/// that path on the space and `[` fails with `too many arguments` on every
/// invocation. This is a defect in the shim template `dart pub global
/// activate` generates for `--source path`/`--source git` packages; it is
/// not something a package can fix by changing its own source.
///
/// Compiling the CLI to a native executable with `dart compile exe` and
/// placing it at the exact path `dart pub global activate` would have used
/// sidesteps the broken shim entirely: there is no shell script to
/// mis-parse, so the fix holds regardless of whether the install path
/// contains spaces, and it behaves identically for every `cuboid` command.
typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
    });

class InstallCuboidException implements Exception {
  const InstallCuboidException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InstallCuboidResult {
  const InstallCuboidResult({required this.executablePath});

  final String executablePath;
}

/// Resolves the directory `dart pub global activate` places executables in,
/// so our installer writes to the same PATH location users already have
/// configured.
Directory resolvePubCacheBinDirectory({
  required Map<String, String> environment,
  required bool isWindows,
}) {
  final override = environment['PUB_CACHE'];
  if (override != null && override.trim().isNotEmpty) {
    return Directory('$override${Platform.pathSeparator}bin');
  }

  if (isWindows) {
    final localAppData = environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.trim().isEmpty) {
      throw const InstallCuboidException(
        'Unable to resolve the pub-cache bin directory: %LOCALAPPDATA% is not set.',
      );
    }
    return Directory('$localAppData\\Pub\\Cache\\bin');
  }

  final home = environment['HOME'];
  if (home == null || home.trim().isEmpty) {
    throw const InstallCuboidException(
      'Unable to resolve the pub-cache bin directory: \$HOME is not set.',
    );
  }
  return Directory('$home/.pub-cache/bin');
}

/// The executable filename `dart compile exe` should target, matching what
/// `dart pub global activate` would have placed on PATH.
String cuboidExecutableFileName({required bool isWindows}) =>
    isWindows ? 'cuboid.exe' : 'cuboid';

/// Compiles `<packageRoot>/<entryPointRelativePath>` to a native executable
/// and installs it into [binDirectory] under [cuboidExecutableFileName],
/// replacing any `dart pub global activate` shim at that path.
Future<InstallCuboidResult> installCuboidExecutable({
  required Directory packageRoot,
  required Directory binDirectory,
  String entryPointRelativePath = 'bin/cuboid.dart',
  ProcessRunner? processRunner,
  bool? isWindows,
}) async {
  final runProcess = processRunner ?? _defaultProcessRunner;
  final targetIsWindows = isWindows ?? Platform.isWindows;
  final entryPoint = File(
    '${packageRoot.path}${Platform.pathSeparator}'
    '${entryPointRelativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  if (!entryPoint.existsSync()) {
    throw InstallCuboidException(
      'CLI entry point was not found: ${entryPoint.path}',
    );
  }

  final pubGet = await runProcess('dart', [
    'pub',
    'get',
  ], workingDirectory: packageRoot.path);
  if (pubGet.exitCode != 0) {
    throw InstallCuboidException(
      'dart pub get failed: ${'${pubGet.stderr}'.trim()}',
    );
  }

  // Best-effort: clear any prior `dart pub global activate` registration so
  // it cannot silently regenerate the broken shim over our compiled binary
  // later. A package that was never activated exits non-zero here, which is
  // expected and ignored.
  await runProcess('dart', [
    'pub',
    'global',
    'deactivate',
    'cuboid',
  ], workingDirectory: packageRoot.path);

  binDirectory.createSync(recursive: true);
  final targetFileName = cuboidExecutableFileName(isWindows: targetIsWindows);
  final targetPath =
      '${binDirectory.path}${Platform.pathSeparator}$targetFileName';
  final stagedPath = '$targetPath.new';

  final compile = await runProcess('dart', [
    'compile',
    'exe',
    entryPoint.path,
    '-o',
    stagedPath,
  ], workingDirectory: packageRoot.path);
  if (compile.exitCode != 0) {
    throw InstallCuboidException(
      'dart compile exe failed: ${'${compile.stderr}'.trim()}',
    );
  }

  final staged = File(stagedPath);
  if (!staged.existsSync()) {
    throw InstallCuboidException(
      'dart compile exe reported success but produced no output at $stagedPath.',
    );
  }
  staged.renameSync(targetPath);

  return InstallCuboidResult(executablePath: targetPath);
}

Future<ProcessResult> _defaultProcessRunner(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) {
  return Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
}
