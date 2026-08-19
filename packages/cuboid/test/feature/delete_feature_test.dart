import 'dart:io';

import 'package:cuboid/src/feature/create_feature.dart';
import 'package:cuboid/src/feature/delete_feature.dart';
import 'package:cuboid/src/view/create_view.dart';
import 'package:test/test.dart';

void main() {
  test(
    'deletes a feature, its route, and its repository registration',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateFeatureService().create(
        CreateFeatureInput(name: 'auth', projectRoot: root),
      );

      final result = await DeleteFeatureService().delete(
        DeleteFeatureInput(name: 'auth', projectRoot: root),
      );

      expect(result.plan.displayName, 'Auth');
      expect(Directory('${root.path}/lib/features/auth').existsSync(), isFalse);
      final router = _routerFile(root).readAsStringSync();
      expect(router, isNot(contains('AuthView')));
      expect(router, isNot(contains('auth_view.dart')));
      final locator = _locatorFile(root).readAsStringSync();
      expect(locator, isNot(contains('AuthRepository')));
      expect(_routerFile(root).existsSync(), isTrue);
      expect(_locatorFile(root).existsSync(), isTrue);
    },
  );

  test(
    'deleting a feature also removes routes for its additional Views',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateFeatureService().create(
        CreateFeatureInput(name: 'auth', projectRoot: root),
      );
      await CreateViewService().create(
        CreateViewInput(
          name: 'forgot_password',
          feature: 'auth',
          projectRoot: root,
        ),
      );

      await DeleteFeatureService().delete(
        DeleteFeatureInput(name: 'auth', projectRoot: root),
      );

      final router = _routerFile(root).readAsStringSync();
      expect(router, isNot(contains('AuthView')));
      expect(router, isNot(contains('ForgotPasswordView')));
    },
  );

  test('deleting a feature with no repository registration succeeds '
      '(matching hand-written base-template features)', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _writeHandWrittenFeature(root, 'home');

    final result = await DeleteFeatureService().delete(
      DeleteFeatureInput(name: 'home', projectRoot: root),
    );

    expect(result.plan.name, 'home');
    expect(Directory('${root.path}/lib/features/home').existsSync(), isFalse);
    final router = _routerFile(root).readAsStringSync();
    expect(router, isNot(contains('HomeView')));
  });

  test('deleting one feature leaves another untouched', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final createService = CreateFeatureService();
    await createService.create(
      CreateFeatureInput(name: 'auth', projectRoot: root),
    );
    await createService.create(
      CreateFeatureInput(name: 'billing', projectRoot: root),
    );

    await DeleteFeatureService().delete(
      DeleteFeatureInput(name: 'auth', projectRoot: root),
    );

    expect(Directory('${root.path}/lib/features/auth').existsSync(), isFalse);
    expect(Directory('${root.path}/lib/features/billing').existsSync(), isTrue);
    final router = _routerFile(root).readAsStringSync();
    expect(router, isNot(contains('AuthView')));
    expect(router, contains('BillingView'));
    final locator = _locatorFile(root).readAsStringSync();
    expect(locator, isNot(contains('AuthRepository')));
    expect(locator, contains('BillingRepository'));
  });

  test(
    'deleting the same feature twice fails safely without corruption',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateFeatureService().create(
        CreateFeatureInput(name: 'auth', projectRoot: root),
      );
      final service = DeleteFeatureService();
      await service.delete(DeleteFeatureInput(name: 'auth', projectRoot: root));
      final afterFirstRouter = _routerFile(root).readAsStringSync();
      final afterFirstLocator = _locatorFile(root).readAsStringSync();

      await expectLater(
        service.delete(DeleteFeatureInput(name: 'auth', projectRoot: root)),
        throwsA(isA<DeleteFeatureException>()),
      );

      expect(_routerFile(root).readAsStringSync(), afterFirstRouter);
      expect(_locatorFile(root).readAsStringSync(), afterFirstLocator);
    },
  );

  test('dry-run validates and deletes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateFeatureService().create(
      CreateFeatureInput(name: 'auth', projectRoot: root),
    );
    final beforeRouter = _routerFile(root).readAsStringSync();
    final beforeLocator = _locatorFile(root).readAsStringSync();

    final result = await DeleteFeatureService().delete(
      DeleteFeatureInput(name: 'auth', projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(Directory('${root.path}/lib/features/auth').existsSync(), isTrue);
    expect(_routerFile(root).readAsStringSync(), beforeRouter);
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
  });

  test('deleting a feature that was never created throws cleanly', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteFeatureService().delete(
        DeleteFeatureInput(name: 'ghost', projectRoot: root),
      ),
      throwsA(
        isA<DeleteFeatureException>().having(
          (error) => error.message,
          'message',
          contains('Feature not found'),
        ),
      ),
    );
  });
}

void _writeHandWrittenFeature(Directory root, String name) {
  final words = name.split('_');
  final className = words
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
  File('${root.path}/lib/features/$name/ui/${name}_view.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('class ${className}View {}\n');
  File(
    '${root.path}/lib/features/$name/ui/${name}_viewmodel.dart',
  ).writeAsStringSync('class ${className}ViewModel {}\n');
  final router = _routerFile(root);
  router.writeAsStringSync(
    router
        .readAsStringSync()
        .replaceFirst(
          '// @cuboid-import',
          "import 'package:test_app/features/$name/ui/${name}_view.dart';\n// @cuboid-import",
        )
        .replaceFirst(
          '// @cuboid-route-const',
          "static const ${name}View = '/$name-view';\n  // @cuboid-route-const",
        )
        .replaceFirst(
          '// @cuboid-route',
          'Routes.${name}View: (_) => const ${className}View(),\n  // @cuboid-route',
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
  final root = Directory.systemTemp.createTempSync('cuboid_delete_feature_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  Directory('${root.path}/lib/features').createSync(recursive: true);
  _routerFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_routerContents());
  _locatorFile(root).writeAsStringSync(_locatorContents());
  return root;
}
