import 'dart:io';

import 'package:cuboid/src/dialog/create_dialog.dart';
import 'package:test/test.dart';

void main() {
  test('creates files and first-use Stacked registration', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateDialogService();

    final result = await service.create(
      CreateDialogInput(name: 'confirm_delete', projectRoot: root),
    );

    expect(result.plan.name, 'confirm_delete');
    expect(result.plan.dialogClassName, 'ConfirmDeleteDialog');
    expect(result.plan.modelClassName, 'ConfirmDeleteDialogModel');
    expect(
      File(
        '${root.path}/lib/shared/dialogs/confirm_delete/'
        'confirm_delete_dialog.dart',
      ).readAsStringSync(),
      contains(
        'class ConfirmDeleteDialog extends '
        'StackedView<ConfirmDeleteDialogModel>',
      ),
    );
    final dialog = File(
      '${root.path}/lib/shared/dialogs/confirm_delete/'
      'confirm_delete_dialog.dart',
    ).readAsStringSync();
    expect(dialog, contains('final DialogRequest<dynamic> request;'));
    expect(
      dialog,
      contains(
        'final void Function(DialogResponse<dynamic> response) completer;',
      ),
    );
    expect(
      File(
        '${root.path}/lib/shared/dialogs/confirm_delete/'
        'confirm_delete_dialog_model.dart',
      ).readAsStringSync(),
      'import \'package:stacked/stacked.dart\';\n\n'
      'class ConfirmDeleteDialogModel extends BaseViewModel {}\n',
    );
    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:test_app/shared/dialogs/confirm_delete/"
        "confirm_delete_dialog.dart';",
      ),
    );
    expect(app, contains('  dialogs: ['));
    expect(
      app,
      contains(
        '    StackedDialog(\n'
        '      classType: ConfirmDeleteDialog,\n'
        '    ),',
      ),
    );
    expect(app, contains('    // @stacked-dialog'));
    expect(app, contains('    LazySingleton(classType: DialogService),'));

    final main = _mainFile(root).readAsStringSync();
    expect(main, contains("import 'package:test_app/app/app.dialogs.dart';"));
    expect(main, contains('  await setupLocator();\n  setupDialogUi();'));
  });

  test('adds to existing dialogs and avoids duplicate runtime setup', () async {
    final root = _projectRoot(existingDialogs: true);
    addTearDown(() => root.deleteSync(recursive: true));
    _mainFile(root).writeAsStringSync('''
import 'package:test_app/app/app.dialogs.dart';
import 'package:test_app/app/app.locator.dart';

Future<void> main() async {
  await setupLocator();
  setupDialogUi();
}
''');
    final service = CreateDialogService();

    await service.create(
      CreateDialogInput(name: 'confirm-delete', projectRoot: root),
    );

    final app = _appFile(root).readAsStringSync();
    expect(
      app,
      contains(
        '    StackedDialog(\n'
        '      classType: ConfirmDeleteDialog,\n'
        '    ),',
      ),
    );
    expect('// @stacked-dialog'.allMatches(app), hasLength(1));
    final main = _mainFile(root).readAsStringSync();
    expect("app/app.dialogs.dart';".allMatches(main), hasLength(1));
    expect('setupDialogUi();'.allMatches(main), hasLength(1));
  });

  test('dry-run validates and writes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final beforeMain = _mainFile(root).readAsStringSync();
    final service = CreateDialogService();

    final result = await service.create(
      CreateDialogInput(
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
    final service = CreateDialogService();

    for (final name in [
      '',
      'two words',
      '1login',
      '_login',
      'login_',
      'login__dialog',
      '.',
      '..',
      'auth/login',
      r'auth\login',
      'class',
    ]) {
      await expectLater(
        service.create(CreateDialogInput(name: name, projectRoot: root)),
        throwsA(isA<CreateDialogException>()),
        reason: name,
      );
    }
  });

  test('rejects existing directory without mutation', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      '${root.path}/lib/shared/dialogs/confirm_delete',
    ).createSync(recursive: true);
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final beforeMain = _mainFile(root).readAsStringSync();
    final service = CreateDialogService();

    await expectLater(
      service.create(
        CreateDialogInput(name: 'confirm_delete', projectRoot: root),
      ),
      throwsA(
        isA<CreateDialogException>().having(
          (error) => error.message,
          'message',
          'Dialog already exists: '
              'lib/shared/dialogs/confirm_delete',
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
    final service = CreateDialogService();

    await expectLater(
      service.create(CreateDialogInput(name: 'confirm', projectRoot: root)),
      throwsA(isA<CreateDialogException>()),
    );
  });

  test('rejects conflicting app and main registrations', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _appFile(root).writeAsStringSync(
      _appContents(
        extraImport:
            "import 'package:other/shared/dialogs/confirm/"
            "confirm_dialog.dart';\n",
      ),
    );
    final service = CreateDialogService();

    await expectLater(
      service.create(CreateDialogInput(name: 'confirm', projectRoot: root)),
      throwsA(
        isA<CreateDialogException>().having(
          (error) => error.message,
          'message',
          contains('Conflicting dialog import'),
        ),
      ),
    );
  });

  test(
    'restores app.dart and removes dialog files when main.dart update fails',
    () async {
      final root = _projectRoot();
      addTearDown(() {
        Process.runSync('chmod', ['755', '${root.path}/lib']);
        root.deleteSync(recursive: true);
      });
      final beforeFiles = _relativeFiles(root);
      final beforeApp = _appFile(root).readAsStringSync();
      final beforeMain = _mainFile(root).readAsStringSync();
      Directory('${root.path}/lib/shared/dialogs').createSync(recursive: true);
      Process.runSync('chmod', ['555', '${root.path}/lib']);
      final service = CreateDialogService();

      await expectLater(
        service.create(CreateDialogInput(name: 'confirm', projectRoot: root)),
        throwsA(isA<CreateDialogException>()),
      );

      Process.runSync('chmod', ['755', '${root.path}/lib']);
      expect(_relativeFiles(root), beforeFiles);
      expect(_appFile(root).readAsStringSync(), beforeApp);
      expect(_mainFile(root).readAsStringSync(), beforeMain);
    },
    skip: Platform.isWindows,
  );

  test(
    'rolls back and creates no directory when the dialog file write fails',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final beforeFiles = _relativeFiles(root);
      final beforeApp = _appFile(root).readAsStringSync();
      final beforeMain = _mainFile(root).readAsStringSync();
      final service = CreateDialogService(
        fileWriter: (file, contents) {
          throw const FileSystemException('simulated write failure');
        },
      );

      await expectLater(
        service.create(CreateDialogInput(name: 'confirm', projectRoot: root)),
        throwsA(isA<CreateDialogException>()),
      );

      expect(_relativeFiles(root), beforeFiles);
      expect(_appFile(root).readAsStringSync(), beforeApp);
      expect(_mainFile(root).readAsStringSync(), beforeMain);
      expect(
        Directory('${root.path}/lib/shared/dialogs/confirm').existsSync(),
        isFalse,
      );
    },
  );

  test('rolls back the dialog file and removes the empty directory when the '
      'model file write fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final beforeMain = _mainFile(root).readAsStringSync();
    var writeCount = 0;
    final service = CreateDialogService(
      fileWriter: (file, contents) {
        writeCount++;
        if (writeCount == 1) {
          file.writeAsStringSync(contents);
          return;
        }
        throw const FileSystemException('simulated write failure');
      },
    );

    await expectLater(
      service.create(CreateDialogInput(name: 'confirm', projectRoot: root)),
      throwsA(isA<CreateDialogException>()),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(_mainFile(root).readAsStringSync(), beforeMain);
    expect(
      Directory('${root.path}/lib/shared/dialogs/confirm').existsSync(),
      isFalse,
    );
  });

  test('removes dialog files and leaves main.dart untouched when the '
      'app.dart update fails', () async {
    final root = _projectRoot();
    addTearDown(() {
      Process.runSync('chmod', ['755', '${root.path}/lib/app']);
      root.deleteSync(recursive: true);
    });
    final beforeFiles = _relativeFiles(root);
    final beforeApp = _appFile(root).readAsStringSync();
    final beforeMain = _mainFile(root).readAsStringSync();
    Process.runSync('chmod', ['555', '${root.path}/lib/app']);
    final service = CreateDialogService();

    await expectLater(
      service.create(CreateDialogInput(name: 'confirm', projectRoot: root)),
      throwsA(isA<CreateDialogException>()),
    );

    Process.runSync('chmod', ['755', '${root.path}/lib/app']);
    expect(_relativeFiles(root), beforeFiles);
    expect(_appFile(root).readAsStringSync(), beforeApp);
    expect(_mainFile(root).readAsStringSync(), beforeMain);
    expect(
      Directory('${root.path}/lib/shared/dialogs/confirm').existsSync(),
      isFalse,
    );
  }, skip: Platform.isWindows);
}

Directory _projectRoot({bool existingDialogs = false}) {
  final root = Directory.systemTemp.createTempSync('cuboid_dialog_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  _appFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_appContents(existingDialogs: existingDialogs));
  _mainFile(root).writeAsStringSync('''
import 'package:test_app/app/app.locator.dart';

Future<void> main() async {
  await setupLocator();
}
''');
  return root;
}

String _appContents({bool existingDialogs = false, String extraImport = ''}) {
  final dialogs = existingDialogs
      ? '''
  dialogs: [
    // @stacked-dialog
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
$dialogs  dependencies: [
    LazySingleton(classType: NavigationService),
    // @stacked-service
  ],
)
class App {}
''';
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
