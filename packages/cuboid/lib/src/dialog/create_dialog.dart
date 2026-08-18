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
    required this.locatorPath,
    required this.dialogsPath,
    required this.dialogServicePath,
    required this.dialogImportLine,
    required this.modelImportLine,
    required this.dialogEntryLine,
    required this.serviceImportLine,
    required this.serviceLine,
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
  final String locatorPath;
  final String dialogsPath;
  final String dialogServicePath;
  final String dialogImportLine;
  final String modelImportLine;
  final String dialogEntryLine;
  final String serviceImportLine;
  final String serviceLine;
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
      locatorPath: 'lib/app/app.locator.dart',
      dialogsPath: 'lib/app/app.dialogs.dart',
      dialogServicePath: 'lib/core/services/dialog_service.dart',
      dialogImportLine:
          "import 'package:$packageName/shared/dialogs/$dialogName/${dialogName}_dialog.dart';",
      modelImportLine:
          "import 'package:$packageName/shared/dialogs/$dialogName/${dialogName}_dialog_model.dart';",
      dialogEntryLine: '$modelClassName: (_) => const $dialogClassName(),',
      serviceImportLine:
          "import 'package:$packageName/core/services/dialog_service.dart';",
      serviceLine:
          '  locator.registerLazySingleton<DialogService>(() => DialogService());',
      dryRun: input.dryRun,
    );
  }

  Future<CreateDialogResult> create(CreateDialogInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final locatorFile = _targetFile(projectRoot, createPlan.locatorPath);
    final dialogsFile = _targetFile(projectRoot, createPlan.dialogsPath);
    final serviceFile = _targetFile(projectRoot, createPlan.dialogServicePath);
    final dialogFile = _targetFile(projectRoot, createPlan.dialogPath);
    final modelFile = _targetFile(projectRoot, createPlan.modelPath);
    final dialogDirectory = _targetDirectory(
      projectRoot,
      createPlan.directoryPath,
    );

    final needsService = !serviceFile.existsSync();
    final dialogsExists = dialogsFile.existsSync();

    final locatorContents = _validateLocator(
      createPlan,
      locatorFile,
      needsService: needsService,
    );
    final dialogsContents = dialogsExists
        ? _validateDialogs(createPlan, dialogsFile)
        : null;
    _validateGeneratedTargets(
      projectRoot,
      createPlan,
      dialogDirectory,
      dialogFile,
      modelFile,
    );
    if (needsService) {
      _ensureNotExisting(serviceFile, label: createPlan.dialogServicePath);
    }

    final nextLocatorContents = needsService
        ? _applyLocatorPlan(locatorContents, createPlan)
        : locatorContents;
    final nextDialogsContents = dialogsExists
        ? _applyDialogsPlan(dialogsContents!, createPlan)
        : _freshDialogsContents(createPlan);

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
      if (needsService) {
        _createParentDirectories(
          projectRoot,
          serviceFile.parent,
          createdDirectories,
        );
        _fileWriter(serviceFile, _dialogServiceContents(createPlan));
        createdFiles.add(serviceFile);
      }
      if (dialogsExists) {
        _replaceFileContents(
          dialogsFile,
          nextDialogsContents,
          label: createPlan.dialogsPath,
        );
      } else {
        _fileWriter(dialogsFile, nextDialogsContents);
        createdFiles.add(dialogsFile);
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
          if (dialogsExists) dialogsFile: dialogsContents!,
        },
      );
      throw CreateDialogException(
        'Unable to create dialog ${createPlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {
          locatorFile: locatorContents,
          if (dialogsExists) dialogsFile: dialogsContents!,
        },
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

void _ensureNotExisting(File file, {required String label}) {
  final type = FileSystemEntity.typeSync(file.path, followLinks: false);
  if (type != FileSystemEntityType.notFound) {
    throw CreateDialogException('Target already exists: $label');
  }
}

String _validateLocator(
  CreateDialogPlan plan,
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
  if (RegExp(r'register\w*\s*<\s*DialogService\s*>').hasMatch(contents)) {
    throw const CreateDialogException('Duplicate DialogService registration.');
  }
  return contents;
}

String _validateDialogs(CreateDialogPlan plan, File dialogsFile) {
  _ensureRegularFile(dialogsFile.path, plan.dialogsPath);
  final contents = _readFile(dialogsFile, plan.dialogsPath);

  _requireSingleMarker(contents, '// @cuboid-import');
  _requireSingleMarker(contents, '// @cuboid-dialog');
  if (contents.contains(plan.dialogImportLine)) {
    throw CreateDialogException(
      'Dialog import already exists for ${plan.dialogClassName}.',
    );
  }
  if (RegExp(RegExp.escape(plan.modelClassName) + r'\s*:').hasMatch(contents)) {
    throw CreateDialogException(
      'Dialog already exists for ${plan.dialogClassName}.',
    );
  }
  return contents;
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

String _applyLocatorPlan(String contents, CreateDialogPlan plan) {
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

String _applyDialogsPlan(String contents, CreateDialogPlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  return contents
      .replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-import', multiLine: true),
        '${plan.dialogImportLine}$lineEnding'
        '${plan.modelImportLine}$lineEnding'
        '// @cuboid-import',
      )
      .replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-dialog', multiLine: true),
        '  ${plan.dialogEntryLine}$lineEnding  // @cuboid-dialog',
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
import 'package:${plan.packageName}/core/mvvm/cuboid_view.dart';
import 'package:${plan.packageName}/shared/dialogs/${plan.name}/${plan.name}_dialog_model.dart';
import 'package:flutter/material.dart';

class ${plan.dialogClassName} extends CuboidView<${plan.modelClassName}> {
  const ${plan.dialogClassName}({super.key});

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
import 'package:${plan.packageName}/core/mvvm/cuboid_view_model.dart';

class ${plan.modelClassName} extends CuboidViewModel {}
''';
}

String _freshDialogsContents(CreateDialogPlan plan) {
  return '''
import 'package:flutter/material.dart';
${plan.dialogImportLine}
${plan.modelImportLine}
// @cuboid-import

final Map<Type, WidgetBuilder> cuboidDialogBuilders = {
  ${plan.dialogEntryLine}
  // @cuboid-dialog
};
''';
}

String _dialogServiceContents(CreateDialogPlan plan) {
  return '''
import 'package:${plan.packageName}/app/app.dialogs.dart';
import 'package:${plan.packageName}/core/services/navigation_service.dart';
import 'package:flutter/material.dart';

/// Shows a registered dialog by its view model type, looked up in
/// [cuboidDialogBuilders] (lib/app/app.dialogs.dart).
class DialogService {
  Future<TResult?> show<TModel, TResult>() {
    final builder = cuboidDialogBuilders[TModel];
    if (builder == null) {
      throw StateError('No dialog registered for \$TModel.');
    }
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      throw StateError('DialogService used before a Navigator exists.');
    }
    return showDialog<TResult>(context: context, builder: builder);
  }
}
''';
}
