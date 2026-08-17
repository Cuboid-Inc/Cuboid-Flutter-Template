import 'dart:io';

import 'package:cuboid/src/bottomsheet/create_bottomsheet.dart';
import 'package:cuboid/src/create/create_project.dart' show ProcessRunner;
import 'package:test/test.dart';

void main() {
  test('creates files and first-use Stacked registration', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final calls = <List<Object?>>[];
    final service = CreateBottomSheetService(
      processRunner: _recordingProcessRunner(calls),
    );

    final result = await service.create(
      CreateBottomSheetInput(name: 'confirm_delete', projectRoot: root),
    );

    expect(calls, [
      [
        'dart',
        ['run', 'build_runner', 'build', '-d'],
        root.path,
      ],
    ]);
    expect(result.buildRunnerResult?.exitCode, 0);
    expect(result.plan.name, 'confirm_delete');
    expect(result.plan.sheetClassName, 'ConfirmDeleteSheet');
    expect(result.plan.modelClassName, 'ConfirmDeleteSheetModel');
    expect(
      File(
        '${root.path}/lib/shared/bottom_sheets/confirm_delete/'
        'confirm_delete_sheet.dart',
      ).readAsStringSync(),
      contains(
        'class ConfirmDeleteSheet extends '
        'StackedView<ConfirmDeleteSheetModel>',
      ),
    );
    expect(
      File(
        '${root.path}/lib/shared/bottom_sheets/confirm_delete/'
        'confirm_delete_sheet_model.dart',
      ).readAsStringSync(),
      'import \'package:stacked/stacked.dart\';\n\n'
      'class ConfirmDeleteSheetModel extends BaseViewModel {}\n',
    );
    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:test_app/shared/bottom_sheets/confirm_delete/"
        "confirm_delete_sheet.dart';",
      ),
    );
    expect(app, contains('  bottomsheets: ['));
    expect(
      app,
      contains('    StackedBottomsheet(classType: ConfirmDeleteSheet),'),
    );
    expect(app, contains('    // @stacked-bottom-sheet'));
    expect(app, contains('    LazySingleton(classType: BottomSheetService),'));

    final main = _mainFile(root).readAsStringSync();
    expect(
      main,
      contains("import 'package:test_app/app/app.bottomsheets.dart';"),
    );
    expect(main, contains('  await setupLocator();\n  setupBottomSheetUi();'));
  });

  test(
    'adds to existing bottomsheets and avoids duplicate runtime setup',
    () async {
      final root = _projectRoot(existingBottomSheets: true);
      addTearDown(() => root.deleteSync(recursive: true));
      _mainFile(root).writeAsStringSync('''
import 'package:test_app/app/app.bottomsheets.dart';
import 'package:test_app/app/app.locator.dart';

Future<void> main() async {
  await setupLocator();
  setupBottomSheetUi();
}
''');
      final service = CreateBottomSheetService(
        processRunner: _successProcessRunner,
      );

      await service.create(
        CreateBottomSheetInput(name: 'confirm-delete', projectRoot: root),
      );

      final app = _appFile(root).readAsStringSync();
      expect(
        app,
        contains('    StackedBottomsheet(classType: ConfirmDeleteSheet),'),
      );
      expect('// @stacked-bottom-sheet'.allMatches(app), hasLength(1));
      final main = _mainFile(root).readAsStringSync();
      expect("app/app.bottomsheets.dart';".allMatches(main), hasLength(1));
      expect('setupBottomSheetUi();'.allMatches(main), hasLength(1));
    },
  );

  test('reports a clear error and keeps the written files when build_runner '
      'fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateBottomSheetService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async =>
              ProcessResult(0, 1, '', 'boom'),
    );

    await expectLater(
      service.create(
        CreateBottomSheetInput(name: 'confirm_delete', projectRoot: root),
      ),
      throwsA(
        isA<CreateBottomSheetException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('dart run build_runner build -d failed'),
            contains('boom'),
            contains('Bottom sheet Confirm Delete was created'),
          ),
        ),
      ),
    );

    expect(
      File(
        '${root.path}/lib/shared/bottom_sheets/confirm_delete/'
        'confirm_delete_sheet.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      _appFile(root).readAsStringSync(),
      contains('    StackedBottomsheet(classType: ConfirmDeleteSheet),'),
    );
  });

  test('dry-run validates and writes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final beforeMain = _mainFile(root).readAsStringSync();
    final service = CreateBottomSheetService();

    final result = await service.create(
      CreateBottomSheetInput(
        name: 'Confirm-Delete',
        projectRoot: root,
        dryRun: true,
      ),
    );

    expect(result.plan.name, 'confirm_delete');
    expect(result.plan.dryRun, isTrue);
    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(_mainFile(root).readAsStringSync(), beforeMain);
  });

  test('rejects invalid names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateBottomSheetService();

    for (final name in [
      '',
      'two words',
      '1login',
      '_login',
      'login_',
      'login__sheet',
      '.',
      '..',
      'auth/login',
      r'auth\login',
      'class',
    ]) {
      await expectLater(
        service.create(CreateBottomSheetInput(name: name, projectRoot: root)),
        throwsA(isA<CreateBottomSheetException>()),
        reason: name,
      );
    }
  });

  test('rejects existing directory without mutation', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      '${root.path}/lib/shared/bottom_sheets/confirm_delete',
    ).createSync(recursive: true);
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final beforeMain = _mainFile(root).readAsStringSync();
    final service = CreateBottomSheetService();

    await expectLater(
      service.create(
        CreateBottomSheetInput(name: 'confirm_delete', projectRoot: root),
      ),
      throwsA(
        isA<CreateBottomSheetException>().having(
          (error) => error.message,
          'message',
          'Bottom sheet already exists: '
              'lib/shared/bottom_sheets/confirm_delete',
        ),
      ),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(_mainFile(root).readAsStringSync(), beforeMain);
  });

  test('rejects symlink ancestors', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = Directory('${root.path}/target_shared')..createSync();
    final shared = Link('${root.path}/lib/shared');
    shared.parent.createSync(recursive: true);
    shared.createSync(target.path);
    final service = CreateBottomSheetService();

    await expectLater(
      service.create(
        CreateBottomSheetInput(name: 'confirm', projectRoot: root),
      ),
      throwsA(isA<CreateBottomSheetException>()),
    );
  });

  test('rejects conflicting app and main registrations', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _appFile(root).writeAsStringSync(
      _appContents(
        extraImport:
            "import 'package:other/shared/bottom_sheets/confirm/"
            "confirm_sheet.dart';\n",
      ),
    );
    final service = CreateBottomSheetService();

    await expectLater(
      service.create(
        CreateBottomSheetInput(name: 'confirm', projectRoot: root),
      ),
      throwsA(
        isA<CreateBottomSheetException>().having(
          (error) => error.message,
          'message',
          contains('Conflicting bottom sheet import'),
        ),
      ),
    );
  });

  test('restores app.dart when main.dart update fails', () async {
    final root = _projectRoot();
    addTearDown(() {
      Process.runSync('chmod', ['755', '${root.path}/lib']);
      root.deleteSync(recursive: true);
    });
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final beforeMain = _mainFile(root).readAsStringSync();
    Directory(
      '${root.path}/lib/shared/bottom_sheets',
    ).createSync(recursive: true);
    Process.runSync('chmod', ['555', '${root.path}/lib']);
    final service = CreateBottomSheetService();

    await expectLater(
      service.create(
        CreateBottomSheetInput(name: 'confirm', projectRoot: root),
      ),
      throwsA(isA<CreateBottomSheetException>()),
    );

    Process.runSync('chmod', ['755', '${root.path}/lib']);
    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(_mainFile(root).readAsStringSync(), beforeMain);
  }, skip: Platform.isWindows);
}

Directory _projectRoot({bool existingBottomSheets = false}) {
  final root = Directory.systemTemp.createTempSync('cuboid_bottomsheet_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  _appFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      _appContents(existingBottomSheets: existingBottomSheets),
    );
  _mainFile(root).writeAsStringSync('''
import 'package:test_app/app/app.locator.dart';

Future<void> main() async {
  await setupLocator();
}
''');
  return root;
}

String _appContents({
  bool existingBottomSheets = false,
  String extraImport = '',
}) {
  final bottomSheets = existingBottomSheets
      ? '''
  bottomsheets: [
    // @stacked-bottom-sheet
  ],
'''
      : '';
  return '''
${extraImport}import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    // @stacked-route
  ],
$bottomSheets  dependencies: [
    LazySingleton(classType: NavigationService),
    // @stacked-service
  ],
)
class App {}
''';
}

Future<ProcessResult> _successProcessRunner(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async => ProcessResult(0, 0, '', '');

ProcessRunner _recordingProcessRunner(List<List<Object?>> calls) {
  return (executable, arguments, {required workingDirectory}) async {
    calls.add([executable, arguments, workingDirectory]);
    return ProcessResult(0, 0, '', '');
  };
}

File _appFile(Directory root) => File('${root.path}/lib/app/app.dart');

File _mainFile(Directory root) => File('${root.path}/lib/main.dart');

List<String> _relativeFiles(Directory root) {
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.substring(root.path.length + 1))
          .map((path) => path.replaceAll(Platform.pathSeparator, '/'))
          .toList()
        ..sort();
  return files;
}
