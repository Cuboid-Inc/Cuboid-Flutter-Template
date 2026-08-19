import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/edit/generated_edits.dart';
import 'package:cuboid/src/route/register_route.dart';

class DeleteFeatureInput {
  const DeleteFeatureInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteFeaturePlan {
  const DeleteFeaturePlan({
    required this.name,
    required this.displayName,
    required this.packageName,
    required this.repositoryClassName,
    required this.featureDirectoryPath,
    required this.locatorPath,
    required this.routerPath,
    required this.repositoryImportLine,
    required this.repositoryLine,
    required this.dryRun,
  });

  final String name;
  final String displayName;
  final String packageName;
  final String repositoryClassName;
  final String featureDirectoryPath;
  final String locatorPath;
  final String routerPath;
  final String repositoryImportLine;
  final String repositoryLine;
  final bool dryRun;
}

class DeleteFeatureResult {
  const DeleteFeatureResult({required this.plan});

  final DeleteFeaturePlan plan;
}

class DeleteFeatureException implements Exception {
  const DeleteFeatureException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeleteFeatureService {
  Future<DeleteFeaturePlan> plan(DeleteFeatureInput input) async {
    final featureName = _normalizeFeatureName(input.name);
    final words = featureName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final repositoryClassName = '${_pascalCase(words)}Repository';

    return DeleteFeaturePlan(
      name: featureName,
      displayName: _humanize(words),
      packageName: packageName,
      repositoryClassName: repositoryClassName,
      featureDirectoryPath: 'lib/features/$featureName',
      locatorPath: 'lib/app/app.locator.dart',
      routerPath: 'lib/app/app.router.dart',
      repositoryImportLine:
          "import 'package:$packageName/features/$featureName/data/${featureName}_repository.dart';",
      repositoryLine:
          '  locator.registerLazySingleton<$repositoryClassName>(() => const $repositoryClassName());',
      dryRun: input.dryRun,
    );
  }

  Future<DeleteFeatureResult> delete(DeleteFeatureInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final featureDirectory = targetDirectory(
      projectRoot,
      deletePlan.featureDirectoryPath,
    );
    final routerFile = targetFile(projectRoot, deletePlan.routerPath);
    final locatorFile = targetFile(projectRoot, deletePlan.locatorPath);

    if (!isRegularDirectory(featureDirectory.path)) {
      throw DeleteFeatureException('Feature not found: ${deletePlan.name}.');
    }
    if (!isRegularFile(routerFile.path)) {
      throw DeleteFeatureException('${deletePlan.routerPath} was not found.');
    }

    final routerContents = _readFile(routerFile, deletePlan.routerPath);
    final nextRouterContents = _removeFeatureRoutes(routerContents, deletePlan);

    String? locatorContents;
    String? nextLocatorContents;
    if (isRegularFile(locatorFile.path)) {
      final contents = _readFile(locatorFile, deletePlan.locatorPath);
      final hasImport = contents.contains(deletePlan.repositoryImportLine);
      final hasRegistration = RegExp(
        r'register\w*\s*<\s*' +
            RegExp.escape(deletePlan.repositoryClassName) +
            r'\s*>',
      ).hasMatch(contents);
      if (hasImport && hasRegistration) {
        locatorContents = contents;
        var next = removeExactLine(contents, deletePlan.repositoryImportLine);
        next = next == null
            ? contents
            : removeExactLine(next, deletePlan.repositoryLine) ?? next;
        nextLocatorContents = next;
      }
    }

    if (deletePlan.dryRun) {
      return DeleteFeatureResult(plan: deletePlan);
    }

    try {
      atomicReplaceFileContents(routerFile, nextRouterContents);
      if (locatorContents != null && nextLocatorContents != null) {
        atomicReplaceFileContents(locatorFile, nextLocatorContents);
      }
      deleteDirectoryIfExists(featureDirectory);
    } on FileSystemException catch (error) {
      final restored = {routerFile: routerContents};
      if (locatorContents != null) {
        restored[locatorFile] = locatorContents;
      }
      restoreFileContents(restored);
      throw DeleteFeatureException(
        'Unable to delete feature ${deletePlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      final restored = {routerFile: routerContents};
      if (locatorContents != null) {
        restored[locatorFile] = locatorContents;
      }
      restoreFileContents(restored);
      throw DeleteFeatureException(
        'Unable to delete feature ${deletePlan.displayName}: $error',
      );
    }

    return DeleteFeatureResult(plan: deletePlan);
  }
}

/// Removes the route registration for every View import found under
/// `lib/features/<name>/ui/` in [routerContents] -- the feature's primary
/// View and any additional Views created later via
/// `cuboid create view <extra> <name>`. Zero matches is not an error: the
/// primary View's route may already have been removed via
/// `cuboid delete view` before this runs.
String _removeFeatureRoutes(String routerContents, DeleteFeaturePlan plan) {
  final viewImportPattern = RegExp(
    r'''^[ \t]*import\s+(['"])[^'"]*/features/''' +
        RegExp.escape(plan.name) +
        r'''/ui/([a-z][a-z0-9_]*)_view\.dart\1\s*;[ \t]*$''',
    multiLine: true,
  );

  final views = <String, String>{};
  for (final match in viewImportPattern.allMatches(routerContents)) {
    views[match.group(2)!] = match.group(0)!.trim();
  }

  var contents = routerContents;
  for (final entry in views.entries) {
    try {
      contents = removeRouteRegistration(
        contents,
        viewName: entry.key,
        importLine: entry.value,
      );
    } on RouteRegistrationException catch (error) {
      throw DeleteFeatureException(error.message);
    }
  }
  return contents;
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw DeleteFeatureException('Unable to read $label: ${error.message}');
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  if (!isRegularFile(pubspecPath)) {
    throw const DeleteFeatureException(
      'pubspec.yaml was not found in the current project.',
    );
  }

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const DeleteFeatureException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const DeleteFeatureException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeFeatureName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const DeleteFeatureException('Feature name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const DeleteFeatureException(
      'Feature name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const DeleteFeatureException(
      'Feature name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const DeleteFeatureException(
      'Feature name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const DeleteFeatureException(
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
