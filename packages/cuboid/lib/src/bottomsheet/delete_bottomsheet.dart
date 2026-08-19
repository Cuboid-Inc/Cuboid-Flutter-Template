import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/edit/generated_edits.dart';

class DeleteBottomSheetInput {
  const DeleteBottomSheetInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteBottomSheetPlan {
  const DeleteBottomSheetPlan({
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
    required this.removesInfrastructure,
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

  /// True when this deletion removes `lib/app/app.bottomsheets.dart` (and
  /// `BottomSheetService`) entirely because this is the last remaining
  /// bottom sheet.
  final bool removesInfrastructure;
  final bool dryRun;

  List<String> get files => [sheetPath, modelPath];
}

class DeleteBottomSheetResult {
  const DeleteBottomSheetResult({required this.plan});

  final DeleteBottomSheetPlan plan;
}

class DeleteBottomSheetException implements Exception {
  const DeleteBottomSheetException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Matches any bottom sheet entry line of the shape a
/// `create_bottomsheet.dart` `_apply*Plan` would insert, regardless of
/// which bottom sheet it belongs to. Used to count how many bottom sheets
/// remain in `app.bottomsheets.dart` so the last deletion can also tear
/// down `BottomSheetService`.
final _genericBottomSheetEntryPattern = RegExp(
  r'^[ \t]*\w+:\s*\(_\)\s*=>\s*const\s+\w+\(\),[ \t]*$',
  multiLine: true,
);

class DeleteBottomSheetService {
  Future<DeleteBottomSheetPlan> plan(DeleteBottomSheetInput input) async {
    final bottomSheetName = _normalizeBottomSheetName(input.name);
    final words = bottomSheetName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final sheetClassName = '${_pascalCase(words)}Sheet';
    final modelClassName = '${_pascalCase(words)}SheetModel';
    final directoryPath = 'lib/shared/bottom_sheets/$bottomSheetName';
    final sheetPath = '$directoryPath/${bottomSheetName}_sheet.dart';
    final modelPath = '$directoryPath/${bottomSheetName}_sheet_model.dart';
    final bottomSheetsFile = targetFile(
      projectRoot,
      'lib/app/app.bottomsheets.dart',
    );

    var removesInfrastructure = false;
    if (isRegularFile(bottomSheetsFile.path)) {
      final contents = _readFile(
        bottomSheetsFile,
        'lib/app/app.bottomsheets.dart',
      );
      final entryCount = _genericBottomSheetEntryPattern
          .allMatches(contents)
          .length;
      removesInfrastructure = entryCount == 1;
    }

    return DeleteBottomSheetPlan(
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
      removesInfrastructure: removesInfrastructure,
      dryRun: input.dryRun,
    );
  }

  Future<DeleteBottomSheetResult> delete(DeleteBottomSheetInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final sheetFile = targetFile(projectRoot, deletePlan.sheetPath);
    final modelFile = targetFile(projectRoot, deletePlan.modelPath);
    final bottomSheetDirectory = targetDirectory(
      projectRoot,
      deletePlan.directoryPath,
    );
    final bottomSheetsFile = targetFile(
      projectRoot,
      deletePlan.bottomSheetsPath,
    );
    final locatorFile = targetFile(projectRoot, deletePlan.locatorPath);
    final serviceFile = targetFile(
      projectRoot,
      deletePlan.bottomSheetServicePath,
    );

    if (!isRegularDirectory(bottomSheetDirectory.path) ||
        !isRegularFile(sheetFile.path) ||
        !isRegularFile(modelFile.path)) {
      throw DeleteBottomSheetException(
        'Bottom sheet not found: ${deletePlan.name}.',
      );
    }
    final bottomSheetsContents = _validateBottomSheets(
      deletePlan,
      bottomSheetsFile,
    );
    final nextBottomSheetsContents = _removeBottomSheetEntries(
      bottomSheetsContents,
      deletePlan,
    );

    String? locatorContents;
    String? nextLocatorContents;
    if (deletePlan.removesInfrastructure) {
      if (!isRegularFile(locatorFile.path)) {
        throw DeleteBottomSheetException(
          '${deletePlan.locatorPath} was not found.',
        );
      }
      locatorContents = _readFile(locatorFile, deletePlan.locatorPath);
      final afterImport = removeExactLine(
        locatorContents,
        deletePlan.serviceImportLine,
      );
      if (afterImport == null) {
        throw DeleteBottomSheetException(
          'Bottom sheet not found: ${deletePlan.name}.',
        );
      }
      final afterService = removeExactLine(afterImport, deletePlan.serviceLine);
      if (afterService == null) {
        throw DeleteBottomSheetException(
          'Bottom sheet not found: ${deletePlan.name}.',
        );
      }
      nextLocatorContents = afterService;
    }

    if (deletePlan.dryRun) {
      return DeleteBottomSheetResult(plan: deletePlan);
    }

    try {
      if (deletePlan.removesInfrastructure) {
        atomicReplaceFileContents(locatorFile, nextLocatorContents!);
        bottomSheetsFile.deleteSync();
        if (serviceFile.existsSync()) {
          serviceFile.deleteSync();
        }
      } else {
        atomicReplaceFileContents(bottomSheetsFile, nextBottomSheetsContents);
      }
      sheetFile.deleteSync();
      modelFile.deleteSync();
      deleteDirectoryIfExists(bottomSheetDirectory);
      pruneEmptyDirectories(
        targetDirectory(projectRoot, 'lib/shared/bottom_sheets'),
        stopAt: targetDirectory(projectRoot, 'lib/shared'),
      );
    } on FileSystemException catch (error) {
      restoreFileContents({
        bottomSheetsFile: bottomSheetsContents,
        if (deletePlan.removesInfrastructure) locatorFile: locatorContents!,
      });
      throw DeleteBottomSheetException(
        'Unable to delete bottom sheet ${deletePlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      restoreFileContents({
        bottomSheetsFile: bottomSheetsContents,
        if (deletePlan.removesInfrastructure) locatorFile: locatorContents!,
      });
      throw DeleteBottomSheetException(
        'Unable to delete bottom sheet ${deletePlan.displayName}: $error',
      );
    }

    return DeleteBottomSheetResult(plan: deletePlan);
  }
}

String _validateBottomSheets(
  DeleteBottomSheetPlan plan,
  File bottomSheetsFile,
) {
  if (!isRegularFile(bottomSheetsFile.path)) {
    throw DeleteBottomSheetException('Bottom sheet not found: ${plan.name}.');
  }
  final contents = _readFile(bottomSheetsFile, plan.bottomSheetsPath);
  if (!contents.contains(plan.sheetImportLine) ||
      !contents.contains(plan.modelImportLine) ||
      !contents.contains(plan.bottomSheetEntryLine)) {
    throw DeleteBottomSheetException('Bottom sheet not found: ${plan.name}.');
  }
  return contents;
}

String _removeBottomSheetEntries(String contents, DeleteBottomSheetPlan plan) {
  var next = removeExactLine(contents, plan.sheetImportLine);
  if (next == null) {
    throw DeleteBottomSheetException('Bottom sheet not found: ${plan.name}.');
  }
  next = removeExactLine(next, plan.modelImportLine);
  if (next == null) {
    throw DeleteBottomSheetException('Bottom sheet not found: ${plan.name}.');
  }
  next = removeExactLine(next, plan.bottomSheetEntryLine);
  if (next == null) {
    throw DeleteBottomSheetException('Bottom sheet not found: ${plan.name}.');
  }
  return next;
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw DeleteBottomSheetException('Unable to read $label: ${error.message}');
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  if (!isRegularFile(pubspecPath)) {
    throw const DeleteBottomSheetException(
      'pubspec.yaml was not found in the current project.',
    );
  }

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const DeleteBottomSheetException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const DeleteBottomSheetException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeBottomSheetName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const DeleteBottomSheetException(
      'Bottom sheet name must not be empty.',
    );
  }
  if (value == '.' || value == '..') {
    throw const DeleteBottomSheetException(
      'Bottom sheet name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const DeleteBottomSheetException(
      'Bottom sheet name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const DeleteBottomSheetException(
      'Bottom sheet name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const DeleteBottomSheetException(
      'Bottom sheet name must not be a Dart keyword.',
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
