import 'dart:io';

import 'package:cuboid/src/migrate/migration.dart';
import 'package:cuboid/src/migrate/migrations/navigation_cuboid_page_route_migration.dart';
import 'package:test/test.dart';

const _legacyRouter = '''
import 'package:my_app/features/home/ui/home_view.dart';
import 'package:flutter/material.dart';
// @cuboid-import

class Routes {
  static const homeView = '/home-view';
  // @cuboid-route-const
}

final Map<String, WidgetBuilder> appRoutes = {
  Routes.homeView: (_) => const HomeView(),
  // @cuboid-route
};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}
''';

const _currentRouter = '''
import 'package:cuboid_flutter/cuboid_flutter.dart';
import 'package:my_app/features/home/ui/home_view.dart';
import 'package:flutter/material.dart';
// @cuboid-import

class Routes {
  static const homeView = '/home-view';
  // @cuboid-route-const
}

final Map<String, WidgetBuilder> appRoutes = {
  Routes.homeView: (_) => const HomeView(),
  // @cuboid-route
};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return CuboidPageRoute<dynamic>(builder: builder, settings: settings);
}
''';

/// A router with a real project's structural customizations: extra routes,
/// extra imports, and -- like PropertyZoom_Mobile's real
/// `lib/app/app.router.dart` -- an application-added conditional branch in
/// `onGenerateRoute` that constructs its own `MaterialPageRoute` for a
/// route carrying typed arguments, in addition to the canonical trailing
/// line.
const _customizedLegacyRouter = '''
import 'package:my_app/features/seller/data/demo_seller_store.dart';
import 'package:my_app/features/seller/ui/screens/account_screen.dart';
import 'package:my_app/features/seller/ui/screens/dashboard_screen.dart';
import 'package:my_app/features/seller/ui/screens/listing_detail_screen.dart';
import 'package:my_app/features/startup/ui/startup_view.dart';
import 'package:flutter/material.dart';

// @cuboid-import

class Routes {
  static const startupView = '/';
  static const dashboard = '/dashboard';
  static const listingDetail = '/dashboard/detail';
  static const account = '/account';
  // @cuboid-route-const
}

final Map<String, WidgetBuilder> appRoutes = {
  Routes.startupView: (_) => const StartupView(),
  Routes.dashboard: (_) => const DashboardScreen(),
  Routes.account: (_) => AccountScreen(store: DemoSellerStore.instance),
  // @cuboid-route
};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  // Application-added: listingDetail needs a typed argument, so it isn't a
  // plain WidgetBuilder entry in appRoutes.
  if (settings.name == Routes.listingDetail) {
    final listingId = settings.arguments;
    if (listingId is String) {
      return MaterialPageRoute<dynamic>(
        builder: (_) => ListingDetailScreen(
          listingId: listingId,
          store: DemoSellerStore.instance,
        ),
        settings: settings,
      );
    }
  }
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}
''';

const _legacyNavigationService = """
import 'package:flutter/material.dart';

/// Navigates using a global [navigatorKey] so view models can request
/// navigation without holding a [BuildContext]. Replaces
/// `stacked_services`' `NavigationService`.
class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError('NavigationService used before a Navigator exists.');
    }
    return state;
  }

  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return _navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  Future<T?> replaceWith<T, TO>(String routeName, {Object? arguments}) {
    return _navigator.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
    );
  }

  void back<T>({T? result}) {
    if (_navigator.canPop()) {
      _navigator.pop<T>(result);
    }
  }
}
""";

/// A NavigationService with a real project's structural customizations:
/// like PropertyZoom_Mobile's real
/// `lib/core/services/navigation_service.dart`, it already has the *entire*
/// 0.2.0-era direct-widget API (someone -- an earlier Cuboid generation,
/// or the developer -- already added it), just still constructing
/// `MaterialPageRoute` instead of `CuboidPageRoute`, plus an
/// application-added custom method, custom import, and custom comment.
const _customizedNavigationServiceWithFullApi = """
import 'package:flutter/material.dart';
import 'package:my_app/core/analytics/analytics_service.dart';

/// Navigates using a global [navigatorKey] so view models can request
/// navigation without holding a [BuildContext]. Replaces
/// `stacked_services`' `NavigationService`.
///
/// Direct-widget methods push a [Widget] instance directly via
/// [MaterialPageRoute], for views that don't need a registered named route.
class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError('NavigationService used before a Navigator exists.');
    }
    return state;
  }

  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) async {
    final result = await _navigator.pushNamed<dynamic>(
      routeName,
      arguments: arguments,
    );
    return result as T?;
  }

  Future<T?> replaceWith<T, TO>(String routeName, {Object? arguments}) async {
    final result = await _navigator.pushReplacementNamed<dynamic, TO>(
      routeName,
      arguments: arguments,
    );
    return result as T?;
  }

  Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName, {
    required RoutePredicate predicate,
    Object? arguments,
  }) async {
    final result = await _navigator.pushNamedAndRemoveUntil<dynamic>(
      routeName,
      predicate,
      arguments: arguments,
    );
    return result as T?;
  }

  Future<T?> clearStackAndShow<T>(String routeName, {Object? arguments}) {
    return pushNamedAndRemoveUntil<T>(
      routeName,
      predicate: (route) => false,
      arguments: arguments,
    );
  }

  Future<T?> navigateToView<T>(Widget view, {RouteSettings? settings}) {
    return _navigator.push<T>(
      MaterialPageRoute<T>(builder: (_) => view, settings: settings),
    );
  }

  Future<T?> replaceWithView<T, TO>(Widget view, {RouteSettings? settings}) {
    return _navigator.pushReplacement<T, TO>(
      MaterialPageRoute<T>(builder: (_) => view, settings: settings),
    );
  }

  Future<T?> pushAndRemoveUntil<T>(
    Widget view, {
    required RoutePredicate predicate,
    RouteSettings? settings,
  }) {
    return _navigator.pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(builder: (_) => view, settings: settings),
      predicate,
    );
  }

  Future<T?> clearStackAndShowView<T>(Widget view, {RouteSettings? settings}) {
    return pushAndRemoveUntil<T>(
      view,
      predicate: (route) => false,
      settings: settings,
    );
  }

  bool get canPop => _navigator.canPop();

  void back<T>({T? result}) {
    if (_navigator.canPop()) {
      _navigator.pop<T>(result);
    }
  }

  void backTo(String routeName) {
    _navigator.popUntil(ModalRoute.withName(routeName));
  }

  void popUntil(RoutePredicate predicate) {
    _navigator.popUntil(predicate);
  }

  // Application-added: track a screen view alongside every named navigation.
  void logScreenView(String routeName) {
    AnalyticsService.instance.logScreenView(routeName);
  }
}
""";

void main() {
  late Directory root;
  const migration = NavigationCuboidPageRouteMigration();

  setUp(() {
    root = Directory.systemTemp.createTempSync('cuboid_nav_migration_test_');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  void writeRouter(String contents) {
    File('${root.path}/lib/app/app.router.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(contents);
  }

  void writeNavigationService(String contents) {
    File('${root.path}/lib/core/services/navigation_service.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(contents);
  }

  MigrationFileChange routerChangeFor(Directory projectRoot) {
    return migration
        .assess(projectRoot)
        .fileChanges
        .firstWhere((change) => change.path == 'lib/app/app.router.dart');
  }

  MigrationFileChange navChangeFor(Directory projectRoot) {
    return migration
        .assess(projectRoot)
        .fileChanges
        .firstWhere(
          (change) =>
              change.path == 'lib/core/services/navigation_service.dart',
        );
  }

  test('declares the 0.1.0 -> 0.2.0 architecture version boundary', () {
    expect(migration.sourceVersion, '0.1.0');
    expect(migration.targetVersion, '0.2.0');
    expect(migration.description, isNotEmpty);
  });

  group('lib/app/app.router.dart', () {
    test('plans MaterialPageRoute -> CuboidPageRoute for a legacy router', () {
      writeRouter(_legacyRouter);
      writeNavigationService(_legacyNavigationService);

      final routerChange = routerChangeFor(root);

      expect(routerChange.outcome, MigrationFileOutcome.modify);
      expect(routerChange.newContents, _currentRouter);
    });

    test(
      'preserves unrelated routes/imports added by cuboid create feature/view',
      () {
        writeRouter(_legacyRouter);
        writeNavigationService(_legacyNavigationService);

        final routerChange = routerChangeFor(root);

        expect(
          routerChange.newContents,
          contains("import 'package:my_app/features/home/ui/home_view.dart';"),
        );
        expect(
          routerChange.newContents,
          contains("static const homeView = '/home-view';"),
        );
        expect(
          routerChange.newContents,
          contains('Routes.homeView: (_) => const HomeView(),'),
        );
      },
    );

    test('preserves the settings: settings argument (route settings)', () {
      writeRouter(_legacyRouter);
      writeNavigationService(_legacyNavigationService);

      final routerChange = routerChangeFor(root);

      expect(
        routerChange.newContents,
        contains(
          'CuboidPageRoute<dynamic>(builder: builder, settings: settings)',
        ),
      );
    });

    test(
      'reports alreadyCurrent when the router already uses CuboidPageRoute',
      () {
        writeRouter(_currentRouter);
        writeNavigationService(_legacyNavigationService);

        expect(
          routerChangeFor(root).outcome,
          MigrationFileOutcome.alreadyCurrent,
        );
      },
    );

    test('reports missing when app.router.dart does not exist', () {
      writeNavigationService(_legacyNavigationService);

      expect(routerChangeFor(root).outcome, MigrationFileOutcome.missing);
    });

    test('reports unsafeToMigrate for a hand-rewritten onGenerateRoute', () {
      writeRouter('''
final Map<String, WidgetBuilder> appRoutes = {};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  // A developer rewrote this by hand, not constructing routes at all.
  return null;
}
''');
      writeNavigationService(_legacyNavigationService);

      final routerChange = routerChangeFor(root);

      expect(routerChange.outcome, MigrationFileOutcome.unsafeToMigrate);
      expect(routerChange.reason, isNotNull);
    });

    group('a real project-shaped router (extra routes and a custom branch)', () {
      test('migrates automatically -- both MaterialPageRoute call sites', () {
        writeRouter(_customizedLegacyRouter);
        writeNavigationService(_legacyNavigationService);

        final routerChange = routerChangeFor(root);

        expect(routerChange.outcome, MigrationFileOutcome.modify);
        expect(routerChange.newContents, isNot(contains('MaterialPageRoute')));
      });

      test('preserves the application-added conditional branch verbatim', () {
        writeRouter(_customizedLegacyRouter);
        writeNavigationService(_legacyNavigationService);

        final updated = routerChangeFor(root).newContents!;

        expect(
          updated,
          contains('if (settings.name == Routes.listingDetail) {'),
        );
        expect(updated, contains('final listingId = settings.arguments;'));
        expect(updated, contains('if (listingId is String) {'));
        expect(
          updated,
          contains(
            'builder: (_) => ListingDetailScreen(\n'
            '          listingId: listingId,\n'
            '          store: DemoSellerStore.instance,\n'
            '        ),',
          ),
        );
        expect(
          updated,
          contains(
            '  // Application-added: listingDetail needs a typed argument, '
            "so it isn't a\n"
            '  // plain WidgetBuilder entry in appRoutes.',
          ),
        );
      });

      test('converts both the branch and the canonical trailing route', () {
        writeRouter(_customizedLegacyRouter);
        writeNavigationService(_legacyNavigationService);

        final updated = routerChangeFor(root).newContents!;

        expect(
          updated,
          contains(
            'return CuboidPageRoute<dynamic>(\n'
            '        builder: (_) => ListingDetailScreen(',
          ),
        );
        expect(
          updated,
          contains(
            'return CuboidPageRoute<dynamic>(builder: builder, settings: settings);',
          ),
        );
      });

      test('preserves every unrelated route, import, and the Routes class', () {
        writeRouter(_customizedLegacyRouter);
        writeNavigationService(_legacyNavigationService);

        final updated = routerChangeFor(root).newContents!;

        expect(updated, contains('static const dashboard = \'/dashboard\';'));
        expect(updated, contains('static const account = \'/account\';'));
        expect(
          updated,
          contains(
            'Routes.account: (_) => AccountScreen(store: DemoSellerStore.instance),',
          ),
        );
        expect(
          updated,
          contains(
            "import 'package:my_app/features/seller/data/demo_seller_store.dart';",
          ),
        );
      });

      test('adds the cuboid_flutter import exactly once', () {
        writeRouter(_customizedLegacyRouter);
        writeNavigationService(_legacyNavigationService);

        final updated = routerChangeFor(root).newContents!;

        expect(
          "import 'package:cuboid_flutter/cuboid_flutter.dart';".allMatches(
            updated,
          ),
          hasLength(1),
        );
      });
    });
  });

  group('lib/core/services/navigation_service.dart', () {
    test('plans a full rewrite for the exact legacy shape', () {
      writeRouter(_legacyRouter);
      writeNavigationService(_legacyNavigationService);

      final navChange = navChangeFor(root);

      expect(navChange.outcome, MigrationFileOutcome.modify);
      expect(navChange.newContents, isNotNull);
    });

    test('preserves the existing NavigationService API and adds the new one', () {
      writeRouter(_legacyRouter);
      writeNavigationService(_legacyNavigationService);

      final updated = navChangeFor(root).newContents!;

      // Existing method signatures/generics/behavior are preserved exactly
      // -- navigateTo/replaceWith/back are never touched by this migration.
      expect(
        updated,
        contains(
          'Future<T?> navigateTo<T>(String routeName, {Object? arguments})',
        ),
      );
      expect(
        updated,
        contains(
          'Future<T?> replaceWith<T, TO>(String routeName, {Object? arguments})',
        ),
      );
      expect(updated, contains('void back<T>({T? result})'));
      expect(
        updated,
        contains('static final navigatorKey = GlobalKey<NavigatorState>();'),
      );
      // And new CuboidPageRoute-based capability is added, not swapped in.
      expect(updated, contains('CuboidPageRoute<T>'));
      expect(updated, contains('Future<T?> navigateToView<T>'));
      expect(updated, contains('Future<T?> replaceWithView<T, TO>'));
      expect(updated, contains('Future<T?> pushAndRemoveUntil<T>'));
      expect(updated, contains('Future<T?> clearStackAndShowView<T>'));
      expect(updated, contains('Future<T?> pushNamedAndRemoveUntil<T>'));
      expect(updated, contains('Future<T?> clearStackAndShow<T>'));
      expect(updated, contains('bool get canPop'));
      expect(updated, contains('void backTo(String routeName)'));
      expect(updated, contains('void popUntil(RoutePredicate predicate)'));
    });

    test(
      'is idempotent: re-assessing the migrated output reports alreadyCurrent',
      () {
        writeRouter(_legacyRouter);
        writeNavigationService(_legacyNavigationService);

        final migratedContents = navChangeFor(root).newContents!;
        writeNavigationService(migratedContents);

        expect(navChangeFor(root).outcome, MigrationFileOutcome.alreadyCurrent);
      },
    );

    test('reports missing when navigation_service.dart does not exist', () {
      writeRouter(_legacyRouter);

      expect(navChangeFor(root).outcome, MigrationFileOutcome.missing);
    });

    test(
      'reports unsafeToMigrate and leaves an unrecognizable file untouched',
      () {
        writeRouter(_legacyRouter);
        writeNavigationService('''
class NavigationService {
  // Hand-modified beyond recognition -- no navigatorKey, no navigateTo.
  void goHome() {}
}
''');

        final navChange = navChangeFor(root);

        expect(navChange.outcome, MigrationFileOutcome.unsafeToMigrate);
        expect(navChange.reason, isNotNull);
        expect(navChange.newContents, isNull);
      },
    );

    group(
      'a real project-shaped NavigationService (full API, still MaterialPageRoute)',
      () {
        test(
          'migrates automatically -- renames all MaterialPageRoute call sites',
          () {
            writeRouter(_legacyRouter);
            writeNavigationService(_customizedNavigationServiceWithFullApi);

            final navChange = navChangeFor(root);

            expect(navChange.outcome, MigrationFileOutcome.modify);
            final updated = navChange.newContents!;
            expect('CuboidPageRoute<T>'.allMatches(updated), hasLength(3));
            expect(updated, isNot(contains('MaterialPageRoute<T>')));
          },
        );

        test('does not insert methods that already exist', () {
          writeRouter(_legacyRouter);
          writeNavigationService(_customizedNavigationServiceWithFullApi);

          final updated = navChangeFor(root).newContents!;

          // Exactly one definition of each -- no duplicate insertion.
          expect(
            'Future<T?> navigateToView<T>'.allMatches(updated),
            hasLength(1),
          );
          expect('bool get canPop'.allMatches(updated), hasLength(1));
        });

        test('preserves the application-added custom method byte-for-byte', () {
          writeRouter(_legacyRouter);
          writeNavigationService(_customizedNavigationServiceWithFullApi);

          final updated = navChangeFor(root).newContents!;

          expect(
            updated,
            contains(
              '  // Application-added: track a screen view alongside every '
              'named navigation.\n'
              '  void logScreenView(String routeName) {\n'
              '    AnalyticsService.instance.logScreenView(routeName);\n'
              '  }',
            ),
          );
        });

        test('preserves the application-added custom import', () {
          writeRouter(_legacyRouter);
          writeNavigationService(_customizedNavigationServiceWithFullApi);

          final updated = navChangeFor(root).newContents!;

          expect(
            updated,
            contains(
              "import 'package:my_app/core/analytics/analytics_service.dart';",
            ),
          );
        });

        test(
          'preserves a comment mentioning MaterialPageRoute (Dartdoc cross-reference)',
          () {
            writeRouter(_legacyRouter);
            writeNavigationService(_customizedNavigationServiceWithFullApi);

            final updated = navChangeFor(root).newContents!;

            expect(
              updated,
              contains(
                '/// [MaterialPageRoute], for views that don\'t need a '
                'registered named route.',
              ),
            );
          },
        );

        test('adds the cuboid_flutter import exactly once', () {
          writeRouter(_legacyRouter);
          writeNavigationService(_customizedNavigationServiceWithFullApi);

          final updated = navChangeFor(root).newContents!;

          expect(
            "import 'package:cuboid_flutter/cuboid_flutter.dart';".allMatches(
              updated,
            ),
            hasLength(1),
          );
        });

        test('produces valid, re-assessable output (idempotent)', () {
          writeRouter(_legacyRouter);
          writeNavigationService(_customizedNavigationServiceWithFullApi);

          final migrated = navChangeFor(root).newContents!;
          writeNavigationService(migrated);

          expect(
            navChangeFor(root).outcome,
            MigrationFileOutcome.alreadyCurrent,
          );
        });
      },
    );

    test('a project missing only some 0.2.0 methods gets just those added', () {
      writeRouter(_legacyRouter);
      writeNavigationService("""
import 'package:flutter/material.dart';

class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError('NavigationService used before a Navigator exists.');
    }
    return state;
  }

  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return _navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  Future<T?> replaceWith<T, TO>(String routeName, {Object? arguments}) {
    return _navigator.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
    );
  }

  void back<T>({T? result}) {
    if (_navigator.canPop()) {
      _navigator.pop<T>(result);
    }
  }

  bool get canPop => _navigator.canPop();

  // Application-added, hand-written before any Cuboid migration existed.
  void backTo(String routeName) {
    _navigator.popUntil(ModalRoute.withName(routeName));
  }
}
""");

      final updated = navChangeFor(root).newContents!;

      // Already present -- kept exactly as the developer wrote them, not
      // replaced with the canonical insertion text.
      expect(
        updated,
        contains(
          '  // Application-added, hand-written before any Cuboid '
          'migration existed.\n'
          '  void backTo(String routeName) {',
        ),
      );
      expect('bool get canPop'.allMatches(updated), hasLength(1));
      // Missing ones are added.
      expect(updated, contains('Future<T?> navigateToView<T>'));
      expect(updated, contains('void popUntil(RoutePredicate predicate)'));
    });
  });

  test('assess never writes to disk', () {
    writeRouter(_customizedLegacyRouter);
    writeNavigationService(_customizedNavigationServiceWithFullApi);
    final routerBefore = File(
      '${root.path}/lib/app/app.router.dart',
    ).readAsStringSync();
    final navBefore = File(
      '${root.path}/lib/core/services/navigation_service.dart',
    ).readAsStringSync();

    migration.assess(root);

    expect(
      File('${root.path}/lib/app/app.router.dart').readAsStringSync(),
      routerBefore,
    );
    expect(
      File(
        '${root.path}/lib/core/services/navigation_service.dart',
      ).readAsStringSync(),
      navBefore,
    );
  });
}
