import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/route/register_route.dart';

typedef ViewFileWriter = void Function(File file, String contents);

class CreateViewInput {
  const CreateViewInput({
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

class CreateViewPlan {
  const CreateViewPlan({
    required this.featureName,
    required this.name,
    required this.displayName,
    required this.packageName,
    required this.viewClassName,
    required this.viewModelClassName,
    required this.featureDirectory,
    required this.files,
    required this.appPath,
    required this.routeImportLine,
    required this.routeLine,
    required this.dryRun,
  });

  /// Null when the view is shared rather than feature-scoped.
  final String? featureName;
  final String name;
  final String displayName;
  final String packageName;
  final String viewClassName;
  final String viewModelClassName;

  /// Null when the view is shared rather than feature-scoped.
  final Directory? featureDirectory;
  final List<String> files;
  final String appPath;
  final String routeImportLine;
  final String routeLine;
  final bool dryRun;

  bool get isShared => featureName == null;
}

class CreateViewResult {
  const CreateViewResult({required this.plan});

  final CreateViewPlan plan;
}

class CreateViewException implements Exception {
  const CreateViewException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateViewService {
  CreateViewService({ViewFileWriter? fileWriter})
    : _fileWriter = fileWriter ?? _defaultFileWriter;

  final ViewFileWriter _fileWriter;

  Future<CreateViewPlan> plan(CreateViewInput input) async {
    final viewName = _normalizeName(input.name, label: 'View');
    final words = viewName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);

    if (input.feature == null) {
      final routeRegistration = planSharedRouteRegistration(
        packageName: packageName,
        viewName: viewName,
      );

      return CreateViewPlan(
        featureName: null,
        name: viewName,
        displayName: _humanize(words),
        packageName: packageName,
        viewClassName: routeRegistration.viewClassName,
        viewModelClassName: '${_pascalCase(words)}ViewModel',
        featureDirectory: null,
        files: [
          'lib/shared/views/${viewName}_view.dart',
          'lib/shared/views/${viewName}_viewmodel.dart',
        ],
        appPath: 'lib/app/app.dart',
        routeImportLine: routeRegistration.importLine,
        routeLine: routeRegistration.routeLine,
        dryRun: input.dryRun,
      );
    }

    final featureName = _normalizeName(input.feature!, label: 'Feature');
    final featureDirectory = Directory(
      '${projectRoot.path}${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}features${Platform.pathSeparator}$featureName',
    );
    final viewPath = 'lib/features/$featureName/ui/${viewName}_view.dart';
    final viewModelPath =
        'lib/features/$featureName/ui/${viewName}_viewmodel.dart';
    final routeRegistration = planRouteRegistration(
      packageName: packageName,
      featureName: featureName,
      viewName: viewName,
    );

    return CreateViewPlan(
      featureName: featureName,
      name: viewName,
      displayName: _humanize(words),
      packageName: packageName,
      viewClassName: routeRegistration.viewClassName,
      viewModelClassName: '${_pascalCase(words)}ViewModel',
      featureDirectory: featureDirectory,
      files: [viewPath, viewModelPath],
      appPath: 'lib/app/app.dart',
      routeImportLine: routeRegistration.importLine,
      routeLine: routeRegistration.routeLine,
      dryRun: input.dryRun,
    );
  }

  Future<CreateViewResult> create(CreateViewInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    _validateTargets(projectRoot, createPlan);

    final appFile = _targetFile(projectRoot, createPlan.appPath);
    final appContents = _validateApp(createPlan, appFile);
    final nextAppContents = _applyAppPlan(appContents, createPlan);

    final viewContents = _viewContents(createPlan);
    final viewModelContents = _viewModelContents(createPlan);

    if (createPlan.dryRun) {
      return CreateViewResult(plan: createPlan);
    }

    final viewFile = _targetFile(projectRoot, createPlan.files[0]);
    final viewModelFile = _targetFile(projectRoot, createPlan.files[1]);
    final createdDirectories = <Directory>[];

    try {
      _createParentDirectories(
        projectRoot,
        viewFile.parent,
        createdDirectories,
      );
      _createParentDirectories(
        projectRoot,
        viewModelFile.parent,
        createdDirectories,
      );
      _fileWriter(viewFile, viewContents);
      _fileWriter(viewModelFile, viewModelContents);
      _replaceFileContents(appFile, nextAppContents, label: createPlan.appPath);
    } on FileSystemException catch (error) {
      _deleteCreatedFile(viewFile);
      _deleteCreatedFile(viewModelFile);
      _pruneCreatedDirectories(createdDirectories);
      _restoreFileContents(appFile, appContents);
      throw CreateViewException(
        'Unable to create view ${createPlan.displayName}: ${error.message}',
      );
    }

    return CreateViewResult(plan: createPlan);
  }
}

void _validateTargets(Directory projectRoot, CreateViewPlan plan) {
  if (!plan.isShared) {
    _ensureRegularDirectory(
      plan.featureDirectory!.path,
      'lib/features/${plan.featureName}',
    );
  }

  for (final path in plan.files) {
    final target = _targetFile(projectRoot, path);
    _ensureBeneathProjectRoot(projectRoot, target);
    _ensureSafeParentDirectories(projectRoot, target.parent);
    final type = FileSystemEntity.typeSync(target.path, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      throw CreateViewException('Target already exists: $path');
    }
  }
}

String _validateApp(CreateViewPlan plan, File appFile) {
  _ensureRegularFile(appFile.path, plan.appPath);
  final contents = _readFile(appFile, plan.appPath);

  final routeRegistration = RouteRegistration(
    viewClassName: plan.viewClassName,
    importLine: plan.routeImportLine,
    routeLine: plan.routeLine,
  );
  try {
    validateRouteRegistration(contents, routeRegistration);
  } on RouteRegistrationException catch (error) {
    throw CreateViewException(error.message);
  }

  return contents;
}

String _applyAppPlan(String contents, CreateViewPlan plan) {
  final routeRegistration = RouteRegistration(
    viewClassName: plan.viewClassName,
    importLine: plan.routeImportLine,
    routeLine: plan.routeLine,
  );
  return applyRouteRegistration(contents, routeRegistration);
}

void _ensureRegularDirectory(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw CreateViewException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw CreateViewException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.directory) {
    throw CreateViewException('$label must be a directory.');
  }
}

void _ensureRegularFile(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw CreateViewException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw CreateViewException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.file) {
    throw CreateViewException('$label must be a regular file.');
  }
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw CreateViewException('Unable to read $label: ${error.message}');
  }
}

void _ensureBeneathProjectRoot(Directory projectRoot, File target) {
  final rootPath = _withTrailingSeparator(projectRoot.absolute.path);
  final targetPath = target.absolute.path;
  if (!targetPath.startsWith(rootPath)) {
    throw const CreateViewException(
      'Target path must stay inside the project.',
    );
  }
}

void _ensureSafeParentDirectories(Directory projectRoot, Directory parent) {
  final rootPath = projectRoot.absolute.path;
  final parentPath = parent.absolute.path;
  if (!parentPath.startsWith(_withTrailingSeparator(rootPath))) {
    throw const CreateViewException(
      'Target path must stay inside the project.',
    );
  }

  final relative = parentPath.substring(rootPath.length + 1);
  var current = rootPath;
  for (final segment in relative.split(Platform.pathSeparator)) {
    current = '$current${Platform.pathSeparator}$segment';
    final type = FileSystemEntity.typeSync(current, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      continue;
    }
    if (type == FileSystemEntityType.link) {
      throw CreateViewException('$current must not be a symlink.');
    }
    if (type != FileSystemEntityType.directory) {
      throw CreateViewException('$current must be a directory.');
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
    throw CreateViewException('Unable to read pubspec.yaml: ${error.message}');
  }

  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const CreateViewException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const CreateViewException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeName(String input, {required String label}) {
  final value = input.trim();
  if (value.isEmpty) {
    throw CreateViewException('$label name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw CreateViewException(
      '$label name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw CreateViewException(
      '$label name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw CreateViewException(
      '$label name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw CreateViewException('$label name must not be a Dart keyword.');
  }
  return normalized;
}

File _targetFile(Directory projectRoot, String path) {
  return File(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${path.replaceAll('/', Platform.pathSeparator)}',
  );
}

String _withTrailingSeparator(String path) {
  return path.endsWith(Platform.pathSeparator)
      ? path
      : '$path${Platform.pathSeparator}';
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}

String _humanize(List<String> words) {
  return words
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String _viewContents(CreateViewPlan plan) {
  final viewName = plan.name;
  final viewModelImportPath = plan.isShared
      ? 'shared/views/${viewName}_viewmodel.dart'
      : 'features/${plan.featureName}/ui/${viewName}_viewmodel.dart';
  return '''
import 'package:${plan.packageName}/$viewModelImportPath';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class ${plan.viewClassName} extends StackedView<${plan.viewModelClassName}> {
  const ${plan.viewClassName}({super.key});

  @override
  ${plan.viewModelClassName} viewModelBuilder(BuildContext context) =>
      ${plan.viewModelClassName}();

  @override
  Widget builder(
    BuildContext context,
    ${plan.viewModelClassName} vm,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('${plan.displayName}')),
      body: const Center(child: Text('${plan.displayName}')),
    );
  }
}
''';
}

String _viewModelContents(CreateViewPlan plan) {
  return '''
import 'package:stacked/stacked.dart';

class ${plan.viewModelClassName} extends BaseViewModel {}
''';
}

void _defaultFileWriter(File file, String contents) {
  file.writeAsStringSync(contents);
}

void _deleteCreatedFile(File file) {
  try {
    if (FileSystemEntity.typeSync(file.path, followLinks: false) ==
        FileSystemEntityType.file) {
      file.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup; preserve the original publish failure.
  }
}

void _restoreFileContents(File file, String contents) {
  try {
    file.writeAsStringSync(contents);
  } on FileSystemException {
    // Best-effort cleanup; preserve the original publish failure.
  }
}

void _replaceFileContents(File file, String contents, {required String label}) {
  final Directory temp;
  try {
    temp = file.parent.createTempSync('.cuboid-view-');
  } on FileSystemException catch (error) {
    throw CreateViewException('Unable to update $label: ${error.message}');
  }
  final tempFile = File(
    '${temp.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
  );
  try {
    tempFile.writeAsStringSync(contents);
    tempFile.renameSync(file.path);
  } on FileSystemException catch (error) {
    throw CreateViewException('Unable to update $label: ${error.message}');
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

void _createParentDirectories(
  Directory projectRoot,
  Directory targetDirectory,
  List<Directory> createdDirectories,
) {
  final missing = <Directory>[];
  var current = targetDirectory;
  while (current.path != projectRoot.path && !current.existsSync()) {
    missing.add(current);
    current = current.parent;
  }

  targetDirectory.createSync(recursive: true);
  createdDirectories.addAll(missing);
}

void _pruneCreatedDirectories(List<Directory> createdDirectories) {
  final directories = createdDirectories.toSet().toList()
    ..sort((a, b) => b.path.length.compareTo(a.path.length));
  for (final directory in directories) {
    try {
      if (directory.existsSync() && directory.listSync().isEmpty) {
        directory.deleteSync();
      }
    } on FileSystemException {
      // Best-effort cleanup; preserve the original creation failure.
    }
  }
}
