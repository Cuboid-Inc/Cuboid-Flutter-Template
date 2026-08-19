import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/edit/generated_edits.dart';

const _supportedProviders = <String>['supabase'];
const _supabaseGuardPath = 'lib/core/network/supabase_guard.dart';

class DeleteDatabaseInput {
  const DeleteDatabaseInput({
    required this.provider,
    this.projectRoot,
    this.dryRun = false,
  });

  final String provider;
  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteDatabasePlan {
  const DeleteDatabasePlan({
    required this.provider,
    required this.packageName,
    required this.modelClassName,
    required this.repositoryClassName,
    required this.modelPath,
    required this.repositoryPath,
    required this.appPath,
    required this.repositoryImportLine,
    required this.repositoryLine,
    required this.dryRun,
  });

  final String provider;
  final String packageName;
  final String modelClassName;
  final String repositoryClassName;
  final String modelPath;
  final String repositoryPath;
  final String appPath;
  final String repositoryImportLine;
  final String repositoryLine;
  final bool dryRun;
}

class DeleteDatabaseResult {
  const DeleteDatabaseResult({required this.plan});

  final DeleteDatabasePlan plan;
}

class DeleteDatabaseException implements Exception {
  const DeleteDatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Since only one database resource can ever exist at a time (creating a
/// second fails because `ExampleRepository` already exists), deleting "the
/// database" is always a full teardown -- there is no partial deletion.
class DeleteDatabaseService {
  Future<DeleteDatabasePlan> plan(DeleteDatabaseInput input) async {
    final provider = _normalizeProvider(input.provider);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);

    return DeleteDatabasePlan(
      provider: provider,
      packageName: packageName,
      modelClassName: 'ExampleModel',
      repositoryClassName: 'ExampleRepository',
      modelPath: 'lib/supabase/example_model.dart',
      repositoryPath: 'lib/supabase/example_repository.dart',
      appPath: 'lib/app/app.locator.dart',
      repositoryImportLine:
          "import 'package:$packageName/supabase/example_repository.dart';",
      repositoryLine:
          '  locator.registerLazySingleton<ExampleRepository>(() => const ExampleRepository());',
      dryRun: input.dryRun,
    );
  }

  Future<DeleteDatabaseResult> delete(DeleteDatabaseInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final modelFile = targetFile(projectRoot, deletePlan.modelPath);
    final repositoryFile = targetFile(projectRoot, deletePlan.repositoryPath);
    final appFile = targetFile(projectRoot, deletePlan.appPath);
    final guardFile = targetFile(projectRoot, _supabaseGuardPath);
    final migrationsDirectory = targetDirectory(
      projectRoot,
      'supabase/migrations',
    );

    if (!isRegularFile(modelFile.path) || !isRegularFile(repositoryFile.path)) {
      throw DeleteDatabaseException(
        'No ${deletePlan.provider} database found.',
      );
    }
    if (!isRegularFile(appFile.path)) {
      throw DeleteDatabaseException('${deletePlan.appPath} was not found.');
    }
    final appContents = _readFile(appFile, deletePlan.appPath);
    final hasImport = appContents.contains(deletePlan.repositoryImportLine);
    final hasRegistration = RegExp(
      r'register\w*\s*<\s*ExampleRepository\s*>',
    ).hasMatch(appContents);
    if (!hasImport || !hasRegistration) {
      throw DeleteDatabaseException(
        'No ${deletePlan.provider} database found.',
      );
    }

    var nextAppContents = removeExactLine(
      appContents,
      deletePlan.repositoryImportLine,
    );
    if (nextAppContents == null) {
      throw DeleteDatabaseException(
        'No ${deletePlan.provider} database found.',
      );
    }
    nextAppContents = removeExactLine(
      nextAppContents,
      deletePlan.repositoryLine,
    );
    if (nextAppContents == null) {
      throw DeleteDatabaseException(
        'No ${deletePlan.provider} database found.',
      );
    }

    if (!isRegularDirectory(migrationsDirectory.path)) {
      throw DeleteDatabaseException(
        'No migration file found for the ${deletePlan.provider} database.',
      );
    }
    final migrationPattern = RegExp(r'^\d{14}_create_examples\.sql$');
    final migrationMatches = migrationsDirectory
        .listSync()
        .whereType<File>()
        .where((file) => migrationPattern.hasMatch(file.uri.pathSegments.last))
        .toList();
    if (migrationMatches.isEmpty) {
      throw DeleteDatabaseException(
        'No migration file found for the ${deletePlan.provider} database.',
      );
    }
    if (migrationMatches.length > 1) {
      throw DeleteDatabaseException(
        'Multiple migration files match the ${deletePlan.provider} '
        'database; refusing to guess which to delete.',
      );
    }
    final migrationFile = migrationMatches.single;

    final pubspecFile = targetFile(projectRoot, 'pubspec.yaml');
    final pubspecContents = _readFile(pubspecFile, 'pubspec.yaml');
    final nextPubspecContents = _removeSupabaseDependency(pubspecContents);
    final pubspecChanged = nextPubspecContents != pubspecContents;

    if (deletePlan.dryRun) {
      return DeleteDatabaseResult(plan: deletePlan);
    }

    try {
      atomicReplaceFileContents(appFile, nextAppContents);
      if (pubspecChanged) {
        atomicReplaceFileContents(pubspecFile, nextPubspecContents);
      }
      modelFile.deleteSync();
      repositoryFile.deleteSync();
      migrationFile.deleteSync();
      deleteFileIfExists(guardFile);
      pruneEmptyDirectories(
        targetDirectory(projectRoot, 'lib/supabase'),
        stopAt: projectRoot,
      );
      pruneEmptyDirectories(migrationsDirectory, stopAt: projectRoot);
    } on FileSystemException catch (error) {
      restoreFileContents({
        appFile: appContents,
        if (pubspecChanged) pubspecFile: pubspecContents,
      });
      throw DeleteDatabaseException(
        'Unable to delete ${deletePlan.provider} database: ${error.message}',
      );
    } catch (error) {
      restoreFileContents({
        appFile: appContents,
        if (pubspecChanged) pubspecFile: pubspecContents,
      });
      throw DeleteDatabaseException(
        'Unable to delete ${deletePlan.provider} database: $error',
      );
    }

    return DeleteDatabaseResult(plan: deletePlan);
  }
}

/// Returns [pubspecContents] with the `supabase_flutter` dependency line
/// removed, or unchanged if none is declared. Matched by regex (rather than
/// an exact string) since the version constraint is part of the line and
/// could have been hand-edited since `cuboid create database supabase` ran.
String _removeSupabaseDependency(String pubspecContents) {
  final pattern = RegExp(
    r'^[ \t]*supabase_flutter[ \t]*:.*$\r?\n?',
    multiLine: true,
  );
  final match = pattern.firstMatch(pubspecContents);
  if (match == null) {
    return pubspecContents;
  }
  return pubspecContents.replaceRange(match.start, match.end, '');
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw DeleteDatabaseException('Unable to read $label: ${error.message}');
  }
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  if (!isRegularFile(pubspecPath)) {
    throw const DeleteDatabaseException(
      'pubspec.yaml was not found in the current project.',
    );
  }

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const DeleteDatabaseException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const DeleteDatabaseException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeProvider(String input) {
  final value = input.trim().toLowerCase();
  if (value.isEmpty) {
    throw const DeleteDatabaseException('Database provider must not be empty.');
  }
  if (!_supportedProviders.contains(value)) {
    throw DeleteDatabaseException(
      'Unsupported database provider "$input". '
      'Currently supported providers: ${_supportedProviders.join(', ')}.',
    );
  }
  return value;
}
