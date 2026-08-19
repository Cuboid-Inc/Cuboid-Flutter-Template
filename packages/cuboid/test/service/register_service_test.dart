import 'dart:io';

import 'package:cuboid/src/service/register_service.dart';
import 'package:test/test.dart';

void main() {
  test('creates and registers an auth service', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterServiceService();

    final result = await service.create(
      RegisterServiceInput(name: 'auth', projectRoot: root),
    );

    expect(result.plan.name, 'auth');
    expect(result.plan.displayName, 'Auth');
    expect(result.plan.serviceClassName, 'AuthService');
    expect(result.plan.servicePath, 'lib/core/services/auth_service.dart');
    expect(
      File(
        '${root.path}/lib/core/services/auth_service.dart',
      ).readAsStringSync(),
      'class AuthService {}\n',
    );
    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains("import 'package:test_app/core/services/auth_service.dart';"),
    );
    expect(
      app,
      contains(
        '  locator.registerLazySingleton<AuthService>(() => AuthService());',
      ),
    );
    expect(_relativeFiles(root), [
      'lib/app/app.locator.dart',
      'lib/core/services/auth_service.dart',
      'pubspec.yaml',
    ]);
  });

  test('creates and registers auth, payment, and notification services in '
      'sequence without losing earlier registrations', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterServiceService();
    const expected = {
      'auth': 'AuthService',
      'payment': 'PaymentService',
      'notification': 'NotificationService',
    };

    for (final name in expected.keys) {
      await service.create(RegisterServiceInput(name: name, projectRoot: root));
    }

    final app = _appFile(root).readAsStringSync();
    for (final entry in expected.entries) {
      expect(
        File(
          '${root.path}/lib/core/services/${entry.key}_service.dart',
        ).existsSync(),
        isTrue,
        reason: entry.value,
      );
      expect(
        app,
        contains(
          "import 'package:test_app/core/services/"
          "${entry.key}_service.dart';",
        ),
        reason: entry.value,
      );
      expect(
        app,
        contains(
          '  locator.registerLazySingleton<${entry.value}>(() => ${entry.value}());',
        ),
        reason: entry.value,
      );
    }
    expect('// @cuboid-import'.allMatches(app), hasLength(1));
    expect('// @cuboid-service'.allMatches(app), hasLength(1));
  });

  test('create normalizes service name variants consistently', () async {
    for (final entry in {
      'auth_service': 'auth_service',
      'auth-service': 'auth_service',
      'AuthService': 'auth_service',
      'userProfile': 'user_profile',
      'HTTPClient': 'http_client',
    }.entries) {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = RegisterServiceService();

      final result = await service.create(
        RegisterServiceInput(name: entry.key, projectRoot: root),
      );

      expect(result.plan.name, entry.value, reason: entry.key);
      expect(
        File(
          '${root.path}/lib/core/services/${entry.value}_service.dart',
        ).existsSync(),
        isTrue,
        reason: entry.key,
      );
    }
  });

  test('create dry-run validates and writes no files', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final service = RegisterServiceService();

    final result = await service.create(
      RegisterServiceInput(
        name: 'auth-session',
        projectRoot: root,
        dryRun: true,
      ),
    );

    expect(result.plan.dryRun, isTrue);
    expect(
      result.plan.servicePath,
      'lib/core/services/auth_session_service.dart',
    );
    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
  });

  test('create rejects existing service targets without mutation', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final service = RegisterServiceService();

    await expectLater(
      service.create(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(
        isA<RegisterServiceException>().having(
          (error) => error.message,
          'message',
          'Target already exists: lib/core/services/auth_session_service.dart',
        ),
      ),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
  });

  test('create refuses service directories through symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = Directory('${root.path}/target_services')..createSync();
    final services = Link('${root.path}/lib/core/services');
    services.parent.createSync(recursive: true);
    services.createSync(target.path);
    final service = RegisterServiceService();

    await expectLater(
      service.create(RegisterServiceInput(name: 'auth', projectRoot: root)),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('create rolls back service file when locator update fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterServiceService(
      fileWriter: (file, contents) {
        file.writeAsStringSync(contents);
        throw const FileSystemException('simulated write failure');
      },
    );

    await expectLater(
      service.create(RegisterServiceInput(name: 'auth', projectRoot: root)),
      throwsA(
        isA<RegisterServiceException>().having(
          (error) => error.message,
          'message',
          contains('Unable to create service Auth'),
        ),
      ),
    );

    expect(Directory('${root.path}/lib/core').existsSync(), isFalse);
    expect(_relativeFiles(root), ['lib/app/app.locator.dart', 'pubspec.yaml']);
  });

  test('registers an auth session service', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final service = RegisterServiceService();

    final result = await service.register(
      RegisterServiceInput(name: 'auth-session', projectRoot: root),
    );

    expect(result.plan.name, 'auth_session');
    expect(result.plan.displayName, 'Auth Session');
    expect(result.plan.serviceClassName, 'AuthSessionService');
    expect(
      result.plan.servicePath,
      'lib/core/services/auth_session_service.dart',
    );
    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:test_app/core/services/auth_session_service.dart';",
      ),
    );
    expect(
      app,
      contains(
        '  locator.registerLazySingleton<AuthSessionService>(() => AuthSessionService());',
      ),
    );
    expect(
      app.indexOf("import 'package:test_app/core/services/auth_session"),
      lessThan(app.indexOf('// @cuboid-import')),
    );
    expect(
      app.indexOf(
        '  locator.registerLazySingleton<AuthSessionService>(() => AuthSessionService());',
      ),
      lessThan(app.indexOf('  // @cuboid-service')),
    );
  });

  test('normalizes service name variants consistently', () async {
    for (final input in ['auth-session', 'AuthSession', 'auth_session']) {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      _writeService(root, 'auth_session');
      final service = RegisterServiceService();

      final result = await service.register(
        RegisterServiceInput(name: input, projectRoot: root),
      );

      expect(result.plan.name, 'auth_session');
      expect(result.plan.serviceClassName, 'AuthSessionService');
      expect(
        _appFile(root).readAsStringSync(),
        contains('registerLazySingleton<AuthSessionService>'),
      );
    }
  });

  test('reads quoted package names with inline comments', () async {
    final root = _projectRoot(pubspec: 'name: "custom_app" # package\n');
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'billing');
    final service = RegisterServiceService();

    await service.register(
      RegisterServiceInput(name: 'billing', projectRoot: root),
    );

    expect(
      _appFile(root).readAsStringSync(),
      contains(
        "import 'package:custom_app/core/services/billing_service.dart';",
      ),
    );
  });

  test('multiple registrations preserve existing content', () async {
    final root = _projectRoot(app: _appContents(extra: '  // answer: 42\n'));
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    _writeService(root, 'billing');
    final service = RegisterServiceService();

    await service.register(
      RegisterServiceInput(name: 'auth-session', projectRoot: root),
    );
    await service.register(
      RegisterServiceInput(name: 'billing', projectRoot: root),
    );

    final app = _appFile(root).readAsStringSync();
    expect(app, contains('  // answer: 42\n'));
    expect(app, contains('registerLazySingleton<AuthSessionService>'));
    expect(app, contains('registerLazySingleton<BillingService>'));
  });

  test('dry-run validates and leaves app.locator.dart byte-identical', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterServiceService();

    final result = await service.register(
      RegisterServiceInput(
        name: 'auth-session',
        projectRoot: root,
        dryRun: true,
      ),
    );

    expect(result.plan.dryRun, isTrue);
    expect(result.plan.importLine, contains('auth_session_service.dart'));
    expect(
      result.plan.serviceLine,
      '  locator.registerLazySingleton<AuthSessionService>(() => AuthSessionService());',
    );
    expect(_appFile(root).readAsStringSync(), before);
  });

  test('rejects invalid names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterServiceService();

    for (final name in [
      '',
      '   ',
      'auth session',
      '_auth',
      'auth_',
      'auth__session',
      'auth--session',
      '2fa',
      'class',
    ]) {
      await expectLater(
        service.register(RegisterServiceInput(name: name, projectRoot: root)),
        throwsA(isA<RegisterServiceException>()),
        reason: name,
      );
    }
  });

  test('rejects traversal and path separator attempts', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterServiceService();

    for (final name in ['.', '..', '../auth', 'auth/child', r'auth\child']) {
      await expectLater(
        service.register(RegisterServiceInput(name: name, projectRoot: root)),
        throwsA(isA<RegisterServiceException>()),
        reason: name,
      );
    }
  });

  test('rejects missing pubspec.yaml', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    File('${root.path}/pubspec.yaml').deleteSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects invalid package names', () async {
    final root = _projectRoot(pubspec: 'name: class\n');
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects pubspec.yaml directories and symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    File('${root.path}/pubspec.yaml').deleteSync();
    Directory('${root.path}/pubspec.yaml').createSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );

    Directory('${root.path}/pubspec.yaml').deleteSync();
    final target = File('${root.path}/target_pubspec.yaml')
      ..writeAsStringSync('name: test_app\n');
    Link('${root.path}/pubspec.yaml').createSync(target.path);

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects missing service file', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(
        isA<RegisterServiceException>().having(
          (error) => error.message,
          'message',
          'lib/core/services/auth_session_service.dart was not found.',
        ),
      ),
    );
  });

  test('rejects service file directories', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      '${root.path}/lib/core/services/auth_session_service.dart',
    ).createSync(recursive: true);
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects service file symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = File('${root.path}/target_service.dart')
      ..writeAsStringSync('// target\n');
    final link = Link(
      '${root.path}/lib/core/services/auth_session_service.dart',
    );
    link.parent.createSync(recursive: true);
    link.createSync(target.path);
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects missing app.locator.dart', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    _appFile(root).deleteSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects app.locator.dart directories and symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    _appFile(root).deleteSync();
    Directory('${root.path}/lib/app/app.locator.dart').createSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );

    Directory('${root.path}/lib/app/app.locator.dart').deleteSync();
    final target = File('${root.path}/target_app_locator.dart')
      ..writeAsStringSync(_appContents());
    Link('${root.path}/lib/app/app.locator.dart').createSync(target.path);

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects missing import marker', () async {
    final root = _projectRoot(
      app: _appContents().replaceAll('// @cuboid-import', '// missing-import'),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects missing service marker', () async {
    final root = _projectRoot(
      app: _appContents().replaceAll(
        '// @cuboid-service',
        '// missing-service',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects duplicate import markers', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '// @cuboid-import',
        '// @cuboid-import\n// @cuboid-import',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects duplicate service markers', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '// @cuboid-service',
        '// @cuboid-service\n  // @cuboid-service',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects existing matching import without mutation', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '// @cuboid-import',
        "import 'package:test_app/core/services/auth_session_service.dart';\n"
            '// @cuboid-import',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
    expect(_appFile(root).readAsStringSync(), before);
  });

  test('rejects existing matching import with extra whitespace', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '// @cuboid-import',
        "import 'package:test_app/core/services/auth_session_service.dart' ;\n"
            '// @cuboid-import',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
    expect(_appFile(root).readAsStringSync(), before);
  });

  test('rejects existing conflicting import without mutation', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '// @cuboid-import',
        "import 'package:other_app/core/services/auth_session_service.dart';\n"
            '// @cuboid-import',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
    expect(_appFile(root).readAsStringSync(), before);
  });

  test('rejects existing conflicting import with extra whitespace', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '// @cuboid-import',
        "import  'package:other_app/core/services/auth_session_service.dart' ;\n"
            '// @cuboid-import',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
    expect(_appFile(root).readAsStringSync(), before);
  });

  test(
    'rejects existing matching service registration without mutation',
    () async {
      final root = _projectRoot(
        app: _appContents().replaceFirst(
          '  // @cuboid-service',
          '  locator.registerLazySingleton<AuthSessionService>(() => AuthSessionService());\n'
              '  // @cuboid-service',
        ),
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeService(root, 'auth_session');
      final before = _appFile(root).readAsStringSync();
      final service = RegisterServiceService();

      await expectLater(
        service.register(
          RegisterServiceInput(name: 'auth-session', projectRoot: root),
        ),
        throwsA(isA<RegisterServiceException>()),
      );
      expect(_appFile(root).readAsStringSync(), before);
    },
  );

  test(
    'rejects existing matching service registration with extra whitespace',
    () async {
      final root = _projectRoot(
        app: _appContents().replaceFirst(
          '  // @cuboid-service',
          '  locator.registerLazySingleton< AuthSessionService >(() => AuthSessionService());\n'
              '  // @cuboid-service',
        ),
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeService(root, 'auth_session');
      final before = _appFile(root).readAsStringSync();
      final service = RegisterServiceService();

      await expectLater(
        service.register(
          RegisterServiceInput(name: 'auth-session', projectRoot: root),
        ),
        throwsA(isA<RegisterServiceException>()),
      );
      expect(_appFile(root).readAsStringSync(), before);
    },
  );

  test('rejects an existing registration for the same class under a '
      'different lifecycle', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '  // @cuboid-service',
        '  locator.registerSingleton<AuthSessionService>(AuthSessionService());\n'
            '  // @cuboid-service',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
    expect(_appFile(root).readAsStringSync(), before);
  });

  test('preserves CRLF line endings around inserted registrations', () async {
    final root = _projectRoot(app: _appContents().replaceAll('\n', '\r\n'));
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final service = RegisterServiceService();

    await service.register(
      RegisterServiceInput(name: 'auth-session', projectRoot: root),
    );

    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:test_app/core/services/auth_session_service.dart';\r\n"
        '// @cuboid-import',
      ),
    );
    expect(
      app,
      contains(
        '  locator.registerLazySingleton<AuthSessionService>(() => AuthSessionService());\r\n'
        '  // @cuboid-service',
      ),
    );
  });

  test('supports markers at file boundaries', () async {
    final root = _projectRoot(
      app: '''
// @cuboid-import

Future<void> setupLocator() async {
  // @cuboid-service
}
''',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    final service = RegisterServiceService();

    await service.register(
      RegisterServiceInput(name: 'auth-session', projectRoot: root),
    );

    final app = _appFile(root).readAsStringSync();
    expect(app, startsWith("import 'package:test_app/core/services/auth"));
    expect(
      app,
      contains(
        'registerLazySingleton<AuthSessionService>(() => AuthSessionService())',
      ),
    );
  });

  test('only app.locator.dart changes', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    File(
      '${root.path}/lib/app/app.router.dart',
    ).writeAsStringSync('// bystander\n');
    File('${root.path}/README.md').writeAsStringSync('keep\n');
    final beforeFiles = _relativeFiles(root);
    final beforeRouter = File(
      '${root.path}/lib/app/app.router.dart',
    ).readAsStringSync();
    final beforeReadme = File('${root.path}/README.md').readAsStringSync();
    final service = RegisterServiceService();

    await service.register(
      RegisterServiceInput(name: 'auth-session', projectRoot: root),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(
      File('${root.path}/lib/app/app.router.dart').readAsStringSync(),
      beforeRouter,
    );
    expect(File('${root.path}/README.md').readAsStringSync(), beforeReadme);
  });

  test('dry-run creates no temp files and changes no files', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    File('${root.path}/README.md').writeAsStringSync('keep\n');
    final beforeFiles = _relativeFiles(root);
    final beforeContents = {
      for (final path in beforeFiles)
        path: File(
          '${root.path}${Platform.pathSeparator}'
          '${path.replaceAll('/', Platform.pathSeparator)}',
        ).readAsStringSync(),
    };
    final service = RegisterServiceService();

    await service.register(
      RegisterServiceInput(
        name: 'auth-session',
        projectRoot: root,
        dryRun: true,
      ),
    );

    expect(_relativeFiles(root), beforeFiles);
    for (final entry in beforeContents.entries) {
      final path = entry.key.replaceAll('/', Platform.pathSeparator);
      expect(
        File('${root.path}${Platform.pathSeparator}$path').readAsStringSync(),
        entry.value,
      );
    }
    expect(
      Directory('${root.path}/lib/app')
          .listSync(followLinks: false)
          .where(
            (entity) =>
                entity.uri.pathSegments.last.startsWith('.cuboid-service-'),
          ),
      isEmpty,
    );
  });
}

Directory _projectRoot({String pubspec = 'name: test_app\n', String? app}) {
  final root = Directory.systemTemp.createTempSync('cuboid_service_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  _appFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(app ?? _appContents());
  return root;
}

File _appFile(Directory root) => File('${root.path}/lib/app/app.locator.dart');

void _writeService(Directory root, String serviceName) {
  final className = serviceName
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
  File('${root.path}/lib/core/services/${serviceName}_service.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class ${className}Service {}\n');
}

String _appContents({String extra = ''}) {
  return '''
import 'package:test_app/core/services/analytics_service.dart';
import 'package:get_it/get_it.dart';
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
$extra  locator.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  // @cuboid-service
}
''';
}

List<String> _relativeFiles(Directory root) {
  return root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((file) => file.path.substring(root.path.length + 1))
      .map((path) => path.replaceAll(Platform.pathSeparator, '/'))
      .toList()
    ..sort();
}
