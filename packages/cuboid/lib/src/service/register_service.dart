import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

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
