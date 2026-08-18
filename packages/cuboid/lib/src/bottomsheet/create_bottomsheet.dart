import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

typedef BottomSheetFileWriter = void Function(File file, String contents);

class CreateBottomSheetInput {
  const CreateBottomSheetInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class CreateBottomSheetPlan {
  const CreateBottomSheetPlan({
    required this.name,
    required this.displayName,
    required this.packageName,
    required this.sheetClassName,
    required this.modelClassName,
    required this.directoryPath,
    required this.sheetPath,
    required this.modelPath,
    required this.locatorPath,
    required this.bottomSheetsPath,
    required this.bottomSheetServicePath,
    required this.sheetImportLine,
    required this.modelImportLine,
    required this.bottomSheetEntryLine,
    required this.serviceImportLine,
    required this.serviceLine,
    required this.dryRun,
  });

  final String name;
  final String displayName;
  final String packageName;
  final String sheetClassName;
  final String modelClassName;
  final String directoryPath;
  final String sheetPath;
  final String modelPath;
  final String locatorPath;
  final String bottomSheetsPath;
  final String bottomSheetServicePath;
  final String sheetImportLine;
  final String modelImportLine;
  final String bottomSheetEntryLine;
  final String serviceImportLine;
  final String serviceLine;
  final bool dryRun;

  List<String> get files => [sheetPath, modelPath];
}

class CreateBottomSheetResult {
  const CreateBottomSheetResult({required this.plan});

  final CreateBottomSheetPlan plan;
}

class CreateBottomSheetException implements Exception {
  const CreateBottomSheetException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateBottomSheetService {
  CreateBottomSheetService({BottomSheetFileWriter? fileWriter})
    : _fileWriter =
          fileWriter ?? ((file, contents) => file.writeAsStringSync(contents));

  final BottomSheetFileWriter _fileWriter;

  Future<CreateBottomSheetPlan> plan(CreateBottomSheetInput input) async {
    final bottomSheetName = _normalizeBottomSheetName(input.name);
    final words = bottomSheetName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final sheetClassName = '${_pascalCase(words)}Sheet';
    final modelClassName = '${_pascalCase(words)}SheetModel';
    final directoryPath = 'lib/shared/bottom_sheets/$bottomSheetName';
    final sheetPath = '$directoryPath/${bottomSheetName}_sheet.dart';
    final modelPath = '$directoryPath/${bottomSheetName}_sheet_model.dart';

    return CreateBottomSheetPlan(
      name: bottomSheetName,
      displayName: _humanize(words),
      packageName: packageName,
      sheetClassName: sheetClassName,
      modelClassName: modelClassName,
      directoryPath: directoryPath,
      sheetPath: sheetPath,
      modelPath: modelPath,
      locatorPath: 'lib/app/app.locator.dart',
      bottomSheetsPath: 'lib/app/app.bottomsheets.dart',
      bottomSheetServicePath: 'lib/core/services/bottom_sheet_service.dart',
      sheetImportLine:
          "import 'package:$packageName/shared/bottom_sheets/$bottomSheetName/${bottomSheetName}_sheet.dart';",
      modelImportLine:
          "import 'package:$packageName/shared/bottom_sheets/$bottomSheetName/${bottomSheetName}_sheet_model.dart';",
      bottomSheetEntryLine: '$modelClassName: (_) => const $sheetClassName(),',
      serviceImportLine:
          "import 'package:$packageName/core/services/bottom_sheet_service.dart';",
      serviceLine:
          '  locator.registerLazySingleton<BottomSheetService>(() => BottomSheetService());',
      dryRun: input.dryRun,
    );
  }

  Future<CreateBottomSheetResult> create(CreateBottomSheetInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final locatorFile = _targetFile(projectRoot, createPlan.locatorPath);
    final bottomSheetsFile = _targetFile(
      projectRoot,
      createPlan.bottomSheetsPath,
    );
    final serviceFile = _targetFile(
      projectRoot,
      createPlan.bottomSheetServicePath,
    );
    final sheetFile = _targetFile(projectRoot, createPlan.sheetPath);
    final modelFile = _targetFile(projectRoot, createPlan.modelPath);
    final bottomSheetDirectory = _targetDirectory(
      projectRoot,
      createPlan.directoryPath,
    );

    final needsService = !serviceFile.existsSync();
    final bottomSheetsExists = bottomSheetsFile.existsSync();

    final locatorContents = _validateLocator(
      createPlan,
      locatorFile,
      needsService: needsService,
    );
    final bottomSheetsContents = bottomSheetsExists
        ? _validateBottomSheets(createPlan, bottomSheetsFile)
        : null;
    _validateGeneratedTargets(
      projectRoot,
      createPlan,
      bottomSheetDirectory,
      sheetFile,
      modelFile,
    );
    if (needsService) {
      _ensureNotExisting(serviceFile, label: createPlan.bottomSheetServicePath);
    }

    final nextLocatorContents = needsService
        ? _applyLocatorPlan(locatorContents, createPlan)
        : locatorContents;
    final nextBottomSheetsContents = bottomSheetsExists
        ? _applyBottomSheetsPlan(bottomSheetsContents!, createPlan)
        : _freshBottomSheetsContents(createPlan);

    if (createPlan.dryRun) {
      return CreateBottomSheetResult(plan: createPlan);
    }

    final createdFiles = <File>[];
    final createdDirectories = <Directory>[];
    try {
      _createParentDirectories(
        projectRoot,
        sheetFile.parent,
        createdDirectories,
      );
      _fileWriter(sheetFile, _sheetContents(createPlan));
      createdFiles.add(sheetFile);
      _fileWriter(modelFile, _modelContents(createPlan));
      createdFiles.add(modelFile);
      if (needsService) {
        _createParentDirectories(
          projectRoot,
          serviceFile.parent,
          createdDirectories,
        );
        _fileWriter(serviceFile, _bottomSheetServiceContents(createPlan));
        createdFiles.add(serviceFile);
      }
      if (bottomSheetsExists) {
        _replaceFileContents(
          bottomSheetsFile,
          nextBottomSheetsContents,
          label: createPlan.bottomSheetsPath,
        );
      } else {
        _fileWriter(bottomSheetsFile, nextBottomSheetsContents);
        createdFiles.add(bottomSheetsFile);
      }
      if (needsService) {
        _replaceFileContents(
          locatorFile,
          nextLocatorContents,
          label: createPlan.locatorPath,
        );
      }
    } on FileSystemException catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {
          locatorFile: locatorContents,
          if (bottomSheetsExists) bottomSheetsFile: bottomSheetsContents!,
        },
      );
      throw CreateBottomSheetException(
        'Unable to create bottom sheet ${createPlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {
          locatorFile: locatorContents,
          if (bottomSheetsExists) bottomSheetsFile: bottomSheetsContents!,
        },
      );
      throw CreateBottomSheetException(
        'Unable to create bottom sheet ${createPlan.displayName}: $error',
      );
    }

    return CreateBottomSheetResult(plan: createPlan);
  }
}

void _validateGeneratedTargets(
  Directory projectRoot,
  CreateBottomSheetPlan plan,
  Directory bottomSheetDirectory,
  File sheetFile,
  File modelFile,
) {
  _ensureSafeParentDirectories(projectRoot, bottomSheetDirectory.parent);
  for (final entity in [bottomSheetDirectory, sheetFile, modelFile]) {
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      final relativePath = _relativePath(projectRoot, entity.path);
      if (relativePath == plan.directoryPath) {
        throw CreateBottomSheetException(
          'Bottom sheet already exists: ${plan.directoryPath}',
        );
      }
      throw CreateBottomSheetException('Target already exists: $relativePath');
    }
  }
}

void _ensureNotExisting(File file, {required String label}) {
  final type = FileSystemEntity.typeSync(file.path, followLinks: false);
  if (type != FileSystemEntityType.notFound) {
    throw CreateBottomSheetException('Target already exists: $label');
  }
}

String _validateLocator(
  CreateBottomSheetPlan plan,
  File locatorFile, {
  required bool needsService,
}) {
  _ensureRegularFile(locatorFile.path, plan.locatorPath);
  final contents = _readFile(locatorFile, plan.locatorPath);

  if (!needsService) {
    return contents;
  }

  _requireSingleMarker(contents, '// @cuboid-import');
  _requireSingleMarker(contents, '// @cuboid-service');
  if (RegExp(r'register\w*\s*<\s*BottomSheetService\s*>').hasMatch(contents)) {
    throw const CreateBottomSheetException(
      'Duplicate BottomSheetService registration.',
    );
  }
  return contents;
}

String _validateBottomSheets(
  CreateBottomSheetPlan plan,
  File bottomSheetsFile,
) {
  _ensureRegularFile(bottomSheetsFile.path, plan.bottomSheetsPath);
  final contents = _readFile(bottomSheetsFile, plan.bottomSheetsPath);

  _requireSingleMarker(contents, '// @cuboid-import');
  _requireSingleMarker(contents, '// @cuboid-bottom-sheet');
  if (contents.contains(plan.sheetImportLine)) {
    throw CreateBottomSheetException(
      'Bottom sheet import already exists for ${plan.sheetClassName}.',
    );
  }
  if (RegExp(RegExp.escape(plan.modelClassName) + r'\s*:').hasMatch(contents)) {
    throw CreateBottomSheetException(
      'Bottom sheet already exists for ${plan.sheetClassName}.',
    );
  }
  return contents;
}

void _ensureRegularFile(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw CreateBottomSheetException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw CreateBottomSheetException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.file) {
    throw CreateBottomSheetException('$label must be a regular file.');
  }
}

void _ensureSafeParentDirectories(Directory projectRoot, Directory parent) {
  final rootPath = projectRoot.absolute.path;
  final parentPath = parent.absolute.path;
  if (!parentPath.startsWith(_withTrailingSeparator(rootPath))) {
    throw const CreateBottomSheetException(
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
      throw CreateBottomSheetException(
        'Refusing to create bottom sheet through a symlink: '
        '${_relativePath(projectRoot, current)}',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw CreateBottomSheetException('$current must be a directory.');
    }
  }
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw CreateBottomSheetException('Unable to read $label: ${error.message}');
  }
}

void _requireSingleMarker(String contents, String marker) {
  final count = marker.allMatches(contents).length;
  if (count == 0) {
    throw CreateBottomSheetException('Missing marker: $marker');
  }
  if (count > 1) {
    throw CreateBottomSheetException('Duplicate marker: $marker');
  }
}

String _applyLocatorPlan(String contents, CreateBottomSheetPlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  return contents
      .replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-import', multiLine: true),
        '${plan.serviceImportLine}$lineEnding// @cuboid-import',
      )
      .replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-service', multiLine: true),
        '${plan.serviceLine}$lineEnding  // @cuboid-service',
      );
}

String _applyBottomSheetsPlan(String contents, CreateBottomSheetPlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  return contents
      .replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-import', multiLine: true),
        '${plan.sheetImportLine}$lineEnding'
        '${plan.modelImportLine}$lineEnding'
        '// @cuboid-import',
      )
      .replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-bottom-sheet', multiLine: true),
        '  ${plan.bottomSheetEntryLine}$lineEnding  // @cuboid-bottom-sheet',
      );
}

void _replaceFileContents(File file, String contents, {required String label}) {
  final Directory temp;
  try {
    temp = file.parent.createTempSync('.cuboid-bottomsheet-');
  } on FileSystemException catch (error) {
    throw CreateBottomSheetException(
      'Unable to update $label: ${error.message}',
    );
  }
  final tempFile = File(
    '${temp.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
  );
  try {
    tempFile.writeAsStringSync(contents);
    tempFile.renameSync(file.path);
  } on FileSystemException catch (error) {
    throw CreateBottomSheetException(
      'Unable to update $label: ${error.message}',
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

Directory _targetDirectory(Directory projectRoot, String path) {
  return Directory(
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

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  _ensureRegularFile(pubspecPath, 'pubspec.yaml');

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const CreateBottomSheetException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const CreateBottomSheetException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeBottomSheetName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const CreateBottomSheetException(
      'Bottom sheet name must not be empty.',
    );
  }
  if (value == '.' || value == '..') {
    throw const CreateBottomSheetException(
      'Bottom sheet name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const CreateBottomSheetException(
      'Bottom sheet name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const CreateBottomSheetException(
      'Bottom sheet name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const CreateBottomSheetException(
      'Bottom sheet name must not be a Dart keyword.',
    );
  }
  return normalized;
}

String _withTrailingSeparator(String path) {
  return path.endsWith(Platform.pathSeparator)
      ? path
      : '$path${Platform.pathSeparator}';
}

String _relativePath(Directory root, String path) {
  return path
      .substring(root.path.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}

String _humanize(List<String> words) {
  return words
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String _sheetContents(CreateBottomSheetPlan plan) {
  return '''
import 'package:${plan.packageName}/core/mvvm/cuboid_view.dart';
import 'package:${plan.packageName}/shared/bottom_sheets/${plan.name}/${plan.name}_sheet_model.dart';
import 'package:flutter/material.dart';

class ${plan.sheetClassName} extends CuboidView<${plan.modelClassName}> {
  const ${plan.sheetClassName}({super.key});

  @override
  ${plan.modelClassName} viewModelBuilder(BuildContext context) =>
      ${plan.modelClassName}();

  @override
  Widget builder(
    BuildContext context,
    ${plan.modelClassName} vm,
    Widget? child,
  ) {
    return const SizedBox.shrink();
  }
}
''';
}

String _modelContents(CreateBottomSheetPlan plan) {
  return '''
import 'package:${plan.packageName}/core/mvvm/cuboid_view_model.dart';

class ${plan.modelClassName} extends CuboidViewModel {}
''';
}

String _freshBottomSheetsContents(CreateBottomSheetPlan plan) {
  return '''
import 'package:flutter/material.dart';
${plan.sheetImportLine}
${plan.modelImportLine}
// @cuboid-import

final Map<Type, WidgetBuilder> cuboidBottomSheetBuilders = {
  ${plan.bottomSheetEntryLine}
  // @cuboid-bottom-sheet
};
''';
}

String _bottomSheetServiceContents(CreateBottomSheetPlan plan) {
  return '''
import 'package:${plan.packageName}/app/app.bottomsheets.dart';
import 'package:${plan.packageName}/core/services/navigation_service.dart';
import 'package:flutter/material.dart';

/// Shows a registered bottom sheet by its view model type, looked up in
/// [cuboidBottomSheetBuilders] (lib/app/app.bottomsheets.dart).
class BottomSheetService {
  Future<TResult?> show<TModel, TResult>() {
    final builder = cuboidBottomSheetBuilders[TModel];
    if (builder == null) {
      throw StateError('No bottom sheet registered for \$TModel.');
    }
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      throw StateError('BottomSheetService used before a Navigator exists.');
    }
    return showModalBottomSheet<TResult>(context: context, builder: builder);
  }
}
''';
}
