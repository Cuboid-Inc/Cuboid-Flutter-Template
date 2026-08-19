import 'dart:io';

import 'package:cuboid/src/edit/generated_edits.dart';

const _storagePath = 'lib/core/storage/local_storage.dart';
const _storageClassName = 'LocalStorage';

class DeleteStorageInput {
  const DeleteStorageInput({this.projectRoot, this.dryRun = false});

  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteStoragePlan {
  const DeleteStoragePlan({
    required this.className,
    required this.path,
    required this.dryRun,
  });

  final String className;
  final String path;
  final bool dryRun;
}

class DeleteStorageResult {
  const DeleteStorageResult({required this.plan});

  final DeleteStoragePlan plan;
}

class DeleteStorageException implements Exception {
  const DeleteStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeleteStorageService {
  Future<DeleteStoragePlan> plan(DeleteStorageInput input) async {
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    _ensureProjectRoot(projectRoot);

    return DeleteStoragePlan(
      className: _storageClassName,
      path: _storagePath,
      dryRun: input.dryRun,
    );
  }

  Future<DeleteStorageResult> delete(DeleteStorageInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final storageFile = targetFile(projectRoot, deletePlan.path);

    if (!isRegularFile(storageFile.path)) {
      throw const DeleteStorageException('No local storage found.');
    }

    if (deletePlan.dryRun) {
      return DeleteStorageResult(plan: deletePlan);
    }

    try {
      storageFile.deleteSync();
      pruneEmptyDirectories(
        targetDirectory(projectRoot, 'lib/core/storage'),
        stopAt: projectRoot,
      );
    } on FileSystemException catch (error) {
      throw DeleteStorageException(
        'Unable to delete storage ${deletePlan.className}: ${error.message}',
      );
    } catch (error) {
      throw DeleteStorageException(
        'Unable to delete storage ${deletePlan.className}: $error',
      );
    }

    return DeleteStorageResult(plan: deletePlan);
  }
}

void _ensureProjectRoot(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  if (!isRegularFile(pubspecPath)) {
    throw const DeleteStorageException(
      'pubspec.yaml was not found in the current project.',
    );
  }
}
