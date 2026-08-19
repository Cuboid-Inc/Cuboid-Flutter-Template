import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

typedef ModelFileWriter = void Function(File file, String contents);

class CreateModelInput {
  const CreateModelInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class CreateModelPlan {
  const CreateModelPlan({
    required this.name,
    required this.className,
    required this.path,
    required this.dryRun,
  });

  final String name;
  final String className;
  final String path;
  final bool dryRun;
}

class CreateModelResult {
  const CreateModelResult({required this.plan});

  final CreateModelPlan plan;
}

class CreateModelException implements Exception {
  const CreateModelException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateModelService {
  CreateModelService({ModelFileWriter? fileWriter})
    : _fileWriter =
          fileWriter ?? ((file, contents) => file.writeAsStringSync(contents));

  final ModelFileWriter _fileWriter;

  Future<CreateModelPlan> plan(CreateModelInput input) async {
    final modelName = _normalizeModelName(input.name);
    final words = modelName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    _ensureProjectRoot(projectRoot);

    return CreateModelPlan(
      name: modelName,
      className: _pascalCase(words),
      path: 'lib/core/models/$modelName.dart',
      dryRun: input.dryRun,
    );
  }

  Future<CreateModelResult> create(CreateModelInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final modelFile = _targetFile(projectRoot, createPlan.path);

    _validateTarget(projectRoot, createPlan, modelFile);

    if (createPlan.dryRun) {
      return CreateModelResult(plan: createPlan);
    }

    final createdDirectories = <Directory>[];
    try {
      _createParentDirectories(
        projectRoot,
        modelFile.parent,
        createdDirectories,
      );
      _fileWriter(modelFile, _modelContents(createPlan));
    } on FileSystemException catch (error) {
      _rollback(modelFile, createdDirectories);
      throw CreateModelException(
        'Unable to create model ${createPlan.className}: ${error.message}',
      );
    } catch (error) {
      _rollback(modelFile, createdDirectories);
      throw CreateModelException(
        'Unable to create model ${createPlan.className}: $error',
      );
    }

    return CreateModelResult(plan: createPlan);
  }
}

void _validateTarget(
  Directory projectRoot,
  CreateModelPlan plan,
  File modelFile,
) {
  _validateNoAncestorSymlinks(projectRoot);

  if (modelFile.existsSync() ||
      Directory(modelFile.path).existsSync() ||
      Link(modelFile.path).existsSync()) {
    throw CreateModelException('Target already exists: ${plan.path}');
  }
}

void _validateNoAncestorSymlinks(Directory projectRoot) {
  final lib = Directory('${projectRoot.path}${Platform.pathSeparator}lib');
  final core = Directory('${lib.path}${Platform.pathSeparator}core');
  final models = Directory('${core.path}${Platform.pathSeparator}models');
  for (final directory in [lib, core, models]) {
    if (Link(directory.path).existsSync()) {
      throw CreateModelException(
        'Refusing to create model through a symlink: '
        '${_relativePath(projectRoot, directory.path)}',
      );
    }
  }
}

void _ensureProjectRoot(Directory projectRoot) {
  final pubspec = File(
    '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml',
  );
  if (!pubspec.existsSync()) {
    throw const CreateModelException(
      'pubspec.yaml was not found in the current project.',
    );
  }
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

void _rollback(File modelFile, List<Directory> createdDirectories) {
  try {
    if (modelFile.existsSync()) {
      modelFile.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup; preserve the original creation failure.
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

String _normalizeModelName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const CreateModelException('Model name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const CreateModelException(
      'Model name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const CreateModelException(
      'Model name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const CreateModelException(
      'Model name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const CreateModelException('Model name must not be a Dart keyword.');
  }
  return normalized;
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}

String _modelContents(CreateModelPlan plan) {
  return '''
class ${plan.className} {
  const ${plan.className}();
}
''';
}
