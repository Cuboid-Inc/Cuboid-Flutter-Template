import 'dart:io';

import 'package:cuboid/src/architecture/architecture_metadata.dart';
import 'package:cuboid/src/architecture/architecture_version.dart';
import 'package:cuboid/src/migrate/migration.dart';
import 'package:cuboid/src/migrate/migration_registry.dart';
import 'package:cuboid/src/migrate/migrations/navigation_cuboid_page_route_migration.dart';
import 'package:cuboid/src/migrate/upgrade.dart';
import 'package:test/test.dart';

const _flutterPubspec =
    'name: my_app\ndependencies:\n  flutter:\n    sdk: flutter\n';

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

const _homeViewFeatureFile = '''
import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''';

void main() {
  late Directory root;
  late Directory backupsRoot;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cuboid_upgrade_test_');
    backupsRoot = Directory.systemTemp.createTempSync(
      'cuboid_upgrade_test_backups_',
    );
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    backupsRoot.deleteSync(recursive: true);
  });

  // Every test builds its [UpgradeService] through this helper -- never the
  // constructor directly -- so backups always land under [backupsRoot]
  // rather than a real developer's platform cache directory (see
  // `migrate/backup_location.dart`). One dedicated CLI-level test covers the
  // real, un-injected default separately.
  UpgradeService buildService({
    List<Migration> migrations = migrationRegistry,
    String latestVersion = currentArchitectureVersion,
    UpgradeProcessRunner? processRunner,
    DateTime Function()? now,
  }) {
    return UpgradeService(
      migrations: migrations,
      latestVersion: latestVersion,
      processRunner: processRunner,
      now: now,
      backupsRootDirectory: backupsRoot,
    );
  }

  void writeLegacyProject() {
    File('${root.path}/pubspec.yaml').writeAsStringSync(_flutterPubspec);
    File('${root.path}/lib/app/app.router.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_legacyRouter);
    File('${root.path}/lib/core/services/navigation_service.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_legacyNavigationService);
    File('${root.path}/lib/features/home/ui/home_view.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_homeViewFeatureFile);
  }

  group('plan', () {
    test('reports notAProject for a directory with no pubspec.yaml', () {
      final service = buildService();
      final result = service.plan(UpgradeInput(projectRoot: root));
      expect(result.outcome, UpgradePlanOutcome.notAProject);
    });

    test('reports unknownVersion for an unrecognized architecture version', () {
      File('${root.path}/pubspec.yaml').writeAsStringSync(_flutterPubspec);
      File('${root.path}/lib/app/app.router.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(_legacyRouter);
      writeArchitectureMetadata(
        root,
        const ArchitectureMetadata(architectureVersion: '9.9.9'),
      );

      final service = buildService();
      final result = service.plan(UpgradeInput(projectRoot: root));
      expect(result.outcome, UpgradePlanOutcome.unknownVersion);
    });

    test('reports alreadyUpToDate for a current project', () {
      File('${root.path}/pubspec.yaml').writeAsStringSync(_flutterPubspec);
      File('${root.path}/lib/app/app.router.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          _legacyRouter.replaceAll('MaterialPageRoute', 'CuboidPageRoute'),
        );

      final service = buildService();
      final result = service.plan(UpgradeInput(projectRoot: root));
      expect(result.outcome, UpgradePlanOutcome.alreadyUpToDate);
    });

    test('is ready with a plan for a legacy project, and touches no files', () {
      writeLegacyProject();
      final beforeRouter = File(
        '${root.path}/lib/app/app.router.dart',
      ).readAsStringSync();
      final beforeNav = File(
        '${root.path}/lib/core/services/navigation_service.dart',
      ).readAsStringSync();

      final service = buildService();
      final result = service.plan(UpgradeInput(projectRoot: root));

      expect(result.outcome, UpgradePlanOutcome.ready);
      expect(result.plan!.fromVersion, '0.1.0');
      expect(result.plan!.toVersion, '0.2.0');
      expect(result.plan!.hasChanges, isTrue);
      expect(result.plan!.changes.map((change) => change.path).toSet(), {
        'lib/app/app.router.dart',
        'lib/core/services/navigation_service.dart',
      });
      expect(
        File('${root.path}/lib/app/app.router.dart').readAsStringSync(),
        beforeRouter,
      );
      expect(
        File(
          '${root.path}/lib/core/services/navigation_service.dart',
        ).readAsStringSync(),
        beforeNav,
      );
      expect(File('${root.path}/.cuboid/project.json').existsSync(), isFalse);
    });
  });

  group('apply', () {
    test('migrates a legacy project end to end (0.1.0 -> 0.2.0)', () async {
      writeLegacyProject();
      final service = buildService();
      final planResult = service.plan(UpgradeInput(projectRoot: root));

      final applyResult = await service.apply(planResult, verify: false);

      expect(applyResult.outcome, UpgradeApplyOutcome.completed);
      expect(applyResult.metadataUpdated, isTrue);
      expect(applyResult.toVersion, '0.2.0');
      expect(applyResult.modifiedFiles.toSet(), {
        'lib/app/app.router.dart',
        'lib/core/services/navigation_service.dart',
      });

      final router = File(
        '${root.path}/lib/app/app.router.dart',
      ).readAsStringSync();
      final navigationService = File(
        '${root.path}/lib/core/services/navigation_service.dart',
      ).readAsStringSync();
      expect(
        router,
        contains(
          'CuboidPageRoute<dynamic>(builder: builder, settings: settings)',
        ),
      );
      expect(router, isNot(contains('MaterialPageRoute')));
      expect(navigationService, contains('CuboidPageRoute<T>'));
      expect(navigationService, contains('Future<T?> navigateToView<T>'));
      // navigateTo predates this migration and is never touched -- its
      // exact pre-existing implementation survives untouched.
      expect(
        navigationService,
        contains(
          'Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {\n'
          '    return _navigator.pushNamed<T>(routeName, arguments: arguments);\n'
          '  }',
        ),
      );

      final metadata = readArchitectureMetadata(root)!;
      expect(metadata.architectureVersion, '0.2.0');
    });

    test('leaves feature/application code completely untouched', () async {
      writeLegacyProject();
      final service = buildService();
      final planResult = service.plan(UpgradeInput(projectRoot: root));

      await service.apply(planResult, verify: false);

      expect(
        File(
          '${root.path}/lib/features/home/ui/home_view.dart',
        ).readAsStringSync(),
        _homeViewFeatureFile,
      );
    });

    test(
      'preserves route settings, generic types, and the existing API surface',
      () async {
        writeLegacyProject();
        final service = buildService();
        final planResult = service.plan(UpgradeInput(projectRoot: root));

        await service.apply(planResult, verify: false);

        final router = File(
          '${root.path}/lib/app/app.router.dart',
        ).readAsStringSync();
        final navigationService = File(
          '${root.path}/lib/core/services/navigation_service.dart',
        ).readAsStringSync();

        // Route settings preserved.
        expect(router, contains('settings: settings'));
        expect(router, contains("static const homeView = '/home-view';"));
        expect(router, contains('Routes.homeView: (_) => const HomeView(),'));
        // Generic types preserved.
        expect(
          router,
          contains('Route<dynamic>? onGenerateRoute(RouteSettings settings)'),
        );
        expect(navigationService, contains('Future<T?> navigateTo<T>'));
        expect(navigationService, contains('Future<T?> replaceWith<T, TO>'));
        // Existing NavigationService API preserved.
        expect(navigationService, contains('void back<T>({T? result})'));
      },
    );

    test('preserves a prior generatedByCuboidVersion in metadata', () async {
      writeLegacyProject();
      writeArchitectureMetadata(
        root,
        const ArchitectureMetadata(
          architectureVersion: '0.1.0',
          generatedByCuboidVersion: '0.0.9-test',
        ),
      );
      final service = buildService();
      final planResult = service.plan(UpgradeInput(projectRoot: root));

      await service.apply(planResult, verify: false);

      final metadata = readArchitectureMetadata(root)!;
      expect(metadata.architectureVersion, '0.2.0');
      expect(metadata.generatedByCuboidVersion, '0.0.9-test');
    });

    test('writes a backup snapshot outside the project before modifying '
        'anything, and never creates .cuboid/backups inside it', () async {
      writeLegacyProject();
      final service = buildService(
        now: () => DateTime.utc(2026, 8, 24, 10, 0, 0),
      );
      final planResult = service.plan(UpgradeInput(projectRoot: root));

      final applyResult = await service.apply(planResult, verify: false);

      expect(applyResult.backupDirectoryPath, isNotNull);
      // The backup lives under the injected backups root, not the project.
      expect(applyResult.backupDirectoryPath, startsWith(backupsRoot.path));
      expect(applyResult.backupDirectoryPath!.startsWith(root.path), isFalse);

      final backupRouter = File(
        '${applyResult.backupDirectoryPath}/lib/app/app.router.dart',
      );
      final backupNav = File(
        '${applyResult.backupDirectoryPath}/lib/core/services/navigation_service.dart',
      );
      expect(backupRouter.readAsStringSync(), _legacyRouter);
      expect(backupNav.readAsStringSync(), _legacyNavigationService);

      expect(Directory('${root.path}/.cuboid/backups').existsSync(), isFalse);
    });

    test('a pre-existing .cuboid/backups/ directory left behind by an older '
        'Cuboid CLI is left completely untouched by a fresh apply', () async {
      writeLegacyProject();
      final leftoverBackup = File(
        '${root.path}/.cuboid/backups/2026-01-01T00-00-00-000Z/lib/app/app.router.dart',
      )..createSync(recursive: true);
      leftoverBackup.writeAsStringSync('old CLI backup, never touched');

      final service = buildService();
      final planResult = service.plan(UpgradeInput(projectRoot: root));
      await service.apply(planResult, verify: false);

      expect(
        leftoverBackup.readAsStringSync(),
        'old CLI backup, never touched',
      );
    });

    test('an already up-to-date project is left untouched by plan alone', () {
      File('${root.path}/pubspec.yaml').writeAsStringSync(_flutterPubspec);
      File('${root.path}/lib/app/app.router.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          _legacyRouter.replaceAll('MaterialPageRoute', 'CuboidPageRoute'),
        );

      final service = buildService();
      final result = service.plan(UpgradeInput(projectRoot: root));

      expect(result.outcome, UpgradePlanOutcome.alreadyUpToDate);
      expect(File('${root.path}/.cuboid/project.json').existsSync(), isFalse);
    });

    test(
      'leaves an unsafe file untouched, migrates what it safely can, and does '
      'not advance the recorded architecture version',
      () async {
        File('${root.path}/pubspec.yaml').writeAsStringSync(_flutterPubspec);
        File('${root.path}/lib/app/app.router.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(_legacyRouter);
        File('${root.path}/lib/core/services/navigation_service.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(
            'class NavigationService {\n  void goHome() {}\n}\n',
          );

        final service = buildService();
        final planResult = service.plan(UpgradeInput(projectRoot: root));
        expect(planResult.plan!.hasUnsafeFiles, isTrue);

        final applyResult = await service.apply(planResult, verify: false);

        expect(applyResult.outcome, UpgradeApplyOutcome.completed);
        expect(applyResult.modifiedFiles, ['lib/app/app.router.dart']);
        expect(applyResult.metadataUpdated, isFalse);
        expect(
          applyResult.blockedFiles.single.path,
          'lib/core/services/navigation_service.dart',
        );

        final router = File(
          '${root.path}/lib/app/app.router.dart',
        ).readAsStringSync();
        expect(router, contains('CuboidPageRoute'));
        final navigationService = File(
          '${root.path}/lib/core/services/navigation_service.dart',
        ).readAsStringSync();
        expect(
          navigationService,
          'class NavigationService {\n  void goHome() {}\n}\n',
        );
        expect(File('${root.path}/.cuboid/project.json').existsSync(), isFalse);
      },
    );

    test(
      'reports verification results from an injected process runner',
      () async {
        writeLegacyProject();
        final commands = <String>[];
        final service = buildService(
          processRunner:
              (executable, arguments, {required workingDirectory}) async {
                commands.add([executable, ...arguments].join(' '));
                return ProcessResult(0, 0, 'ok', '');
              },
        );
        final planResult = service.plan(UpgradeInput(projectRoot: root));

        final applyResult = await service.apply(planResult, verify: true);

        expect(commands, ['flutter analyze', 'flutter test']);
        expect(applyResult.verification, isNotNull);
        expect(applyResult.verification!.ran, isTrue);
        expect(applyResult.verification!.passed, isTrue);
      },
    );

    test(
      'reports a failing flutter analyze/test without pretending success',
      () async {
        writeLegacyProject();
        final service = buildService(
          processRunner:
              (executable, arguments, {required workingDirectory}) async {
                if (arguments.contains('analyze')) {
                  return ProcessResult(0, 1, '', 'error: something is wrong');
                }
                return ProcessResult(0, 0, 'ok', '');
              },
        );
        final planResult = service.plan(UpgradeInput(projectRoot: root));

        final applyResult = await service.apply(planResult, verify: true);

        // The migration itself still completed -- verification is a distinct,
        // separately reported concern.
        expect(applyResult.outcome, UpgradeApplyOutcome.completed);
        expect(applyResult.metadataUpdated, isTrue);
        expect(applyResult.verification!.passed, isFalse);
        expect(applyResult.verification!.analyzePassed, isFalse);
        expect(
          renderUpgradeApplyResult(applyResult),
          contains('✗ Project verification failed.'),
        );
      },
    );

    test('skipping verification is reported, not silently ignored', () async {
      writeLegacyProject();
      final service = buildService();
      final planResult = service.plan(UpgradeInput(projectRoot: root));

      final applyResult = await service.apply(planResult, verify: false);

      expect(applyResult.verification, isNull);
      expect(
        renderUpgradeApplyResult(applyResult),
        isNot(contains('verification')),
      );
    });
  });

  group('sequential migrations', () {
    test(
      'a two-hop chain applies both migrations and lands on the final version',
      () async {
        File('${root.path}/pubspec.yaml').writeAsStringSync(_flutterPubspec);
        File('${root.path}/lib/app/app.router.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('placeholder so this looks like a project\n');
        File('${root.path}/a.txt').writeAsStringSync('A-original');
        File('${root.path}/b.txt').writeAsStringSync('B-original');
        writeArchitectureMetadata(
          root,
          const ArchitectureMetadata(architectureVersion: 'test.0'),
        );

        final service = buildService(
          migrations: const [_FakeMigrationA(), _FakeMigrationB()],
          latestVersion: 'test.2',
        );
        final planResult = service.plan(UpgradeInput(projectRoot: root));
        expect(planResult.outcome, UpgradePlanOutcome.ready);
        expect(planResult.plan!.chain.map((m) => m.sourceVersion), [
          'test.0',
          'test.1',
        ]);

        final applyResult = await service.apply(planResult, verify: false);

        expect(applyResult.outcome, UpgradeApplyOutcome.completed);
        expect(applyResult.toVersion, 'test.2');
        expect(File('${root.path}/a.txt').readAsStringSync(), 'A-migrated');
        expect(File('${root.path}/b.txt').readAsStringSync(), 'B-migrated');
        expect(readArchitectureMetadata(root)!.architectureVersion, 'test.2');
      },
    );

    test(
      'a failure partway through a multi-migration chain rolls back every '
      'earlier change -- no partially migrated project is left behind',
      () async {
        File('${root.path}/pubspec.yaml').writeAsStringSync(_flutterPubspec);
        File('${root.path}/lib/app/app.router.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('placeholder so this looks like a project\n');
        File('${root.path}/a.txt').writeAsStringSync('A-original');
        writeArchitectureMetadata(
          root,
          const ArchitectureMetadata(architectureVersion: 'test.0'),
        );

        final service = buildService(
          migrations: const [
            _FakeMigrationA(),
            _FakeMigrationThatFailsToWrite(),
          ],
          latestVersion: 'test.2',
        );
        final planResult = service.plan(UpgradeInput(projectRoot: root));

        final applyResult = await service.apply(planResult, verify: false);

        expect(applyResult.outcome, UpgradeApplyOutcome.failed);
        expect(applyResult.error, isNotNull);
        // Migration A's change (applied first) must be rolled back.
        expect(File('${root.path}/a.txt').readAsStringSync(), 'A-original');
        // The architecture version must not have been advanced.
        expect(readArchitectureMetadata(root)!.architectureVersion, 'test.0');
      },
    );
  });

  test(
    'the real NavigationCuboidPageRouteMigration chains from legacyArchitectureVersion',
    () {
      final service = buildService();
      expect(
        service.migrations,
        contains(isA<NavigationCuboidPageRouteMigration>()),
      );
    },
  );
}

/// A migration touching a single, real file (`a.txt`) -- used only to
/// exercise [UpgradeService]'s sequential chain application and rollback,
/// independent of the real [NavigationCuboidPageRouteMigration].
class _FakeMigrationA extends Migration {
  const _FakeMigrationA();

  @override
  String get sourceVersion => 'test.0';

  @override
  String get targetVersion => 'test.1';

  @override
  String get description => 'Fake migration A';

  @override
  MigrationAssessment assess(Directory projectRoot) {
    final file = File('${projectRoot.path}/a.txt');
    final outcome = file.existsSync() && file.readAsStringSync() == 'A-original'
        ? MigrationFileOutcome.modify
        : MigrationFileOutcome.alreadyCurrent;
    return MigrationAssessment(
      migration: this,
      fileChanges: [
        MigrationFileChange(
          path: 'a.txt',
          outcome: outcome,
          newContents: outcome == MigrationFileOutcome.modify
              ? 'A-migrated'
              : null,
        ),
      ],
    );
  }
}

class _FakeMigrationB extends Migration {
  const _FakeMigrationB();

  @override
  String get sourceVersion => 'test.1';

  @override
  String get targetVersion => 'test.2';

  @override
  String get description => 'Fake migration B';

  @override
  MigrationAssessment assess(Directory projectRoot) {
    final file = File('${projectRoot.path}/b.txt');
    final outcome = file.existsSync() && file.readAsStringSync() == 'B-original'
        ? MigrationFileOutcome.modify
        : MigrationFileOutcome.alreadyCurrent;
    return MigrationAssessment(
      migration: this,
      fileChanges: [
        MigrationFileChange(
          path: 'b.txt',
          outcome: outcome,
          newContents: outcome == MigrationFileOutcome.modify
              ? 'B-migrated'
              : null,
        ),
      ],
    );
  }
}

/// A migration whose planned write always fails (its target's parent
/// directory does not exist and is never created), used to deterministically
/// force [UpgradeService.apply] down its rollback path.
class _FakeMigrationThatFailsToWrite extends Migration {
  const _FakeMigrationThatFailsToWrite();

  @override
  String get sourceVersion => 'test.1';

  @override
  String get targetVersion => 'test.2';

  @override
  String get description => 'Fake migration that fails to write';

  @override
  MigrationAssessment assess(Directory projectRoot) {
    return MigrationAssessment(
      migration: this,
      fileChanges: const [
        MigrationFileChange(
          path: 'no_such_directory/unwritable.txt',
          outcome: MigrationFileOutcome.modify,
          newContents: 'will never be written',
        ),
      ],
    );
  }
}
