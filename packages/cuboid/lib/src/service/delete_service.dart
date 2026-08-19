import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/edit/generated_edits.dart';

class DeleteServiceInput {
  const DeleteServiceInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteServicePlan {
  const DeleteServicePlan({
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

class DeleteServiceResult {
  const DeleteServiceResult({required this.plan});

  final DeleteServicePlan plan;
}

class DeleteServiceException implements Exception {
  const DeleteServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Services owned automatically by another `cuboid delete` command and
/// therefore refused here (see `delete_dialog.dart` / `delete_bottomsheet.dart`
/// for `DialogService` / `BottomSheetService` teardown, and
/// `lib/core/services/navigation_service.dart`, which every generated app
/// depends on directly from `main.dart`).
const _reservedServiceNames = <String, String>{
  'navigation':
      'NavigationService is foundational to every generated app and cannot '
      'be deleted with cuboid delete service.',
  'dialog':
      'DialogService is managed automatically by cuboid delete dialog; it '
      'cannot be deleted with cuboid delete service.',
  'bottom_sheet':
      'BottomSheetService is managed automatically by cuboid delete '
      'bottomsheet; it cannot be deleted with cuboid delete service.',
};

class DeleteServiceService {
  Future<DeleteServicePlan> plan(DeleteServiceInput input) async {
    final serviceName = _normalizeServiceName(input.name);
    _ensureNotReserved(serviceName);
    final words = serviceName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final serviceClassName = '${_pascalCase(words)}Service';
    final servicePath = 'lib/core/services/${serviceName}_service.dart';

    return DeleteServicePlan(
      name: serviceName,
      displayName: _humanize(words),
      packageName: packageName,
      serviceClassName: serviceClassName,
      servicePath: servicePath,
      appPath: 'lib/app/app.locator.dart',
      importLine:
          "import 'package:$packageName/core/services/${serviceName}_service.dart';",
      serviceLine:
          '  locator.registerLazySingleton<$serviceClassName>(() => $serviceClassName());',
      dryRun: input.dryRun,
    );
  }

  Future<DeleteServiceResult> delete(DeleteServiceInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final appFile = targetFile(projectRoot, deletePlan.appPath);
    final serviceFile = targetFile(projectRoot, deletePlan.servicePath);

    if (!isRegularFile(serviceFile.path)) {
      throw DeleteServiceException('Service not found: ${deletePlan.name}.');
    }
    final appContents = _validateAppRegistration(deletePlan, appFile);
    final nextContents = _applyRemoval(appContents, deletePlan);

    if (deletePlan.dryRun) {
      return DeleteServiceResult(plan: deletePlan);
    }

    try {
      atomicReplaceFileContents(appFile, nextContents);
      serviceFile.deleteSync();
    } on FileSystemException catch (error) {
      restoreFileContents({appFile: appContents});
      throw DeleteServiceException(
        'Unable to delete service ${deletePlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      restoreFileContents({appFile: appContents});
      throw DeleteServiceException(
        'Unable to delete service ${deletePlan.displayName}: $error',
      );
    }

    return DeleteServiceResult(plan: deletePlan);
  }
}

void _ensureNotReserved(String serviceName) {
  final message = _reservedServiceNames[serviceName];
  if (message != null) {
    throw DeleteServiceException(message);
  }
}

String _validateAppRegistration(DeleteServicePlan plan, File appFile) {
  if (!isRegularFile(appFile.path)) {
    throw DeleteServiceException('${plan.appPath} was not found.');
  }
  final contents = _readFile(appFile, plan.appPath);

  if (!contents.contains(plan.importLine) ||
      !_hasServiceRegistration(contents, plan)) {
    throw DeleteServiceException('Service not found: ${plan.name}.');
  }
  return contents;
}

bool _hasServiceRegistration(String contents, DeleteServicePlan plan) {
  final pattern = RegExp(
    r'register\w*\s*<\s*' + RegExp.escape(plan.serviceClassName) + r'\s*>',
  );
  return pattern.hasMatch(contents);
}

String _applyRemoval(String contents, DeleteServicePlan plan) {
  final afterImport = removeExactLine(contents, plan.importLine);
  if (afterImport == null) {
    throw DeleteServiceException('Service not found: ${plan.name}.');
  }
  final afterService = removeExactLine(afterImport, plan.serviceLine);
  if (afterService == null) {
    throw DeleteServiceException('Service not found: ${plan.name}.');
  }
  return afterService;
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw DeleteServiceException('Unable to read $label: ${error.message}');
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  if (!isRegularFile(pubspecPath)) {
    throw const DeleteServiceException(
      'pubspec.yaml was not found in the current project.',
    );
  }

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const DeleteServiceException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const DeleteServiceException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeServiceName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const DeleteServiceException('Service name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const DeleteServiceException(
      'Service name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const DeleteServiceException(
      'Service name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const DeleteServiceException(
      'Service name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = _splitCamelCase(value.replaceAll('-', '_')).toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const DeleteServiceException(
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
