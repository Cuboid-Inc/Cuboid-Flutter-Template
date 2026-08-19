import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart' show dartKeywords;

typedef StorageFileWriter = void Function(File file, String contents);

const _storagePath = 'lib/core/storage/local_storage.dart';
const _storageClassName = 'LocalStorage';
const _cacheEntryPath = 'lib/core/storage/cache_entry.dart';

class CreateStorageInput {
  const CreateStorageInput({this.projectRoot, this.dryRun = false});

  final Directory? projectRoot;
  final bool dryRun;
}

class CreateStoragePlan {
  const CreateStoragePlan({
    required this.className,
    required this.path,
    required this.cacheEntryPath,
    required this.packageName,
    required this.dryRun,
  });

  final String className;
  final String path;
  final String cacheEntryPath;
  final String packageName;
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
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    _ensureProjectRoot(projectRoot);
    final packageName = _readPackageName(projectRoot);

    return CreateStoragePlan(
      className: _storageClassName,
      path: _storagePath,
      cacheEntryPath: _cacheEntryPath,
      packageName: packageName,
      dryRun: input.dryRun,
    );
  }

  Future<CreateStorageResult> create(CreateStorageInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final storageFile = _targetFile(projectRoot, createPlan.path);
    final cacheEntryFile = _targetFile(projectRoot, createPlan.cacheEntryPath);

    _validateTarget(projectRoot, createPlan, storageFile, cacheEntryFile);

    if (createPlan.dryRun) {
      return CreateStorageResult(plan: createPlan);
    }

    final createdDirectories = <Directory>[];
    final createdFiles = <File>[];
    try {
      _createParentDirectories(
        projectRoot,
        storageFile.parent,
        createdDirectories,
      );
      _fileWriter(storageFile, _storageContents(createPlan));
      createdFiles.add(storageFile);
      _fileWriter(cacheEntryFile, _cacheEntryContents(createPlan));
      createdFiles.add(cacheEntryFile);
    } on FileSystemException catch (error) {
      _rollback(createdFiles, createdDirectories);
      throw CreateStorageException(
        'Unable to create storage ${createPlan.className}: '
        '${error.message}',
      );
    } catch (error) {
      _rollback(createdFiles, createdDirectories);
      throw CreateStorageException(
        'Unable to create storage ${createPlan.className}: $error',
      );
    }

    return CreateStorageResult(plan: createPlan);
  }
}

void _validateTarget(
  Directory projectRoot,
  CreateStoragePlan plan,
  File storageFile,
  File cacheEntryFile,
) {
  _validateNoAncestorSymlinks(projectRoot);

  for (final MapEntry(key: file, value: path) in {
    storageFile: plan.path,
    cacheEntryFile: plan.cacheEntryPath,
  }.entries) {
    if (file.existsSync() ||
        Directory(file.path).existsSync() ||
        Link(file.path).existsSync()) {
      throw CreateStorageException('Target already exists: $path');
    }
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

String _readPackageName(Directory projectRoot) {
  final pubspec = File(
    '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml',
  );
  final String contents;
  try {
    contents = pubspec.readAsStringSync();
  } on FileSystemException catch (error) {
    throw CreateStorageException(
      'Unable to read pubspec.yaml: ${error.message}',
    );
  }

  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const CreateStorageException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const CreateStorageException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
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

void _rollback(List<File> createdFiles, List<Directory> createdDirectories) {
  for (final file in createdFiles) {
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

String _relativePath(Directory root, String path) {
  return path
      .substring(root.path.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

String _storageContents(CreateStoragePlan plan) {
  return '''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key-value local storage for the application.
class ${plan.className} {
  const ${plan.className}();

  static const _storage = FlutterSecureStorage();

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  Future<void> clear() => _storage.deleteAll();
}
''';
}

String _cacheEntryContents(CreateStoragePlan plan) {
  return '''
import 'package:${plan.packageName}/core/errors/result.dart';

/// A generic in-memory cache entry with TTL support.
class CacheEntry<T> {
  final T value;
  final DateTime storedAt;
  static const Duration defaultTtl = Duration(minutes: 1);

  const CacheEntry({required this.value, required this.storedAt});
  factory CacheEntry.now(T value) =>
      CacheEntry(value: value, storedAt: DateTime.now());

  bool isFresh([Duration? ttl]) =>
      DateTime.now().difference(storedAt) <= (ttl ?? defaultTtl);
}

mixin RepositoryCacheMixin {
  Future<Result<T>> cached<T extends Object>(
    Map<String, CacheEntry<Object>> cache,
    String key,
    Future<Result<T>> Function() load,
  ) async {
    final entry = cache[key];
    if (entry?.isFresh() ?? false) return Success(entry!.value as T);
    final result = await load();
    if (result case Success<T>(:final value)) {
      cache[key] = CacheEntry<Object>.now(value);
    }
    return result;
  }

  void clearCache<T>(Map<String, CacheEntry<T>> cache) => cache.clear();
}
''';
}
