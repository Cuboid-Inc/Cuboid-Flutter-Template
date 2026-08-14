import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

typedef DialogFileWriter = void Function(File file, String contents);

class CreateDialogInput {
  const CreateDialogInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class CreateDialogPlan {
  const CreateDialogPlan({
    required this.name,
    required this.displayName,
    required this.packageName,
    required this.dialogClassName,
    required this.modelClassName,
    required this.directoryPath,
    required this.dialogPath,
    required this.modelPath,
    required this.appPath,
    required this.mainPath,
    required this.dialogImportLine,
    required this.dialogLine,
    required this.serviceLine,
    required this.dialogsImportLine,
    required this.setupLine,
    required this.dryRun,
  });

  final String name;
  final String displayName;
  final String packageName;
  final String dialogClassName;
  final String modelClassName;
  final String directoryPath;
  final String dialogPath;
  final String modelPath;
  final String appPath;
  final String mainPath;
  final String dialogImportLine;
  final String dialogLine;
  final String serviceLine;
  final String dialogsImportLine;
  final String setupLine;
  final bool dryRun;

  List<String> get files => [dialogPath, modelPath];
}

class CreateDialogResult {
  const CreateDialogResult({required this.plan});

  final CreateDialogPlan plan;
}

class CreateDialogException implements Exception {
  const CreateDialogException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateDialogService {
  CreateDialogService({DialogFileWriter? fileWriter})
    : _fileWriter =
          fileWriter ?? ((file, contents) => file.writeAsStringSync(contents));

  final DialogFileWriter _fileWriter;

  Future<CreateDialogPlan> plan(CreateDialogInput input) async {
    final dialogName = _normalizeDialogName(input.name);
    final words = dialogName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final dialogClassName = '${_pascalCase(words)}Dialog';
    final modelClassName = '${_pascalCase(words)}DialogModel';
    final directoryPath = 'lib/shared/dialogs/$dialogName';
    final dialogPath = '$directoryPath/${dialogName}_dialog.dart';
    final modelPath = '$directoryPath/${dialogName}_dialog_model.dart';

    return CreateDialogPlan(
      name: dialogName,
      displayName: _humanize(words),
      packageName: packageName,
      dialogClassName: dialogClassName,
      modelClassName: modelClassName,
      directoryPath: directoryPath,
      dialogPath: dialogPath,
      modelPath: modelPath,
      appPath: 'lib/app/app.dart',
      mainPath: 'lib/main.dart',
      dialogImportLine:
          "import 'package:$packageName/shared/dialogs/$dialogName/${dialogName}_dialog.dart';",
      dialogLine:
          '    StackedDialog(\n'
          '      classType: $dialogClassName,\n'
          '    ),',
      serviceLine: '    LazySingleton(classType: DialogService),',
      dialogsImportLine: "import 'package:$packageName/app/app.dialogs.dart';",
      setupLine: '  setupDialogUi();',
      dryRun: input.dryRun,
    );
  }

  Future<CreateDialogResult> create(CreateDialogInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final appFile = _targetFile(projectRoot, createPlan.appPath);
    final mainFile = _targetFile(projectRoot, createPlan.mainPath);
    final dialogFile = _targetFile(projectRoot, createPlan.dialogPath);
    final modelFile = _targetFile(projectRoot, createPlan.modelPath);
    final dialogDirectory = _targetDirectory(
      projectRoot,
      createPlan.directoryPath,
    );

    final appContents = _validateApp(projectRoot, createPlan, appFile);
    final mainContents = _validateMain(createPlan, mainFile);
    _validateGeneratedTargets(
      projectRoot,
      createPlan,
      dialogDirectory,
      dialogFile,
      modelFile,
    );

    final nextAppContents = _applyAppPlan(appContents, createPlan);
    final nextMainContents = _applyMainPlan(mainContents, createPlan);

    if (createPlan.dryRun) {
      return CreateDialogResult(plan: createPlan);
    }

    final createdFiles = <File>[];
    final createdDirectories = <Directory>[];
    try {
      _createParentDirectories(
        projectRoot,
        dialogFile.parent,
        createdDirectories,
      );
      _fileWriter(dialogFile, _dialogContents(createPlan));
      createdFiles.add(dialogFile);
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
      throw CreateDialogException(
        'Unable to create dialog ${createPlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {appFile: appContents, mainFile: mainContents},
      );
      throw CreateDialogException(
        'Unable to create dialog ${createPlan.displayName}: $error',
      );
    }

    return CreateDialogResult(plan: createPlan);
  }
}

void _validateGeneratedTargets(
  Directory projectRoot,
  CreateDialogPlan plan,
  Directory dialogDirectory,
  File dialogFile,
  File modelFile,
) {
  _ensureSafeParentDirectories(projectRoot, dialogDirectory.parent);
  for (final entity in [dialogDirectory, dialogFile, modelFile]) {
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      final relativePath = _relativePath(projectRoot, entity.path);
      if (relativePath == plan.directoryPath) {
        throw CreateDialogException(
          'Dialog already exists: ${plan.directoryPath}',
        );
      }
      throw CreateDialogException('Target already exists: $relativePath');
    }
  }
}

String _validateApp(
  Directory projectRoot,
  CreateDialogPlan plan,
  File appFile,
) {
  _ensureRegularFile(appFile.path, plan.appPath);
  final contents = _readFile(appFile, plan.appPath);

  _requireSingleMarker(contents, '// @stacked-import');
  _requireSingleMarker(contents, '// @stacked-service');
  if (_hasMatchingDialogImport(contents, plan)) {
    throw CreateDialogException(
      'Dialog import already exists for ${plan.dialogClassName}.',
    );
  }
  if (_hasConflictingDialogImport(contents, plan)) {
    throw CreateDialogException(
      'Conflicting dialog import exists for ${plan.dialogClassName}.',
    );
  }
  if (_hasDialogRegistration(contents, plan)) {
    throw CreateDialogException(
      'Dialog already exists for ${plan.dialogClassName}.',
    );
  }
  if (_dialogServiceRegistrationCount(contents) > 1) {
    throw const CreateDialogException('Duplicate DialogService registration.');
  }
  if (!_hasDialogsConfiguration(contents)) {
    _validateCanCreateDialogsConfiguration(contents);
  } else {
    _requireSingleMarker(contents, '// @stacked-dialog');
  }

  final dialogDirectory = _targetDirectory(projectRoot, plan.directoryPath);
  _ensureSafeParentDirectories(projectRoot, dialogDirectory.parent);
  return contents;
}

String _validateMain(CreateDialogPlan plan, File mainFile) {
  _ensureRegularFile(mainFile.path, plan.mainPath);
  final contents = _readFile(mainFile, plan.mainPath);

  if (_importCount(contents, plan.dialogsImportLine) > 1) {
    throw const CreateDialogException('Duplicate app.dialogs.dart import.');
  }
  if (_hasConflictingDialogsImport(contents, plan)) {
    throw const CreateDialogException(
      'Conflicting app.dialogs.dart import exists.',
    );
  }
  if (_setupDialogUiCount(contents) > 1) {
    throw const CreateDialogException('Duplicate setupDialogUi call.');
  }
  if (!contents.contains(RegExp(r'\bawait\s+setupLocator\(\)\s*;'))) {
    throw const CreateDialogException(
      'lib/main.dart must call await setupLocator();',
    );
  }
  return contents;
}

void _validateCanCreateDialogsConfiguration(String contents) {
  final appStart = contents.indexOf('@StackedApp(');
  if (appStart == -1) {
    throw const CreateDialogException('Missing @StackedApp annotation.');
  }
  final dependenciesStart = contents.indexOf(
    RegExp(r'^[ \t]*dependencies\s*:\s*\[', multiLine: true),
    appStart,
  );
  if (dependenciesStart == -1) {
    throw const CreateDialogException(
      'Missing dependencies configuration in @StackedApp.',
    );
  }
}

void _ensureRegularFile(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw CreateDialogException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw CreateDialogException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.file) {
    throw CreateDialogException('$label must be a regular file.');
  }
}

void _ensureSafeParentDirectories(Directory projectRoot, Directory parent) {
  final rootPath = projectRoot.absolute.path;
  final parentPath = parent.absolute.path;
  if (!parentPath.startsWith(_withTrailingSeparator(rootPath))) {
    throw const CreateDialogException(
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
      throw CreateDialogException(
        'Refusing to create dialog through a symlink: '
        '${_relativePath(projectRoot, current)}',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw CreateDialogException('$current must be a directory.');
    }
  }
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw CreateDialogException('Unable to read $label: ${error.message}');
  }
}

void _requireSingleMarker(String contents, String marker) {
  final count = marker.allMatches(contents).length;
  if (count == 0) {
    throw CreateDialogException('Missing marker: $marker');
  }
  if (count > 1) {
    throw CreateDialogException('Duplicate marker: $marker');
  }
}

bool _hasDialogsConfiguration(String contents) {
  return RegExp(r'^[ \t]*dialogs\s*:\s*\[', multiLine: true).hasMatch(contents);
}

bool _hasMatchingDialogImport(String contents, CreateDialogPlan plan) {
  return _dialogImports(contents, plan).contains(plan.dialogImportLine);
}

bool _hasConflictingDialogImport(String contents, CreateDialogPlan plan) {
  return _dialogImports(
    contents,
    plan,
  ).any((line) => line != plan.dialogImportLine);
}

List<String> _dialogImports(String contents, CreateDialogPlan plan) {
  final pattern = RegExp(
    r'''^import\s+(['"])([^'"]*/shared/dialogs/''' +
        RegExp.escape(plan.name) +
        r'''/''' +
        RegExp.escape('${plan.name}_dialog.dart') +
        r''')\1\s*;''',
    multiLine: true,
  );
  return pattern
      .allMatches(contents)
      .map((match) => "import '${match.group(2)}';")
      .toList();
}

bool _hasDialogRegistration(String contents, CreateDialogPlan plan) {
  final pattern = RegExp(
    r'StackedDialog\s*\(\s*classType\s*:\s*' +
        RegExp.escape(plan.dialogClassName) +
        r'\b',
  );
  return pattern.hasMatch(contents);
}

int _dialogServiceRegistrationCount(String contents) {
  return RegExp(r'classType\s*:\s*DialogService\b').allMatches(contents).length;
}

int _importCount(String contents, String importLine) {
  return RegExp(
    '^${RegExp.escape(importLine)}\$',
    multiLine: true,
  ).allMatches(contents).length;
}

bool _hasConflictingDialogsImport(String contents, CreateDialogPlan plan) {
  final pattern = RegExp(
    r'''^import\s+(['"])([^'"]*/app/app\.dialogs\.dart)\1\s*;''',
    multiLine: true,
  );
  return pattern
      .allMatches(contents)
      .map((match) => "import '${match.group(2)}';")
      .any((line) => line != plan.dialogsImportLine);
}

int _setupDialogUiCount(String contents) {
  return RegExp(r'\bsetupDialogUi\s*\(\s*\)\s*;').allMatches(contents).length;
}

String _applyAppPlan(String contents, CreateDialogPlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  var next = contents.replaceFirst(
    RegExp(r'^[ \t]*// @stacked-import', multiLine: true),
    '${plan.dialogImportLine}$lineEnding// @stacked-import',
  );

  if (_dialogServiceRegistrationCount(next) == 0) {
    next = next.replaceFirst(
      RegExp(r'^[ \t]*// @stacked-service', multiLine: true),
      '${plan.serviceLine}$lineEnding    // @stacked-service',
    );
  }

  if (_hasDialogsConfiguration(next)) {
    return next.replaceFirst(
      RegExp(r'^[ \t]*// @stacked-dialog', multiLine: true),
      '${plan.dialogLine}$lineEnding    // @stacked-dialog',
    );
  }

  return next.replaceFirst(
    RegExp(r'^[ \t]*dependencies\s*:\s*\[', multiLine: true),
    '  dialogs: [$lineEnding'
    '${plan.dialogLine}$lineEnding'
    '    // @stacked-dialog$lineEnding'
    '  ],$lineEnding'
    '  dependencies: [',
  );
}

String _applyMainPlan(String contents, CreateDialogPlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  var next = contents;
  if (_importCount(next, plan.dialogsImportLine) == 0) {
    next = _insertImport(next, plan.dialogsImportLine, lineEnding);
  }
  if (_setupDialogUiCount(next) == 0) {
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
    throw const CreateDialogException(
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
    temp = file.parent.createTempSync('.cuboid-dialog-');
  } on FileSystemException catch (error) {
    throw CreateDialogException('Unable to update $label: ${error.message}');
  }
  final tempFile = File(
    '${temp.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
  );
  try {
    tempFile.writeAsStringSync(contents);
    tempFile.renameSync(file.path);
  } on FileSystemException catch (error) {
    throw CreateDialogException('Unable to update $label: ${error.message}');
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
    throw const CreateDialogException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const CreateDialogException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeDialogName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const CreateDialogException('Dialog name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const CreateDialogException(
      'Dialog name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const CreateDialogException(
      'Dialog name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const CreateDialogException(
      'Dialog name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const CreateDialogException(
      'Dialog name must not be a Dart keyword.',
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

String _dialogContents(CreateDialogPlan plan) {
  return '''
import 'package:${plan.packageName}/shared/dialogs/${plan.name}/${plan.name}_dialog_model.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ${plan.dialogClassName} extends StackedView<${plan.modelClassName}> {
  const ${plan.dialogClassName}({
    super.key,
    required this.request,
    required this.completer,
  });

  final DialogRequest<dynamic> request;
  final void Function(DialogResponse<dynamic> response) completer;

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

String _modelContents(CreateDialogPlan plan) {
  return '''
import 'package:stacked/stacked.dart';

class ${plan.modelClassName} extends BaseViewModel {}
''';
}
