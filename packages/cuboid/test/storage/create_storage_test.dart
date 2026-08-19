import 'dart:io';

import 'package:cuboid/src/storage/create_storage.dart';
import 'package:test/test.dart';

void main() {
  test('creates a secure key-value local storage wrapper', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateStorageService();

    final result = await service.create(CreateStorageInput(projectRoot: root));

    expect(result.plan.className, 'LocalStorage');
    expect(result.plan.path, 'lib/core/storage/local_storage.dart');
    expect(result.plan.cacheEntryPath, 'lib/core/storage/cache_entry.dart');

    final contents = File(
      '${root.path}/lib/core/storage/local_storage.dart',
    ).readAsStringSync();
    expect(
      contents,
      contains(
        "import 'package:flutter_secure_storage/flutter_secure_storage.dart';",
      ),
    );
    expect(contents, contains('class LocalStorage {'));
    expect(
      contents,
      contains('static const _storage = FlutterSecureStorage();'),
    );
    expect(contents, contains('Future<String?> read(String key)'));
    expect(contents, contains('Future<void> write(String key, String value)'));
    expect(contents, contains('Future<void> delete(String key)'));
    expect(contents, contains('Future<bool> containsKey(String key)'));
    expect(contents, contains('Future<void> clear()'));
  });

  test('creates a cache entry helper alongside local storage', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateStorageService();

    await service.create(CreateStorageInput(projectRoot: root));

    final contents = File(
      '${root.path}/lib/core/storage/cache_entry.dart',
    ).readAsStringSync();
    expect(
      contents,
      contains("import 'package:test_app/core/errors/result.dart';"),
    );
    expect(contents, contains('class CacheEntry<T> {'));
    expect(contents, contains('mixin RepositoryCacheMixin {'));
    expect(contents, contains('factory CacheEntry.now(T value)'));
    expect(contents, contains('bool isFresh([Duration? ttl])'));
  });

  test('dry-run validates and writes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final service = CreateStorageService();

    final result = await service.create(
      CreateStorageInput(projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(_relativeFiles(root), beforeFiles);
    expect(Directory('${root.path}/lib/core/storage').existsSync(), isFalse);
  });

  test('rejects a project without pubspec.yaml', () async {
    final root = Directory.systemTemp.createTempSync('cuboid_storage_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateStorageService();

    await expectLater(
      service.create(CreateStorageInput(projectRoot: root)),
      throwsA(isA<CreateStorageException>()),
    );
  });

  test('does not overwrite an existing target file', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = File('${root.path}/lib/core/storage/local_storage.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('keep\n');
    final service = CreateStorageService();

    await expectLater(
      service.create(CreateStorageInput(projectRoot: root)),
      throwsA(
        isA<CreateStorageException>().having(
          (error) => error.message,
          'message',
          'Target already exists: lib/core/storage/local_storage.dart',
        ),
      ),
    );
    expect(target.readAsStringSync(), 'keep\n');
  });

  test('does not overwrite an existing cache entry file', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = File('${root.path}/lib/core/storage/cache_entry.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('keep\n');
    final service = CreateStorageService();

    await expectLater(
      service.create(CreateStorageInput(projectRoot: root)),
      throwsA(
        isA<CreateStorageException>().having(
          (error) => error.message,
          'message',
          'Target already exists: lib/core/storage/cache_entry.dart',
        ),
      ),
    );
    expect(target.readAsStringSync(), 'keep\n');
    expect(
      File('${root.path}/lib/core/storage/local_storage.dart').existsSync(),
      isFalse,
    );
  });

  test('rejects symlink ancestors', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = Directory('${root.path}/target_core')..createSync();
    final core = Link('${root.path}/lib/core');
    core.parent.createSync(recursive: true);
    core.createSync(target.path);
    final service = CreateStorageService();

    await expectLater(
      service.create(CreateStorageInput(projectRoot: root)),
      throwsA(isA<CreateStorageException>()),
    );
  });

  test('leaves unrelated files untouched and creates no extra files', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final appFile = File('${root.path}/lib/app/app.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('app registration\n');
    final service = CreateStorageService();

    await service.create(CreateStorageInput(projectRoot: root));

    expect(appFile.readAsStringSync(), 'app registration\n');
    expect(_relativeFiles(root), [
      'lib/app/app.dart',
      'lib/core/storage/cache_entry.dart',
      'lib/core/storage/local_storage.dart',
      'pubspec.yaml',
    ]);
  });

  test('rolls back and creates no directory when the first write fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final service = CreateStorageService(
      fileWriter: (file, contents) {
        throw const FileSystemException('simulated write failure');
      },
    );

    await expectLater(
      service.create(CreateStorageInput(projectRoot: root)),
      throwsA(
        isA<CreateStorageException>().having(
          (error) => error.message,
          'message',
          contains('Unable to create storage LocalStorage'),
        ),
      ),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(Directory('${root.path}/lib/core/storage').existsSync(), isFalse);
  });

  test('rolls back the first file when the second write fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final service = CreateStorageService(
      fileWriter: (file, contents) {
        if (file.path.endsWith('cache_entry.dart')) {
          throw const FileSystemException('simulated write failure');
        }
        file.writeAsStringSync(contents);
      },
    );

    await expectLater(
      service.create(CreateStorageInput(projectRoot: root)),
      throwsA(
        isA<CreateStorageException>().having(
          (error) => error.message,
          'message',
          contains('Unable to create storage LocalStorage'),
        ),
      ),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(Directory('${root.path}/lib/core/storage').existsSync(), isFalse);
  });

  test('running twice refuses to overwrite the existing storage', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateStorageService();

    await service.create(CreateStorageInput(projectRoot: root));

    await expectLater(
      service.create(CreateStorageInput(projectRoot: root)),
      throwsA(isA<CreateStorageException>()),
    );
  });
}

Directory _projectRoot({String pubspec = 'name: test_app\n'}) {
  final root = Directory.systemTemp.createTempSync('cuboid_storage_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  return root;
}

List<String> _relativeFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.substring(root.path.length + 1))
      .map((path) => path.replaceAll(Platform.pathSeparator, '/'))
      .toList()
    ..sort();
}
