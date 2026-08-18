import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cuboid/cuboid.dart';
import 'package:test/test.dart';

const _knownCreateArtifacts = <String>[
  'app',
  'service',
  'feature',
  'bottomsheet',
  'dialog',
  'storage',
  'database',
];

void main() {
  test('command runner starts', () {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.executableName, 'cuboid');
    expect(runner.commands, contains('create'));
    expect(runner.commands, contains('feature'));
    expect(runner.commands, contains('service'));
    expect(runner.commands, contains('view'));
    expect(runner.commands, isNot(contains('route')));
    expect(runner.commands, isNot(contains('repository')));
  });

  test('--help works', () async {
    final output = _memorySink();
    final exitCode = await runCuboid(['--help'], stdout: output);

    expect(exitCode, 0);
    expect(
      output.content,
      contains('Command-line tools for Cuboid Flutter projects.'),
    );
    expect(output.content, contains('create'));
    expect(output.content, contains('feature'));
    expect(output.content, contains('service'));
    expect(output.content, contains('view'));
  });

  test('--version works', () async {
    final output = _memorySink();
    final exitCode = await runCuboid(['--version'], stdout: output);

    expect(exitCode, 0);
    expect(output.content.trim(), cuboidVersion);
  });

  test('create command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['create'], isA<CreateCommand>());
    expect(runner.commands['create']!.description, contains('Create a new'));
  });

  test('feature command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['feature'], isA<FeatureCommand>());
    expect(
      runner.commands['feature']!.description,
      contains('Create a new Cuboid feature'),
    );
  });

  test('view command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['view'], isA<ViewCommand>());
    expect(
      runner.commands['view']!.description,
      contains('Create an additional Cuboid View'),
    );
  });

  test('service command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['service'], isA<ServiceCommand>());
    expect(
      runner.commands['service']!.description,
      contains('Register an existing core service'),
    );
  });

  test(
    'create dry-run reports the planned project without writing files',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        [
          'create',
          '--dry-run',
          '--output-dir',
          temp.path,
          'My App',
          'com.example.myapp',
        ],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Dry run: no files were written.'));
      expect(
        output.content,
        contains('Destination: ${temp.absolute.path}/my_app'),
      );
      expect(output.content, contains('Planned actions:'));
      expect(errorOutput.content, isEmpty);
      expect(Directory('${temp.path}/my_app').existsSync(), isFalse);
    },
  );

  test(
    'create app dry-run reports the planned project without writing files',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        [
          'create',
          '--dry-run',
          '--output-dir',
          temp.path,
          'app',
          'Some App',
          'com.someapp.someapp',
        ],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Dry run: no files were written.'));
      expect(
        output.content,
        contains('Destination: ${temp.absolute.path}/some_app'),
      );
      expect(errorOutput.content, isEmpty);
      expect(Directory('${temp.path}/some_app').existsSync(), isFalse);
    },
  );

  test('create app validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'app', 'Some App'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a display name and package identifier.'),
    );
  });

  test(
    'create app rejects a package identifier with digits or underscores',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        [
          'create',
          '--dry-run',
          '--output-dir',
          temp.path,
          'app',
          'Some App',
          'com.some_app.someapp',
        ],
        stdout: _memorySink(),
        stderr: errorOutput,
      );

      expect(exitCode, 64);
      expect(
        errorOutput.content,
        contains('Invalid package component "some_app"'),
      );
    },
  );

  test('create validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'My App'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a display name and package identifier.'),
    );
  });

  test('bare create keeps existing project creation usage behavior', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a display name and package identifier.'),
    );
    expect(errorOutput.content, contains('Usage: cuboid create'));
  });

  test(
    'create help describes namespace without claiming artifacts work',
    () async {
      final output = _memorySink();
      final exitCode = await runCuboid(
        ['create', '--help'],
        stdout: output,
        stderr: _memorySink(),
      );

      expect(exitCode, 0);
      expect(
        output.content,
        contains('Canonical namespace: cuboid create <artifact>'),
      );
      expect(output.content, contains('Known artifact categories'));
      expect(output.content, contains('app, service, feature'));
      expect(
        output.content,
        contains('other artifact commands are not yet implemented'),
      );
      expect(output.content, contains('cuboid create feature <name>'));
      expect(output.content, contains('cuboid create service <name>'));
      expect(output.content, contains('cuboid create bottomsheet <name>'));
      expect(output.content, contains('cuboid create dialog <name>'));
      expect(output.content, contains('cuboid create storage,'));
      expect(output.content, contains('cuboid create database <provider>'));
      expect(
        output.content,
        contains('cuboid create view <view-name> <feature>'),
      );
      expect(output.content, contains('cuboid create model <name>'));
      expect(output.content, contains('cuboid create widget <name>'));
      expect(output.content, contains('Run flutter pub get and dart format.'));
      expect(output.content, isNot(contains('build_runner')));
      expect(output.content, isNot(contains('cuboid create route')));
      expect(output.content, isNot(contains('cuboid create repository')));
    },
  );

  test(
    'create feature command creates the canonical feature scaffold',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      final previousCurrent = Directory.current;
      addTearDown(() {
        Directory.current = previousCurrent;
        temp.deleteSync(recursive: true);
      });
      _writeFeatureProject(temp);
      final beforePubspec = File(
        '${temp.path}/pubspec.yaml',
      ).readAsStringSync();
      Directory.current = temp;
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['create', 'feature', 'auth'],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Created feature Auth.'));
      expect(output.content, isNot(contains('build_runner')));
      expect(errorOutput.content, isEmpty);
      expect(
        File('${temp.path}/lib/features/auth/ui/auth_view.dart').existsSync(),
        isTrue,
      );
      expect(
        File(
          '${temp.path}/lib/features/auth/ui/auth_viewmodel.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${temp.path}/lib/features/auth/data/auth_repository.dart',
        ).existsSync(),
        isTrue,
      );
      final router = File(
        '${temp.path}/lib/app/app.router.dart',
      ).readAsStringSync();
      expect(
        router,
        contains("import 'package:my_app/features/auth/ui/auth_view.dart';"),
      );
      expect(router, contains("static const authView = '/auth-view';"));
      expect(router, contains('Routes.authView: (_) => const AuthView(),'));
      final locator = File(
        '${temp.path}/lib/app/app.locator.dart',
      ).readAsStringSync();
      expect(
        locator,
        contains(
          "import 'package:my_app/features/auth/data/auth_repository.dart';",
        ),
      );
      expect(
        locator,
        contains(
          '  locator.registerLazySingleton<AuthRepository>('
          '() => const AuthRepository());',
        ),
      );
      expect(
        File('${temp.path}/pubspec.yaml').readAsStringSync(),
        beforePubspec,
      );
      expect(_relativeFiles(temp), [
        'lib/app/app.locator.dart',
        'lib/app/app.router.dart',
        'lib/features/auth/data/auth_repository.dart',
        'lib/features/auth/ui/auth_view.dart',
        'lib/features/auth/ui/auth_viewmodel.dart',
        'pubspec.yaml',
      ]);
    },
  );

  test('create feature normalizes names and uses package imports', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeFeatureProject(temp, pubspec: "name: 'custom_app' # comment\n");
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'feature', 'user-profile'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(errorOutput.content, isEmpty);
    final view = File(
      '${temp.path}/lib/features/user_profile/ui/user_profile_view.dart',
    ).readAsStringSync();
    final viewModel = File(
      '${temp.path}/lib/features/user_profile/ui/user_profile_viewmodel.dart',
    ).readAsStringSync();
    expect(
      view,
      contains(
        "import 'package:custom_app/features/user_profile/ui/"
        "user_profile_viewmodel.dart';",
      ),
    );
    expect(
      view,
      contains(
        'class UserProfileView extends CuboidView<UserProfileViewModel>',
      ),
    );
    expect(
      viewModel,
      contains('class UserProfileViewModel extends CuboidViewModel {}'),
    );
  });

  test('create feature dry-run reports the plan and writes nothing', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeFeatureProject(temp);
    final beforeFiles = _relativeFiles(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'feature', 'auth', '--dry-run'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Feature: Auth'));
    expect(output.content, contains('- lib/features/auth/ui/auth_view.dart'));
    expect(
      output.content,
      contains('- lib/features/auth/ui/auth_viewmodel.dart'),
    );
    expect(
      output.content,
      contains('- lib/features/auth/data/auth_repository.dart'),
    );
    expect(output.content, contains('- lib/app/app.router.dart'));
    expect(output.content, contains('- lib/app/app.locator.dart'));
    expect(output.content, contains("static const authView = '/auth-view';"));
    expect(
      output.content,
      contains('Routes.authView: (_) => const AuthView(),'),
    );
    expect(
      output.content,
      contains(
        'locator.registerLazySingleton<AuthRepository>('
        '() => const AuthRepository());',
      ),
    );
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create feature validates positional argument count', () async {
    final errorOutput = _memorySink();

    expect(
      await runCuboid(
        ['create', 'feature'],
        stdout: _memorySink(),
        stderr: errorOutput,
      ),
      64,
    );
    expect(errorOutput.content, contains('Expected a feature name.'));

    final extraErrorOutput = _memorySink();
    expect(
      await runCuboid(
        ['create', 'feature', 'auth', 'extra'],
        stdout: _memorySink(),
        stderr: extraErrorOutput,
      ),
      64,
    );
    expect(extraErrorOutput.content, contains('Expected a feature name.'));
  });

  test('create feature returns generation failure for invalid names', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeFeatureProject(temp);
    Directory.current = temp;

    for (final name in ['', '   ', '2fa', '_auth', 'user profile', 'class']) {
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['create', 'feature', name],
        stdout: _memorySink(),
        stderr: errorOutput,
      );

      expect(exitCode, 1, reason: name);
      expect(errorOutput.content, isNotEmpty, reason: name);
    }
  });

  for (final artifact in _knownCreateArtifacts.where(
    (name) =>
        name != 'app' &&
        name != 'feature' &&
        name != 'service' &&
        name != 'bottomsheet' &&
        name != 'dialog' &&
        name != 'storage' &&
        name != 'database' &&
        name != 'route' &&
        name != 'view' &&
        name != 'repository' &&
        name != 'model' &&
        name != 'widget',
  )) {
    test('create $artifact fails cleanly as unimplemented', () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      final previousCurrent = Directory.current;
      addTearDown(() {
        Directory.current = previousCurrent;
        temp.deleteSync(recursive: true);
      });
      Directory.current = temp;
      final beforeFiles = _relativeFiles(temp);
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['create', artifact],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 64);
      expect(output.content, isEmpty);
      expect(
        errorOutput.content,
        contains('cuboid create $artifact is not implemented yet.'),
      );
      expect(_relativeFiles(temp), beforeFiles);
    });

    test(
      'create $artifact with arguments does not fall back to app creation',
      () async {
        final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
        final previousCurrent = Directory.current;
        addTearDown(() {
          Directory.current = previousCurrent;
          temp.deleteSync(recursive: true);
        });
        Directory.current = temp;
        final beforeFiles = _relativeFiles(temp);
        final output = _memorySink();
        final errorOutput = _memorySink();
        final exitCode = await runCuboid(
          ['create', artifact, 'auth'],
          stdout: output,
          stderr: errorOutput,
        );

        expect(exitCode, 64);
        expect(output.content, isEmpty);
        expect(
          errorOutput.content,
          contains('cuboid create $artifact is not implemented yet.'),
        );
        expect(errorOutput.content, isNot(contains('Destination:')));
        expect(_relativeFiles(temp), beforeFiles);
      },
    );
  }

  test('create known artifact with multiple arguments fails cleanly', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'service', 'auth', 'extra'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(output.content, isEmpty);
    expect(errorOutput.content, contains('Expected a service name.'));
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create service with dry-run creates no files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeServiceProject(temp, createFile: false);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'service', 'auth'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Service: AuthService'));
    expect(output.content, contains('- lib/core/services/auth_service.dart'));
    expect(output.content, contains('- lib/app/app.locator.dart'));
    expect(output.content, contains('- class AuthService {}'));
    expect(
      output.content,
      contains("import 'package:my_app/core/services/auth_service.dart';"),
    );
    expect(
      output.content,
      contains(
        'locator.registerLazySingleton<AuthService>(() => AuthService());',
      ),
    );
    expect(output.content, isNot(contains('build_runner')));
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create service command creates and registers a core service', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeServiceProject(temp, createFile: false);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'service', 'userProfile'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created service UserProfileService.'));
    expect(output.content, isNot(contains('build_runner')));
    expect(errorOutput.content, isEmpty);
    final serviceFile = File(
      '${temp.path}/lib/core/services/user_profile_service.dart',
    );
    expect(serviceFile.readAsStringSync(), 'class UserProfileService {}\n');
    final locator = File(
      '${temp.path}/lib/app/app.locator.dart',
    ).readAsStringSync();
    expect(
      locator,
      contains(
        "import 'package:my_app/core/services/user_profile_service.dart';",
      ),
    );
    expect(
      locator,
      contains(
        '  locator.registerLazySingleton<UserProfileService>('
        '() => UserProfileService());',
      ),
    );
    expect(_relativeFiles(temp), [
      'lib/app/app.locator.dart',
      'lib/core/services/user_profile_service.dart',
      'pubspec.yaml',
    ]);
  });

  test('create service registers every service across repeated invocations '
      '(auth, payment, notification)', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeServiceProject(temp, createFile: false);
    Directory.current = temp;

    for (final name in ['auth', 'payment', 'notification']) {
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['create', 'service', name],
        stdout: output,
        stderr: errorOutput,
      );
      expect(exitCode, 0, reason: name);
      expect(errorOutput.content, isEmpty, reason: name);
    }

    final locator = File(
      '${temp.path}/lib/app/app.locator.dart',
    ).readAsStringSync();
    for (final entry in {
      'auth': 'AuthService',
      'payment': 'PaymentService',
      'notification': 'NotificationService',
    }.entries) {
      expect(
        File(
          '${temp.path}/lib/core/services/${entry.key}_service.dart',
        ).existsSync(),
        isTrue,
        reason: entry.value,
      );
      expect(
        locator,
        contains(
          '  locator.registerLazySingleton<${entry.value}>('
          '() => ${entry.value}());',
        ),
        reason: entry.value,
      );
    }
    expect('// @cuboid-service'.allMatches(locator), hasLength(1));
    expect('// @cuboid-import'.allMatches(locator), hasLength(1));
  });

  test('create service rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeServiceProject(temp, createFile: false);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'service', 'auth', '--output-dir', temp.path],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create service.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create bottomsheet with dry-run creates no files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeBottomSheetProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'bottomsheet', 'confirm-delete'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Bottom sheet: ConfirmDeleteSheet'));
    expect(
      output.content,
      contains(
        '- lib/shared/bottom_sheets/confirm_delete/'
        'confirm_delete_sheet.dart',
      ),
    );
    expect(
      output.content,
      contains(
        '- lib/shared/bottom_sheets/confirm_delete/'
        'confirm_delete_sheet_model.dart',
      ),
    );
    expect(output.content, contains('- lib/app/app.bottomsheets.dart'));
    expect(
      output.content,
      contains(
        '- lib/core/services/bottom_sheet_service.dart '
        '(first use only)',
      ),
    );
    expect(
      output.content,
      contains('- lib/app/app.locator.dart (first use only)'),
    );
    expect(
      output.content,
      contains('ConfirmDeleteSheetModel: (_) => const ConfirmDeleteSheet(),'),
    );
    expect(
      output.content,
      contains(
        'locator.registerLazySingleton<BottomSheetService>('
        '() => BottomSheetService());',
      ),
    );
    expect(
      output.content,
      contains(
        "import 'package:my_app/core/services/bottom_sheet_service.dart';",
      ),
    );
    expect(output.content, isNot(contains('lib/main.dart')));
    expect(output.content, isNot(contains('build_runner')));
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create bottomsheet creates files and registrations', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeBottomSheetProject(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'bottomsheet', 'confirm_delete'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(
      output.content,
      contains('Created bottom sheet ConfirmDeleteSheet.'),
    );
    expect(output.content, isNot(contains('build_runner')));
    expect(errorOutput.content, isEmpty);
    final sheet = File(
      '${temp.path}/lib/shared/bottom_sheets/confirm_delete/'
      'confirm_delete_sheet.dart',
    ).readAsStringSync();
    expect(
      sheet,
      contains(
        'class ConfirmDeleteSheet extends '
        'CuboidView<ConfirmDeleteSheetModel>',
      ),
    );
    expect(
      sheet,
      contains("import 'package:my_app/core/mvvm/cuboid_view.dart';"),
    );
    final model = File(
      '${temp.path}/lib/shared/bottom_sheets/confirm_delete/'
      'confirm_delete_sheet_model.dart',
    ).readAsStringSync();
    expect(
      model,
      contains('class ConfirmDeleteSheetModel extends CuboidViewModel {}'),
    );
    final bottomSheets = File(
      '${temp.path}/lib/app/app.bottomsheets.dart',
    ).readAsStringSync();
    expect(
      bottomSheets,
      contains(
        "import 'package:my_app/shared/bottom_sheets/confirm_delete/"
        "confirm_delete_sheet.dart';",
      ),
    );
    expect(
      bottomSheets,
      contains(
        "import 'package:my_app/shared/bottom_sheets/confirm_delete/"
        "confirm_delete_sheet_model.dart';",
      ),
    );
    expect(
      bottomSheets,
      contains('ConfirmDeleteSheetModel: (_) => const ConfirmDeleteSheet(),'),
    );
    final serviceFile = File(
      '${temp.path}/lib/core/services/bottom_sheet_service.dart',
    ).readAsStringSync();
    expect(serviceFile, contains('class BottomSheetService {'));
    expect(
      serviceFile,
      contains("import 'package:my_app/app/app.bottomsheets.dart';"),
    );
    final locator = File(
      '${temp.path}/lib/app/app.locator.dart',
    ).readAsStringSync();
    expect(
      locator,
      contains(
        "import 'package:my_app/core/services/bottom_sheet_service.dart';",
      ),
    );
    expect(
      locator,
      contains(
        '  locator.registerLazySingleton<BottomSheetService>('
        '() => BottomSheetService());',
      ),
    );
    expect(File('${temp.path}/lib/main.dart').existsSync(), isFalse);
  });

  test('create bottomsheet rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeBottomSheetProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'bottomsheet', 'confirm', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create bottomsheet.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create dialog with dry-run creates no files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeDialogProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'dialog', 'confirm-delete'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Dialog: ConfirmDeleteDialog'));
    expect(
      output.content,
      contains(
        '- lib/shared/dialogs/confirm_delete/'
        'confirm_delete_dialog.dart',
      ),
    );
    expect(
      output.content,
      contains(
        '- lib/shared/dialogs/confirm_delete/'
        'confirm_delete_dialog_model.dart',
      ),
    );
    expect(output.content, contains('- lib/app/app.dialogs.dart'));
    expect(
      output.content,
      contains('- lib/core/services/dialog_service.dart (first use only)'),
    );
    expect(
      output.content,
      contains('- lib/app/app.locator.dart (first use only)'),
    );
    expect(
      output.content,
      contains('ConfirmDeleteDialogModel: (_) => const ConfirmDeleteDialog(),'),
    );
    expect(
      output.content,
      contains(
        'locator.registerLazySingleton<DialogService>(() => DialogService());',
      ),
    );
    expect(
      output.content,
      contains("import 'package:my_app/core/services/dialog_service.dart';"),
    );
    expect(output.content, isNot(contains('lib/main.dart')));
    expect(output.content, isNot(contains('build_runner')));
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create dialog creates files and registrations', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeDialogProject(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'dialog', 'confirm_delete'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created dialog ConfirmDeleteDialog.'));
    expect(output.content, isNot(contains('build_runner')));
    expect(errorOutput.content, isEmpty);
    final dialog = File(
      '${temp.path}/lib/shared/dialogs/confirm_delete/'
      'confirm_delete_dialog.dart',
    ).readAsStringSync();
    expect(
      dialog,
      contains(
        'class ConfirmDeleteDialog extends '
        'CuboidView<ConfirmDeleteDialogModel>',
      ),
    );
    expect(
      dialog,
      contains(
        'ConfirmDeleteDialogModel viewModelBuilder(BuildContext context)',
      ),
    );
    final model = File(
      '${temp.path}/lib/shared/dialogs/confirm_delete/'
      'confirm_delete_dialog_model.dart',
    ).readAsStringSync();
    expect(
      model,
      contains('class ConfirmDeleteDialogModel extends CuboidViewModel {}'),
    );
    final dialogs = File(
      '${temp.path}/lib/app/app.dialogs.dart',
    ).readAsStringSync();
    expect(
      dialogs,
      contains(
        "import 'package:my_app/shared/dialogs/confirm_delete/"
        "confirm_delete_dialog.dart';",
      ),
    );
    expect(
      dialogs,
      contains('ConfirmDeleteDialogModel: (_) => const ConfirmDeleteDialog(),'),
    );
    final serviceFile = File(
      '${temp.path}/lib/core/services/dialog_service.dart',
    ).readAsStringSync();
    expect(serviceFile, contains('class DialogService {'));
    expect(
      serviceFile,
      contains("import 'package:my_app/app/app.dialogs.dart';"),
    );
    final locator = File(
      '${temp.path}/lib/app/app.locator.dart',
    ).readAsStringSync();
    expect(
      locator,
      contains("import 'package:my_app/core/services/dialog_service.dart';"),
    );
    expect(
      locator,
      contains(
        '  locator.registerLazySingleton<DialogService>('
        '() => DialogService());',
      ),
    );
    expect(File('${temp.path}/lib/main.dart').existsSync(), isFalse);
  });

  test('create dialog rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeDialogProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'dialog', 'confirm', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create dialog.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create storage with dry-run creates no files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeStorageProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'storage'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Storage: LocalStorage'));
    expect(output.content, contains('- lib/core/storage/local_storage.dart'));
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create storage creates a secure key-value wrapper', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeStorageProject(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'storage'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created storage LocalStorage.'));
    expect(output.content, contains('- lib/core/storage/local_storage.dart'));
    expect(errorOutput.content, isEmpty);
    final storage = File(
      '${temp.path}/lib/core/storage/local_storage.dart',
    ).readAsStringSync();
    expect(
      storage,
      contains(
        "import 'package:flutter_secure_storage/flutter_secure_storage.dart';",
      ),
    );
    expect(storage, contains('class LocalStorage {'));
  });

  test('create storage rejects a storage name argument', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeStorageProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'storage', 'cache'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('cuboid create storage does not take a storage name.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create storage rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeStorageProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'storage', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create storage.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create database with dry-run creates no files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeDatabaseProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'database', 'supabase'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Database: supabase'));
    expect(output.content, contains('- lib/supabase/example_repository.dart'));
    expect(output.content, contains('- lib/app/app.locator.dart'));
    expect(
      output.content,
      contains("import 'package:my_app/supabase/example_repository.dart';"),
    );
    expect(
      output.content,
      contains(
        'locator.registerLazySingleton<ExampleRepository>('
        '() => const ExampleRepository());',
      ),
    );
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test(
    'create database generates the supabase example and registers it',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      final previousCurrent = Directory.current;
      addTearDown(() {
        Directory.current = previousCurrent;
        temp.deleteSync(recursive: true);
      });
      _writeDatabaseProject(temp);
      Directory.current = temp;
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['create', 'database', 'supabase'],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Created supabase database example.'));
      expect(output.content, contains('Next steps:'));
      expect(output.content, contains('- flutter pub get'));
      expect(output.content, contains('supabase db push'));
      expect(output.content, isNot(contains('build_runner')));
      expect(errorOutput.content, isEmpty);
      final repository = File(
        '${temp.path}/lib/supabase/example_repository.dart',
      ).readAsStringSync();
      expect(repository, contains('class ExampleRepository {'));
      final locator = File(
        '${temp.path}/lib/app/app.locator.dart',
      ).readAsStringSync();
      expect(
        locator,
        contains("import 'package:my_app/supabase/example_repository.dart';"),
      );
      expect(
        locator,
        contains(
          '  locator.registerLazySingleton<ExampleRepository>('
          '() => const ExampleRepository());',
        ),
      );
      expect(
        Directory(
          '${temp.path}/supabase/migrations',
        ).listSync().whereType<File>().length,
        1,
      );
    },
  );

  test('create database provisions the supabase_flutter dependency and guard '
      'when missing', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeDatabaseProject(temp, withSupabaseFoundation: false);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'database', 'supabase'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(errorOutput.content, isEmpty);
    final pubspec = File('${temp.path}/pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('supabase_flutter: ^2.17.1'));
    expect(pubspec, contains('name: my_app'));
    final guard = File(
      '${temp.path}/lib/core/network/supabase_guard.dart',
    ).readAsStringSync();
    expect(guard, contains('Future<Result<T>> guard<T>('));
    expect(
      guard,
      contains("import 'package:supabase_flutter/supabase_flutter.dart';"),
    );
  });

  test('create database does not duplicate an existing supabase_flutter '
      'dependency or overwrite an existing guard', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeDatabaseProject(temp);
    File(
      '${temp.path}/lib/core/network/supabase_guard.dart',
    ).writeAsStringSync('// customized guard\nFuture<void> guard() async {}\n');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'database', 'supabase'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(errorOutput.content, isEmpty);
    final pubspec = File('${temp.path}/pubspec.yaml').readAsStringSync();
    expect('supabase_flutter'.allMatches(pubspec).length, 1);
    final guard = File(
      '${temp.path}/lib/core/network/supabase_guard.dart',
    ).readAsStringSync();
    expect(guard, contains('// customized guard'));
  });

  test('create database rejects an unsupported provider', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeDatabaseProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'database', 'firebase'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 1);
    expect(
      errorOutput.content,
      contains('Unsupported database provider "firebase"'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create database rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeDatabaseProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'database', 'supabase', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create database.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test(
    'create view with dry-run reports planned files without writing',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      final previousCurrent = Directory.current;
      addTearDown(() {
        Directory.current = previousCurrent;
        temp.deleteSync(recursive: true);
      });
      _writeViewProject(temp, 'auth');
      final beforeFiles = _relativeFiles(temp);
      Directory.current = temp;
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['create', '--dry-run', 'view', 'forgot-password', 'auth'],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Dry run: no files were written.'));
      expect(output.content, contains('View: Forgot Password'));
      expect(output.content, contains('Feature: auth'));
      expect(
        output.content,
        contains('- lib/features/auth/ui/forgot_password_view.dart'),
      );
      expect(output.content, contains('- lib/app/app.router.dart'));
      expect(
        output.content,
        contains("static const forgotPasswordView = '/forgot-password-view';"),
      );
      expect(
        output.content,
        contains(
          'Routes.forgotPasswordView: (_) => const ForgotPasswordView(),',
        ),
      );
      expect(output.content, isNot(contains('build_runner')));
      expect(errorOutput.content, isEmpty);
      expect(_relativeFiles(temp), beforeFiles);
    },
  );

  test('create view creates an additional feature View', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeViewProject(temp, 'auth');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'view', 'forgot-password', 'auth'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created view Forgot Password.'));
    expect(output.content, isNot(contains('build_runner')));
    expect(errorOutput.content, isEmpty);
    final view = File(
      '${temp.path}/lib/features/auth/ui/forgot_password_view.dart',
    ).readAsStringSync();
    expect(
      view,
      contains(
        'class ForgotPasswordView extends CuboidView<ForgotPasswordViewModel>',
      ),
    );
    final viewModel = File(
      '${temp.path}/lib/features/auth/ui/forgot_password_viewmodel.dart',
    ).readAsStringSync();
    expect(
      viewModel,
      contains('class ForgotPasswordViewModel extends CuboidViewModel {}'),
    );
    final router = File(
      '${temp.path}/lib/app/app.router.dart',
    ).readAsStringSync();
    expect(
      router,
      contains(
        "import 'package:my_app/features/auth/ui/forgot_password_view.dart';",
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

  test('create view rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeViewProject(temp, 'auth');
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'view', 'login', 'auth', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create view.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create view validates required positional arguments', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeViewProject(temp, 'auth');
    Directory.current = temp;
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'view'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a view name, or a view name and feature name.'),
    );
  });

  test('create view with a single argument creates a shared view', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeViewProject(temp, 'auth');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'view', 'login'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(errorOutput.content, isEmpty);
    expect(output.content, contains('Created view Login.'));
    expect(output.content, isNot(contains('Feature:')));
    expect(output.content, contains('- lib/shared/views/login_view.dart'));
    expect(output.content, contains('- lib/shared/views/login_viewmodel.dart'));

    final view = File(
      '${temp.path}/lib/shared/views/login_view.dart',
    ).readAsStringSync();
    expect(
      view,
      contains("import 'package:my_app/shared/views/login_viewmodel.dart';"),
    );
    expect(
      view,
      contains('class LoginView extends CuboidView<LoginViewModel>'),
    );
    expect(
      File(
        '${temp.path}/lib/shared/views/login_viewmodel.dart',
      ).readAsStringSync(),
      contains('class LoginViewModel extends CuboidViewModel {}'),
    );

    final router = File(
      '${temp.path}/lib/app/app.router.dart',
    ).readAsStringSync();
    expect(
      router,
      contains("import 'package:my_app/shared/views/login_view.dart';"),
    );
    expect(router, contains("static const loginView = '/login-view';"));
    expect(router, contains('Routes.loginView: (_) => const LoginView(),'));
  });

  test('create model with dry-run creates no files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeModelProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'model', 'invoice'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Model: Invoice'));
    expect(output.content, contains('- lib/core/models/invoice.dart'));
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create model creates a bare model shell', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeModelProject(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'model', 'invoice'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created model Invoice.'));
    expect(errorOutput.content, isEmpty);
    final model = File(
      '${temp.path}/lib/core/models/invoice.dart',
    ).readAsStringSync();
    expect(model, contains('class Invoice {'));
    expect(model, contains('const Invoice();'));
  });

  test('create model rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeModelProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'model', 'invoice', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create model.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create widget with one argument creates a shared widget', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeModelProject(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'widget', 'status_badge'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created widget StatusBadge.'));
    expect(errorOutput.content, isEmpty);
    expect(output.content, isNot(contains('Feature:')));
    expect(
      output.content,
      contains('- lib/shared/widgets/status_badge/status_badge_widget.dart'),
    );
    expect(
      output.content,
      contains(
        '- lib/shared/widgets/status_badge/status_badge_view_model.dart',
      ),
    );
    final widget = File(
      '${temp.path}/lib/shared/widgets/status_badge/status_badge_widget.dart',
    ).readAsStringSync();
    expect(
      widget,
      contains(
        "import 'package:my_app/shared/widgets/status_badge/"
        "status_badge_view_model.dart';",
      ),
    );
    expect(
      widget,
      contains('class StatusBadge extends CuboidView<StatusBadgeViewModel> {'),
    );
    final viewModel = File(
      '${temp.path}/lib/shared/widgets/status_badge/'
      'status_badge_view_model.dart',
    ).readAsStringSync();
    expect(
      viewModel,
      contains('class StatusBadgeViewModel extends CuboidViewModel {}'),
    );
  });

  test(
    'create widget with two arguments creates a feature-scoped widget',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      final previousCurrent = Directory.current;
      addTearDown(() {
        Directory.current = previousCurrent;
        temp.deleteSync(recursive: true);
      });
      _writeViewProject(temp, 'auth');
      Directory.current = temp;
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['create', 'widget', 'password_field', 'auth'],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Created widget PasswordField.'));
      expect(output.content, contains('Feature: auth'));
      expect(errorOutput.content, isEmpty);
      final widget = File(
        '${temp.path}/lib/features/auth/ui/widgets/password_field/'
        'password_field_widget.dart',
      ).readAsStringSync();
      expect(
        widget,
        contains(
          "import 'package:my_app/features/auth/ui/widgets/password_field/"
          "password_field_view_model.dart';",
        ),
      );
      expect(
        widget,
        contains(
          'class PasswordField extends CuboidView<PasswordFieldViewModel> {',
        ),
      );
      final viewModel = File(
        '${temp.path}/lib/features/auth/ui/widgets/password_field/'
        'password_field_view_model.dart',
      ).readAsStringSync();
      expect(
        viewModel,
        contains('class PasswordFieldViewModel extends CuboidViewModel {}'),
      );
    },
  );

  test('create widget with dry-run creates no files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeModelProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'widget', 'status_badge'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(
      output.content,
      contains('- lib/shared/widgets/status_badge/status_badge_widget.dart'),
    );
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create widget rejects an invalid argument count', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeModelProject(temp);
    Directory.current = temp;
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'widget', 'a', 'b', 'c'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a widget name, or a widget name and feature name.'),
    );
  });

  test('create widget rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeModelProject(temp);
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'widget', 'status_badge', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create widget.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create unknown artifact fails cleanly', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'gizmo'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(output.content, isEmpty);
    expect(errorOutput.content, contains('Unknown create artifact "gizmo".'));
    expect(errorOutput.content, contains('Known artifacts:'));
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create preserves legacy app creation for non-artifact names', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      [
        'create',
        '--dry-run',
        '--output-dir',
        temp.path,
        'Customer Portal',
        'com.example.customer',
      ],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(
      output.content,
      contains('Destination: ${temp.absolute.path}/customer_portal'),
    );
    expect(output.content, contains('App package: com.example.customer'));
    expect(errorOutput.content, isEmpty);
    expect(Directory('${temp.path}/customer_portal').existsSync(), isFalse);
  });

  test('feature dry-run reports planned files without writing files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeFeatureProject(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['feature', 'auth', '--dry-run'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Feature: Auth'));
    expect(output.content, contains('- lib/features/auth/ui/auth_view.dart'));
    expect(
      output.content,
      contains('- lib/features/auth/ui/auth_viewmodel.dart'),
    );
    expect(errorOutput.content, isEmpty);
    expect(Directory('${temp.path}/lib/features/auth').existsSync(), isFalse);
  });

  test('feature validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['feature'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(errorOutput.content, contains('Expected a feature name.'));
  });

  test(
    'service dry-run reports planned registration without writing',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      final previousCurrent = Directory.current;
      addTearDown(() {
        Directory.current = previousCurrent;
        temp.deleteSync(recursive: true);
      });
      _writeServiceProject(temp);
      final before = File(
        '${temp.path}/lib/app/app.locator.dart',
      ).readAsStringSync();
      Directory.current = temp;
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['service', 'auth-session', '--dry-run'],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Dry run: no files were written.'));
      expect(output.content, contains('Service: AuthSessionService'));
      expect(output.content, contains('- lib/app/app.locator.dart'));
      expect(
        output.content,
        contains(
          "import 'package:my_app/core/services/auth_session_service.dart';",
        ),
      );
      expect(
        output.content,
        contains(
          'locator.registerLazySingleton<AuthSessionService>('
          '() => AuthSessionService());',
        ),
      );
      expect(errorOutput.content, isEmpty);
      expect(
        File('${temp.path}/lib/app/app.locator.dart').readAsStringSync(),
        before,
      );
    },
  );

  test('service command registers an existing core service', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeServiceProject(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['service', 'AuthSession'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Registered service AuthSessionService.'));
    expect(output.content, isNot(contains('build_runner')));
    expect(errorOutput.content, isEmpty);
    final locator = File(
      '${temp.path}/lib/app/app.locator.dart',
    ).readAsStringSync();
    expect(
      locator,
      contains(
        "import 'package:my_app/core/services/auth_session_service.dart';",
      ),
    );
    expect(
      locator,
      contains(
        '  locator.registerLazySingleton<AuthSessionService>('
        '() => AuthSessionService());',
      ),
    );
  });

  test('service validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['service'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(errorOutput.content, contains('Expected a service name.'));
  });

  test('service failures return non-zero and write stderr', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeServiceProject(temp);
    File(
      '${temp.path}/lib/core/services/auth_session_service.dart',
    ).deleteSync();
    Directory.current = temp;
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['service', 'auth-session'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 1);
    expect(
      errorOutput.content,
      contains('lib/core/services/auth_session_service.dart was not found.'),
    );
  });

  test('view dry-run reports planned files without writing', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeViewProject(temp, 'auth');
    final beforeFiles = _relativeFiles(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['view', 'forgot-password', 'auth', '--dry-run'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('View: Forgot Password'));
    expect(output.content, contains('Feature: auth'));
    expect(
      output.content,
      contains('- lib/features/auth/ui/forgot_password_view.dart'),
    );
    expect(
      output.content,
      contains('- lib/features/auth/ui/forgot_password_viewmodel.dart'),
    );
    expect(output.content, contains('- lib/app/app.router.dart'));
    expect(
      output.content,
      contains('Routes.forgotPasswordView: (_) => const ForgotPasswordView(),'),
    );
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('view command creates an additional feature View', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeViewProject(temp, 'auth');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['view', 'forgot-password', 'auth'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created view Forgot Password.'));
    expect(errorOutput.content, isEmpty);
    final view = File(
      '${temp.path}/lib/features/auth/ui/forgot_password_view.dart',
    ).readAsStringSync();
    final viewModel = File(
      '${temp.path}/lib/features/auth/ui/forgot_password_viewmodel.dart',
    ).readAsStringSync();
    expect(
      view,
      contains(
        "import 'package:my_app/features/auth/ui/"
        "forgot_password_viewmodel.dart';",
      ),
    );
    expect(
      view,
      contains(
        'class ForgotPasswordView extends CuboidView<ForgotPasswordViewModel>',
      ),
    );
    expect(
      viewModel,
      contains('class ForgotPasswordViewModel extends CuboidViewModel {}'),
    );
    final router = File(
      '${temp.path}/lib/app/app.router.dart',
    ).readAsStringSync();
    expect(
      router,
      contains('Routes.forgotPasswordView: (_) => const ForgotPasswordView(),'),
    );
  });

  test('view validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['view', 'auth'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a view name and feature name.'),
    );
  });

  test('view service failures return non-zero and write stderr', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    File('${temp.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
    Directory.current = temp;
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['view', 'login', 'auth'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 1);
    expect(errorOutput.content, contains('lib/features/auth was not found.'));
  });

  test('runner can use an injected create service', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final output = _memorySink();
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            return ProcessResult(0, 0, '', '');
          },
    );
    final runner = CuboidCommandRunner(
      stdout: output,
      stderr: _memorySink(),
      createProjectService: service,
    );

    final exitCode = await runner.run([
      'create',
      '--no-post-steps',
      '--output-dir',
      temp.path,
      'Nemara Homes',
      'com.nemara.homes',
    ]);

    expect(exitCode, 0);
    expect(output.content, contains('Created Nemara Homes.'));
    expect(Directory('${temp.path}/nemara_homes').existsSync(), isTrue);
    final appRoot = File(
      '${temp.path}/nemara_homes/lib/app/app_root.dart',
    ).readAsStringSync();
    expect(appRoot, contains('class NemaraHomes extends StatelessWidget'));
    expect(appRoot, contains('const NemaraHomes({super.key});'));
    final main = File(
      '${temp.path}/nemara_homes/lib/main.dart',
    ).readAsStringSync();
    expect(main, contains('runApp(const NemaraHomes());'));
  });

  test('invalid command returns non-zero and writes usage', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['missing'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, isNot(0));
    expect(
      errorOutput.content,
      contains('Could not find a command named "missing".'),
    );
    expect(errorOutput.content, contains('Usage:'));
  });

  test('runner throws UsageException for invalid command', () {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(() => runner.run(['missing']), throwsA(isA<UsageException>()));
  });
}

_MemorySink _memorySink() => _MemorySink();

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

String _locatorContents({String extraImport = '', String extraService = ''}) {
  return '''
${extraImport}import 'package:get_it/get_it.dart';
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
$extraService  // @cuboid-service
}
''';
}

void _writeViewProject(Directory root, String featureName) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.router.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_routerContents());
  Directory(
    '${root.path}/lib/features/$featureName',
  ).createSync(recursive: true);
}

void _writeFeatureProject(Directory root, {String pubspec = 'name: my_app\n'}) {
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  File('${root.path}/lib/app/app.router.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_routerContents());
  File(
    '${root.path}/lib/app/app.locator.dart',
  ).writeAsStringSync(_locatorContents());
  Directory('${root.path}/lib/features').createSync(recursive: true);
}

void _writeServiceProject(
  Directory root, {
  String serviceName = 'auth_session',
  bool createFile = true,
}) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.locator.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      _locatorContents(
        extraImport:
            "import 'package:my_app/core/services/analytics_service.dart';\n",
        extraService:
            '  locator.registerLazySingleton<AnalyticsService>('
            '() => AnalyticsService());\n',
      ),
    );
  if (!createFile) {
    return;
  }
  final className = serviceName
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
  File('${root.path}/lib/core/services/${serviceName}_service.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class ${className}Service {}\n');
}

void _writeBottomSheetProject(Directory root) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.locator.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      _locatorContents(
        extraImport:
            "import 'package:my_app/core/services/analytics_service.dart';\n",
        extraService:
            '  locator.registerLazySingleton<AnalyticsService>('
            '() => AnalyticsService());\n',
      ),
    );
}

void _writeDialogProject(Directory root) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.locator.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      _locatorContents(
        extraImport:
            "import 'package:my_app/core/services/analytics_service.dart';\n",
        extraService:
            '  locator.registerLazySingleton<AnalyticsService>('
            '() => AnalyticsService());\n',
      ),
    );
}

void _writeStorageProject(Directory root) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
}

void _writeModelProject(Directory root) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
}

void _writeDatabaseProject(
  Directory root, {
  bool withSupabaseFoundation = true,
}) {
  File('${root.path}/pubspec.yaml').writeAsStringSync(
    withSupabaseFoundation
        ? 'name: my_app\ndependencies:\n  supabase_flutter: ^2.16.0\n'
        : 'name: my_app\ndependencies:\n  flutter:\n    sdk: flutter\n',
  );
  File('${root.path}/lib/app/app.locator.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      _locatorContents(
        extraImport:
            "import 'package:my_app/core/services/analytics_service.dart';\n",
        extraService:
            '  locator.registerLazySingleton<AnalyticsService>('
            '() => AnalyticsService());\n',
      ),
    );
  if (withSupabaseFoundation) {
    File('${root.path}/lib/core/network/supabase_guard.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('Future<void> guard() async {}\n');
  }
  File('${root.path}/lib/core/errors/result.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class Result<T> {}\n');
  File('${root.path}/lib/core/errors/failures.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class AppFailure {}\n');
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

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  Encoding encoding = utf8;

  @override
  void write(Object? object) {
    _buffer.write(object);
  }

  @override
  void writeln([Object? object = '']) {
    _buffer.writeln(object);
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    _buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
  }

  @override
  void add(List<int> data) {
    _buffer.write(encoding.decode(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> close() async {
    await Future<void>.value();
  }

  @override
  Future<void> get done => Future.value();

  @override
  Future<void> flush() async {}
}
