import 'dart:io';

import 'package:cuboid/src/feature/create_feature.dart';
import 'package:test/test.dart';

void main() {
  test('creates an auth feature with a Cuboid view and viewmodel', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    final result = await service.create(
      CreateFeatureInput(name: 'auth', projectRoot: root),
    );

    expect(result.plan.displayName, 'Auth');
    expect(result.plan.files, [
      'lib/features/auth/ui/auth_view.dart',
      'lib/features/auth/ui/auth_viewmodel.dart',
      'lib/features/auth/data/auth_repository.dart',
    ]);

    final view = File(
      '${root.path}/lib/features/auth/ui/auth_view.dart',
    ).readAsStringSync();
    final viewModel = File(
      '${root.path}/lib/features/auth/ui/auth_viewmodel.dart',
    ).readAsStringSync();

    expect(
      view,
      contains(
        "import 'package:test_app/features/auth/ui/auth_viewmodel.dart';",
      ),
    );
    expect(view, contains('class AuthView extends CuboidView<AuthViewModel>'));
    expect(
      view,
      contains('AuthViewModel viewModelBuilder(BuildContext context)'),
    );
    expect(view, contains("AppBar(title: const Text('Auth'))"));
    expect(view, contains("body: const Center(child: Text('Auth'))"));
    expect(
      viewModel,
      contains('class AuthViewModel extends CuboidViewModel {}'),
    );
  });

  test(
    'creates the feature repository under data/ and registers it for DI',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateFeatureService();

      final result = await service.create(
        CreateFeatureInput(name: 'auth', projectRoot: root),
      );

      expect(result.plan.repositoryClassName, 'AuthRepository');
      final repository = File(
        '${root.path}/lib/features/auth/data/auth_repository.dart',
      ).readAsStringSync();
      expect(repository, contains('class AuthRepository {'));
      expect(repository, contains('const AuthRepository();'));

      final locator = _locatorFile(root).readAsStringSync();
      expect(
        locator,
        contains(
          "import 'package:test_app/features/auth/data/auth_repository.dart';",
        ),
      );
      expect(
        locator,
        contains(
          '  locator.registerLazySingleton<AuthRepository>(() => const AuthRepository());',
        ),
      );
    },
  );

  test(
    'registers the feature view as a route in lib/app/app.router.dart',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateFeatureService();

      await service.create(CreateFeatureInput(name: 'auth', projectRoot: root));

      final router = _routerFile(root).readAsStringSync();
      expect(
        router,
        contains("import 'package:test_app/features/auth/ui/auth_view.dart';"),
      );
      expect(router, contains("static const authView = '/auth-view';"));
      expect(router, contains('Routes.authView: (_) => const AuthView(),'));
    },
  );

  test('creates a user_profile feature with PascalCase class names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    await service.create(
      CreateFeatureInput(name: 'user_profile', projectRoot: root),
    );

    final view = File(
      '${root.path}/lib/features/user_profile/ui/user_profile_view.dart',
    ).readAsStringSync();
    final viewModel = File(
      '${root.path}/lib/features/user_profile/ui/user_profile_viewmodel.dart',
    ).readAsStringSync();
    final repository = File(
      '${root.path}/lib/features/user_profile/data/user_profile_repository.dart',
    ).readAsStringSync();

    expect(
      view,
      contains(
        'class UserProfileView extends CuboidView<UserProfileViewModel>',
      ),
    );
    expect(view, contains("AppBar(title: const Text('User Profile'))"));
    expect(
      viewModel,
      contains('class UserProfileViewModel extends CuboidViewModel {}'),
    );
    expect(repository, contains('class UserProfileRepository {'));

    final router = _routerFile(root).readAsStringSync();
    expect(
      router,
      contains("static const userProfileView = '/user-profile-view';"),
    );
  });

  test('normalizes hyphenated feature names to lower snake case', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    final result = await service.create(
      CreateFeatureInput(name: 'user-profile', projectRoot: root),
    );

    expect(result.plan.name, 'user_profile');
    expect(
      File(
        '${root.path}/lib/features/user_profile/ui/user_profile_view.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${root.path}/lib/features/user_profile/ui/user_profile_viewmodel.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${root.path}/lib/features/user_profile/data/user_profile_repository.dart',
      ).existsSync(),
      isTrue,
    );
  });

  test(
    'reads quoted package names and inline comments from pubspec.yaml',
    () async {
      final root = _projectRoot(pubspec: 'name: "custom_app" # app package\n');
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateFeatureService();

      await service.create(
        CreateFeatureInput(name: 'billing', projectRoot: root),
      );

      final view = File(
        '${root.path}/lib/features/billing/ui/billing_view.dart',
      ).readAsStringSync();

      expect(
        view,
        contains(
          "import 'package:custom_app/features/billing/ui/billing_viewmodel.dart';",
        ),
      );
    },
  );

  test(
    'dry-run validates and reports files without creating directories',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateFeatureService();

      final result = await service.create(
        CreateFeatureInput(name: 'auth', projectRoot: root, dryRun: true),
      );

      expect(result.plan.dryRun, isTrue);
      expect(result.plan.files, [
        'lib/features/auth/ui/auth_view.dart',
        'lib/features/auth/ui/auth_viewmodel.dart',
        'lib/features/auth/data/auth_repository.dart',
      ]);
      expect(Directory('${root.path}/lib/features/auth').existsSync(), isFalse);
      expect(_routerFile(root).readAsStringSync(), _routerContents());
      expect(_locatorFile(root).readAsStringSync(), _locatorContents());
    },
  );

  test('rejects invalid names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    for (final name in ['', '   ', 'user profile', '_auth', '2fa', 'class']) {
      await expectLater(
        service.create(CreateFeatureInput(name: name, projectRoot: root)),
        throwsA(isA<CreateFeatureException>()),
        reason: name,
      );
    }
  });

  test('rejects traversal and path separator attempts', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    for (final name in ['.', '..', '../auth', 'auth/child', r'auth\child']) {
      await expectLater(
        service.create(CreateFeatureInput(name: name, projectRoot: root)),
        throwsA(isA<CreateFeatureException>()),
        reason: name,
      );
    }
  });

  test('does not overwrite an existing feature', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final existing = Directory('${root.path}/lib/features/auth')
      ..createSync(recursive: true);
    File('${existing.path}/keep.txt').writeAsStringSync('keep\n');
    final service = CreateFeatureService();

    await expectLater(
      service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
      throwsA(
        isA<CreateFeatureException>().having(
          (error) => error.message,
          'message',
          'Feature already exists: lib/features/auth',
        ),
      ),
    );
    expect(File('${existing.path}/keep.txt').readAsStringSync(), 'keep\n');
  });

  test(
    'refuses to create a feature through a symlinked features dir',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final target = Directory('${root.path}/target_features')..createSync();
      Directory('${root.path}/lib/features').deleteSync(recursive: true);
      Link('${root.path}/lib/features').createSync(target.path);
      final service = CreateFeatureService();

      await expectLater(
        service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
        throwsA(
          isA<CreateFeatureException>().having(
            (error) => error.message,
            'message',
            contains('Refusing to create feature through a symlink'),
          ),
        ),
      );
      expect(Directory('${target.path}/auth').existsSync(), isFalse);
    },
  );

  test('refuses to create a feature through a symlinked lib dir', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = Directory('${root.path}/target_lib')..createSync();
    Directory('${root.path}/lib').deleteSync(recursive: true);
    Link('${root.path}/lib').createSync(target.path);
    final service = CreateFeatureService();

    await expectLater(
      service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
      throwsA(
        isA<CreateFeatureException>().having(
          (error) => error.message,
          'message',
          contains('Refusing to create feature through a symlink'),
        ),
      ),
    );
    expect(Directory('${target.path}/features').existsSync(), isFalse);
  });

  test('detects existing features during dry-run', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    Directory('${root.path}/lib/features/auth').createSync(recursive: true);
    final service = CreateFeatureService();

    await expectLater(
      service.create(
        CreateFeatureInput(name: 'auth', projectRoot: root, dryRun: true),
      ),
      throwsA(isA<CreateFeatureException>()),
    );
  });

  test('does not overwrite an existing target file', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = File('${root.path}/lib/features/auth/ui/auth_view.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('keep\n');
    final service = CreateFeatureService();

    await expectLater(
      service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
      throwsA(isA<CreateFeatureException>()),
    );
    expect(target.readAsStringSync(), 'keep\n');
  });

  test('rejects when lib/app/app.router.dart is missing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _routerFile(root).deleteSync();
    final service = CreateFeatureService();

    await expectLater(
      service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
      throwsA(
        isA<CreateFeatureException>().having(
          (error) => error.message,
          'message',
          'lib/app/app.router.dart was not found.',
        ),
      ),
    );
  });

  test('rejects when lib/app/app.locator.dart is missing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _locatorFile(root).deleteSync();
    final service = CreateFeatureService();

    await expectLater(
      service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
      throwsA(
        isA<CreateFeatureException>().having(
          (error) => error.message,
          'message',
          'lib/app/app.locator.dart was not found.',
        ),
      ),
    );
  });

  test('creates no files and leaves the router and locator untouched when a '
      'later write fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeRouter = _routerFile(root).readAsStringSync();
    final beforeLocator = _locatorFile(root).readAsStringSync();
    var writes = 0;
    final service = CreateFeatureService(
      fileWriter: (file, contents) {
        writes += 1;
        if (writes == 2) {
          throw const FileSystemException('simulated write failure');
        }
        file.writeAsStringSync(contents);
      },
    );

    await expectLater(
      service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
      throwsA(
        isA<CreateFeatureException>().having(
          (error) => error.message,
          'message',
          contains('Unable to create feature Auth'),
        ),
      ),
    );

    expect(Directory('${root.path}/lib/features/auth').existsSync(), isFalse);
    expect(_routerFile(root).readAsStringSync(), beforeRouter);
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
  });
}

String _routerContents() {
  return '''
// @cuboid-import

class Routes {
  // @cuboid-route-const
}

final Map<String, WidgetBuilder> appRoutes = {
  // @cuboid-route
};
''';
}

String _locatorContents() {
  return '''
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // @cuboid-service
}
''';
}

File _routerFile(Directory root) =>
    File('${root.path}/lib/app/app.router.dart');

File _locatorFile(Directory root) =>
    File('${root.path}/lib/app/app.locator.dart');

Directory _projectRoot({String pubspec = 'name: test_app\n'}) {
  final root = Directory.systemTemp.createTempSync('cuboid_feature_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  Directory('${root.path}/lib/features').createSync(recursive: true);
  _routerFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_routerContents());
  _locatorFile(root).writeAsStringSync(_locatorContents());
  return root;
}
