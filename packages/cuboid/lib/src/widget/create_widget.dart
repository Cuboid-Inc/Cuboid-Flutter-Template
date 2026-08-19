import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

typedef WidgetFileWriter = void Function(File file, String contents);

class CreateWidgetInput {
  const CreateWidgetInput({
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

class CreateWidgetPlan {
  const CreateWidgetPlan({
    required this.name,
    required this.feature,
    required this.packageName,
    required this.className,
    required this.viewModelClassName,
    required this.path,
    required this.viewModelPath,
    required this.dryRun,
  });

  final String name;
  final String? feature;
  final String packageName;
  final String className;
  final String viewModelClassName;
  final String path;
  final String viewModelPath;
  final bool dryRun;

  bool get isShared => feature == null;
}

class CreateWidgetResult {
  const CreateWidgetResult({required this.plan});

  final CreateWidgetPlan plan;
}

class CreateWidgetException implements Exception {
  const CreateWidgetException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateWidgetService {
  CreateWidgetService({WidgetFileWriter? fileWriter})
    : _fileWriter =
          fileWriter ?? ((file, contents) => file.writeAsStringSync(contents));

  final WidgetFileWriter _fileWriter;

  Future<CreateWidgetPlan> plan(CreateWidgetInput input) async {
    final widgetName = _normalizeName(input.name, label: 'Widget');
    final words = widgetName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    _ensureProjectRoot(projectRoot);
    final packageName = _readPackageName(projectRoot);

    if (input.feature == null) {
      final directoryPath = 'lib/shared/widgets/$widgetName';
      return CreateWidgetPlan(
        name: widgetName,
        feature: null,
        packageName: packageName,
        className: _pascalCase(words),
        viewModelClassName: '${_pascalCase(words)}ViewModel',
        path: '$directoryPath/${widgetName}_widget.dart',
        viewModelPath: '$directoryPath/${widgetName}_view_model.dart',
        dryRun: input.dryRun,
      );
    }

    final featureName = _normalizeName(input.feature!, label: 'Feature');
    final directoryPath = 'lib/features/$featureName/ui/widgets/$widgetName';
    return CreateWidgetPlan(
      name: widgetName,
      feature: featureName,
      packageName: packageName,
      className: _pascalCase(words),
      viewModelClassName: '${_pascalCase(words)}ViewModel',
      path: '$directoryPath/${widgetName}_widget.dart',
      viewModelPath: '$directoryPath/${widgetName}_view_model.dart',
      dryRun: input.dryRun,
    );
  }

  Future<CreateWidgetResult> create(CreateWidgetInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final widgetFile = _targetFile(projectRoot, createPlan.path);
    final viewModelFile = _targetFile(projectRoot, createPlan.viewModelPath);

    _validateTarget(projectRoot, createPlan, widgetFile, viewModelFile);

    if (createPlan.dryRun) {
      return CreateWidgetResult(plan: createPlan);
    }

    final createdDirectories = <Directory>[];
    try {
      _createParentDirectories(
        projectRoot,
        widgetFile.parent,
        createdDirectories,
      );
      _fileWriter(viewModelFile, _viewModelContents(createPlan));
      _fileWriter(widgetFile, _widgetContents(createPlan));
    } on FileSystemException catch (error) {
      _rollback(widgetFile, viewModelFile, createdDirectories);
      throw CreateWidgetException(
        'Unable to create widget ${createPlan.className}: ${error.message}',
      );
    } catch (error) {
      _rollback(widgetFile, viewModelFile, createdDirectories);
      throw CreateWidgetException(
        'Unable to create widget ${createPlan.className}: $error',
      );
    }

    return CreateWidgetResult(plan: createPlan);
  }
}

void _validateTarget(
  Directory projectRoot,
  CreateWidgetPlan plan,
  File widgetFile,
  File viewModelFile,
) {
  if (!plan.isShared) {
    final featureDirectory = Directory(
      '${projectRoot.path}${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}features${Platform.pathSeparator}${plan.feature}',
    );
    _ensureRegularDirectory(
      featureDirectory.path,
      'lib/features/${plan.feature}',
    );
  }

  _validateNoAncestorSymlinks(projectRoot, plan);

  for (final file in [widgetFile, viewModelFile]) {
    if (file.existsSync() ||
        Directory(file.path).existsSync() ||
        Link(file.path).existsSync()) {
      final path = file == widgetFile ? plan.path : plan.viewModelPath;
      throw CreateWidgetException('Target already exists: $path');
    }
  }
}

void _validateNoAncestorSymlinks(Directory projectRoot, CreateWidgetPlan plan) {
  final lib = Directory('${projectRoot.path}${Platform.pathSeparator}lib');
  final directories = <Directory>[lib];
  if (plan.isShared) {
    final shared = Directory('${lib.path}${Platform.pathSeparator}shared');
    final widgets = Directory('${shared.path}${Platform.pathSeparator}widgets');
    directories.addAll([
      shared,
      widgets,
      Directory('${widgets.path}${Platform.pathSeparator}${plan.name}'),
    ]);
  } else {
    final features = Directory('${lib.path}${Platform.pathSeparator}features');
    final feature = Directory(
      '${features.path}${Platform.pathSeparator}${plan.feature}',
    );
    final ui = Directory('${feature.path}${Platform.pathSeparator}ui');
    final widgets = Directory('${ui.path}${Platform.pathSeparator}widgets');
    directories.addAll([
      features,
      feature,
      ui,
      widgets,
      Directory('${widgets.path}${Platform.pathSeparator}${plan.name}'),
    ]);
  }

  for (final directory in directories) {
    if (Link(directory.path).existsSync()) {
      throw CreateWidgetException(
        'Refusing to create widget through a symlink: '
        '${_relativePath(projectRoot, directory.path)}',
      );
    }
  }
}

void _ensureRegularDirectory(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw CreateWidgetException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw CreateWidgetException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.directory) {
    throw CreateWidgetException('$label must be a directory.');
  }
}

void _ensureProjectRoot(Directory projectRoot) {
  final pubspec = File(
    '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml',
  );
  if (!pubspec.existsSync()) {
    throw const CreateWidgetException(
      'pubspec.yaml was not found in the current project.',
    );
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  final pubspec = File(pubspecPath);
  final String contents;
  try {
    contents = pubspec.readAsStringSync();
  } on FileSystemException catch (error) {
    throw CreateWidgetException(
      'Unable to read pubspec.yaml: ${error.message}',
    );
  }

  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const CreateWidgetException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const CreateWidgetException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

File _targetFile(Directory projectRoot, String path) {
  return File(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${path.replaceAll('/', Platform.pathSeparator)}',
  );
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

void _rollback(
  File widgetFile,
  File viewModelFile,
  List<Directory> createdDirectories,
) {
  for (final file in [widgetFile, viewModelFile]) {
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on FileSystemException {
      // Best-effort cleanup; preserve the original creation failure.
    }
  }

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

String _relativePath(Directory root, String path) {
  return path
      .substring(root.path.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

String _normalizeName(String input, {required String label}) {
  final value = input.trim();
  if (value.isEmpty) {
    throw CreateWidgetException('$label name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw CreateWidgetException(
      '$label name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw CreateWidgetException(
      '$label name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw CreateWidgetException(
      '$label name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw CreateWidgetException('$label name must not be a Dart keyword.');
  }
  return normalized;
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}

String _widgetContents(CreateWidgetPlan plan) {
  final viewModelImportPath = plan.isShared
      ? 'shared/widgets/${plan.name}/${plan.name}_view_model.dart'
      : 'features/${plan.feature}/ui/widgets/${plan.name}/'
            '${plan.name}_view_model.dart';
  final imports = <String>[
    "import 'package:cuboid_flutter/cuboid_flutter.dart';",
    "import 'package:${plan.packageName}/$viewModelImportPath';",
    "import 'package:flutter/material.dart';",
  ]..sort();
  return '''
${imports.join('\n')}

class ${plan.className} extends CuboidView<${plan.viewModelClassName}> {
  const ${plan.className}({super.key});

  @override
  ${plan.viewModelClassName} viewModelBuilder(BuildContext context) =>
      ${plan.viewModelClassName}();

  @override
  Widget builder(
    BuildContext context,
    ${plan.viewModelClassName} vm,
    Widget? child,
  ) {
    return const SizedBox.shrink();
  }
}
''';
}

String _viewModelContents(CreateWidgetPlan plan) {
  return '''
import 'package:cuboid_flutter/cuboid_flutter.dart';

class ${plan.viewModelClassName} extends CuboidViewModel {}
''';
}
