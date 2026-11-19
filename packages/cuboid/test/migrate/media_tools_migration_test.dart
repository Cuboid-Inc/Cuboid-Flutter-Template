import 'dart:io';

import 'package:cuboid/src/architecture/architecture_metadata.dart';
import 'package:cuboid/src/architecture/architecture_version.dart';
import 'package:cuboid/src/migrate/migration.dart';
import 'package:cuboid/src/migrate/migration_registry.dart';
import 'package:cuboid/src/migrate/migrations/media_tools_migration.dart';
import 'package:cuboid/src/migrate/upgrade.dart';
import 'package:cuboid/src/templates/flutter_app/bundled_template.dart';
import 'package:test/test.dart';

const _newFilePaths = [
  'lib/app/app.snackbars.dart',
  'lib/core/services/message_service.dart',
  'lib/core/services/media_utils.dart',
  'lib/shared/widgets/app_image_cropper.dart',
];

void main() {
  late Directory root;
  late Directory backupsRoot;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cuboid_media_tools_test_');
    backupsRoot = Directory.systemTemp.createTempSync(
      'cuboid_media_tools_test_backups_',
    );
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    backupsRoot.deleteSync(recursive: true);
  });

  // Same helper pattern as `upgrade_test.dart` -- always routes backups
  // under [backupsRoot], never a real developer's platform cache directory.
  UpgradeService buildService({
    List<Migration> migrations = const [MediaToolsMigration()],
    String latestVersion = '0.3.0',
    UpgradeProcessRunner? processRunner,
  }) {
    return UpgradeService(
      migrations: migrations,
      latestVersion: latestVersion,
      processRunner: processRunner,
      backupsRootDirectory: backupsRoot,
    );
  }

  /// A project already on `0.2.0` (post-navigation-migration) with none of
  /// the four new files yet -- exactly what `MediaToolsMigration` exists to
  /// carry forward to `0.3.0`.
  void writeReadyProject({
    String architectureVersion = '0.2.0',
    String pubspec =
        'name: my_app\ndependencies:\n  flutter:\n    sdk: flutter\n',
  }) {
    File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
    File('${root.path}/lib/app/app.locator.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:get_it/get_it.dart';
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // @cuboid-service
}
''');
    File('${root.path}/lib/app/app_root.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:my_app/core/services/navigation_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
    );
  }
}
''');
    writeArchitectureMetadata(
      root,
      ArchitectureMetadata(architectureVersion: architectureVersion),
    );
  }

  bool fileExists(String relativePath) =>
      File('${root.path}/$relativePath').existsSync();

  String readFile(String relativePath) =>
      File('${root.path}/$relativePath').readAsStringSync();

  group('assess', () {
    test('plans to create all four new files for a project missing them', () {
      writeReadyProject();
      final service = buildService();

      final result = service.plan(UpgradeInput(projectRoot: root));

      expect(result.outcome, UpgradePlanOutcome.ready);
      final createdPaths = result.plan!.changes
          .where((change) => change.outcome == MigrationFileOutcome.create)
          .map((change) => change.path)
          .toSet();
      expect(createdPaths, _newFilePaths.toSet());
      expect(result.plan!.skippedFiles, isEmpty);
      expect(result.plan!.unsafeFiles, isEmpty);
    });

    test(
      'a project already on the latest version reports nothing to migrate',
      () {
        writeReadyProject(architectureVersion: '0.3.0');
        final service = buildService();

        final result = service.plan(UpgradeInput(projectRoot: root));

        expect(result.outcome, UpgradePlanOutcome.alreadyUpToDate);
      },
    );

    test('reports skippedExisting for a file that already exists, and '
        'never includes it in changes', () {
      writeReadyProject();
      File('${root.path}/lib/core/services/message_service.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// hand-customized, keep me as-is\n');

      final service = buildService();
      final result = service.plan(UpgradeInput(projectRoot: root));

      final allChanges = [
        for (final assessment in result.plan!.assessments)
          ...assessment.fileChanges,
      ];
      final messageServiceChange = allChanges.firstWhere(
        (change) => change.path == 'lib/core/services/message_service.dart',
      );
      expect(
        messageServiceChange.outcome,
        MigrationFileOutcome.skippedExisting,
      );
      expect(
        result.plan!.changes.map((change) => change.path),
        isNot(contains('lib/core/services/message_service.dart')),
      );
    });
  });

  group('apply', () {
    test('writes all four new files with the bundled template\'s exact '
        'contents, and registers MessageService/wires app_root.dart/adds '
        'dependencies', () async {
      writeReadyProject();
      final service = buildService();
      final plan = service.plan(UpgradeInput(projectRoot: root));

      final applyResult = await service.apply(plan, verify: false);

      expect(applyResult.outcome, UpgradeApplyOutcome.completed);
      expect(applyResult.addedFiles.toSet(), _newFilePaths.toSet());
      expect(applyResult.metadataUpdated, isTrue);
      expect(readArchitectureMetadata(root)!.architectureVersion, '0.3.0');

      final bundled = loadBundledTemplatePayload();
      for (final path in _newFilePaths) {
        expect(fileExists(path), isTrue);
        expect(readFile(path), bundled.utf8ContentsOf(path));
      }

      expect(
        readFile('lib/app/app.locator.dart'),
        contains('locator.registerLazySingleton<MessageService>'),
      );
      expect(
        readFile('lib/app/app_root.dart'),
        contains('scaffoldMessengerKey: MessageService.scaffoldMessengerKey'),
      );
      final pubspec = readFile('pubspec.yaml');
      expect(pubspec, contains('image_picker:'));
      expect(pubspec, contains('crop_your_image:'));
    });

    test('never overwrites a file that already exists, even with different '
        'content than the bundled template', () async {
      writeReadyProject();
      const customContents = '// hand-customized, keep me as-is\n';
      File('${root.path}/lib/core/services/media_utils.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(customContents);

      final service = buildService();
      final plan = service.plan(UpgradeInput(projectRoot: root));
      final applyResult = await service.apply(plan, verify: false);

      expect(applyResult.outcome, UpgradeApplyOutcome.completed);
      expect(
        applyResult.skippedFiles.map((change) => change.path),
        contains('lib/core/services/media_utils.dart'),
      );
      expect(readFile('lib/core/services/media_utils.dart'), customContents);
      // The other three untouched new files are still added.
      expect(fileExists('lib/app/app.snackbars.dart'), isTrue);
      expect(fileExists('lib/core/services/message_service.dart'), isTrue);
      expect(fileExists('lib/shared/widgets/app_image_cropper.dart'), isTrue);
      // A safe skip is not a block: metadata still advances.
      expect(applyResult.metadataUpdated, isTrue);
      expect(readArchitectureMetadata(root)!.architectureVersion, '0.3.0');
    });

    test('running the migration twice is idempotent', () async {
      writeReadyProject();
      final service = buildService();

      final firstPlan = service.plan(UpgradeInput(projectRoot: root));
      final firstApply = await service.apply(firstPlan, verify: false);
      expect(firstApply.outcome, UpgradeApplyOutcome.completed);
      expect(firstApply.addedFiles, isNotEmpty);

      final contentsAfterFirstApply = {
        for (final path in _newFilePaths) path: readFile(path),
      };

      final secondPlan = service.plan(UpgradeInput(projectRoot: root));
      expect(secondPlan.outcome, UpgradePlanOutcome.alreadyUpToDate);

      // Re-running against an explicit, already-current plan would also be
      // a no-op were it attempted: nothing left to add, and every
      // "modify" target (locator/app_root/pubspec) is now alreadyCurrent.
      final reassessment = const MediaToolsMigration().assess(root);
      expect(reassessment.hasChanges, isFalse);
      for (final path in _newFilePaths) {
        expect(readFile(path), contentsAfterFirstApply[path]);
      }
    });

    test(
      'adds missing dependencies but leaves already-present ones alone',
      () async {
        writeReadyProject(
          pubspec:
              'name: my_app\ndependencies:\n  flutter:\n    sdk: flutter\n'
              '  image_picker: ^1.2.4\n',
        );
        final service = buildService();
        final plan = service.plan(UpgradeInput(projectRoot: root));
        await service.apply(plan, verify: false);

        final pubspec = readFile('pubspec.yaml');
        expect('image_picker:'.allMatches(pubspec).length, 1);
        expect(pubspec, contains('crop_your_image:'));
      },
    );

    test('a project whose pubspec.yaml already has both dependencies reports '
        'pubspec.yaml as alreadyCurrent', () {
      writeReadyProject(
        pubspec:
            'name: my_app\ndependencies:\n  flutter:\n    sdk: flutter\n'
            '  image_picker: ^1.2.4\n  crop_your_image: ^2.0.1\n',
      );
      final changes = const MediaToolsMigration().assess(root).fileChanges;
      final pubspecChange = changes.firstWhere(
        (change) => change.path == 'pubspec.yaml',
      );
      expect(pubspecChange.outcome, MigrationFileOutcome.alreadyCurrent);
    });

    test('does not modify any file it does not own', () async {
      writeReadyProject();
      File('${root.path}/lib/features/home/ui/home_view.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// untouched feature file\n');
      final before = readFile('lib/features/home/ui/home_view.dart');

      final service = buildService();
      final plan = service.plan(UpgradeInput(projectRoot: root));
      await service.apply(plan, verify: false);

      expect(readFile('lib/features/home/ui/home_view.dart'), before);
    });

    test('an unexpected write failure rolls back every file this run added, '
        'and does not advance the recorded architecture version', () async {
      writeReadyProject();
      // Put a directory where `media_utils.dart` should be created --
      // the write will throw partway through the chain.
      Directory(
        '${root.path}/lib/core/services/media_utils.dart',
      ).createSync(recursive: true);

      final service = buildService();
      final plan = service.plan(UpgradeInput(projectRoot: root));
      final applyResult = await service.apply(plan, verify: false);

      expect(applyResult.outcome, UpgradeApplyOutcome.failed);
      expect(applyResult.error, isNotNull);
      expect(fileExists('lib/app/app.snackbars.dart'), isFalse);
      expect(fileExists('lib/core/services/message_service.dart'), isFalse);
      expect(
        Directory(
          '${root.path}/lib/core/services/media_utils.dart',
        ).existsSync(),
        isTrue,
      );
      expect(readArchitectureMetadata(root)!.architectureVersion, '0.2.0');
    });

    test('chains through both real migrations from legacyArchitectureVersion '
        'to currentArchitectureVersion in one apply', () async {
      File('${root.path}/pubspec.yaml').writeAsStringSync(
        'name: my_app\ndependencies:\n  flutter:\n    sdk: flutter\n',
      );
      File('${root.path}/lib/app/app.router.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
// @cuboid-import

class Routes {
  // @cuboid-route-const
}

final Map<String, WidgetBuilder> appRoutes = {
  // @cuboid-route
};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}
''');
      File('${root.path}/lib/core/services/navigation_service.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => navigatorKey.currentState!;

  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return _navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  void back<T>({T? result}) {
    if (_navigator.canPop()) {
      _navigator.pop<T>(result);
    }
  }
}
''');
      File('${root.path}/lib/app/app.locator.dart').writeAsStringSync('''
import 'package:get_it/get_it.dart';
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // @cuboid-service
}
''');
      File('${root.path}/lib/app/app_root.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:my_app/core/services/navigation_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
    );
  }
}
''');

      final service = buildService(
        migrations: migrationRegistry,
        latestVersion: currentArchitectureVersion,
      );
      final plan = service.plan(UpgradeInput(projectRoot: root));
      expect(plan.plan!.chain, hasLength(2));

      final applyResult = await service.apply(plan, verify: false);

      expect(applyResult.outcome, UpgradeApplyOutcome.completed);
      expect(applyResult.metadataUpdated, isTrue);
      expect(
        readArchitectureMetadata(root)!.architectureVersion,
        currentArchitectureVersion,
      );
      final router = readFile('lib/app/app.router.dart');
      expect(router, contains('CuboidPageRoute'));
      for (final path in _newFilePaths) {
        expect(fileExists(path), isTrue);
      }
    });
  });
}
