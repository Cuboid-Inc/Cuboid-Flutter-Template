import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/route/register_route.dart';

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
    required this.repositoryClassName,
    required this.featureDirectory,
    required this.files,
    required this.locatorPath,
    required this.routerPath,
    required this.routeRegistration,
    required this.repositoryImportLine,
    required this.repositoryLine,
    required this.dryRun,
  });

  final String name;
  final String displayName;
  final String packageName;
  final String viewClassName;
  final String viewModelClassName;
  final String repositoryClassName;
  final Directory featureDirectory;
  final List<String> files;
  final String locatorPath;
  final String routerPath;
  final RouteRegistration routeRegistration;
  final String repositoryImportLine;
  final String repositoryLine;
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
    final repositoryPath =
        'lib/features/$featureName/data/${featureName}_repository.dart';
    final repositoryClassName = '${_pascalCase(words)}Repository';
    final routeRegistration = planRouteRegistration(
      packageName: packageName,
      featureName: featureName,
      viewName: featureName,
    );

    return CreateFeaturePlan(
      name: featureName,
      displayName: _humanize(words),
      packageName: packageName,
      viewClassName: '${_pascalCase(words)}View',
      viewModelClassName: '${_pascalCase(words)}ViewModel',
      repositoryClassName: repositoryClassName,
      featureDirectory: featureDirectory,
      files: [viewPath, viewModelPath, repositoryPath],
      locatorPath: 'lib/app/app.locator.dart',
      routerPath: 'lib/app/app.router.dart',
      routeRegistration: routeRegistration,
      repositoryImportLine:
          "import 'package:$packageName/features/$featureName/data/${featureName}_repository.dart';",
      repositoryLine:
          '  locator.registerLazySingleton<$repositoryClassName>(() => const $repositoryClassName());',
      dryRun: input.dryRun,
    );
  }

  Future<CreateFeatureResult> create(CreateFeatureInput input) async {
    final createPlan = await plan(input);
    _validateTargets(createPlan);

    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final routerFile = _targetFile(projectRoot, createPlan.routerPath);
    final locatorFile = _targetFile(projectRoot, createPlan.locatorPath);
    final routerContents = _validateRouter(createPlan, routerFile);
    final locatorContents = _validateLocator(createPlan, locatorFile);
    final nextRouterContents = applyRouteRegistration(
      routerContents,
      createPlan.routeRegistration,
    );
    final nextLocatorContents = _applyLocatorPlan(locatorContents, createPlan);

    if (createPlan.dryRun) {
      return CreateFeatureResult(plan: createPlan);
    }

    final stagedFiles = <_StagedFeatureFile>[
      _StagedFeatureFile(
        file: _targetFile(projectRoot, createPlan.files[0]),
        contents: _viewContents(createPlan),
      ),
      _StagedFeatureFile(
        file: _targetFile(projectRoot, createPlan.files[1]),
        contents: _viewModelContents(createPlan),
      ),
      _StagedFeatureFile(
        file: _targetFile(projectRoot, createPlan.files[2]),
        contents: _repositoryContents(createPlan),
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
      _replaceFileContents(
        routerFile,
        nextRouterContents,
        label: createPlan.routerPath,
      );
      _replaceFileContents(
        locatorFile,
        nextLocatorContents,
        label: createPlan.locatorPath,
      );
    } on FileSystemException catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {
          routerFile: routerContents,
          locatorFile: locatorContents,
        },
      );
      throw CreateFeatureException(
        'Unable to create feature ${createPlan.displayName}: ${error.message}',
      );
    } catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {
          routerFile: routerContents,
          locatorFile: locatorContents,
        },
      );
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

String _validateRouter(CreateFeaturePlan plan, File routerFile) {
  _ensureRegularFile(routerFile.path, plan.routerPath);
  final contents = _readFile(routerFile, plan.routerPath);

  try {
    validateRouteRegistration(contents, plan.routeRegistration);
  } on RouteRegistrationException catch (error) {
    throw CreateFeatureException(error.message);
  }

  return contents;
}

String _validateLocator(CreateFeaturePlan plan, File locatorFile) {
  _ensureRegularFile(locatorFile.path, plan.locatorPath);
  final contents = _readFile(locatorFile, plan.locatorPath);

  _requireSingleMarker(contents, '// @cuboid-import');
  _requireSingleMarker(contents, '// @cuboid-service');
  if (contents.contains(plan.repositoryImportLine)) {
    throw CreateFeatureException(
      'Repository import already exists for ${plan.repositoryClassName}.',
    );
  }
  if (RegExp(
    r'register\w*\s*<\s*' + RegExp.escape(plan.repositoryClassName) + r'\s*>',
  ).hasMatch(contents)) {
    throw CreateFeatureException(
      'Repository already exists for ${plan.repositoryClassName}.',
    );
  }

  return contents;
}

String _applyLocatorPlan(String contents, CreateFeaturePlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  return contents
      .replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-import', multiLine: true),
        '${plan.repositoryImportLine}$lineEnding// @cuboid-import',
      )
      .replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-service', multiLine: true),
        '${plan.repositoryLine}$lineEnding  // @cuboid-service',
      );
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

void _ensureRegularFile(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw CreateFeatureException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw CreateFeatureException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.file) {
    throw CreateFeatureException('$label must be a regular file.');
  }
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw CreateFeatureException('Unable to read $label: ${error.message}');
  }
}

void _requireSingleMarker(String contents, String marker) {
  final count = marker.allMatches(contents).length;
  if (count == 0) {
    throw CreateFeatureException('Missing marker: $marker');
  }
  if (count > 1) {
    throw CreateFeatureException('Duplicate marker: $marker');
  }
}

void _replaceFileContents(File file, String contents, {required String label}) {
  final Directory temp;
  try {
    temp = file.parent.createTempSync('.cuboid-feature-');
  } on FileSystemException catch (error) {
    throw CreateFeatureException('Unable to update $label: ${error.message}');
  }
  final tempFile = File(
    '${temp.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
  );
  try {
    tempFile.writeAsStringSync(contents);
    tempFile.renameSync(file.path);
  } on FileSystemException catch (error) {
    throw CreateFeatureException('Unable to update $label: ${error.message}');
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

void _rollback(
  List<File> createdFiles,
  List<Directory> createdDirectories, {
  Map<File, String> restoredFiles = const {},
}) {
  for (final entry in restoredFiles.entries) {
    try {
      entry.key.writeAsStringSync(entry.value);
    } on FileSystemException {
      // Best-effort cleanup; preserve the original creation failure.
    }
  }

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
  final imports = <String>[
    "import 'package:cuboid_flutter/cuboid_flutter.dart';",
    "import 'package:${plan.packageName}/features/$importName/ui/${importName}_viewmodel.dart';",
    "import 'package:flutter/material.dart';",
  ]..sort();
  return '''
${imports.join('\n')}

class ${plan.viewClassName} extends CuboidView<${plan.viewModelClassName}> {
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
import 'package:cuboid_flutter/cuboid_flutter.dart';

class ${plan.viewModelClassName} extends CuboidViewModel {}
''';
}

String _repositoryContents(CreateFeaturePlan plan) {
  return '''
/// Owns persistent data access for the ${plan.displayName} feature.
///
/// ViewModels consume this repository instead of calling a backend SDK
/// directly; wire it to a real data source once this feature has
/// persistent data to store.
class ${plan.repositoryClassName} {
  const ${plan.repositoryClassName}();
}
''';
}

class _StagedFeatureFile {
  const _StagedFeatureFile({required this.file, required this.contents});

  final File file;
  final String contents;
}
