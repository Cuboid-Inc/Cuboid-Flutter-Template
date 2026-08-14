import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

typedef FeatureFileWriter = void Function(File file, String contents);

class CreateFeatureInput {
  const CreateFeatureInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class CreateFeaturePlan {
  const CreateFeaturePlan({
    required this.name,
    required this.displayName,
    required this.packageName,
    required this.viewClassName,
    required this.viewModelClassName,
    required this.featureDirectory,
    required this.files,
    required this.dryRun,
  });

  final String name;
  final String displayName;
  final String packageName;
  final String viewClassName;
  final String viewModelClassName;
  final Directory featureDirectory;
  final List<String> files;
  final bool dryRun;
}

class CreateFeatureResult {
  const CreateFeatureResult({required this.plan});

  final CreateFeaturePlan plan;
}

class CreateFeatureException implements Exception {
  const CreateFeatureException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateFeatureService {
  CreateFeatureService({FeatureFileWriter? fileWriter})
    : _fileWriter =
          fileWriter ?? ((file, contents) => file.writeAsStringSync(contents));

  final FeatureFileWriter _fileWriter;

  Future<CreateFeaturePlan> plan(CreateFeatureInput input) async {
    final featureName = _normalizeFeatureName(input.name);
    final words = featureName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final featureDirectory = Directory(
      '${projectRoot.path}${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}features${Platform.pathSeparator}$featureName',
    );
    final viewPath = 'lib/features/$featureName/ui/${featureName}_view.dart';
    final viewModelPath =
        'lib/features/$featureName/ui/${featureName}_viewmodel.dart';

    return CreateFeaturePlan(
      name: featureName,
      displayName: _humanize(words),
      packageName: packageName,
      viewClassName: '${_pascalCase(words)}View',
      viewModelClassName: '${_pascalCase(words)}ViewModel',
      featureDirectory: featureDirectory,
      files: [viewPath, viewModelPath],
      dryRun: input.dryRun,
    );
  }

  Future<CreateFeatureResult> create(CreateFeatureInput input) async {
    final createPlan = await plan(input);
    _validateTargets(createPlan);

    if (createPlan.dryRun) {
      return CreateFeatureResult(plan: createPlan);
    }

    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final stagedFiles = <_StagedFeatureFile>[
      _StagedFeatureFile(
        file: _targetFile(projectRoot, createPlan.files[0]),
        contents: _viewContents(createPlan),
      ),
      _StagedFeatureFile(
        file: _targetFile(projectRoot, createPlan.files[1]),
        contents: _viewModelContents(createPlan),
      ),
    ];
    final createdFiles = <File>[];
    final createdDirectories = <Directory>[];

    try {
      for (final stagedFile in stagedFiles) {
        _createParentDirectories(
          projectRoot,
          stagedFile.file.parent,
          createdDirectories,
        );
        _fileWriter(stagedFile.file, stagedFile.contents);
        createdFiles.add(stagedFile.file);
      }
    } on FileSystemException catch (error) {
      _rollback(createdFiles, createdDirectories);
      throw CreateFeatureException(
        'Unable to create feature ${createPlan.displayName}: ${error.message}',
      );
    } catch (error) {
      _rollback(createdFiles, createdDirectories);
      throw CreateFeatureException(
        'Unable to create feature ${createPlan.displayName}: $error',
      );
    }

    return CreateFeatureResult(plan: createPlan);
  }
}

void _validateTargets(CreateFeaturePlan plan) {
  _validateNoAncestorSymlinks(plan.featureDirectory);

  if (plan.featureDirectory.existsSync() ||
      File(plan.featureDirectory.path).existsSync() ||
      Link(plan.featureDirectory.path).existsSync()) {
    throw CreateFeatureException(
      'Feature already exists: lib/features/${plan.name}',
    );
  }

  final projectRoot = plan.featureDirectory.parent.parent.parent;
  for (final path in plan.files) {
    final target = _targetFile(projectRoot, path).path;
    if (File(target).existsSync() ||
        Directory(target).existsSync() ||
        Link(target).existsSync()) {
      throw CreateFeatureException('Target already exists: $path');
    }
  }
}

void _validateNoAncestorSymlinks(Directory featureDirectory) {
  final projectRoot = featureDirectory.parent.parent.parent;
  final lib = Directory('${projectRoot.path}${Platform.pathSeparator}lib');
  final features = Directory('${lib.path}${Platform.pathSeparator}features');
  for (final directory in [lib, features]) {
    if (Link(directory.path).existsSync()) {
      throw CreateFeatureException(
        'Refusing to create feature through a symlink: '
        '${_relativePath(projectRoot, directory.path)}',
      );
    }
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

void _rollback(List<File> createdFiles, List<Directory> createdDirectories) {
  for (final file in createdFiles.reversed) {
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

String _readPackageName(Directory projectRoot) {
  final pubspec = File(
    '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml',
  );
  if (!pubspec.existsSync()) {
    throw const CreateFeatureException(
      'pubspec.yaml was not found in the current project.',
    );
  }

  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  if (match == null) {
    throw const CreateFeatureException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const CreateFeatureException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeFeatureName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const CreateFeatureException('Feature name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const CreateFeatureException(
      'Feature name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const CreateFeatureException(
      'Feature name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const CreateFeatureException(
      'Feature name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const CreateFeatureException(
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

String _viewContents(CreateFeaturePlan plan) {
  final importName = plan.name;
  return '''
import 'package:${plan.packageName}/features/$importName/ui/${importName}_viewmodel.dart';
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

String _viewModelContents(CreateFeaturePlan plan) {
  return '''
import 'package:stacked/stacked.dart';

class ${plan.viewModelClassName} extends BaseViewModel {}
''';
}

class _StagedFeatureFile {
  const _StagedFeatureFile({required this.file, required this.contents});

  final File file;
  final String contents;
}
