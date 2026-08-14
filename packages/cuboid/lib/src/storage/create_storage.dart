import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

typedef StorageFileWriter = void Function(File file, String contents);

class CreateStorageInput {
  const CreateStorageInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class CreateStoragePlan {
  const CreateStoragePlan({
    required this.name,
    required this.displayName,
    required this.className,
    required this.path,
    required this.dryRun,
  });

  final String name;
  final String displayName;
  final String className;
  final String path;
  final bool dryRun;
}

class CreateStorageResult {
  const CreateStorageResult({required this.plan});

  final CreateStoragePlan plan;
}

class CreateStorageException implements Exception {
  const CreateStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateStorageService {
  CreateStorageService({StorageFileWriter? fileWriter})
    : _fileWriter =
          fileWriter ?? ((file, contents) => file.writeAsStringSync(contents));

  final StorageFileWriter _fileWriter;

  Future<CreateStoragePlan> plan(CreateStorageInput input) async {
    final storageName = _normalizeStorageName(input.name);
    final words = storageName.split('_');
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    _ensureProjectRoot(projectRoot);

    return CreateStoragePlan(
      name: storageName,
      displayName: _humanize(words),
      className: '${_pascalCase(words)}Storage',
      path: 'lib/core/storage/${storageName}_storage.dart',
      dryRun: input.dryRun,
    );
  }

  Future<CreateStorageResult> create(CreateStorageInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final storageFile = _targetFile(projectRoot, createPlan.path);

    _validateTarget(projectRoot, createPlan, storageFile);

    if (createPlan.dryRun) {
      return CreateStorageResult(plan: createPlan);
    }

    final createdDirectories = <Directory>[];
    try {
      _createParentDirectories(
        projectRoot,
        storageFile.parent,
        createdDirectories,
      );
      _fileWriter(storageFile, _storageContents(createPlan));
    } on FileSystemException catch (error) {
      _rollback(storageFile, createdDirectories);
      throw CreateStorageException(
        'Unable to create storage ${createPlan.displayName}: '
        '${error.message}',
      );
    } catch (error) {
      _rollback(storageFile, createdDirectories);
      throw CreateStorageException(
        'Unable to create storage ${createPlan.displayName}: $error',
      );
    }

    return CreateStorageResult(plan: createPlan);
  }
}

void _validateTarget(
  Directory projectRoot,
  CreateStoragePlan plan,
  File storageFile,
) {
  _validateNoAncestorSymlinks(projectRoot);

  if (storageFile.existsSync() ||
      Directory(storageFile.path).existsSync() ||
      Link(storageFile.path).existsSync()) {
    throw CreateStorageException('Target already exists: ${plan.path}');
  }
}

void _validateNoAncestorSymlinks(Directory projectRoot) {
  final lib = Directory('${projectRoot.path}${Platform.pathSeparator}lib');
  final core = Directory('${lib.path}${Platform.pathSeparator}core');
  final storage = Directory('${core.path}${Platform.pathSeparator}storage');
  for (final directory in [lib, core, storage]) {
    if (Link(directory.path).existsSync()) {
      throw CreateStorageException(
        'Refusing to create storage through a symlink: '
        '${_relativePath(projectRoot, directory.path)}',
      );
    }
  }
}

void _ensureProjectRoot(Directory projectRoot) {
  final pubspec = File(
    '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml',
  );
  if (!pubspec.existsSync()) {
    throw const CreateStorageException(
      'pubspec.yaml was not found in the current project.',
    );
  }
}

File _targetFile(Directory projectRoot, String path) {
  return File(
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

void _rollback(File storageFile, List<Directory> createdDirectories) {
  try {
    if (storageFile.existsSync()) {
      storageFile.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup; preserve the original creation failure.
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

String _relativePath(Directory root, String path) {
  return path
      .substring(root.path.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

String _normalizeStorageName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const CreateStorageException('Storage name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const CreateStorageException(
      'Storage name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const CreateStorageException(
      'Storage name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const CreateStorageException(
      'Storage name must use letters and numbers separated by _ or -.',
    );
  }

  final normalized = value.replaceAll('-', '_').toLowerCase();
  if (dartKeywords.contains(normalized)) {
    throw const CreateStorageException(
      'Storage name must not be a Dart keyword.',
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

String _storageContents(CreateStoragePlan plan) {
  return '''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key-value storage scoped to the '${plan.name}' namespace.
class ${plan.className} {
  const ${plan.className}();

  static const _storage = FlutterSecureStorage();

  Future<String?> read(String key) => _storage.read(key: _namespaced(key));

  Future<void> write(String key, String value) =>
      _storage.write(key: _namespaced(key), value: value);

  Future<void> delete(String key) => _storage.delete(key: _namespaced(key));

  Future<bool> containsKey(String key) =>
      _storage.containsKey(key: _namespaced(key));

  Future<void> clear() async {
    final all = await _storage.readAll();
    for (final key in all.keys.where((key) => key.startsWith(_prefix))) {
      await _storage.delete(key: key);
    }
  }

  static const _prefix = '${plan.name}.';

  String _namespaced(String key) => '\$_prefix\$key';
}
''';
}
