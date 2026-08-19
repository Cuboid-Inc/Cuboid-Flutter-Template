import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/edit/generated_edits.dart';
import 'package:cuboid/src/route/register_route.dart';

class DeleteViewInput {
  const DeleteViewInput({
    this.feature,
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  /// The feature this view belongs to. When null, the view is shared
  /// (`lib/shared/views/`) instead of feature-scoped
  /// (`lib/features/<feature>/ui/`).
  final String? feature;
  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteViewPlan {
  const DeleteViewPlan({
    required this.featureName,
    required this.name,
    required this.displayName,
    required this.packageName,
    required this.viewClassName,
    required this.viewModelClassName,
    required this.files,
    required this.routerPath,
    required this.routeRegistration,
    required this.dryRun,
  });

  /// Null when the view is shared rather than feature-scoped.
  final String? featureName;
  final String name;
  final String displayName;
  final String packageName;
  final String viewClassName;
  final String viewModelClassName;
  final List<String> files;
  final String routerPath;
  final RouteRegistration routeRegistration;
  final bool dryRun;

  bool get isShared => featureName == null;
}

class DeleteViewResult {
  const DeleteViewResult({required this.plan});

  final DeleteViewPlan plan;
}

class DeleteViewException implements Exception {
  const DeleteViewException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeleteViewService {
  Future<DeleteViewPlan> plan(DeleteViewInput input) async {
    final viewName = _normalizeName(input.name, label: 'View');
    final words = viewName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);

    if (input.feature == null) {
      final routeRegistration = planSharedRouteRegistration(
        packageName: packageName,
        viewName: viewName,
      );

      return DeleteViewPlan(
        featureName: null,
        name: viewName,
        displayName: _humanize(words),
        packageName: packageName,
        viewClassName: routeRegistration.viewClassName,
        viewModelClassName: '${_pascalCase(words)}ViewModel',
        files: [
          'lib/shared/views/${viewName}_view.dart',
          'lib/shared/views/${viewName}_viewmodel.dart',
        ],
        routerPath: 'lib/app/app.router.dart',
        routeRegistration: routeRegistration,
        dryRun: input.dryRun,
      );
    }

    final featureName = _normalizeName(input.feature!, label: 'Feature');
    final routeRegistration = planRouteRegistration(
      packageName: packageName,
      featureName: featureName,
      viewName: viewName,
    );

    return DeleteViewPlan(
      featureName: featureName,
      name: viewName,
      displayName: _humanize(words),
      packageName: packageName,
      viewClassName: routeRegistration.viewClassName,
      viewModelClassName: '${_pascalCase(words)}ViewModel',
      files: [
        'lib/features/$featureName/ui/${viewName}_view.dart',
        'lib/features/$featureName/ui/${viewName}_viewmodel.dart',
      ],
      routerPath: 'lib/app/app.router.dart',
      routeRegistration: routeRegistration,
      dryRun: input.dryRun,
    );
  }

  Future<DeleteViewResult> delete(DeleteViewInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final viewFile = targetFile(projectRoot, deletePlan.files[0]);
    final viewModelFile = targetFile(projectRoot, deletePlan.files[1]);
    final routerFile = targetFile(projectRoot, deletePlan.routerPath);

    if (!isRegularFile(viewFile.path) || !isRegularFile(viewModelFile.path)) {
      throw DeleteViewException('View not found: ${deletePlan.name}.');
    }
    if (!isRegularFile(routerFile.path)) {
      throw DeleteViewException('${deletePlan.routerPath} was not found.');
    }
    final routerContents = _readFile(routerFile, deletePlan.routerPath);
    final String nextRouterContents;
    try {
      nextRouterContents = removeRouteRegistration(
        routerContents,
        viewName: deletePlan.name,
        importLine: deletePlan.routeRegistration.importLine,
      );
    } on RouteRegistrationException catch (error) {
      throw DeleteViewException(error.message);
    }

    if (deletePlan.dryRun) {
      return DeleteViewResult(plan: deletePlan);
    }

    try {
      atomicReplaceFileContents(routerFile, nextRouterContents);
      viewFile.deleteSync();
      viewModelFile.deleteSync();
      if (deletePlan.isShared) {
        pruneEmptyDirectories(
          targetDirectory(projectRoot, 'lib/shared/views'),
          stopAt: projectRoot,
        );
      }
    } on FileSystemException catch (error) {
      restoreFileContents({routerFile: routerContents});
      throw DeleteViewException(
        'Unable to delete view ${deletePlan.displayName}: ${error.message}',
      );
    } catch (error) {
      restoreFileContents({routerFile: routerContents});
      throw DeleteViewException(
        'Unable to delete view ${deletePlan.displayName}: $error',
      );
    }

    return DeleteViewResult(plan: deletePlan);
  }
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw DeleteViewException('Unable to read $label: ${error.message}');
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  if (!isRegularFile(pubspecPath)) {
    throw const DeleteViewException(
      'pubspec.yaml was not found in the current project.',
    );
  }

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const DeleteViewException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const DeleteViewException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeName(String input, {required String label}) {
  final value = input.trim();
  if (value.isEmpty) {
    throw DeleteViewException('$label name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw DeleteViewException(
      '$label name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw DeleteViewException(
      '$label name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw DeleteViewException(
      '$label name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw DeleteViewException('$label name must not be a Dart keyword.');
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
