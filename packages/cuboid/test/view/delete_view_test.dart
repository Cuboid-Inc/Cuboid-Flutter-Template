import 'dart:io';

import 'package:cuboid/src/view/create_view.dart';
import 'package:cuboid/src/view/delete_view.dart';
import 'package:test/test.dart';

void main() {
  test('deletes a shared view, its route, and prunes the now-empty '
      'lib/shared/views directory', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateViewService().create(
      CreateViewInput(name: 'login', projectRoot: root),
    );

    final result = await DeleteViewService().delete(
      DeleteViewInput(name: 'login', projectRoot: root),
    );

    expect(result.plan.isShared, isTrue);
    expect(
      File('${root.path}/lib/shared/views/login_view.dart').existsSync(),
      isFalse,
    );
    expect(
      File('${root.path}/lib/shared/views/login_viewmodel.dart').existsSync(),
      isFalse,
    );
    expect(Directory('${root.path}/lib/shared/views').existsSync(), isFalse);
    final router = _routerFile(root).readAsStringSync();
    expect(router, isNot(contains('LoginView')));
    expect(router, isNot(contains('login_view.dart')));
    expect(_routerFile(root).existsSync(), isTrue);
  });

  test('deletes a feature-scoped view without touching the feature\'s '
      'primary view', () async {
    final root = _projectRoot(feature: 'auth');
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFeatureView(root, 'auth');
    await CreateViewService().create(
      CreateViewInput(
        name: 'forgot_password',
        feature: 'auth',
        projectRoot: root,
      ),
    );

    final result = await DeleteViewService().delete(
      DeleteViewInput(
        name: 'forgot_password',
        feature: 'auth',
        projectRoot: root,
      ),
    );

    expect(result.plan.isShared, isFalse);
    expect(
      File(
        '${root.path}/lib/features/auth/ui/forgot_password_view.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File('${root.path}/lib/features/auth/ui/auth_view.dart').existsSync(),
      isTrue,
    );
    final router = _routerFile(root).readAsStringSync();
    expect(router, isNot(contains('ForgotPasswordView')));
    expect(router, contains('AuthView'));
  });

  test('deleting one shared view leaves another untouched', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final createService = CreateViewService();
    await createService.create(
      CreateViewInput(name: 'login', projectRoot: root),
    );
    await createService.create(
      CreateViewInput(name: 'signup', projectRoot: root),
    );

    await DeleteViewService().delete(
      DeleteViewInput(name: 'login', projectRoot: root),
    );

    expect(
      File('${root.path}/lib/shared/views/login_view.dart').existsSync(),
      isFalse,
    );
    expect(
      File('${root.path}/lib/shared/views/signup_view.dart').existsSync(),
      isTrue,
    );
    final router = _routerFile(root).readAsStringSync();
    expect(router, isNot(contains('LoginView')));
    expect(router, contains('SignupView'));
  });

  test(
    'deleting the same view twice fails safely without corruption',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateViewService().create(
        CreateViewInput(name: 'login', projectRoot: root),
      );
      final service = DeleteViewService();
      await service.delete(DeleteViewInput(name: 'login', projectRoot: root));
      final afterFirst = _routerFile(root).readAsStringSync();

      await expectLater(
        service.delete(DeleteViewInput(name: 'login', projectRoot: root)),
        throwsA(isA<DeleteViewException>()),
      );

      expect(_routerFile(root).readAsStringSync(), afterFirst);
    },
  );

  test('dry-run validates and deletes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateViewService().create(
      CreateViewInput(name: 'login', projectRoot: root),
    );
    final beforeRouter = _routerFile(root).readAsStringSync();

    final result = await DeleteViewService().delete(
      DeleteViewInput(name: 'login', projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(
      File('${root.path}/lib/shared/views/login_view.dart').existsSync(),
      isTrue,
    );
    expect(_routerFile(root).readAsStringSync(), beforeRouter);
  });

  test('deleting a view that was never created throws cleanly', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteViewService().delete(
        DeleteViewInput(name: 'ghost', projectRoot: root),
      ),
      throwsA(
        isA<DeleteViewException>().having(
          (error) => error.message,
          'message',
          contains('View not found'),
        ),
      ),
    );
  });
}

void _writeFeatureView(Directory root, String feature) {
  File('${root.path}/lib/features/$feature/ui/${feature}_view.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class AuthView {}\n');
  File(
    '${root.path}/lib/features/$feature/ui/${feature}_viewmodel.dart',
  ).writeAsStringSync('class AuthViewModel {}\n');
  final router = _routerFile(root);
  router.writeAsStringSync(
    router
        .readAsStringSync()
        .replaceFirst(
          '// @cuboid-import',
          "import 'package:test_app/features/$feature/ui/${feature}_view.dart';\n// @cuboid-import",
        )
        .replaceFirst(
          '// @cuboid-route-const',
          "static const ${feature}View = '/$feature-view';\n  // @cuboid-route-const",
        )
        .replaceFirst(
          '// @cuboid-route',
          'Routes.${feature}View: (_) => const AuthView(),\n  // @cuboid-route',
        ),
  );
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

Directory _projectRoot({String? feature}) {
  final root = Directory.systemTemp.createTempSync('cuboid_delete_view_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  _routerFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_routerContents());
  if (feature != null) {
    Directory('${root.path}/lib/features/$feature').createSync(recursive: true);
  }
  return root;
}
