import 'dart:io';

import 'package:cuboid/src/dialog/create_dialog.dart';
import 'package:test/test.dart';

void main() {
  test('creates files and first-use registration', () async {
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
        'CuboidView<ConfirmDeleteDialogModel>',
      ),
    );
    expect(
      File(
        '${root.path}/lib/shared/dialogs/confirm_delete/'
        'confirm_delete_dialog_model.dart',
      ).readAsStringSync(),
      "import 'package:test_app/core/mvvm/cuboid_view_model.dart';\n\n"
      'class ConfirmDeleteDialogModel extends CuboidViewModel {}\n',
    );

    final dialogs = _dialogsFile(root).readAsStringSync();
    expect(
      dialogs,
      contains(
        "import 'package:test_app/shared/dialogs/confirm_delete/"
        "confirm_delete_dialog.dart';",
      ),
    );
    expect(
      dialogs,
      contains(
        "import 'package:test_app/shared/dialogs/confirm_delete/"
        "confirm_delete_dialog_model.dart';",
      ),
    );
    expect(
      dialogs,
      contains('ConfirmDeleteDialogModel: (_) => const ConfirmDeleteDialog(),'),
    );
    expect(dialogs, contains('// @cuboid-dialog'));

    final serviceFile = _dialogServiceFile(root).readAsStringSync();
    expect(serviceFile, contains('class DialogService {'));
    expect(
      serviceFile,
      contains("import 'package:test_app/app/app.dialogs.dart';"),
    );

    final locator = _locatorFile(root).readAsStringSync();
    expect(
      locator,
      contains("import 'package:test_app/core/services/dialog_service.dart';"),
    );
    expect(
      locator,
      contains(
        '  locator.registerLazySingleton<DialogService>(() => DialogService());',
      ),
    );
  });

  test(
    'adds to existing dialogs and does not re-register the service',
    () async {
      final root = _projectRoot(existingDialogs: true, existingService: true);
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateDialogService();

      await service.create(
        CreateDialogInput(name: 'confirm-delete', projectRoot: root),
      );

      final dialogs = _dialogsFile(root).readAsStringSync();
      expect(
        dialogs,
        contains(
          'ConfirmDeleteDialogModel: (_) => const ConfirmDeleteDialog(),',
        ),
      );
      expect('// @cuboid-dialog'.allMatches(dialogs), hasLength(1));

      final locator = _locatorFile(root).readAsStringSync();
      expect(
        'registerLazySingleton<DialogService>'.allMatches(locator),
        hasLength(1),
      );
    },
  );

  test('dry-run validates and writes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeLocator = _locatorFile(root).readAsStringSync();
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
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
    expect(_dialogsFile(root).existsSync(), isFalse);
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
    final beforeLocator = _locatorFile(root).readAsStringSync();
    final service = CreateDialogService();

    await expectLater(
      service.create(
        CreateDialogInput(name: 'confirm_delete', projectRoot: root),
      ),
      throwsA(
        isA<CreateDialogException>().having(
          (error) => error.message,
          'message',
          'Dialog already exists: lib/shared/dialogs/confirm_delete',
        ),
      ),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
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

  test('rejects a duplicate dialog import in app.dialogs.dart', () async {
    final root = _projectRoot(existingDialogs: true, existingService: true);
    addTearDown(() => root.deleteSync(recursive: true));
    _dialogsFile(root).writeAsStringSync(
      _dialogsContents(
        extraImport:
            "import 'package:test_app/shared/dialogs/confirm/"
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
          contains('Dialog import already exists'),
        ),
      ),
    );
  });

  test('rejects a duplicate DialogService registration', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _locatorFile(root).writeAsStringSync(
      _locatorContents(
        extraService:
            '  locator.registerLazySingleton<DialogService>(() => DialogService());\n',
      ),
    );
    final service = CreateDialogService();

    await expectLater(
      service.create(CreateDialogInput(name: 'confirm', projectRoot: root)),
      throwsA(
        isA<CreateDialogException>().having(
          (error) => error.message,
          'message',
          'Duplicate DialogService registration.',
        ),
      ),
    );
  });

  test(
    'rolls back and creates no directory when the dialog file write fails',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final beforeFiles = _relativeFiles(root);
      final beforeLocator = _locatorFile(root).readAsStringSync();
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
      expect(_locatorFile(root).readAsStringSync(), beforeLocator);
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
    final beforeLocator = _locatorFile(root).readAsStringSync();
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
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
    expect(
      Directory('${root.path}/lib/shared/dialogs/confirm').existsSync(),
      isFalse,
    );
  });

  test(
    'restores locator.dart when the dialogs file update fails',
    () async {
      final root = _projectRoot(existingDialogs: true, existingService: true);
      addTearDown(() {
        Process.runSync('chmod', ['755', '${root.path}/lib/app']);
        root.deleteSync(recursive: true);
      });
      final beforeFiles = _relativeFiles(root);
      final beforeLocator = _locatorFile(root).readAsStringSync();
      final beforeDialogs = _dialogsFile(root).readAsStringSync();
      Process.runSync('chmod', ['555', '${root.path}/lib/app']);
      final service = CreateDialogService();

      await expectLater(
        service.create(CreateDialogInput(name: 'confirm', projectRoot: root)),
        throwsA(isA<CreateDialogException>()),
      );

      Process.runSync('chmod', ['755', '${root.path}/lib/app']);
      expect(_relativeFiles(root), beforeFiles);
      expect(_locatorFile(root).readAsStringSync(), beforeLocator);
      expect(_dialogsFile(root).readAsStringSync(), beforeDialogs);
    },
    skip: Platform.isWindows,
  );
}

Directory _projectRoot({
  bool existingDialogs = false,
  bool existingService = false,
}) {
  final root = Directory.systemTemp.createTempSync('cuboid_dialog_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  _locatorFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      _locatorContents(
        extraService: existingService
            ? '  locator.registerLazySingleton<DialogService>(() => DialogService());\n'
            : '',
      ),
    );
  if (existingDialogs) {
    _dialogsFile(root).writeAsStringSync(_dialogsContents());
  }
  if (existingService) {
    _dialogServiceFile(root)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('class DialogService {}\n');
  }
  return root;
}

String _locatorContents({String extraService = ''}) {
  return '''
import 'package:get_it/get_it.dart';
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
$extraService  // @cuboid-service
}
''';
}

String _dialogsContents({String extraImport = ''}) {
  return '''
import 'package:flutter/material.dart';
$extraImport// @cuboid-import

final Map<Type, WidgetBuilder> cuboidDialogBuilders = {
  // @cuboid-dialog
};
''';
}

File _locatorFile(Directory root) =>
    File('${root.path}/lib/app/app.locator.dart');

File _dialogsFile(Directory root) =>
    File('${root.path}/lib/app/app.dialogs.dart');

File _dialogServiceFile(Directory root) =>
    File('${root.path}/lib/core/services/dialog_service.dart');

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
