import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

class RegisterRouteInput {
  const RegisterRouteInput({
    required this.feature,
    this.projectRoot,
    this.dryRun = false,
  });

  final String feature;
  final Directory? projectRoot;
  final bool dryRun;
}

class RegisterRoutePlan {
  const RegisterRoutePlan({
    required this.featureName,
    required this.displayName,
    required this.packageName,
    required this.viewClassName,
    required this.viewPath,
    required this.appPath,
    required this.importLine,
    required this.routeLine,
    required this.dryRun,
  });

  final String featureName;
  final String displayName;
  final String packageName;
  final String viewClassName;
  final String viewPath;
  final String appPath;
  final String importLine;
  final String routeLine;
  final bool dryRun;
}

class RegisterRouteResult {
  const RegisterRouteResult({required this.plan});

  final RegisterRoutePlan plan;
}

class RegisterRouteException implements Exception {
  const RegisterRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RegisterRouteService {
  Future<RegisterRoutePlan> plan(RegisterRouteInput input) async {
    final featureName = _normalizeFeatureName(input.feature);
    final words = featureName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final viewClassName = '${_pascalCase(words)}View';
    final viewPath = 'lib/features/$featureName/ui/${featureName}_view.dart';

    return RegisterRoutePlan(
      featureName: featureName,
      displayName: _humanize(words),
      packageName: packageName,
      viewClassName: viewClassName,
      viewPath: viewPath,
      appPath: 'lib/app/app.dart',
      importLine:
          "import 'package:$packageName/features/$featureName/ui/${featureName}_view.dart';",
      routeLine: '    MaterialRoute(page: $viewClassName),',
      dryRun: input.dryRun,
    );
  }

  Future<RegisterRouteResult> register(RegisterRouteInput input) async {
    final routePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final appFile = File(
      '${projectRoot.path}${Platform.pathSeparator}'
      '${routePlan.appPath.replaceAll('/', Platform.pathSeparator)}',
    );

    final appContents = _validateTargets(projectRoot, routePlan, appFile);
    final nextContents = _applyPlan(appContents, routePlan);

    if (routePlan.dryRun) {
      return RegisterRouteResult(plan: routePlan);
    }

    _replaceFileContents(appFile, nextContents);
    return RegisterRouteResult(plan: routePlan);
  }
}

String _validateTargets(
  Directory projectRoot,
  RegisterRoutePlan plan,
  File appFile,
) {
  _ensureRegularFile(appFile.path, 'lib/app/app.dart');
  _ensureRegularFile(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${plan.viewPath.replaceAll('/', Platform.pathSeparator)}',
    plan.viewPath,
  );

  final String contents;
  try {
    contents = appFile.readAsStringSync();
  } on FileSystemException catch (error) {
    throw RegisterRouteException(
      'Unable to read lib/app/app.dart: ${error.message}',
    );
  }

  _requireSingleMarker(contents, '// @stacked-import');
  _requireSingleMarker(contents, '// @stacked-route');
  if (contents.contains(plan.importLine)) {
    throw RegisterRouteException(
      'Route import already exists for ${plan.viewClassName}.',
    );
  }
  if (contents.contains('MaterialRoute(page: ${plan.viewClassName})')) {
    throw RegisterRouteException(
      'Route already exists for ${plan.viewClassName}.',
    );
  }
  return contents;
}

void _ensureRegularFile(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw RegisterRouteException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw RegisterRouteException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.file) {
    throw RegisterRouteException('$label must be a regular file.');
  }
}

void _requireSingleMarker(String contents, String marker) {
  final count = marker.allMatches(contents).length;
  if (count == 0) {
    throw RegisterRouteException('Missing marker: $marker');
  }
  if (count > 1) {
    throw RegisterRouteException('Duplicate marker: $marker');
  }
}

String _applyPlan(String contents, RegisterRoutePlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  return contents
      .replaceFirst(
        RegExp(r'^[ \t]*// @stacked-import', multiLine: true),
        '${plan.importLine}$lineEnding// @stacked-import',
      )
      .replaceFirst(
        RegExp(r'^[ \t]*// @stacked-route', multiLine: true),
        '${plan.routeLine}$lineEnding    // @stacked-route',
      );
}

void _replaceFileContents(File file, String contents) {
  final Directory temp;
  try {
    temp = file.parent.createTempSync('.cuboid-route-');
  } on FileSystemException catch (error) {
    throw RegisterRouteException(
      'Unable to update lib/app/app.dart: ${error.message}',
    );
  }
  final tempFile = File(
    '${temp.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
  );
  try {
    tempFile.writeAsStringSync(contents);
    tempFile.renameSync(file.path);
  } on FileSystemException catch (error) {
    throw RegisterRouteException(
      'Unable to update lib/app/app.dart: ${error.message}',
    );
  } finally {
    try {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // Best-effort cleanup; preserve the actual write or publish result.
    }
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  _ensureRegularFile(pubspecPath, 'pubspec.yaml');

  final pubspec = File(pubspecPath);
  final String contents;
  try {
    contents = pubspec.readAsStringSync();
  } on FileSystemException catch (error) {
    throw RegisterRouteException(
      'Unable to read pubspec.yaml: ${error.message}',
    );
  }

  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const RegisterRouteException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const RegisterRouteException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeFeatureName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const RegisterRouteException('Feature name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const RegisterRouteException(
      'Feature name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const RegisterRouteException(
      'Feature name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const RegisterRouteException(
      'Feature name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const RegisterRouteException(
      'Feature name must not be a Dart keyword.',
    );
  }
  return normalized;
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}

String _humanize(List<String> words) {
  return words
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
