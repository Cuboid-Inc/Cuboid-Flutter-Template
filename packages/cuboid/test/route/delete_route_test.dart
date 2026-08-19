import 'dart:io';

import 'package:cuboid/src/route/delete_route.dart';
import 'package:cuboid/src/view/create_view.dart';
import 'package:test/test.dart';

void main() {
  test(
    'removes only the router entry, leaving the View files untouched',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateViewService().create(
        CreateViewInput(name: 'login', projectRoot: root),
      );

      final result = await DeleteRouteService().delete(
        DeleteRouteInput(name: 'login', projectRoot: root),
      );

      expect(result.plan.name, 'login');
      final router = _routerFile(root).readAsStringSync();
      expect(router, isNot(contains('LoginView')));
      expect(router, isNot(contains('login_view.dart')));
      // The View and ViewModel files are untouched.
      expect(
        File('${root.path}/lib/shared/views/login_view.dart').existsSync(),
        isTrue,
      );
      expect(
        File('${root.path}/lib/shared/views/login_viewmodel.dart').existsSync(),
        isTrue,
      );
    },
  );

  test(
    'refuses to guess when multiple imports match, deleting nothing',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final router = _routerFile(root);
      router.writeAsStringSync(
        router.readAsStringSync().replaceFirst(
          '// @cuboid-import',
          "import 'package:test_app/shared/views/login_view.dart';\n"
              "import 'package:test_app/features/auth/ui/login_view.dart';\n"
              '// @cuboid-import',
        ),
      );
      final before = router.readAsStringSync();

      await expectLater(
        DeleteRouteService().delete(
          DeleteRouteInput(name: 'login', projectRoot: root),
        ),
        throwsA(
          isA<DeleteRouteException>().having(
            (error) => error.message,
            'message',
            contains('Multiple route imports match'),
          ),
        ),
      );
      expect(router.readAsStringSync(), before);
    },
  );

  test(
    'deleting the same route twice fails safely without corruption',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateViewService().create(
        CreateViewInput(name: 'login', projectRoot: root),
      );
      final service = DeleteRouteService();
      await service.delete(DeleteRouteInput(name: 'login', projectRoot: root));
      final afterFirst = _routerFile(root).readAsStringSync();

      await expectLater(
        service.delete(DeleteRouteInput(name: 'login', projectRoot: root)),
        throwsA(isA<DeleteRouteException>()),
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
    final before = _routerFile(root).readAsStringSync();

    final result = await DeleteRouteService().delete(
      DeleteRouteInput(name: 'login', projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(_routerFile(root).readAsStringSync(), before);
  });

  test('deleting a route that was never registered throws cleanly', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteRouteService().delete(
        DeleteRouteInput(name: 'ghost', projectRoot: root),
      ),
      throwsA(
        isA<DeleteRouteException>().having(
          (error) => error.message,
          'message',
          contains('No route registered'),
        ),
      ),
    );
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

Directory _projectRoot() {
  final root = Directory.systemTemp.createTempSync('cuboid_delete_route_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  _routerFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_routerContents());
  return root;
}
