import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/edit/generated_edits.dart';

class DeleteWidgetInput {
  const DeleteWidgetInput({
    required this.name,
    this.feature,
    this.projectRoot,
    this.dryRun = false,
  });

  /// The widget name. When [feature] is null, the widget is shared
  /// (`lib/shared/widgets/<name>/`); otherwise it is scoped to that feature
  /// (`lib/features/<feature>/ui/widgets/<name>/`).
  final String name;
  final String? feature;
  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteWidgetPlan {
  const DeleteWidgetPlan({
    required this.name,
    required this.feature,
    required this.packageName,
    required this.className,
    required this.viewModelClassName,
    required this.directoryPath,
    required this.path,
    required this.viewModelPath,
    required this.dryRun,
  });

  final String name;
  final String? feature;
  final String packageName;
  final String className;
  final String viewModelClassName;
  final String directoryPath;
  final String path;
  final String viewModelPath;
  final bool dryRun;

  bool get isShared => feature == null;
}

class DeleteWidgetResult {
  const DeleteWidgetResult({required this.plan});

  final DeleteWidgetPlan plan;
}

class DeleteWidgetException implements Exception {
  const DeleteWidgetException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeleteWidgetService {
  Future<DeleteWidgetPlan> plan(DeleteWidgetInput input) async {
    final widgetName = _normalizeName(input.name, label: 'Widget');
    final words = widgetName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);

    if (input.feature == null) {
      final directoryPath = 'lib/shared/widgets/$widgetName';
      return DeleteWidgetPlan(
        name: widgetName,
        feature: null,
        packageName: packageName,
        className: _pascalCase(words),
        viewModelClassName: '${_pascalCase(words)}ViewModel',
        directoryPath: directoryPath,
        path: '$directoryPath/${widgetName}_widget.dart',
        viewModelPath: '$directoryPath/${widgetName}_view_model.dart',
        dryRun: input.dryRun,
      );
    }

    final featureName = _normalizeName(input.feature!, label: 'Feature');
    final directoryPath = 'lib/features/$featureName/ui/widgets/$widgetName';
    return DeleteWidgetPlan(
      name: widgetName,
      feature: featureName,
      packageName: packageName,
      className: _pascalCase(words),
      viewModelClassName: '${_pascalCase(words)}ViewModel',
      directoryPath: directoryPath,
      path: '$directoryPath/${widgetName}_widget.dart',
      viewModelPath: '$directoryPath/${widgetName}_view_model.dart',
      dryRun: input.dryRun,
    );
  }

  Future<DeleteWidgetResult> delete(DeleteWidgetInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final widgetFile = targetFile(projectRoot, deletePlan.path);
    final viewModelFile = targetFile(projectRoot, deletePlan.viewModelPath);
    final widgetDirectory = targetDirectory(
      projectRoot,
      deletePlan.directoryPath,
    );

    if (!isRegularFile(widgetFile.path) || !isRegularFile(viewModelFile.path)) {
      throw DeleteWidgetException('Widget not found: ${deletePlan.name}.');
    }

    if (deletePlan.dryRun) {
      return DeleteWidgetResult(plan: deletePlan);
    }

    try {
      widgetFile.deleteSync();
      viewModelFile.deleteSync();
      deleteDirectoryIfExists(widgetDirectory);
      if (deletePlan.isShared) {
        pruneEmptyDirectories(
          targetDirectory(projectRoot, 'lib/shared/widgets'),
          stopAt: projectRoot,
        );
      } else {
        final featureUiDirectory = targetDirectory(
          projectRoot,
          'lib/features/${deletePlan.feature}/ui',
        );
        pruneEmptyDirectories(
          targetDirectory(
            projectRoot,
            'lib/features/${deletePlan.feature}/ui/widgets',
          ),
          stopAt: featureUiDirectory,
        );
      }
    } on FileSystemException catch (error) {
      throw DeleteWidgetException(
        'Unable to delete widget ${deletePlan.className}: ${error.message}',
      );
    } catch (error) {
      throw DeleteWidgetException(
        'Unable to delete widget ${deletePlan.className}: $error',
      );
    }

    return DeleteWidgetResult(plan: deletePlan);
  }
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw DeleteWidgetException('Unable to read $label: ${error.message}');
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  if (!isRegularFile(pubspecPath)) {
    throw const DeleteWidgetException(
      'pubspec.yaml was not found in the current project.',
    );
  }

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const DeleteWidgetException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const DeleteWidgetException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeName(String input, {required String label}) {
  final value = input.trim();
  if (value.isEmpty) {
    throw DeleteWidgetException('$label name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw DeleteWidgetException(
      '$label name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw DeleteWidgetException(
      '$label name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw DeleteWidgetException(
      '$label name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw DeleteWidgetException('$label name must not be a Dart keyword.');
  }
  return normalized;
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}
