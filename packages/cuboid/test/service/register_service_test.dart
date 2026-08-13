import 'dart:io';

import 'package:cuboid/src/service/register_service.dart';
import 'package:test/test.dart';

void main() {
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
    expect(app, contains('    LazySingleton(classType: AuthSessionService),'));
    expect(
      app.indexOf("import 'package:test_app/core/services/auth_session"),
      lessThan(app.indexOf('// @stacked-import')),
    );
    expect(
      app.indexOf('    LazySingleton(classType: AuthSessionService),'),
      lessThan(app.indexOf('    // @stacked-service')),
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
        contains('LazySingleton(classType: AuthSessionService),'),
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
    final root = _projectRoot(app: _appContents(extra: '  answer: 42,\n'));
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
    expect(app, contains('  answer: 42,\n'));
    expect(app, contains('LazySingleton(classType: AuthSessionService),'));
    expect(app, contains('LazySingleton(classType: BillingService),'));
  });

  test('dry-run validates and leaves app.dart byte-identical', () async {
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
      '    LazySingleton(classType: AuthSessionService),',
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

  test('rejects missing app.dart', () async {
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

  test('rejects app.dart directories and symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    _appFile(root).deleteSync();
    Directory('${root.path}/lib/app/app.dart').createSync();
    final service = RegisterServiceService();

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );

    Directory('${root.path}/lib/app/app.dart').deleteSync();
    final target = File('${root.path}/target_app.dart')
      ..writeAsStringSync(_appContents());
    Link('${root.path}/lib/app/app.dart').createSync(target.path);

    await expectLater(
      service.register(
        RegisterServiceInput(name: 'auth-session', projectRoot: root),
      ),
      throwsA(isA<RegisterServiceException>()),
    );
  });

  test('rejects missing import marker', () async {
    final root = _projectRoot(
      app: _appContents().replaceAll('// @stacked-import', '// missing-import'),
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
        '// @stacked-service',
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
        '// @stacked-import',
        '// @stacked-import\n// @stacked-import',
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
        '// @stacked-service',
        '// @stacked-service\n    // @stacked-service',
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
        '// @stacked-import',
        "import 'package:test_app/core/services/auth_session_service.dart';\n"
            '// @stacked-import',
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
        '// @stacked-import',
        "import 'package:test_app/core/services/auth_session_service.dart' ;\n"
            '// @stacked-import',
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
        '// @stacked-import',
        "import 'package:other_app/core/services/auth_session_service.dart';\n"
            '// @stacked-import',
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
        '// @stacked-import',
        "import  'package:other_app/core/services/auth_session_service.dart' ;\n"
            '// @stacked-import',
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
          '    // @stacked-service',
          '    LazySingleton(classType: AuthSessionService),\n'
              '    // @stacked-service',
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
    'rejects existing matching service registration without colon whitespace',
    () async {
      final root = _projectRoot(
        app: _appContents().replaceFirst(
          '    // @stacked-service',
          '    LazySingleton(classType:AuthSessionService),\n'
              '    // @stacked-service',
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
    'rejects existing conflicting service registration without mutation',
    () async {
      final root = _projectRoot(
        app: _appContents().replaceFirst(
          '    // @stacked-service',
          '    Singleton(classType: AuthSessionService),\n'
              '    // @stacked-service',
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
    'rejects existing conflicting service registration with colon whitespace',
    () async {
      final root = _projectRoot(
        app: _appContents().replaceFirst(
          '    // @stacked-service',
          '    Singleton(classType : AuthSessionService),\n'
              '    // @stacked-service',
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
        '// @stacked-import',
      ),
    );
    expect(
      app,
      contains(
        '    LazySingleton(classType: AuthSessionService),\r\n'
        '    // @stacked-service',
      ),
    );
  });

  test('supports markers at file boundaries', () async {
    final root = _projectRoot(
      app: '''
// @stacked-import
@StackedApp(
  dependencies: [
    // @stacked-service
  ],
)
class App {}
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
    expect(app, contains('    LazySingleton(classType: AuthSessionService),'));
  });

  test('only app.dart changes', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeService(root, 'auth_session');
    File(
      '${root.path}/lib/app/app.locator.dart',
    ).writeAsStringSync('// generated\n');
    File('${root.path}/README.md').writeAsStringSync('keep\n');
    final beforeFiles = _relativeFiles(root);
    final beforeLocator = File(
      '${root.path}/lib/app/app.locator.dart',
    ).readAsStringSync();
    final beforeReadme = File('${root.path}/README.md').readAsStringSync();
    final service = RegisterServiceService();

    await service.register(
      RegisterServiceInput(name: 'auth-session', projectRoot: root),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(
      File('${root.path}/lib/app/app.locator.dart').readAsStringSync(),
      beforeLocator,
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

File _appFile(Directory root) => File('${root.path}/lib/app/app.dart');

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
import 'package:test_app/core/services/shell_service.dart';
import 'package:stacked/stacked_annotations.dart';
// @stacked-import

@StackedApp(
$extra  dependencies: [
    LazySingleton(classType: ShellService),
    // @stacked-service
  ],
)
class App {}
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
