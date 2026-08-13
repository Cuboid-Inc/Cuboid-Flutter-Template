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
    required this.appPath,
    required this.mainPath,
    required this.sheetImportLine,
    required this.bottomSheetLine,
    required this.serviceLine,
    required this.bottomSheetsImportLine,
    required this.setupLine,
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
  final String appPath;
  final String mainPath;
  final String sheetImportLine;
  final String bottomSheetLine;
  final String serviceLine;
  final String bottomSheetsImportLine;
  final String setupLine;
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
      appPath: 'lib/app/app.dart',
      mainPath: 'lib/main.dart',
      sheetImportLine:
          "import 'package:$packageName/shared/bottom_sheets/$bottomSheetName/${bottomSheetName}_sheet.dart';",
      bottomSheetLine: '    StackedBottomsheet(classType: $sheetClassName),',
      serviceLine: '    LazySingleton(classType: BottomSheetService),',
      bottomSheetsImportLine:
          "import 'package:$packageName/app/app.bottomsheets.dart';",
      setupLine: '  setupBottomSheetUi();',
      dryRun: input.dryRun,
    );
  }

  Future<CreateBottomSheetResult> create(CreateBottomSheetInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final appFile = _targetFile(projectRoot, createPlan.appPath);
    final mainFile = _targetFile(projectRoot, createPlan.mainPath);
    final sheetFile = _targetFile(projectRoot, createPlan.sheetPath);
    final modelFile = _targetFile(projectRoot, createPlan.modelPath);
    final bottomSheetDirectory = _targetDirectory(
      projectRoot,
      createPlan.directoryPath,
    );

    final appContents = _validateApp(projectRoot, createPlan, appFile);
    final mainContents = _validateMain(createPlan, mainFile);
    _validateGeneratedTargets(
      projectRoot,
      createPlan,
      bottomSheetDirectory,
      sheetFile,
      modelFile,
    );

    final nextAppContents = _applyAppPlan(appContents, createPlan);
    final nextMainContents = _applyMainPlan(mainContents, createPlan);

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
      _replaceFileContents(appFile, nextAppContents, label: createPlan.appPath);
      _replaceFileContents(
        mainFile,
        nextMainContents,
        label: createPlan.mainPath,
      );
    } on FileSystemException catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {appFile: appContents, mainFile: mainContents},
      );
      throw CreateBottomSheetException(
        'Unable to create bottom sheet ${createPlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {appFile: appContents, mainFile: mainContents},
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

String _validateApp(
  Directory projectRoot,
  CreateBottomSheetPlan plan,
  File appFile,
) {
  _ensureRegularFile(appFile.path, plan.appPath);
  final contents = _readFile(appFile, plan.appPath);

  _requireSingleMarker(contents, '// @stacked-import');
  _requireSingleMarker(contents, '// @stacked-service');
  if (_hasMatchingSheetImport(contents, plan)) {
    throw CreateBottomSheetException(
      'Bottom sheet import already exists for ${plan.sheetClassName}.',
    );
  }
  if (_hasConflictingSheetImport(contents, plan)) {
    throw CreateBottomSheetException(
      'Conflicting bottom sheet import exists for ${plan.sheetClassName}.',
    );
  }
  if (_hasBottomSheetRegistration(contents, plan)) {
    throw CreateBottomSheetException(
      'Bottom sheet already exists for ${plan.sheetClassName}.',
    );
  }
  if (_bottomSheetServiceRegistrationCount(contents) > 1) {
    throw const CreateBottomSheetException(
      'Duplicate BottomSheetService registration.',
    );
  }
  if (!_hasBottomSheetsConfiguration(contents)) {
    _validateCanCreateBottomSheetsConfiguration(contents);
  } else {
    _requireSingleMarker(contents, '// @stacked-bottom-sheet');
  }

  final sheetDirectory = _targetDirectory(projectRoot, plan.directoryPath);
  _ensureSafeParentDirectories(projectRoot, sheetDirectory.parent);
  return contents;
}

String _validateMain(CreateBottomSheetPlan plan, File mainFile) {
  _ensureRegularFile(mainFile.path, plan.mainPath);
  final contents = _readFile(mainFile, plan.mainPath);

  if (_importCount(contents, plan.bottomSheetsImportLine) > 1) {
    throw const CreateBottomSheetException(
      'Duplicate app.bottomsheets.dart import.',
    );
  }
  if (_hasConflictingBottomSheetsImport(contents, plan)) {
    throw const CreateBottomSheetException(
      'Conflicting app.bottomsheets.dart import exists.',
    );
  }
  if (_setupBottomSheetUiCount(contents) > 1) {
    throw const CreateBottomSheetException(
      'Duplicate setupBottomSheetUi call.',
    );
  }
  if (!contents.contains(RegExp(r'\bawait\s+setupLocator\(\)\s*;'))) {
    throw const CreateBottomSheetException(
      'lib/main.dart must call await setupLocator();',
    );
  }
  return contents;
}

void _validateCanCreateBottomSheetsConfiguration(String contents) {
  final appStart = contents.indexOf('@StackedApp(');
  if (appStart == -1) {
    throw const CreateBottomSheetException('Missing @StackedApp annotation.');
  }
  final dependenciesStart = contents.indexOf(
    RegExp(r'^[ \t]*dependencies\s*:\s*\[', multiLine: true),
    appStart,
  );
  if (dependenciesStart == -1) {
    throw const CreateBottomSheetException(
      'Missing dependencies configuration in @StackedApp.',
    );
  }
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

bool _hasBottomSheetsConfiguration(String contents) {
  return RegExp(
    r'^[ \t]*bottomsheets\s*:\s*\[',
    multiLine: true,
  ).hasMatch(contents);
}

bool _hasMatchingSheetImport(String contents, CreateBottomSheetPlan plan) {
  return _sheetImports(contents, plan).contains(plan.sheetImportLine);
}

bool _hasConflictingSheetImport(String contents, CreateBottomSheetPlan plan) {
  return _sheetImports(
    contents,
    plan,
  ).any((line) => line != plan.sheetImportLine);
}

List<String> _sheetImports(String contents, CreateBottomSheetPlan plan) {
  final pattern = RegExp(
    r'''^import\s+(['"])([^'"]*/shared/bottom_sheets/''' +
        RegExp.escape(plan.name) +
        r'''/''' +
        RegExp.escape('${plan.name}_sheet.dart') +
        r''')\1\s*;''',
    multiLine: true,
  );
  return pattern
      .allMatches(contents)
      .map((match) => "import '${match.group(2)}';")
      .toList();
}

bool _hasBottomSheetRegistration(String contents, CreateBottomSheetPlan plan) {
  final pattern = RegExp(
    r'StackedBottomsheet\s*\(\s*classType\s*:\s*' +
        RegExp.escape(plan.sheetClassName) +
        r'\b',
  );
  return pattern.hasMatch(contents);
}

int _bottomSheetServiceRegistrationCount(String contents) {
  return RegExp(
    r'classType\s*:\s*BottomSheetService\b',
  ).allMatches(contents).length;
}

int _importCount(String contents, String importLine) {
  return RegExp(
    '^${RegExp.escape(importLine)}\$',
    multiLine: true,
  ).allMatches(contents).length;
}

bool _hasConflictingBottomSheetsImport(
  String contents,
  CreateBottomSheetPlan plan,
) {
  final pattern = RegExp(
    r'''^import\s+(['"])([^'"]*/app/app\.bottomsheets\.dart)\1\s*;''',
    multiLine: true,
  );
  return pattern
      .allMatches(contents)
      .map((match) => "import '${match.group(2)}';")
      .any((line) => line != plan.bottomSheetsImportLine);
}

int _setupBottomSheetUiCount(String contents) {
  return RegExp(
    r'\bsetupBottomSheetUi\s*\(\s*\)\s*;',
  ).allMatches(contents).length;
}

String _applyAppPlan(String contents, CreateBottomSheetPlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  var next = contents.replaceFirst(
    RegExp(r'^[ \t]*// @stacked-import', multiLine: true),
    '${plan.sheetImportLine}$lineEnding// @stacked-import',
  );

  if (_bottomSheetServiceRegistrationCount(next) == 0) {
    next = next.replaceFirst(
      RegExp(r'^[ \t]*// @stacked-service', multiLine: true),
      '${plan.serviceLine}$lineEnding    // @stacked-service',
    );
  }

  if (_hasBottomSheetsConfiguration(next)) {
    return next.replaceFirst(
      RegExp(r'^[ \t]*// @stacked-bottom-sheet', multiLine: true),
      '${plan.bottomSheetLine}$lineEnding    // @stacked-bottom-sheet',
    );
  }

  return next.replaceFirst(
    RegExp(r'^[ \t]*dependencies\s*:\s*\[', multiLine: true),
    '  bottomsheets: [$lineEnding'
    '${plan.bottomSheetLine}$lineEnding'
    '    // @stacked-bottom-sheet$lineEnding'
    '  ],$lineEnding'
    '  dependencies: [',
  );
}

String _applyMainPlan(String contents, CreateBottomSheetPlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  var next = contents;
  if (_importCount(next, plan.bottomSheetsImportLine) == 0) {
    next = _insertImport(next, plan.bottomSheetsImportLine, lineEnding);
  }
  if (_setupBottomSheetUiCount(next) == 0) {
    next = next.replaceFirst(
      RegExp(r'^[ \t]*await\s+setupLocator\(\)\s*;', multiLine: true),
      '  await setupLocator();$lineEnding${plan.setupLine}',
    );
  }
  return next;
}

String _insertImport(String contents, String importLine, String lineEnding) {
  final importMatches = RegExp(
    r'^import .+;$',
    multiLine: true,
  ).allMatches(contents);
  if (importMatches.isEmpty) {
    throw const CreateBottomSheetException(
      'lib/main.dart must contain import declarations.',
    );
  }
  final lastImport = importMatches.last;
  return contents.replaceRange(
    lastImport.end,
    lastImport.end,
    '$lineEnding$importLine',
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
import 'package:${plan.packageName}/shared/bottom_sheets/${plan.name}/${plan.name}_sheet_model.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ${plan.sheetClassName} extends StackedView<${plan.modelClassName}> {
  const ${plan.sheetClassName}({
    super.key,
    required this.request,
    required this.completer,
  });

  final SheetRequest<dynamic> request;
  final void Function(SheetResponse<dynamic> response) completer;

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
import 'package:stacked/stacked.dart';

class ${plan.modelClassName} extends BaseViewModel {}
''';
}
