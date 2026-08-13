import 'dart:io';

import 'package:cuboid/src/route/register_route.dart';
import 'package:test/test.dart';

void main() {
  test('registers an auth feature route', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    final result = await service.register(
      RegisterRouteInput(feature: 'auth', projectRoot: root),
    );

    expect(result.plan.displayName, 'Auth');
    expect(result.plan.viewClassName, 'AuthView');
    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:test_app/features/auth/ui/views/auth_view.dart';",
      ),
    );
    expect(app, contains('    MaterialRoute(page: AuthView),'));
    expect(
      app.indexOf("import 'package:test_app/features/auth"),
      lessThan(app.indexOf('// @stacked-import')),
    );
    expect(
      app.indexOf('    MaterialRoute(page: AuthView),'),
      lessThan(app.indexOf('    // @stacked-route')),
    );
  });

  test('normalizes hyphenated feature names to lower snake case', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'user_profile');
    final service = RegisterRouteService();

    final result = await service.register(
      RegisterRouteInput(feature: 'user-profile', projectRoot: root),
    );

    expect(result.plan.featureName, 'user_profile');
    expect(result.plan.viewClassName, 'UserProfileView');
    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:test_app/features/user_profile/ui/views/user_profile_view.dart';",
      ),
    );
    expect(app, contains('    MaterialRoute(page: UserProfileView),'));
  });

  test('normalizes mixed casing consistently with feature creation', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'user_profile');
    final service = RegisterRouteService();

    final result = await service.register(
      RegisterRouteInput(feature: 'User_Profile', projectRoot: root),
    );

    expect(result.plan.featureName, 'user_profile');
    expect(result.plan.viewClassName, 'UserProfileView');
  });

  test('reads quoted package names with inline comments', () async {
    final root = _projectRoot(pubspec: 'name: "custom_app" # package\n');
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'billing');
    final service = RegisterRouteService();

    await service.register(
      RegisterRouteInput(feature: 'billing', projectRoot: root),
    );

    expect(
      _appFile(root).readAsStringSync(),
      contains(
        "import 'package:custom_app/features/billing/ui/views/billing_view.dart';",
      ),
    );
  });

  test('dry-run validates and leaves app.dart byte-identical', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterRouteService();

    final result = await service.register(
      RegisterRouteInput(feature: 'auth', projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(result.plan.importLine, contains('auth_view.dart'));
    expect(result.plan.routeLine, '    MaterialRoute(page: AuthView),');
    expect(_appFile(root).readAsStringSync(), before);
  });

  test('rejects invalid names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterRouteService();

    for (final name in [
      '',
      '   ',
      'user profile',
      '_auth',
      'auth_',
      'auth__profile',
      'auth--profile',
      '2fa',
      'class',
    ]) {
      await expectLater(
        service.register(RegisterRouteInput(feature: name, projectRoot: root)),
        throwsA(isA<RegisterRouteException>()),
        reason: name,
      );
    }
  });

  test('rejects traversal and path separator attempts', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterRouteService();

    for (final name in ['.', '..', '../auth', 'auth/child', r'auth\child']) {
      await expectLater(
        service.register(RegisterRouteInput(feature: name, projectRoot: root)),
        throwsA(isA<RegisterRouteException>()),
        reason: name,
      );
    }
  });

  test('rejects missing pubspec.yaml', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    File('${root.path}/pubspec.yaml').deleteSync();
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects invalid package names', () async {
    final root = _projectRoot(pubspec: 'name: class\n');
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects pubspec.yaml symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final target = File('${root.path}/target_pubspec.yaml')
      ..writeAsStringSync('name: test_app\n');
    File('${root.path}/pubspec.yaml').deleteSync();
    Link('${root.path}/pubspec.yaml').createSync(target.path);
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects missing feature View', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(
        isA<RegisterRouteException>().having(
          (error) => error.message,
          'message',
          'lib/features/auth/ui/views/auth_view.dart was not found.',
        ),
      ),
    );
  });

  test('rejects feature View directories', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      '${root.path}/lib/features/auth/ui/views/auth_view.dart',
    ).createSync(recursive: true);
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects feature View symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = File('${root.path}/target_view.dart')
      ..writeAsStringSync('// target\n');
    final link = Link('${root.path}/lib/features/auth/ui/views/auth_view.dart');
    link.parent.createSync(recursive: true);
    link.createSync(target.path);
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects missing app.dart', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    _appFile(root).deleteSync();
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects app.dart directories', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    _appFile(root).deleteSync();
    Directory('${root.path}/lib/app/app.dart').createSync();
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects app.dart symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final target = File('${root.path}/target_app.dart')
      ..writeAsStringSync(_appContents());
    _appFile(root).deleteSync();
    Link('${root.path}/lib/app/app.dart').createSync(target.path);
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects missing import marker', () async {
    final root = _projectRoot(
      app: _appContents().replaceAll('// @stacked-import', '// missing-import'),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects missing route marker', () async {
    final root = _projectRoot(
      app: _appContents().replaceAll('// @stacked-route', '// missing-route'),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
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
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects duplicate route markers', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '// @stacked-route',
        '// @stacked-route\n    // @stacked-route',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
  });

  test('rejects existing import conflicts without mutation', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '// @stacked-import',
        "import 'package:test_app/features/auth/ui/views/auth_view.dart';\n"
            '// @stacked-import',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
    expect(_appFile(root).readAsStringSync(), before);
  });

  test('rejects existing route conflicts without mutation', () async {
    final root = _projectRoot(
      app: _appContents().replaceFirst(
        '    // @stacked-route',
        '    MaterialRoute(page: AuthView),\n    // @stacked-route',
      ),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final before = _appFile(root).readAsStringSync();
    final service = RegisterRouteService();

    await expectLater(
      service.register(RegisterRouteInput(feature: 'auth', projectRoot: root)),
      throwsA(isA<RegisterRouteException>()),
    );
    expect(_appFile(root).readAsStringSync(), before);
  });

  test('preserves unrelated app.dart content exactly', () async {
    final root = _projectRoot(app: _appContents(extra: '  answer: 42,\n'));
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    await service.register(
      RegisterRouteInput(feature: 'auth', projectRoot: root),
    );

    final app = _appFile(root).readAsStringSync();
    expect(app, contains('  answer: 42,\n'));
    expect(app, contains('MaterialRoute(page: StartupView, initial: true),'));
  });

  test('preserves CRLF line endings around inserted registrations', () async {
    final root = _projectRoot(app: _appContents().replaceAll('\n', '\r\n'));
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    await service.register(
      RegisterRouteInput(feature: 'auth', projectRoot: root),
    );

    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:test_app/features/auth/ui/views/auth_view.dart';\r\n"
        '// @stacked-import',
      ),
    );
    expect(
      app,
      contains(
        '    MaterialRoute(page: AuthView),\r\n'
        '    // @stacked-route',
      ),
    );
  });

  test('supports markers at file boundaries', () async {
    final root = _projectRoot(
      app: '''
// @stacked-import
@StackedApp(
  routes: [
    // @stacked-route
  ],
)
class App {}
''',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    final service = RegisterRouteService();

    await service.register(
      RegisterRouteInput(feature: 'auth', projectRoot: root),
    );

    final app = _appFile(root).readAsStringSync();
    expect(app, startsWith("import 'package:test_app/features/auth"));
    expect(app, contains('    MaterialRoute(page: AuthView),'));
  });

  test('only app.dart changes', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    File(
      '${root.path}/lib/app/app.router.dart',
    ).writeAsStringSync('// generated\n');
    File('${root.path}/README.md').writeAsStringSync('keep\n');
    final beforeFiles = _relativeFiles(root);
    final beforeRouter = File(
      '${root.path}/lib/app/app.router.dart',
    ).readAsStringSync();
    final beforeReadme = File('${root.path}/README.md').readAsStringSync();
    final service = RegisterRouteService();

    await service.register(
      RegisterRouteInput(feature: 'auth', projectRoot: root),
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
    _writeFeatureView(root, 'auth');
    File('${root.path}/README.md').writeAsStringSync('keep\n');
    final beforeFiles = _relativeFiles(root);
    final beforeContents = {
      for (final path in beforeFiles)
        path: File(
          '${root.path}${Platform.pathSeparator}'
          '${path.replaceAll('/', Platform.pathSeparator)}',
        ).readAsStringSync(),
    };
    final service = RegisterRouteService();

    await service.register(
      RegisterRouteInput(feature: 'auth', projectRoot: root, dryRun: true),
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
                entity.uri.pathSegments.last.startsWith('.cuboid-route-'),
          ),
      isEmpty,
    );
  });
}

Directory _projectRoot({String pubspec = 'name: test_app\n', String? app}) {
  final root = Directory.systemTemp.createTempSync('cuboid_route_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  _appFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(app ?? _appContents());
  return root;
}

File _appFile(Directory root) => File('${root.path}/lib/app/app.dart');

void _writeFeatureView(Directory root, String featureName) {
  final className = featureName
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
  File(
      '${root.path}/lib/features/$featureName/ui/views/${featureName}_view.dart',
    )
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class ${className}View {}\n');
}

String _appContents({String extra = ''}) {
  return '''
import 'package:test_app/features/startup/ui/views/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
// @stacked-import

@StackedApp(
$extra  routes: [
    MaterialRoute(page: StartupView, initial: true),
    // @stacked-route
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
