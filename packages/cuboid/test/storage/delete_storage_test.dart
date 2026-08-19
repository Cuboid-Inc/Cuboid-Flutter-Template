import 'dart:io';

import 'package:cuboid/src/storage/create_storage.dart';
import 'package:cuboid/src/storage/delete_storage.dart';
import 'package:test/test.dart';

void main() {
  test('deletes the local storage wrapper', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateStorageService().create(CreateStorageInput(projectRoot: root));

    final result = await DeleteStorageService().delete(
      DeleteStorageInput(projectRoot: root),
    );

    expect(result.plan.className, 'LocalStorage');
    expect(
      File('${root.path}/lib/core/storage/local_storage.dart').existsSync(),
      isFalse,
    );
    expect(
      File('${root.path}/lib/core/storage/cache_entry.dart').existsSync(),
      isFalse,
    );
    expect(Directory('${root.path}/lib/core/storage').existsSync(), isFalse);
    // lib/core/ holds other things and must survive.
    expect(Directory('${root.path}/lib/core').existsSync(), isTrue);
  });

  test(
    'tolerates a project whose cache entry file was already removed',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateStorageService().create(
        CreateStorageInput(projectRoot: root),
      );
      File(
        '${root.path}/lib/core/storage/cache_entry.dart',
      ).deleteSync();

      final result = await DeleteStorageService().delete(
        DeleteStorageInput(projectRoot: root),
      );

      expect(result.plan.className, 'LocalStorage');
      expect(
        File('${root.path}/lib/core/storage/local_storage.dart').existsSync(),
        isFalse,
      );
      expect(Directory('${root.path}/lib/core/storage').existsSync(), isFalse);
    },
  );

  test('deleting storage twice fails safely without corruption', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateStorageService().create(CreateStorageInput(projectRoot: root));
    final service = DeleteStorageService();
    await service.delete(DeleteStorageInput(projectRoot: root));

    await expectLater(
      service.delete(DeleteStorageInput(projectRoot: root)),
      throwsA(isA<DeleteStorageException>()),
    );
  });

  test('dry-run validates and deletes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateStorageService().create(CreateStorageInput(projectRoot: root));

    final result = await DeleteStorageService().delete(
      DeleteStorageInput(projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(
      File('${root.path}/lib/core/storage/local_storage.dart').existsSync(),
      isTrue,
    );
    expect(
      File('${root.path}/lib/core/storage/cache_entry.dart').existsSync(),
      isTrue,
    );
  });

  test('deleting storage that was never created throws cleanly', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteStorageService().delete(DeleteStorageInput(projectRoot: root)),
      throwsA(
        isA<DeleteStorageException>().having(
          (error) => error.message,
          'message',
          'No local storage found.',
        ),
      ),
    );
  });
}

Directory _projectRoot() {
  final root = Directory.systemTemp.createTempSync('cuboid_delete_storage_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  // lib/core/ holds other hand-written files besides storage.
  File('${root.path}/lib/core/constants/app_constants.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('class AppConstants {}\n');
  return root;
}
