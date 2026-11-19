import 'dart:io';

import 'package:cuboid/src/architecture/architecture_metadata.dart';
import 'package:cuboid/src/architecture/architecture_version.dart'
    show currentArchitectureVersion;
import 'package:cuboid/src/doctor/doctor.dart';
import 'package:cuboid/src/migrate/migrations/navigation_cuboid_page_route_migration.dart';
import 'package:test/test.dart';

const _flutterPubspec =
    'name: my_app\ndependencies:\n  flutter:\n    sdk: flutter\n';

const _legacyRouter = '''
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}
''';

const _currentRouter = '''
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return CuboidPageRoute<dynamic>(builder: builder, settings: settings);
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

void main() {
  late Directory root;
  // Pinned to just the navigation migration/0.2.0 -- not the real, growing
  // migration registry/[currentArchitectureVersion] -- so this file's
  // fixtures (which only cover what that one migration touches) stay exact
  // unit tests of generic doctor diagnosis, independent of how many
  // migrations a later Cuboid version adds. `media_tools_migration_test.dart`
  // covers doctor's behavior against the real default registry.
  const service = DoctorService(
    migrations: [NavigationCuboidPageRouteMigration()],
    latestVersion: '0.2.0',
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('cuboid_doctor_test_');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  void writePubspec([String contents = _flutterPubspec]) {
    File('${root.path}/pubspec.yaml').writeAsStringSync(contents);
  }

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

  test('a directory with no pubspec.yaml is not a Cuboid project', () {
    final report = service.diagnose(DoctorInput(projectRoot: root));

    expect(report.isFlutterProject, isFalse);
    expect(report.isCuboidProject, isFalse);
    expect(
      renderDoctorReport(report),
      'This directory does not appear to be a Cuboid project.',
    );
  });

  test('a Dart-only (non-Flutter) pubspec.yaml is not a Cuboid project', () {
    writePubspec('name: my_pkg\nenvironment:\n  sdk: ^3.0.0\n');

    final report = service.diagnose(DoctorInput(projectRoot: root));

    expect(report.isFlutterProject, isFalse);
    expect(report.isCuboidProject, isFalse);
    expect(
      renderDoctorReport(report),
      'This directory does not appear to be a Cuboid project.',
    );
  });

  test(
    'a Flutter project with no Cuboid infrastructure is not a Cuboid project',
    () {
      writePubspec();

      final report = service.diagnose(DoctorInput(projectRoot: root));

      expect(report.isFlutterProject, isTrue);
      expect(report.isCuboidProject, isFalse);
      expect(
        renderDoctorReport(report),
        'This directory does not appear to be a Cuboid project.',
      );
    },
  );

  test('a project already on the current architecture is up to date', () {
    writePubspec();
    writeRouter(_currentRouter);

    // Not the pinned `service` above -- an inferred current router always
    // infers as the real, live `currentArchitectureVersion` (see
    // `architecture/architecture_metadata.dart`), so this test (about
    // `isUpToDate` detection via inference, not about any specific
    // migration) uses a `DoctorService` with the real defaults rather than
    // asserting against a version pinned out of step with it.
    const realDefaultService = DoctorService();
    final report = realDefaultService.diagnose(DoctorInput(projectRoot: root));

    expect(report.isCuboidProject, isTrue);
    expect(report.currentVersion, currentArchitectureVersion);
    expect(report.versionSource, ArchitectureVersionSource.inferred);
    expect(report.isUpToDate, isTrue);
    expect(report.hasPendingMigrations, isFalse);

    final rendered = renderDoctorReport(report);
    expect(rendered, contains('Cuboid project: yes'));
    expect(rendered, contains('✓ Project is up to date.'));
    expect(rendered, contains('✓ No migrations required.'));
  });

  test('a project declared current via .cuboid/project.json is up to date', () {
    writePubspec();
    writeRouter(_currentRouter);
    writeArchitectureMetadata(
      root,
      const ArchitectureMetadata(architectureVersion: '0.2.0'),
    );

    final report = service.diagnose(DoctorInput(projectRoot: root));

    expect(report.versionSource, ArchitectureVersionSource.metadata);
    expect(report.isUpToDate, isTrue);
  });

  test('an outdated project reports the available navigation migration', () {
    writePubspec();
    writeRouter(_legacyRouter);
    writeNavigationService(_legacyNavigationService);

    final report = service.diagnose(DoctorInput(projectRoot: root));

    expect(report.currentVersion, '0.1.0');
    expect(report.isUpToDate, isFalse);
    expect(report.hasPendingMigrations, isTrue);
    expect(report.hasSuspiciousFiles, isFalse);
    expect(
      report.assessments.single.changes.map((change) => change.path).toSet(),
      {'lib/app/app.router.dart', 'lib/core/services/navigation_service.dart'},
    );

    final rendered = renderDoctorReport(report);
    expect(rendered, contains('Current architecture: 0.1.x'));
    expect(rendered, contains('Latest compatible architecture: 0.2.x'));
    expect(rendered, contains('Migration status:'));
    expect(rendered, contains('!'));
    expect(rendered, contains('Run `cuboid upgrade` to migrate this project.'));
  });

  test('doctor does not modify any files', () {
    writePubspec();
    writeRouter(_legacyRouter);
    writeNavigationService(_legacyNavigationService);
    final routerBefore = File(
      '${root.path}/lib/app/app.router.dart',
    ).readAsStringSync();
    final navBefore = File(
      '${root.path}/lib/core/services/navigation_service.dart',
    ).readAsStringSync();

    service.diagnose(DoctorInput(projectRoot: root));

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
    expect(File('${root.path}/.cuboid/project.json').existsSync(), isFalse);
  });

  test(
    'a project on an unknown/future architecture version is reported distinctly',
    () {
      writePubspec();
      writeRouter(_currentRouter);
      writeArchitectureMetadata(
        root,
        const ArchitectureMetadata(architectureVersion: '9.9.9'),
      );

      final report = service.diagnose(DoctorInput(projectRoot: root));

      expect(report.isCuboidProject, isTrue);
      expect(report.isKnownVersion, isFalse);
      expect(report.isUpToDate, isFalse);

      final rendered = renderDoctorReport(report);
      expect(rendered, contains('Current architecture: 9.9.9 (not recognized'));
      expect(rendered, contains('not recognized by this Cuboid CLI'));
      expect(rendered, isNot(contains('Run `cuboid upgrade`')));
    },
  );

  test(
    'flags navigation_service.dart as suspicious when it matches neither shape',
    () {
      writePubspec();
      writeRouter(_legacyRouter);
      writeNavigationService(
        'class NavigationService {\n  void goHome() {}\n}\n',
      );

      final report = service.diagnose(DoctorInput(projectRoot: root));

      expect(report.hasSuspiciousFiles, isTrue);
      expect(
        report.suspiciousFiles.single.path,
        'lib/core/services/navigation_service.dart',
      );

      final rendered = renderDoctorReport(report);
      expect(
        rendered,
        contains(
          'lib/core/services/navigation_service.dart could not be automatically '
          'assessed',
        ),
      );
    },
  );
}
