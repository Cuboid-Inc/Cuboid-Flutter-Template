import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/edit/generated_edits.dart';

class DeleteDialogInput {
  const DeleteDialogInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteDialogPlan {
  const DeleteDialogPlan({
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
    required this.removesInfrastructure,
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

  /// True when this deletion removes `lib/app/app.dialogs.dart` (and
  /// `DialogService`) entirely because this is the last remaining dialog.
  final bool removesInfrastructure;
  final bool dryRun;

  List<String> get files => [dialogPath, modelPath];
}

class DeleteDialogResult {
  const DeleteDialogResult({required this.plan});

  final DeleteDialogPlan plan;
}

class DeleteDialogException implements Exception {
  const DeleteDialogException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Matches any dialog entry line of the shape a `create_dialog.dart`
/// `_apply*Plan` would insert, regardless of which dialog it belongs to.
/// Used to count how many dialogs remain in `app.dialogs.dart` so the last
/// deletion can also tear down `DialogService`.
final _genericDialogEntryPattern = RegExp(
  r'^[ \t]*\w+:\s*\(_\)\s*=>\s*const\s+\w+\(\),[ \t]*$',
  multiLine: true,
);

class DeleteDialogService {
  Future<DeleteDialogPlan> plan(DeleteDialogInput input) async {
    final dialogName = _normalizeDialogName(input.name);
    final words = dialogName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final dialogClassName = '${_pascalCase(words)}Dialog';
    final modelClassName = '${_pascalCase(words)}DialogModel';
    final directoryPath = 'lib/shared/dialogs/$dialogName';
    final dialogPath = '$directoryPath/${dialogName}_dialog.dart';
    final modelPath = '$directoryPath/${dialogName}_dialog_model.dart';
    final dialogsFile = targetFile(projectRoot, 'lib/app/app.dialogs.dart');

    var removesInfrastructure = false;
    if (isRegularFile(dialogsFile.path)) {
      final contents = _readFile(dialogsFile, 'lib/app/app.dialogs.dart');
      final entryCount = _genericDialogEntryPattern.allMatches(contents).length;
      removesInfrastructure = entryCount == 1;
    }

    return DeleteDialogPlan(
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
      removesInfrastructure: removesInfrastructure,
      dryRun: input.dryRun,
    );
  }

  Future<DeleteDialogResult> delete(DeleteDialogInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final dialogFile = targetFile(projectRoot, deletePlan.dialogPath);
    final modelFile = targetFile(projectRoot, deletePlan.modelPath);
    final dialogDirectory = targetDirectory(
      projectRoot,
      deletePlan.directoryPath,
    );
    final dialogsFile = targetFile(projectRoot, deletePlan.dialogsPath);
    final locatorFile = targetFile(projectRoot, deletePlan.locatorPath);
    final serviceFile = targetFile(projectRoot, deletePlan.dialogServicePath);

    if (!isRegularDirectory(dialogDirectory.path) ||
        !isRegularFile(dialogFile.path) ||
        !isRegularFile(modelFile.path)) {
      throw DeleteDialogException('Dialog not found: ${deletePlan.name}.');
    }
    final dialogsContents = _validateDialogs(deletePlan, dialogsFile);
    final nextDialogsContents = _removeDialogEntries(
      dialogsContents,
      deletePlan,
    );

    String? locatorContents;
    String? nextLocatorContents;
    if (deletePlan.removesInfrastructure) {
      if (!isRegularFile(locatorFile.path)) {
        throw DeleteDialogException('${deletePlan.locatorPath} was not found.');
      }
      locatorContents = _readFile(locatorFile, deletePlan.locatorPath);
      final afterImport = removeExactLine(
        locatorContents,
        deletePlan.serviceImportLine,
      );
      if (afterImport == null) {
        throw DeleteDialogException('Dialog not found: ${deletePlan.name}.');
      }
      final afterService = removeExactLine(afterImport, deletePlan.serviceLine);
      if (afterService == null) {
        throw DeleteDialogException('Dialog not found: ${deletePlan.name}.');
      }
      nextLocatorContents = afterService;
    }

    if (deletePlan.dryRun) {
      return DeleteDialogResult(plan: deletePlan);
    }

    try {
      if (deletePlan.removesInfrastructure) {
        atomicReplaceFileContents(locatorFile, nextLocatorContents!);
        dialogsFile.deleteSync();
        if (serviceFile.existsSync()) {
          serviceFile.deleteSync();
        }
      } else {
        atomicReplaceFileContents(dialogsFile, nextDialogsContents);
      }
      dialogFile.deleteSync();
      modelFile.deleteSync();
      deleteDirectoryIfExists(dialogDirectory);
      pruneEmptyDirectories(
        targetDirectory(projectRoot, 'lib/shared/dialogs'),
        stopAt: targetDirectory(projectRoot, 'lib/shared'),
      );
    } on FileSystemException catch (error) {
      restoreFileContents({
        dialogsFile: dialogsContents,
        if (deletePlan.removesInfrastructure) locatorFile: locatorContents!,
      });
      throw DeleteDialogException(
        'Unable to delete dialog ${deletePlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      restoreFileContents({
        dialogsFile: dialogsContents,
        if (deletePlan.removesInfrastructure) locatorFile: locatorContents!,
      });
      throw DeleteDialogException(
        'Unable to delete dialog ${deletePlan.displayName}: $error',
      );
    }

    return DeleteDialogResult(plan: deletePlan);
  }
}

String _validateDialogs(DeleteDialogPlan plan, File dialogsFile) {
  if (!isRegularFile(dialogsFile.path)) {
    throw DeleteDialogException('Dialog not found: ${plan.name}.');
  }
  final contents = _readFile(dialogsFile, plan.dialogsPath);
  if (!contents.contains(plan.dialogImportLine) ||
      !contents.contains(plan.modelImportLine) ||
      !contents.contains(plan.dialogEntryLine)) {
    throw DeleteDialogException('Dialog not found: ${plan.name}.');
  }
  return contents;
}

String _removeDialogEntries(String contents, DeleteDialogPlan plan) {
  var next = removeExactLine(contents, plan.dialogImportLine);
  if (next == null) {
    throw DeleteDialogException('Dialog not found: ${plan.name}.');
  }
  next = removeExactLine(next, plan.modelImportLine);
  if (next == null) {
    throw DeleteDialogException('Dialog not found: ${plan.name}.');
  }
  next = removeExactLine(next, plan.dialogEntryLine);
  if (next == null) {
    throw DeleteDialogException('Dialog not found: ${plan.name}.');
  }
  return next;
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw DeleteDialogException('Unable to read $label: ${error.message}');
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  if (!isRegularFile(pubspecPath)) {
    throw const DeleteDialogException(
      'pubspec.yaml was not found in the current project.',
    );
  }

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const DeleteDialogException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const DeleteDialogException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeDialogName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const DeleteDialogException('Dialog name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const DeleteDialogException(
      'Dialog name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const DeleteDialogException(
      'Dialog name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const DeleteDialogException(
      'Dialog name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const DeleteDialogException(
      'Dialog name must not be a Dart keyword.',
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
