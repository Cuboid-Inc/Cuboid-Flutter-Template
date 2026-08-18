import 'dart:io';

import 'package:cuboid/src/bottomsheet/create_bottomsheet.dart';
import 'package:test/test.dart';

void main() {
  test('creates files and first-use registration', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateBottomSheetService();

    final result = await service.create(
      CreateBottomSheetInput(name: 'confirm_delete', projectRoot: root),
    );

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
        'CuboidView<ConfirmDeleteSheetModel>',
      ),
    );
    expect(
      File(
        '${root.path}/lib/shared/bottom_sheets/confirm_delete/'
        'confirm_delete_sheet_model.dart',
      ).readAsStringSync(),
      "import 'package:test_app/core/mvvm/cuboid_view_model.dart';\n\n"
      'class ConfirmDeleteSheetModel extends CuboidViewModel {}\n',
    );

    final bottomSheets = _bottomSheetsFile(root).readAsStringSync();
    expect(
      bottomSheets,
      contains(
        "import 'package:test_app/shared/bottom_sheets/confirm_delete/"
        "confirm_delete_sheet.dart';",
      ),
    );
    expect(
      bottomSheets,
      contains(
        "import 'package:test_app/shared/bottom_sheets/confirm_delete/"
        "confirm_delete_sheet_model.dart';",
      ),
    );
    expect(
      bottomSheets,
      contains('ConfirmDeleteSheetModel: (_) => const ConfirmDeleteSheet(),'),
    );
    expect(bottomSheets, contains('// @cuboid-bottom-sheet'));

    final serviceFile = _bottomSheetServiceFile(root).readAsStringSync();
    expect(serviceFile, contains('class BottomSheetService {'));
    expect(
      serviceFile,
      contains("import 'package:test_app/app/app.bottomsheets.dart';"),
    );

    final locator = _locatorFile(root).readAsStringSync();
    expect(
      locator,
      contains(
        "import 'package:test_app/core/services/bottom_sheet_service.dart';",
      ),
    );
    expect(
      locator,
      contains(
        '  locator.registerLazySingleton<BottomSheetService>(() => BottomSheetService());',
      ),
    );
  });

  test(
    'adds to existing bottomsheets and does not re-register the service',
    () async {
      final root = _projectRoot(
        existingBottomSheets: true,
        existingService: true,
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateBottomSheetService();

      await service.create(
        CreateBottomSheetInput(name: 'confirm-delete', projectRoot: root),
      );

      final bottomSheets = _bottomSheetsFile(root).readAsStringSync();
      expect(
        bottomSheets,
        contains('ConfirmDeleteSheetModel: (_) => const ConfirmDeleteSheet(),'),
      );
      expect('// @cuboid-bottom-sheet'.allMatches(bottomSheets), hasLength(1));

      final locator = _locatorFile(root).readAsStringSync();
      expect(
        'registerLazySingleton<BottomSheetService>'.allMatches(locator),
        hasLength(1),
      );
    },
  );

  test('dry-run validates and writes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final beforeLocator = _locatorFile(root).readAsStringSync();
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
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
    expect(_bottomSheetsFile(root).existsSync(), isFalse);
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
    final beforeLocator = _locatorFile(root).readAsStringSync();
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
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
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

  test(
    'rejects a duplicate bottom sheet import in app.bottomsheets.dart',
    () async {
      final root = _projectRoot(
        existingBottomSheets: true,
        existingService: true,
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _bottomSheetsFile(root).writeAsStringSync(
        _bottomSheetsContents(
          extraImport:
              "import 'package:test_app/shared/bottom_sheets/confirm/"
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
            contains('Bottom sheet import already exists'),
          ),
        ),
      );
    },
  );

  test('rejects a duplicate BottomSheetService registration', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    _locatorFile(root).writeAsStringSync(
      _locatorContents(
        extraService:
            '  locator.registerLazySingleton<BottomSheetService>(() => BottomSheetService());\n',
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
          'Duplicate BottomSheetService registration.',
        ),
      ),
    );
  });

  test(
    'restores locator.dart when the bottomsheets file update fails',
    () async {
      final root = _projectRoot(
        existingBottomSheets: true,
        existingService: true,
      );
      addTearDown(() {
        Process.runSync('chmod', ['755', '${root.path}/lib/app']);
        root.deleteSync(recursive: true);
      });
      final beforeFiles = _relativeFiles(root);
      final beforeLocator = _locatorFile(root).readAsStringSync();
      final beforeBottomSheets = _bottomSheetsFile(root).readAsStringSync();
      Process.runSync('chmod', ['555', '${root.path}/lib/app']);
      final service = CreateBottomSheetService();

      await expectLater(
        service.create(
          CreateBottomSheetInput(name: 'confirm', projectRoot: root),
        ),
        throwsA(isA<CreateBottomSheetException>()),
      );

      Process.runSync('chmod', ['755', '${root.path}/lib/app']);
      expect(_relativeFiles(root), beforeFiles);
      expect(_locatorFile(root).readAsStringSync(), beforeLocator);
      expect(_bottomSheetsFile(root).readAsStringSync(), beforeBottomSheets);
    },
    skip: Platform.isWindows,
  );
}

Directory _projectRoot({
  bool existingBottomSheets = false,
  bool existingService = false,
}) {
  final root = Directory.systemTemp.createTempSync('cuboid_bottomsheet_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  _locatorFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      _locatorContents(
        extraService: existingService
            ? '  locator.registerLazySingleton<BottomSheetService>(() => BottomSheetService());\n'
            : '',
      ),
    );
  if (existingBottomSheets) {
    _bottomSheetsFile(root).writeAsStringSync(_bottomSheetsContents());
  }
  if (existingService) {
    _bottomSheetServiceFile(root)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('class BottomSheetService {}\n');
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

String _bottomSheetsContents({String extraImport = ''}) {
  return '''
import 'package:flutter/material.dart';
$extraImport// @cuboid-import

final Map<Type, WidgetBuilder> cuboidBottomSheetBuilders = {
  // @cuboid-bottom-sheet
};
''';
}

File _locatorFile(Directory root) =>
    File('${root.path}/lib/app/app.locator.dart');

File _bottomSheetsFile(Directory root) =>
    File('${root.path}/lib/app/app.bottomsheets.dart');

File _bottomSheetServiceFile(Directory root) =>
    File('${root.path}/lib/core/services/bottom_sheet_service.dart');

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
