import 'dart:io';

import 'package:cuboid/src/database/create_database.dart';
import 'package:cuboid/src/database/delete_database.dart';
import 'package:test/test.dart';

void main() {
  test('deletes the supabase example, its migration, and tears down the '
      'guard and pubspec dependency', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateDatabaseService().create(
      CreateDatabaseInput(
        provider: 'supabase',
        projectRoot: root,
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
      ),
    );

    final result = await DeleteDatabaseService().delete(
      DeleteDatabaseInput(provider: 'supabase', projectRoot: root),
    );

    expect(result.plan.provider, 'supabase');
    expect(
      File('${root.path}/lib/supabase/example_model.dart').existsSync(),
      isFalse,
    );
    expect(
      File('${root.path}/lib/supabase/example_repository.dart').existsSync(),
      isFalse,
    );
    expect(Directory('${root.path}/lib/supabase').existsSync(), isFalse);
    expect(
      File(
        '${root.path}/supabase/migrations/'
        '20260102030405_create_examples.sql',
      ).existsSync(),
      isFalse,
    );
    expect(
      File('${root.path}/lib/core/network/supabase_guard.dart').existsSync(),
      isFalse,
    );
    final locator = _appFile(root).readAsStringSync();
    expect(locator, isNot(contains('ExampleRepository')));
    final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('supabase_flutter')));
    expect(pubspec, contains('name: test_app'));
    expect(_appFile(root).existsSync(), isTrue);
  });

  test(
    'deleting the same database twice fails safely without corruption',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateDatabaseService().create(
        CreateDatabaseInput(
          provider: 'supabase',
          projectRoot: root,
          timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
        ),
      );
      final service = DeleteDatabaseService();
      await service.delete(
        DeleteDatabaseInput(provider: 'supabase', projectRoot: root),
      );
      final afterFirstLocator = _appFile(root).readAsStringSync();

      await expectLater(
        service.delete(
          DeleteDatabaseInput(provider: 'supabase', projectRoot: root),
        ),
        throwsA(isA<DeleteDatabaseException>()),
      );

      expect(_appFile(root).readAsStringSync(), afterFirstLocator);
    },
  );

  test('dry-run validates and deletes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateDatabaseService().create(
      CreateDatabaseInput(
        provider: 'supabase',
        projectRoot: root,
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
      ),
    );
    final beforeLocator = _appFile(root).readAsStringSync();
    final beforePubspec = File('${root.path}/pubspec.yaml').readAsStringSync();

    final result = await DeleteDatabaseService().delete(
      DeleteDatabaseInput(
        provider: 'supabase',
        projectRoot: root,
        dryRun: true,
      ),
    );

    expect(result.plan.dryRun, isTrue);
    expect(
      File('${root.path}/lib/supabase/example_model.dart').existsSync(),
      isTrue,
    );
    expect(_appFile(root).readAsStringSync(), beforeLocator);
    expect(File('${root.path}/pubspec.yaml').readAsStringSync(), beforePubspec);
  });

  test(
    'refuses to guess when multiple migration files match, deleting nothing',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateDatabaseService().create(
        CreateDatabaseInput(
          provider: 'supabase',
          projectRoot: root,
          timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
        ),
      );
      File(
        '${root.path}/supabase/migrations/20260102030406_create_examples.sql',
      ).writeAsStringSync('-- duplicate migration\n');

      await expectLater(
        DeleteDatabaseService().delete(
          DeleteDatabaseInput(provider: 'supabase', projectRoot: root),
        ),
        throwsA(
          isA<DeleteDatabaseException>().having(
            (error) => error.message,
            'message',
            contains('Multiple migration files match'),
          ),
        ),
      );
      expect(
        File('${root.path}/lib/supabase/example_model.dart').existsSync(),
        isTrue,
      );
    },
  );

  test('deleting a database that was never created throws cleanly', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteDatabaseService().delete(
        DeleteDatabaseInput(provider: 'supabase', projectRoot: root),
      ),
      throwsA(
        isA<DeleteDatabaseException>().having(
          (error) => error.message,
          'message',
          contains('No supabase database found'),
        ),
      ),
    );
  });

  test('rejects an unsupported provider', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteDatabaseService().delete(
        DeleteDatabaseInput(provider: 'firebase', projectRoot: root),
      ),
      throwsA(isA<DeleteDatabaseException>()),
    );
  });
}

String _appContents() {
  return '''
import 'package:get_it/get_it.dart';
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // @cuboid-service
}
''';
}

File _appFile(Directory root) => File('${root.path}/lib/app/app.locator.dart');

Directory _projectRoot() {
  final root = Directory.systemTemp.createTempSync('cuboid_delete_database_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(
    'name: test_app\ndependencies:\n  flutter:\n    sdk: flutter\n',
  );
  _appFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_appContents());
  File('${root.path}/lib/core/errors/result.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class Result<T> {}\n');
  File('${root.path}/lib/core/errors/failures.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class AppFailure {}\n');
  return root;
}
