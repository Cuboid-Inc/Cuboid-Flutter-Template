import 'dart:io';

import 'package:cuboid/src/repository/create_repository.dart';
import 'package:test/test.dart';

void main() {
  test(
    'creates the repository, model, and migration for a new entity',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateRepositoryService();

      final result = await service.create(
        CreateRepositoryInput(
          name: 'todo',
          projectRoot: root,
          timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
        ),
      );

      expect(result.plan.name, 'todo');
      expect(result.plan.tableName, 'todos');
      expect(result.plan.modelClassName, 'TodoModel');
      expect(result.plan.repositoryClassName, 'TodoRepository');
      expect(
        result.plan.migrationPath,
        'supabase/migrations/20260102030405_create_todos.sql',
      );

      final model = File(
        '${root.path}/lib/supabase/todo_model.dart',
      ).readAsStringSync();
      expect(model, contains('class TodoModel {'));

      final repository = File(
        '${root.path}/lib/supabase/todo_repository.dart',
      ).readAsStringSync();
      expect(
        repository,
        contains("import 'package:test_app/supabase/todo_model.dart';"),
      );
      expect(repository, contains('class TodoRepository {'));
      expect(repository, contains("static const _table = 'todos';"));

      final migration = File(
        '${root.path}/supabase/migrations/20260102030405_create_todos.sql',
      ).readAsStringSync();
      expect(migration, contains('create table if not exists public.todos'));
      expect(migration, contains('auth.uid() = user_id'));

      final app = File('${root.path}/lib/app/app.dart').readAsStringSync();
      expect(
        app,
        contains("import 'package:test_app/supabase/todo_repository.dart';"),
      );
      expect(app, contains('LazySingleton(classType: TodoRepository),'));
    },
  );

  test('pluralizes common English nouns for the table name', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateRepositoryService();

    final cases = {
      'category': 'categories',
      'box': 'boxes',
      'bus': 'buses',
      'invoice': 'invoices',
      'blog_post': 'blog_posts',
    };

    for (final entry in cases.entries) {
      final plan = await service.plan(
        CreateRepositoryInput(name: entry.key, projectRoot: root),
      );
      expect(plan.tableName, entry.value, reason: entry.key);
    }
  });

  test('dry-run validates and writes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final service = CreateRepositoryService();

    final result = await service.create(
      CreateRepositoryInput(
        name: 'Invoice-Item',
        projectRoot: root,
        dryRun: true,
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
      ),
    );

    expect(result.plan.name, 'invoice_item');
    expect(result.plan.tableName, 'invoice_items');
    expect(result.plan.dryRun, isTrue);
    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(Directory('${root.path}/lib/supabase').existsSync(), isFalse);
  });

  test('rejects invalid names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateRepositoryService();

    for (final name in [
      '',
      'two words',
      '1todo',
      '_todo',
      'todo_',
      'todo__item',
      '.',
      '..',
      'auth/todo',
      r'auth\todo',
      'class',
    ]) {
      await expectLater(
        service.create(CreateRepositoryInput(name: name, projectRoot: root)),
        throwsA(isA<CreateRepositoryException>()),
        reason: name,
      );
    }
  });

  test('rejects when supabase_flutter is not a dependency', () async {
    final root = _projectRoot(withSupabaseDependency: false);
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateRepositoryService();

    await expectLater(
      service.create(CreateRepositoryInput(name: 'todo', projectRoot: root)),
      throwsA(
        isA<CreateRepositoryException>().having(
          (error) => error.message,
          'message',
          contains('supabase_flutter dependency'),
        ),
      ),
    );
  });

  test('rejects when the supabase foundation is missing', () async {
    final root = _projectRoot(withGuard: false);
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateRepositoryService();

    await expectLater(
      service.create(CreateRepositoryInput(name: 'todo', projectRoot: root)),
      throwsA(
        isA<CreateRepositoryException>().having(
          (error) => error.message,
          'message',
          'lib/core/network/supabase_guard.dart was not found.',
        ),
      ),
    );
  });

  test('rejects an existing target without mutation', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    File('${root.path}/lib/supabase/todo_repository.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('keep\n');
    final beforeApp = _appFile(root).readAsStringSync();
    final service = CreateRepositoryService();

    await expectLater(
      service.create(CreateRepositoryInput(name: 'todo', projectRoot: root)),
      throwsA(isA<CreateRepositoryException>()),
    );

    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(Directory('${root.path}/supabase/migrations').existsSync(), isFalse);
  });

  test(
    'rejects a second repository colliding with an existing import',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateRepositoryService();
      await service.create(
        CreateRepositoryInput(
          name: 'todo',
          projectRoot: root,
          timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
        ),
      );

      await expectLater(
        service.create(
          CreateRepositoryInput(
            name: 'todo',
            projectRoot: root,
            timestamp: DateTime.utc(2026, 1, 2, 3, 4, 6),
          ),
        ),
        throwsA(isA<CreateRepositoryException>()),
      );
    },
  );

  test('two different repositories can coexist', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateRepositoryService();

    await service.create(
      CreateRepositoryInput(
        name: 'todo',
        projectRoot: root,
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
      ),
    );
    await service.create(
      CreateRepositoryInput(
        name: 'category',
        projectRoot: root,
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 6),
      ),
    );

    final app = _appFile(root).readAsStringSync();
    expect(app, contains('LazySingleton(classType: TodoRepository),'));
    expect(app, contains('LazySingleton(classType: CategoryRepository),'));
    expect('// @stacked-service'.allMatches(app), hasLength(1));
    expect(
      Directory(
        '${root.path}/supabase/migrations',
      ).listSync().whereType<File>().length,
      2,
    );
  });

  test('rejects symlink ancestors for lib/supabase', () async {
    final root = Directory.systemTemp.createTempSync('cuboid_repository_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    File('${root.path}/pubspec.yaml').writeAsStringSync(
      'name: test_app\ndependencies:\n  supabase_flutter: ^2.16.0\n',
    );
    final targetLib = Directory('${root.path}/target_lib')
      ..createSync(recursive: true);
    File('${targetLib.path}/app/app.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_appContents());
    File('${targetLib.path}/core/network/supabase_guard.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('Future<void> guard() async {}\n');
    File('${targetLib.path}/core/errors/result.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('class Result<T> {}\n');
    File('${targetLib.path}/core/errors/failures.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('class AppFailure {}\n');
    Link('${root.path}/lib').createSync(targetLib.path);
    final service = CreateRepositoryService();

    await expectLater(
      service.create(CreateRepositoryInput(name: 'todo', projectRoot: root)),
      throwsA(isA<CreateRepositoryException>()),
    );
  });

  test('rolls back created files and restores app.dart when the migration '
      'write fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    var writes = 0;
    final service = CreateRepositoryService(
      fileWriter: (file, contents) {
        writes += 1;
        if (writes == 3) {
          throw const FileSystemException('simulated write failure');
        }
        file.writeAsStringSync(contents);
      },
    );

    await expectLater(
      service.create(CreateRepositoryInput(name: 'todo', projectRoot: root)),
      throwsA(isA<CreateRepositoryException>()),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(Directory('${root.path}/lib/supabase').existsSync(), isFalse);
    expect(Directory('${root.path}/supabase/migrations').existsSync(), isFalse);
  });

  test('rolls back created files and leaves app.dart untouched when the '
      'app.dart update fails', () async {
    final root = _projectRoot();
    addTearDown(() {
      Process.runSync('chmod', ['755', '${root.path}/lib/app']);
      root.deleteSync(recursive: true);
    });
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    Process.runSync('chmod', ['555', '${root.path}/lib/app']);
    final service = CreateRepositoryService();

    await expectLater(
      service.create(CreateRepositoryInput(name: 'todo', projectRoot: root)),
      throwsA(isA<CreateRepositoryException>()),
    );

    Process.runSync('chmod', ['755', '${root.path}/lib/app']);
    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(Directory('${root.path}/lib/supabase').existsSync(), isFalse);
    expect(Directory('${root.path}/supabase/migrations').existsSync(), isFalse);
  }, skip: Platform.isWindows);
}

Directory _projectRoot({
  bool withSupabaseDependency = true,
  bool withGuard = true,
}) {
  final root = Directory.systemTemp.createTempSync('cuboid_repository_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(
    withSupabaseDependency
        ? 'name: test_app\ndependencies:\n  supabase_flutter: ^2.16.0\n'
        : 'name: test_app\n',
  );
  _appFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_appContents());
  if (withGuard) {
    File('${root.path}/lib/core/network/supabase_guard.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('Future<void> guard() async {}\n');
    File('${root.path}/lib/core/errors/result.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('class Result<T> {}\n');
    File('${root.path}/lib/core/errors/failures.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('class AppFailure {}\n');
  }
  return root;
}

String _appContents() {
  return '''
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    // @stacked-service
  ],
)
class App {}
''';
}

File _appFile(Directory root) => File('${root.path}/lib/app/app.dart');

List<String> _relativeFiles(Directory root) {
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.substring(root.path.length + 1))
          .map((path) => path.replaceAll(Platform.pathSeparator, '/'))
          .toList()
        ..sort();
  return files;
}
