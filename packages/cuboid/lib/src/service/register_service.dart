import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

typedef ServiceFileWriter = void Function(File file, String contents);

class RegisterServiceInput {
  const RegisterServiceInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class RegisterServicePlan {
  const RegisterServicePlan({
    required this.name,
    required this.displayName,
    required this.packageName,
    required this.serviceClassName,
    required this.servicePath,
    required this.appPath,
    required this.importLine,
    required this.serviceLine,
    required this.dryRun,
  });

  final String name;
  final String displayName;
  final String packageName;
  final String serviceClassName;
  final String servicePath;
  final String appPath;
  final String importLine;
  final String serviceLine;
  final bool dryRun;
}

class RegisterServiceResult {
  const RegisterServiceResult({required this.plan});

  final RegisterServicePlan plan;
}

class RegisterServiceException implements Exception {
  const RegisterServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RegisterServiceService {
  RegisterServiceService({ServiceFileWriter? fileWriter})
    : _fileWriter =
          fileWriter ?? ((file, contents) => file.writeAsStringSync(contents));

  final ServiceFileWriter _fileWriter;

  Future<RegisterServicePlan> plan(RegisterServiceInput input) async {
    final serviceName = _normalizeServiceName(input.name);
    final words = serviceName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final serviceClassName = '${_pascalCase(words)}Service';
    final servicePath = 'lib/core/services/${serviceName}_service.dart';

    return RegisterServicePlan(
      name: serviceName,
      displayName: _humanize(words),
      packageName: packageName,
      serviceClassName: serviceClassName,
      servicePath: servicePath,
      appPath: 'lib/app/app.dart',
      importLine:
          "import 'package:$packageName/core/services/${serviceName}_service.dart';",
      serviceLine: '    LazySingleton(classType: $serviceClassName),',
      dryRun: input.dryRun,
    );
  }

  Future<RegisterServiceResult> register(RegisterServiceInput input) async {
    final servicePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final appFile = File(
      '${projectRoot.path}${Platform.pathSeparator}'
      '${servicePlan.appPath.replaceAll('/', Platform.pathSeparator)}',
    );

    final appContents = _validateTargets(projectRoot, servicePlan, appFile);
    final nextContents = _applyPlan(appContents, servicePlan);

    if (servicePlan.dryRun) {
      return RegisterServiceResult(plan: servicePlan);
    }

    _replaceFileContents(appFile, nextContents);
    return RegisterServiceResult(plan: servicePlan);
  }

  Future<RegisterServiceResult> create(RegisterServiceInput input) async {
    final servicePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final appFile = File(
      '${projectRoot.path}${Platform.pathSeparator}'
      '${servicePlan.appPath.replaceAll('/', Platform.pathSeparator)}',
    );
    final serviceFile = _targetFile(projectRoot, servicePlan.servicePath);

    final appContents = _validateCreateTargets(
      projectRoot,
      servicePlan,
      appFile,
      serviceFile,
    );
    final nextContents = _applyPlan(appContents, servicePlan);

    if (servicePlan.dryRun) {
      return RegisterServiceResult(plan: servicePlan);
    }

    final createdDirectories = <Directory>[];
    try {
      _createParentDirectories(
        projectRoot,
        serviceFile.parent,
        createdDirectories,
      );
      _fileWriter(serviceFile, _serviceContents(servicePlan));
      _replaceFileContents(appFile, nextContents);
    } on FileSystemException catch (error) {
      _rollbackCreatedService(serviceFile, createdDirectories);
      throw RegisterServiceException(
        'Unable to create service ${servicePlan.displayName}: ${error.message}',
      );
    } catch (error) {
      _rollbackCreatedService(serviceFile, createdDirectories);
      throw RegisterServiceException(
        'Unable to create service ${servicePlan.displayName}: $error',
      );
    }

    return RegisterServiceResult(plan: servicePlan);
  }
}

String _validateTargets(
  Directory projectRoot,
  RegisterServicePlan plan,
  File appFile,
) {
  _ensureRegularFile(appFile.path, 'lib/app/app.dart');
  _ensureRegularFile(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${plan.servicePath.replaceAll('/', Platform.pathSeparator)}',
    plan.servicePath,
  );

  return _validateAppRegistration(plan, appFile);
}

String _validateCreateTargets(
  Directory projectRoot,
  RegisterServicePlan plan,
  File appFile,
  File serviceFile,
) {
  _ensureRegularFile(appFile.path, 'lib/app/app.dart');
  _validateNoAncestorSymlinks(projectRoot, serviceFile.parent);
  if (File(serviceFile.path).existsSync() ||
      Directory(serviceFile.path).existsSync() ||
      Link(serviceFile.path).existsSync()) {
    throw RegisterServiceException(
      'Target already exists: ${plan.servicePath}',
    );
  }

  return _validateAppRegistration(plan, appFile);
}

String _validateAppRegistration(RegisterServicePlan plan, File appFile) {
  final String contents;
  try {
    contents = appFile.readAsStringSync();
  } on FileSystemException catch (error) {
    throw RegisterServiceException(
      'Unable to read lib/app/app.dart: ${error.message}',
    );
  }

  _requireSingleMarker(contents, '// @stacked-import');
  _requireSingleMarker(contents, '// @stacked-service');
  if (_hasMatchingImport(contents, plan)) {
    throw RegisterServiceException(
      'Service import already exists for ${plan.serviceClassName}.',
    );
  }
  if (_hasConflictingImport(contents, plan)) {
    throw RegisterServiceException(
      'Service import already exists for ${plan.serviceClassName}.',
    );
  }
  if (_hasServiceRegistration(contents, plan)) {
    throw RegisterServiceException(
      'Service already exists for ${plan.serviceClassName}.',
    );
  }
  return contents;
}

void _validateNoAncestorSymlinks(
  Directory projectRoot,
  Directory targetDirectory,
) {
  var current = targetDirectory;
  final ancestors = <Directory>[];
  while (current.path != projectRoot.path) {
    ancestors.add(current);
    current = current.parent;
  }

  for (final directory in ancestors.reversed) {
    if (Link(directory.path).existsSync()) {
      throw RegisterServiceException(
        'Refusing to create service through a symlink: '
        '${_relativePath(projectRoot, directory.path)}',
      );
    }
  }
}

void _ensureRegularFile(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw RegisterServiceException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw RegisterServiceException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.file) {
    throw RegisterServiceException('$label must be a regular file.');
  }
}

void _requireSingleMarker(String contents, String marker) {
  final count = marker.allMatches(contents).length;
  if (count == 0) {
    throw RegisterServiceException('Missing marker: $marker');
  }
  if (count > 1) {
    throw RegisterServiceException('Duplicate marker: $marker');
  }
}

bool _hasMatchingImport(String contents, RegisterServicePlan plan) {
  return _serviceImports(contents, plan).contains(plan.importLine);
}

bool _hasConflictingImport(String contents, RegisterServicePlan plan) {
  return _serviceImports(contents, plan).any((line) => line != plan.importLine);
}

List<String> _serviceImports(String contents, RegisterServicePlan plan) {
  final pattern = RegExp(
    r'''^import\s+(['"])([^'"]*/core/services/''' +
        RegExp.escape('${plan.name}_service.dart') +
        r''')\1\s*;''',
    multiLine: true,
  );
  return pattern
      .allMatches(contents)
      .map((match) => "import '${match.group(2)}';")
      .toList();
}

bool _hasServiceRegistration(String contents, RegisterServicePlan plan) {
  final pattern = RegExp(
    r'classType\s*:\s*' + RegExp.escape(plan.serviceClassName) + r'\b',
  );
  return pattern.hasMatch(contents);
}

String _applyPlan(String contents, RegisterServicePlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  return contents
      .replaceFirst(
        RegExp(r'^[ \t]*// @stacked-import', multiLine: true),
        '${plan.importLine}$lineEnding// @stacked-import',
      )
      .replaceFirst(
        RegExp(r'^[ \t]*// @stacked-service', multiLine: true),
        '${plan.serviceLine}$lineEnding    // @stacked-service',
      );
}

void _replaceFileContents(File file, String contents) {
  final Directory temp;
  try {
    temp = file.parent.createTempSync('.cuboid-service-');
  } on FileSystemException catch (error) {
    throw RegisterServiceException(
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
    throw RegisterServiceException(
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

void _rollbackCreatedService(
  File serviceFile,
  List<Directory> createdDirectories,
) {
  try {
    if (serviceFile.existsSync()) {
      serviceFile.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup; preserve the original failure.
  }

  final directories = createdDirectories.toSet().toList()
    ..sort((a, b) => b.path.length.compareTo(a.path.length));
  for (final directory in directories) {
    try {
      if (directory.existsSync() && directory.listSync().isEmpty) {
        directory.deleteSync();
      }
    } on FileSystemException {
      // Best-effort cleanup; preserve the original failure.
    }
  }
}

String _relativePath(Directory root, String path) {
  return path
      .substring(root.path.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
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
    throw RegisterServiceException(
      'Unable to read pubspec.yaml: ${error.message}',
    );
  }

  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const RegisterServiceException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const RegisterServiceException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeServiceName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const RegisterServiceException('Service name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const RegisterServiceException(
      'Service name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const RegisterServiceException(
      'Service name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const RegisterServiceException(
      'Service name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = _splitCamelCase(value.replaceAll('-', '_')).toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const RegisterServiceException(
      'Service name must not be a Dart keyword.',
    );
  }
  return normalized;
}

String _splitCamelCase(String value) {
  return value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .replaceAllMapped(
        RegExp(r'([A-Z]+)([A-Z][a-z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      );
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}

String _humanize(List<String> words) {
  return words
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String _serviceContents(RegisterServicePlan plan) {
  return '''
class ${plan.serviceClassName} {}
''';
}
