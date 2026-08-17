import 'dart:io';

import 'package:cuboid/src/database/create_database.dart';
import 'package:test/test.dart';

void main() {
  test(
    'creates the supabase example repository, model, and migration',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateDatabaseService();

      final result = await service.create(
        CreateDatabaseInput(
          provider: 'supabase',
          projectRoot: root,
          timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
        ),
      );

      expect(result.plan.provider, 'supabase');
      expect(result.plan.modelClassName, 'ExampleModel');
      expect(result.plan.repositoryClassName, 'ExampleRepository');
      expect(
        result.plan.migrationPath,
        'supabase/migrations/20260102030405_create_examples.sql',
      );

      final model = File(
        '${root.path}/lib/supabase/example_model.dart',
      ).readAsStringSync();
      expect(model, contains('class ExampleModel {'));
      expect(model, contains('factory ExampleModel.fromJson'));

      final repository = File(
        '${root.path}/lib/supabase/example_repository.dart',
      ).readAsStringSync();
      expect(
        repository,
        contains("import 'package:test_app/core/network/supabase_guard.dart';"),
      );
      expect(
        repository,
        contains("import 'package:test_app/supabase/example_model.dart';"),
      );
      expect(repository, contains('class ExampleRepository {'));
      expect(
        repository,
        contains('Future<Result<List<ExampleModel>>> getAll() => guard('),
      );
      expect(repository, contains("static const _table = 'examples';"));

      final migration = File(
        '${root.path}/supabase/migrations/20260102030405_create_examples.sql',
      ).readAsStringSync();
      expect(migration, contains('create table if not exists public.examples'));
      expect(
        migration,
        contains('alter table public.examples enable row level security'),
      );
      expect(migration, contains('auth.uid() = user_id'));

      final app = File('${root.path}/lib/app/app.dart').readAsStringSync();
      expect(
        app,
        contains("import 'package:test_app/supabase/example_repository.dart';"),
      );
      expect(app, contains('LazySingleton(classType: ExampleRepository),'));
    },
  );

  test('dry-run validates and writes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final service = CreateDatabaseService();

    final result = await service.create(
      CreateDatabaseInput(
        provider: 'Supabase',
        projectRoot: root,
        dryRun: true,
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
      ),
    );

    expect(result.plan.provider, 'supabase');
    expect(result.plan.dryRun, isTrue);
    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(Directory('${root.path}/lib/supabase').existsSync(), isFalse);
    expect(Directory('${root.path}/supabase/migrations').existsSync(), isFalse);
  });

  test('rejects an unsupported provider', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateDatabaseService();

    await expectLater(
      service.create(
        CreateDatabaseInput(provider: 'firebase', projectRoot: root),
      ),
      throwsA(
        isA<CreateDatabaseException>().having(
          (error) => error.message,
          'message',
          contains('Unsupported database provider "firebase"'),
        ),
      ),
    );
  });

  test(
    'provisions the supabase_flutter dependency when it is missing',
    () async {
      final root = _projectRoot(withSupabaseDependency: false);
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateDatabaseService();

      await service.create(
        CreateDatabaseInput(provider: 'supabase', projectRoot: root),
      );

      final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('name: test_app'));
      expect(pubspec, contains('supabase_flutter: ^2.17.1'));
    },
  );

  test(
    'does not duplicate an already-declared supabase_flutter dependency',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateDatabaseService();

      await service.create(
        CreateDatabaseInput(provider: 'supabase', projectRoot: root),
      );

      final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
      expect('supabase_flutter'.allMatches(pubspec).length, 1);
      expect(pubspec, contains('supabase_flutter: ^2.16.0'));
    },
  );

  test(
    'provisions lib/core/network/supabase_guard.dart when it is missing',
    () async {
      final root = _projectRoot(withGuard: false);
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateDatabaseService();

      await service.create(
        CreateDatabaseInput(provider: 'supabase', projectRoot: root),
      );

      final guard = File(
        '${root.path}/lib/core/network/supabase_guard.dart',
      ).readAsStringSync();
      expect(guard, contains('Future<Result<T>> guard<T>('));
      expect(
        guard,
        contains("import 'package:supabase_flutter/supabase_flutter.dart';"),
      );
      expect(
        guard,
        contains("import 'package:test_app/core/errors/result.dart';"),
      );
    },
  );

  test('does not overwrite an existing supabase_guard.dart', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    File(
      '${root.path}/lib/core/network/supabase_guard.dart',
    ).writeAsStringSync('// customized\nFuture<void> guard() async {}\n');
    final service = CreateDatabaseService();

    await service.create(
      CreateDatabaseInput(provider: 'supabase', projectRoot: root),
    );

    final guard = File(
      '${root.path}/lib/core/network/supabase_guard.dart',
    ).readAsStringSync();
    expect(guard, contains('// customized'));
  });

  test(
    'rolls back a provisioned pubspec dependency when a later write fails',
    () async {
      final root = _projectRoot(
        withSupabaseDependency: false,
        withGuard: false,
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final beforePubspec = File(
        '${root.path}/pubspec.yaml',
      ).readAsStringSync();
      final service = CreateDatabaseService(
        fileWriter: (file, contents) {
          throw const FileSystemException('simulated write failure');
        },
      );

      await expectLater(
        service.create(
          CreateDatabaseInput(provider: 'supabase', projectRoot: root),
        ),
        throwsA(isA<CreateDatabaseException>()),
      );

      expect(
        File('${root.path}/pubspec.yaml').readAsStringSync(),
        beforePubspec,
      );
      expect(
        File('${root.path}/lib/core/network/supabase_guard.dart').existsSync(),
        isFalse,
      );
    },
  );

  test('rejects an existing lib/supabase target without mutation', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    File('${root.path}/lib/supabase/example_model.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('keep\n');
    final beforeApp = _appFile(root).readAsStringSync();
    final service = CreateDatabaseService();

    await expectLater(
      service.create(
        CreateDatabaseInput(provider: 'supabase', projectRoot: root),
      ),
      throwsA(isA<CreateDatabaseException>()),
    );

    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(Directory('${root.path}/supabase/migrations').existsSync(), isFalse);
  });

  test('rejects symlink ancestors for lib/supabase', () async {
    final root = Directory.systemTemp.createTempSync('cuboid_database_test_');
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
    final service = CreateDatabaseService();

    await expectLater(
      service.create(
        CreateDatabaseInput(provider: 'supabase', projectRoot: root),
      ),
      throwsA(isA<CreateDatabaseException>()),
    );
  });

  test('rejects conflicting app registrations', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _appFile(root).writeAsStringSync(
      _appContents(
        extraImport:
            "import 'package:other/supabase/example_repository.dart';\n",
      ),
    );
    final service = CreateDatabaseService();

    await expectLater(
      service.create(
        CreateDatabaseInput(provider: 'supabase', projectRoot: root),
      ),
      throwsA(
        isA<CreateDatabaseException>().having(
          (error) => error.message,
          'message',
          contains('Conflicting repository import'),
        ),
      ),
    );
  });

  test('rolls back created files and restores app.dart when the migration '
      'write fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    var writes = 0;
    final service = CreateDatabaseService(
      fileWriter: (file, contents) {
        writes += 1;
        if (writes == 3) {
          throw const FileSystemException('simulated write failure');
        }
        file.writeAsStringSync(contents);
      },
    );

    await expectLater(
      service.create(
        CreateDatabaseInput(provider: 'supabase', projectRoot: root),
      ),
      throwsA(isA<CreateDatabaseException>()),
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
    final service = CreateDatabaseService();

    await expectLater(
      service.create(
        CreateDatabaseInput(provider: 'supabase', projectRoot: root),
      ),
      throwsA(isA<CreateDatabaseException>()),
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
  final root = Directory.systemTemp.createTempSync('cuboid_database_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(
    withSupabaseDependency
        ? 'name: test_app\ndependencies:\n  supabase_flutter: ^2.16.0\n'
        : 'name: test_app\ndependencies:\n  flutter:\n    sdk: flutter\n',
  );
  _appFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_appContents());
  if (withGuard) {
    File('${root.path}/lib/core/network/supabase_guard.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('Future<void> guard() async {}\n');
  }
  File('${root.path}/lib/core/errors/result.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class Result<T> {}\n');
  File('${root.path}/lib/core/errors/failures.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class AppFailure {}\n');
  return root;
}

String _appContents({String extraImport = ''}) {
  return '''
${extraImport}import 'package:stacked/stacked_annotations.dart';
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
