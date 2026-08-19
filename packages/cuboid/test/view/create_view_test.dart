import 'dart:io';

import 'package:cuboid/src/view/create_view.dart';
import 'package:test/test.dart';

void main() {
  test('creates an auth forgot_password view and viewmodel', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateViewService();

    final result = await service.create(
      CreateViewInput(
        feature: 'auth',
        name: 'forgot-password',
        projectRoot: root,
      ),
    );

    expect(result.plan.featureName, 'auth');
    expect(result.plan.name, 'forgot_password');
    expect(result.plan.displayName, 'Forgot Password');
    expect(result.plan.viewClassName, 'ForgotPasswordView');
    expect(result.plan.viewModelClassName, 'ForgotPasswordViewModel');
    expect(result.plan.files, [
      'lib/features/auth/ui/forgot_password_view.dart',
      'lib/features/auth/ui/forgot_password_viewmodel.dart',
    ]);

    final view = File(
      '${root.path}/lib/features/auth/ui/forgot_password_view.dart',
    ).readAsStringSync();
    final viewModel = File(
      '${root.path}/lib/features/auth/ui/forgot_password_viewmodel.dart',
    ).readAsStringSync();

    expect(
      view,
      contains(
        "import 'package:test_app/features/auth/ui/forgot_password_viewmodel.dart';",
      ),
    );
    expect(
      view,
      contains(
        'class ForgotPasswordView extends CuboidView<ForgotPasswordViewModel>',
      ),
    );
    expect(
      view,
      contains(
        'ForgotPasswordViewModel viewModelBuilder(BuildContext context)',
      ),
    );
    expect(view, contains("AppBar(title: const Text('Forgot Password'))"));
    expect(
      view,
      contains("body: const Center(child: Text('Forgot Password'))"),
    );
    expect(
      viewModel,
      contains('class ForgotPasswordViewModel extends CuboidViewModel {}'),
    );

    final router = _routerFile(root).readAsStringSync();
    expect(
      router,
      contains(
        "import 'package:test_app/features/auth/ui/forgot_password_view.dart';",
      ),
    );
    expect(
      router,
      contains("static const forgotPasswordView = '/forgot-password-view';"),
    );
    expect(
      router,
      contains('Routes.forgotPasswordView: (_) => const ForgotPasswordView(),'),
    );
  });

  test(
    'creates a shared login view and viewmodel when no feature is given',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateViewService();

      final result = await service.create(
        CreateViewInput(name: 'login', projectRoot: root),
      );

      expect(result.plan.featureName, isNull);
      expect(result.plan.isShared, isTrue);
      expect(result.plan.name, 'login');
      expect(result.plan.viewClassName, 'LoginView');
      expect(result.plan.viewModelClassName, 'LoginViewModel');
      expect(result.plan.files, [
        'lib/shared/views/login_view.dart',
        'lib/shared/views/login_viewmodel.dart',
      ]);

      final view = File(
        '${root.path}/lib/shared/views/login_view.dart',
      ).readAsStringSync();
      final viewModel = File(
        '${root.path}/lib/shared/views/login_viewmodel.dart',
      ).readAsStringSync();

      expect(
        view,
        contains(
          "import 'package:test_app/shared/views/login_viewmodel.dart';",
        ),
      );
      expect(
        view,
        contains('class LoginView extends CuboidView<LoginViewModel>'),
      );
      expect(
        viewModel,
        contains('class LoginViewModel extends CuboidViewModel {}'),
      );

      final router = _routerFile(root).readAsStringSync();
      expect(
        router,
        contains("import 'package:test_app/shared/views/login_view.dart';"),
      );
      expect(router, contains('Routes.loginView: (_) => const LoginView(),'));

      expect(
        Directory('${root.path}/lib/features').existsSync() &&
            Directory('${root.path}/lib/features/login').existsSync(),
        isFalse,
      );
    },
  );

  test(
    'does not require an existing feature directory for shared views',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateViewService();

      await expectLater(
        service.create(CreateViewInput(name: 'login', projectRoot: root)),
        completes,
      );
    },
  );

  test('normalizes mixed-case and hyphenated feature and view names', () async {
    final root = _projectRoot(feature: 'user_profile');
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateViewService();

    final result = await service.create(
      CreateViewInput(
        feature: 'User-Profile',
        name: 'Invite-Member',
        projectRoot: root,
      ),
    );

    expect(result.plan.featureName, 'user_profile');
    expect(result.plan.name, 'invite_member');
    expect(result.plan.viewClassName, 'InviteMemberView');
    expect(
      File(
        '${root.path}/lib/features/user_profile/ui/invite_member_view.dart',
      ).existsSync(),
      isTrue,
    );
  });

  test('reads quoted package names and inline comments', () async {
    final root = _projectRoot(pubspec: 'name: "custom_app" # package\n');
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateViewService();

    await service.create(
      CreateViewInput(
        feature: 'auth',
        name: 'reset_password',
        projectRoot: root,
      ),
    );

    final view = File(
      '${root.path}/lib/features/auth/ui/reset_password_view.dart',
    ).readAsStringSync();

    expect(
      view,
      contains(
        "import 'package:custom_app/features/auth/ui/reset_password_viewmodel.dart';",
      ),
    );
  });

  test('reads single quoted package names', () async {
    final root = _projectRoot(pubspec: "name: 'custom_app'\n");
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateViewService();

    await service.create(
      CreateViewInput(
        feature: 'auth',
        name: 'reset_password',
        projectRoot: root,
      ),
    );

    final view = File(
      '${root.path}/lib/features/auth/ui/reset_password_view.dart',
    ).readAsStringSync();

    expect(
      view,
      contains(
        "import 'package:custom_app/features/auth/ui/reset_password_viewmodel.dart';",
      ),
    );
  });

  test('dry-run validates and creates no files or directories', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final service = CreateViewService();

    final result = await service.create(
      CreateViewInput(
        feature: 'auth',
        name: 'forgot_password',
        projectRoot: root,
        dryRun: true,
      ),
    );

    expect(result.plan.dryRun, isTrue);
    expect(result.plan.files, [
      'lib/features/auth/ui/forgot_password_view.dart',
      'lib/features/auth/ui/forgot_password_viewmodel.dart',
    ]);
    expect(_relativeFiles(root), beforeFiles);
    expect(
      Directory('${root.path}/lib/features/auth/ui').existsSync(),
      isFalse,
    );
  });

  test('rejects invalid feature names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateViewService();

    for (final name in [
      '',
      '   ',
      'user profile',
      '_auth',
      'auth_',
      'auth__login',
      'auth--login',
      '2fa',
      'class',
    ]) {
      await expectLater(
        service.create(
          CreateViewInput(feature: name, name: 'login', projectRoot: root),
        ),
        throwsA(isA<CreateViewException>()),
        reason: name,
      );
    }
  });

  test('rejects invalid view names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateViewService();

    for (final name in [
      '',
      '   ',
      'reset password',
      '_reset',
      'reset_',
      'reset__password',
      'reset--password',
      '2fa',
      'class',
    ]) {
      await expectLater(
        service.create(
          CreateViewInput(feature: 'auth', name: name, projectRoot: root),
        ),
        throwsA(isA<CreateViewException>()),
        reason: name,
      );
    }
  });

  test('rejects traversal and path separators', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateViewService();

    for (final value in ['.', '..', '../auth', 'auth/child', r'auth\child']) {
      await expectLater(
        service.create(
          CreateViewInput(feature: value, name: 'login', projectRoot: root),
        ),
        throwsA(isA<CreateViewException>()),
        reason: value,
      );
      await expectLater(
        service.create(
          CreateViewInput(feature: 'auth', name: value, projectRoot: root),
        ),
        throwsA(isA<CreateViewException>()),
        reason: value,
      );
    }
  });

  test('rejects missing pubspec.yaml', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    File('${root.path}/pubspec.yaml').deleteSync();
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
  });

  test('rejects invalid pubspec package names', () async {
    final root = _projectRoot(pubspec: 'name: class\n');
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
  });

  test('rejects pubspec.yaml directories', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    File('${root.path}/pubspec.yaml').deleteSync();
    Directory('${root.path}/pubspec.yaml').createSync();
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
  });

  test('rejects pubspec.yaml symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = File('${root.path}/target_pubspec.yaml')
      ..writeAsStringSync('name: test_app\n');
    File('${root.path}/pubspec.yaml').deleteSync();
    Link('${root.path}/pubspec.yaml').createSync(target.path);
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
  });

  test('rejects missing feature directories', () async {
    final root = _projectRoot(feature: 'auth');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory('${root.path}/lib/features/auth').deleteSync(recursive: true);
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(
        isA<CreateViewException>().having(
          (error) => error.message,
          'message',
          'lib/features/auth was not found.',
        ),
      ),
    );
  });

  test('rejects feature paths that are files', () async {
    final root = _projectRoot(feature: 'auth');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory('${root.path}/lib/features/auth').deleteSync(recursive: true);
    File('${root.path}/lib/features/auth').writeAsStringSync('nope\n');
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
  });

  test('rejects feature symlinks', () async {
    final root = _projectRoot(feature: 'auth');
    addTearDown(() => root.deleteSync(recursive: true));
    final target = Directory('${root.path}/target_auth')..createSync();
    Directory('${root.path}/lib/features/auth').deleteSync(recursive: true);
    Link('${root.path}/lib/features/auth').createSync(target.path);
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
  });

  test('rejects existing View files without mutation', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = File('${root.path}/lib/features/auth/ui/login_view.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('keep\n');
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
    expect(target.readAsStringSync(), 'keep\n');
    expect(
      File(
        '${root.path}/lib/features/auth/ui/login_viewmodel.dart',
      ).existsSync(),
      isFalse,
    );
  });

  test('rejects existing ViewModel files without mutation', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target =
        File('${root.path}/lib/features/auth/ui/login_viewmodel.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('keep\n');
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
    expect(target.readAsStringSync(), 'keep\n');
    expect(
      File('${root.path}/lib/features/auth/ui/login_view.dart').existsSync(),
      isFalse,
    );
  });

  test('rejects target directories and symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      '${root.path}/lib/features/auth/ui/login_view.dart',
    ).createSync(recursive: true);
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );

    Directory('${root.path}/lib/features/auth/ui').deleteSync(recursive: true);
    final target = File('${root.path}/target_view.dart')
      ..writeAsStringSync('// target\n');
    final link = Link('${root.path}/lib/features/auth/ui/login_view.dart');
    link.parent.createSync(recursive: true);
    link.createSync(target.path);

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
  });

  test('rejects ViewModel target directories and symlinks', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      '${root.path}/lib/features/auth/ui/login_viewmodel.dart',
    ).createSync(recursive: true);
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
    expect(
      File('${root.path}/lib/features/auth/ui/login_view.dart').existsSync(),
      isFalse,
    );

    Directory('${root.path}/lib/features/auth/ui').deleteSync(recursive: true);
    final target = File('${root.path}/target_viewmodel.dart')
      ..writeAsStringSync('// target\n');
    final link = Link('${root.path}/lib/features/auth/ui/login_viewmodel.dart');
    link.parent.createSync(recursive: true);
    link.createSync(target.path);

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
    expect(
      File('${root.path}/lib/features/auth/ui/login_view.dart').existsSync(),
      isFalse,
    );
  });

  test('rejects symlink parent directories', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = Directory('${root.path}/target_ui')..createSync();
    Link('${root.path}/lib/features/auth/ui').createSync(target.path);
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
    expect(Directory('${target.path}/views').existsSync(), isFalse);
  });

  test('creates exactly two files and preserves unrelated files', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final unrelated = File('${root.path}/lib/features/auth/keep.txt')
      ..writeAsStringSync('keep\n');
    final service = CreateViewService();

    await service.create(
      CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
    );

    expect(unrelated.readAsStringSync(), 'keep\n');
    expect(_relativeFiles(root), [
      'lib/app/app.router.dart',
      'lib/features/auth/keep.txt',
      'lib/features/auth/ui/login_view.dart',
      'lib/features/auth/ui/login_viewmodel.dart',
      'pubspec.yaml',
    ]);
  });

  test('rejects when lib/app/app.router.dart is missing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _routerFile(root).deleteSync();
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(
        isA<CreateViewException>().having(
          (error) => error.message,
          'message',
          'lib/app/app.router.dart was not found.',
        ),
      ),
    );
  });

  test('rejects a route that already exists for the view', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _routerFile(root).writeAsStringSync('''
import 'package:test_app/features/auth/ui/login_view.dart';
// @cuboid-import

class Routes {
  static const loginView = '/login-view';
  // @cuboid-route-const
}

final Map<String, WidgetBuilder> appRoutes = {
  Routes.loginView: (_) => const LoginView(),
  // @cuboid-route
};
''');
    final service = CreateViewService();

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(isA<CreateViewException>()),
    );
    expect(
      File('${root.path}/lib/features/auth/ui/login_view.dart').existsSync(),
      isFalse,
    );
  });

  test('cleans up partial first file when first final publish fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final unrelated = File('${root.path}/lib/features/auth/keep.txt')
      ..writeAsStringSync('keep\n');
    final service = CreateViewService(
      fileWriter: (file, contents) {
        file.writeAsStringSync('partial\n');
        throw const FileSystemException('first publish failed');
      },
    );

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(
        isA<CreateViewException>().having(
          (error) => error.message,
          'message',
          contains('first publish failed'),
        ),
      ),
    );

    expect(
      File('${root.path}/lib/features/auth/ui/login_view.dart').existsSync(),
      isFalse,
    );
    expect(
      File(
        '${root.path}/lib/features/auth/ui/login_viewmodel.dart',
      ).existsSync(),
      isFalse,
    );
    expect(unrelated.readAsStringSync(), 'keep\n');
    expect(
      Directory('${root.path}/lib/features/auth/ui').existsSync(),
      isFalse,
    );
  });

  test('cleans up first file and leaves the router untouched when second '
      'final publish fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final unrelated = File('${root.path}/lib/features/auth/keep.txt')
      ..writeAsStringSync('keep\n');
    final beforeRouter = _routerFile(root).readAsStringSync();
    var writes = 0;
    final service = CreateViewService(
      fileWriter: (file, contents) {
        writes++;
        if (writes == 2) {
          file.writeAsStringSync('partial\n');
          throw const FileSystemException('second publish failed');
        }
        file.writeAsStringSync(contents);
      },
    );

    await expectLater(
      service.create(
        CreateViewInput(feature: 'auth', name: 'login', projectRoot: root),
      ),
      throwsA(
        isA<CreateViewException>().having(
          (error) => error.message,
          'message',
          contains('second publish failed'),
        ),
      ),
    );

    expect(
      File('${root.path}/lib/features/auth/ui/login_view.dart').existsSync(),
      isFalse,
    );
    expect(
      File(
        '${root.path}/lib/features/auth/ui/login_viewmodel.dart',
      ).existsSync(),
      isFalse,
    );
    expect(unrelated.readAsStringSync(), 'keep\n');
    expect(
      Directory('${root.path}/lib/features/auth/ui').existsSync(),
      isFalse,
    );
    expect(_routerFile(root).readAsStringSync(), beforeRouter);
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

File _routerFile(Directory root) =>
    File('${root.path}/lib/app/app.router.dart');

Directory _projectRoot({
  String pubspec = 'name: test_app\n',
  String feature = 'auth',
}) {
  final root = Directory.systemTemp.createTempSync('cuboid_view_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  Directory('${root.path}/lib/features/$feature').createSync(recursive: true);
  _routerFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_routerContents());
  return root;
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
