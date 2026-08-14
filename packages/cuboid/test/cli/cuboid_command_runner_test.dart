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
    expect(runner.commands, contains('route'));
    expect(runner.commands, contains('service'));
    expect(runner.commands, contains('view'));
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
    expect(output.content, contains('route'));
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

  test('route command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['route'], isA<RouteCommand>());
    expect(
      runner.commands['route']!.description,
      contains('Register an existing feature View'),
    );
  });

  test('view command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['view'], isA<ViewCommand>());
    expect(
      runner.commands['view']!.description,
      contains('Create an additional Stacked View'),
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
      expect(output.content, contains('cuboid create storage <name>'));
      expect(output.content, contains('cuboid create database <provider>'));
      expect(output.content, contains('cuboid create route <feature>'));
      expect(output.content, contains('cuboid create view <feature> <name>'));
      expect(output.content, contains('cuboid create repository <name>'));
      expect(output.content, contains('cuboid create model <name>'));
      expect(output.content, contains('cuboid create widget <name>'));
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
      final beforeApp = File(
        '${temp.path}/lib/app/app.dart',
      ).readAsStringSync();
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
        File('${temp.path}/lib/app/app.dart').readAsStringSync(),
        beforeApp,
      );
      expect(
        File('${temp.path}/pubspec.yaml').readAsStringSync(),
        beforePubspec,
      );
      expect(_relativeFiles(temp), [
        'lib/app/app.dart',
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
        "import 'package:custom_app/features/user_profile/ui/user_profile_viewmodel.dart';",
      ),
    );
    expect(
      view,
      contains(
        'class UserProfileView extends StackedView<UserProfileViewModel>',
      ),
    );
    expect(
      viewModel,
      contains('class UserProfileViewModel extends BaseViewModel {}'),
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
    expect(output.content, contains('- lib/app/app.dart'));
    expect(
      output.content,
      contains("import 'package:my_app/core/services/auth_service.dart';"),
    );
    expect(output.content, contains('LazySingleton(classType: AuthService),'));
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
    expect(
      output.content,
      contains('Next step: dart run build_runner build -d'),
    );
    expect(errorOutput.content, isEmpty);
    final serviceFile = File(
      '${temp.path}/lib/core/services/user_profile_service.dart',
    );
    expect(serviceFile.readAsStringSync(), 'class UserProfileService {}\n');
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:my_app/core/services/user_profile_service.dart';",
      ),
    );
    expect(app, contains('    LazySingleton(classType: UserProfileService),'));
    expect(_relativeFiles(temp), [
      'lib/app/app.dart',
      'lib/core/services/user_profile_service.dart',
      'pubspec.yaml',
    ]);
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
    expect(output.content, contains('- lib/app/app.dart'));
    expect(output.content, contains('- lib/main.dart'));
    expect(
      output.content,
      contains('StackedBottomsheet(classType: ConfirmDeleteSheet),'),
    );
    expect(
      output.content,
      contains('LazySingleton(classType: BottomSheetService),'),
    );
    expect(
      output.content,
      contains("import 'package:my_app/app/app.bottomsheets.dart';"),
    );
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
    expect(
      output.content,
      contains('Next step: dart run build_runner build -d'),
    );
    expect(errorOutput.content, isEmpty);
    final sheet = File(
      '${temp.path}/lib/shared/bottom_sheets/confirm_delete/'
      'confirm_delete_sheet.dart',
    ).readAsStringSync();
    expect(
      sheet,
      contains(
        'class ConfirmDeleteSheet extends '
        'StackedView<ConfirmDeleteSheetModel>',
      ),
    );
    final model = File(
      '${temp.path}/lib/shared/bottom_sheets/confirm_delete/'
      'confirm_delete_sheet_model.dart',
    ).readAsStringSync();
    expect(
      model,
      contains('class ConfirmDeleteSheetModel extends BaseViewModel {}'),
    );
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:my_app/shared/bottom_sheets/confirm_delete/"
        "confirm_delete_sheet.dart';",
      ),
    );
    expect(app, contains('  bottomsheets: ['));
    expect(
      app,
      contains('    StackedBottomsheet(classType: ConfirmDeleteSheet),'),
    );
    expect(app, contains('    LazySingleton(classType: BottomSheetService),'));
    final main = File('${temp.path}/lib/main.dart').readAsStringSync();
    expect(
      main,
      contains("import 'package:my_app/app/app.bottomsheets.dart';"),
    );
    expect(main, contains('  await setupLocator();\n  setupBottomSheetUi();'));
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
    expect(output.content, contains('- lib/app/app.dart'));
    expect(output.content, contains('- lib/main.dart'));
    expect(output.content, contains('StackedDialog('));
    expect(output.content, contains('classType: ConfirmDeleteDialog,'));
    expect(
      output.content,
      contains('LazySingleton(classType: DialogService),'),
    );
    expect(
      output.content,
      contains("import 'package:my_app/app/app.dialogs.dart';"),
    );
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
    expect(
      output.content,
      contains('Next step: dart run build_runner build -d'),
    );
    expect(errorOutput.content, isEmpty);
    final dialog = File(
      '${temp.path}/lib/shared/dialogs/confirm_delete/'
      'confirm_delete_dialog.dart',
    ).readAsStringSync();
    expect(
      dialog,
      contains(
        'class ConfirmDeleteDialog extends '
        'StackedView<ConfirmDeleteDialogModel>',
      ),
    );
    expect(dialog, contains('DialogRequest<dynamic> request'));
    expect(dialog, contains('DialogResponse<dynamic> response'));
    final model = File(
      '${temp.path}/lib/shared/dialogs/confirm_delete/'
      'confirm_delete_dialog_model.dart',
    ).readAsStringSync();
    expect(
      model,
      contains('class ConfirmDeleteDialogModel extends BaseViewModel {}'),
    );
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:my_app/shared/dialogs/confirm_delete/"
        "confirm_delete_dialog.dart';",
      ),
    );
    expect(app, contains('  dialogs: ['));
    expect(app, contains('      classType: ConfirmDeleteDialog,'));
    expect(app, contains('    LazySingleton(classType: DialogService),'));
    final main = File('${temp.path}/lib/main.dart').readAsStringSync();
    expect(main, contains("import 'package:my_app/app/app.dialogs.dart';"));
    expect(main, contains('  await setupLocator();\n  setupDialogUi();'));
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
      ['create', '--dry-run', 'storage', 'user-prefs'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Storage: UserPrefsStorage'));
    expect(
      output.content,
      contains('- lib/core/storage/user_prefs_storage.dart'),
    );
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
      ['create', 'storage', 'user_prefs'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created storage UserPrefsStorage.'));
    expect(
      output.content,
      contains('- lib/core/storage/user_prefs_storage.dart'),
    );
    expect(errorOutput.content, isEmpty);
    final storage = File(
      '${temp.path}/lib/core/storage/user_prefs_storage.dart',
    ).readAsStringSync();
    expect(
      storage,
      contains(
        "import 'package:flutter_secure_storage/flutter_secure_storage.dart';",
      ),
    );
    expect(storage, contains('class UserPrefsStorage {'));
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
      ['create', 'storage', 'cache', '--directory', 'ignored'],
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
    expect(
      output.content,
      contains('LazySingleton(classType: ExampleRepository),'),
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
      expect(output.content, contains('- dart run build_runner build -d'));
      expect(output.content, contains('supabase db push'));
      expect(errorOutput.content, isEmpty);
      final repository = File(
        '${temp.path}/lib/supabase/example_repository.dart',
      ).readAsStringSync();
      expect(repository, contains('class ExampleRepository {'));
      final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
      expect(
        app,
        contains("import 'package:my_app/supabase/example_repository.dart';"),
      );
      expect(app, contains('LazySingleton(classType: ExampleRepository),'));
      expect(
        Directory(
          '${temp.path}/supabase/migrations',
        ).listSync().whereType<File>().length,
        1,
      );
    },
  );

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

  test('create route with dry-run reports the plan without writing', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'user_profile');
    final before = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'route', 'user-profile'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Route: UserProfileView'));
    expect(output.content, contains('MaterialRoute(page: UserProfileView),'));
    expect(errorOutput.content, isEmpty);
    expect(File('${temp.path}/lib/app/app.dart').readAsStringSync(), before);
  });

  test('create route registers an existing feature View', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'auth');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'route', 'auth'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Registered route AuthView.'));
    expect(
      output.content,
      contains('Next step: dart run build_runner build -d'),
    );
    expect(errorOutput.content, isEmpty);
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains("import 'package:my_app/features/auth/ui/auth_view.dart';"),
    );
    expect(app, contains('    MaterialRoute(page: AuthView),'));
  });

  test('create route rejects project creation options', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'auth');
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'route', 'auth', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create route.'),
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
        ['create', '--dry-run', 'view', 'auth', 'forgot-password'],
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
      ['create', 'view', 'auth', 'forgot-password'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created view Forgot Password.'));
    expect(errorOutput.content, isEmpty);
    final view = File(
      '${temp.path}/lib/features/auth/ui/forgot_password_view.dart',
    ).readAsStringSync();
    expect(
      view,
      contains(
        'class ForgotPasswordView extends StackedView<ForgotPasswordViewModel>',
      ),
    );
    final viewModel = File(
      '${temp.path}/lib/features/auth/ui/forgot_password_viewmodel.dart',
    ).readAsStringSync();
    expect(
      viewModel,
      contains('class ForgotPasswordViewModel extends BaseViewModel {}'),
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
      ['create', 'view', 'auth', 'login', '--directory', 'ignored'],
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
      ['create', 'view', 'auth'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a feature name and view name.'),
    );
  });

  test('create repository with dry-run creates no files', () async {
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
      ['create', '--dry-run', 'repository', 'todo'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Repository: TodoRepository'));
    expect(output.content, contains('Table: todos'));
    expect(output.content, contains('- lib/supabase/todo_repository.dart'));
    expect(
      output.content,
      contains('LazySingleton(classType: TodoRepository),'),
    );
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create repository generates a new entity and registers it', () async {
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
      ['create', 'repository', 'category'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created repository CategoryRepository.'));
    expect(output.content, contains('Table: categories'));
    expect(output.content, contains('- dart run build_runner build -d'));
    expect(output.content, contains('supabase db push'));
    expect(errorOutput.content, isEmpty);
    final repository = File(
      '${temp.path}/lib/supabase/category_repository.dart',
    ).readAsStringSync();
    expect(repository, contains('class CategoryRepository {'));
    expect(repository, contains("static const _table = 'categories';"));
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains("import 'package:my_app/supabase/category_repository.dart';"),
    );
    expect(app, contains('LazySingleton(classType: CategoryRepository),'));
    expect(
      Directory(
        '${temp.path}/supabase/migrations',
      ).listSync().whereType<File>().length,
      1,
    );
  });

  test('create repository rejects project creation options', () async {
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
      ['create', 'repository', 'todo', '--directory', 'ignored'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Only --dry-run is supported for cuboid create repository.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
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
    final widget = File(
      '${temp.path}/lib/shared/widgets/status_badge.dart',
    ).readAsStringSync();
    expect(widget, contains('class StatusBadge extends StatelessWidget {'));
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
        ['create', 'widget', 'auth', 'password_field'],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Created widget PasswordField.'));
      expect(output.content, contains('Feature: auth'));
      expect(errorOutput.content, isEmpty);
      final widget = File(
        '${temp.path}/lib/features/auth/ui/widgets/password_field.dart',
      ).readAsStringSync();
      expect(widget, contains('class PasswordField extends StatelessWidget {'));
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
    expect(output.content, contains('- lib/shared/widgets/status_badge.dart'));
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
      contains('Expected a widget name, or a feature name and widget name.'),
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
    File('${temp.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
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

  test('route dry-run reports planned registration without writing', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'user_profile');
    final before = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['route', 'user-profile', '--dry-run'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Route: UserProfileView'));
    expect(output.content, contains('- lib/app/app.dart'));
    expect(
      output.content,
      contains(
        "import 'package:my_app/features/user_profile/ui/user_profile_view.dart';",
      ),
    );
    expect(output.content, contains('MaterialRoute(page: UserProfileView),'));
    expect(errorOutput.content, isEmpty);
    expect(File('${temp.path}/lib/app/app.dart').readAsStringSync(), before);
  });

  test('route command registers an existing feature View', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'auth');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['route', 'auth'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Registered route AuthView.'));
    expect(
      output.content,
      contains('Next step: dart run build_runner build -d'),
    );
    expect(errorOutput.content, isEmpty);
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains("import 'package:my_app/features/auth/ui/auth_view.dart';"),
    );
    expect(app, contains('    MaterialRoute(page: AuthView),'));
  });

  test('route validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['route'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(errorOutput.content, contains('Expected a feature name.'));
  });

  test('route service failures return non-zero and write stderr', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'auth');
    File('${temp.path}/lib/features/auth/ui/auth_view.dart').deleteSync();
    Directory.current = temp;
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['route', 'auth'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 1);
    expect(
      errorOutput.content,
      contains('lib/features/auth/ui/auth_view.dart was not found.'),
    );
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
      final before = File('${temp.path}/lib/app/app.dart').readAsStringSync();
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
      expect(output.content, contains('- lib/app/app.dart'));
      expect(
        output.content,
        contains(
          "import 'package:my_app/core/services/auth_session_service.dart';",
        ),
      );
      expect(
        output.content,
        contains('LazySingleton(classType: AuthSessionService),'),
      );
      expect(errorOutput.content, isEmpty);
      expect(File('${temp.path}/lib/app/app.dart').readAsStringSync(), before);
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
    expect(
      output.content,
      contains('Next step: dart run build_runner build -d'),
    );
    expect(errorOutput.content, isEmpty);
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:my_app/core/services/auth_session_service.dart';",
      ),
    );
    expect(app, contains('    LazySingleton(classType: AuthSessionService),'));
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
      ['view', 'auth', 'forgot-password', '--dry-run'],
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
      ['view', 'auth', 'forgot-password'],
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
        "import 'package:my_app/features/auth/ui/forgot_password_viewmodel.dart';",
      ),
    );
    expect(
      view,
      contains(
        'class ForgotPasswordView extends StackedView<ForgotPasswordViewModel>',
      ),
    );
    expect(
      viewModel,
      contains('class ForgotPasswordViewModel extends BaseViewModel {}'),
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
      contains('Expected a feature name and view name.'),
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
      ['view', 'auth', 'login'],
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
      'My App',
      'com.example.myapp',
    ]);

    expect(exitCode, 0);
    expect(output.content, contains('Created My App.'));
    expect(Directory('${temp.path}/my_app').existsSync(), isTrue);
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

void _writeRouteProject(Directory root, String featureName) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/features/startup/ui/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    // @stacked-route
  ],
)
class App {}
''');
  File('${root.path}/lib/features/$featureName/ui/${featureName}_view.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class View {}\n');
}

void _writeViewProject(Directory root, String featureName) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  Directory(
    '${root.path}/lib/features/$featureName',
  ).createSync(recursive: true);
}

void _writeFeatureProject(Directory root, {String pubspec = 'name: my_app\n'}) {
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  File('${root.path}/lib/app/app.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('app registration\n');
  Directory('${root.path}/lib/features').createSync(recursive: true);
}

void _writeServiceProject(
  Directory root, {
  String serviceName = 'auth_session',
  bool createFile = true,
}) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/core/services/shell_service.dart';
import 'package:stacked/stacked_annotations.dart';
// @stacked-import

@StackedApp(
  dependencies: [
    LazySingleton(classType: ShellService),
    // @stacked-service
  ],
)
class App {}
''');
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
  File('${root.path}/lib/app/app.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/core/services/shell_service.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: ShellService),
    // @stacked-service
  ],
)
class App {}
''');
  File('${root.path}/lib/main.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/app/app.locator.dart';

Future<void> main() async {
  await setupLocator();
}
''');
}

void _writeDialogProject(Directory root) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/core/services/shell_service.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: ShellService),
    // @stacked-service
  ],
)
class App {}
''');
  File('${root.path}/lib/main.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/app/app.locator.dart';

Future<void> main() async {
  await setupLocator();
}
''');
}

void _writeStorageProject(Directory root) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
}

void _writeModelProject(Directory root) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
}

void _writeDatabaseProject(Directory root) {
  File('${root.path}/pubspec.yaml').writeAsStringSync(
    'name: my_app\ndependencies:\n  supabase_flutter: ^2.16.0\n',
  );
  File('${root.path}/lib/app/app.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/core/services/shell_service.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: ShellService),
    // @stacked-service
  ],
)
class App {}
''');
  File('${root.path}/lib/core/network/supabase_guard.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('Future<void> guard() async {}\n');
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
