import 'dart:io';

import 'package:cuboid/src/bottomsheet/create_bottomsheet.dart';
import 'package:cuboid/src/bottomsheet/delete_bottomsheet.dart';
import 'package:test/test.dart';

void main() {
  test('deleting the last bottom sheet removes app.bottomsheets.dart and '
      'BottomSheetService', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateBottomSheetService().create(
      CreateBottomSheetInput(name: 'filter', projectRoot: root),
    );

    final result = await DeleteBottomSheetService().delete(
      DeleteBottomSheetInput(name: 'filter', projectRoot: root),
    );

    expect(result.plan.removesInfrastructure, isTrue);
    expect(
      Directory('${root.path}/lib/shared/bottom_sheets/filter').existsSync(),
      isFalse,
    );
    expect(
      Directory('${root.path}/lib/shared/bottom_sheets').existsSync(),
      isFalse,
    );
    expect(_bottomSheetsFile(root).existsSync(), isFalse);
    expect(_bottomSheetServiceFile(root).existsSync(), isFalse);
    final locator = _locatorFile(root).readAsStringSync();
    expect(locator, isNot(contains('BottomSheetService')));
    expect(_locatorFile(root).existsSync(), isTrue);
    expect(locator, contains('// @cuboid-import'));
    expect(locator, contains('// @cuboid-service'));
  });

  test('deleting one of several bottom sheets keeps app.bottomsheets.dart and '
      'BottomSheetService intact', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final createService = CreateBottomSheetService();
    await createService.create(
      CreateBottomSheetInput(name: 'filter', projectRoot: root),
    );
    await createService.create(
      CreateBottomSheetInput(name: 'sort', projectRoot: root),
    );

    final result = await DeleteBottomSheetService().delete(
      DeleteBottomSheetInput(name: 'filter', projectRoot: root),
    );

    expect(result.plan.removesInfrastructure, isFalse);
    expect(
      Directory('${root.path}/lib/shared/bottom_sheets/filter').existsSync(),
      isFalse,
    );
    expect(
      Directory('${root.path}/lib/shared/bottom_sheets/sort').existsSync(),
      isTrue,
    );
    final bottomSheets = _bottomSheetsFile(root).readAsStringSync();
    expect(bottomSheets, isNot(contains('FilterSheet')));
    expect(bottomSheets, contains('SortSheet'));
    expect('// @cuboid-bottom-sheet'.allMatches(bottomSheets), hasLength(1));
    expect(_bottomSheetServiceFile(root).existsSync(), isTrue);
    final locator = _locatorFile(root).readAsStringSync();
    expect(locator, contains('BottomSheetService'));
    expect(
      'registerLazySingleton<BottomSheetService>'.allMatches(locator),
      hasLength(1),
    );
  });

  test(
    'deleting the same bottom sheet twice fails safely without corruption',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateBottomSheetService().create(
        CreateBottomSheetInput(name: 'filter', projectRoot: root),
      );
      final service = DeleteBottomSheetService();
      await service.delete(
        DeleteBottomSheetInput(name: 'filter', projectRoot: root),
      );

      await expectLater(
        service.delete(
          DeleteBottomSheetInput(name: 'filter', projectRoot: root),
        ),
        throwsA(isA<DeleteBottomSheetException>()),
      );
      expect(_locatorFile(root).existsSync(), isTrue);
      expect(_bottomSheetsFile(root).existsSync(), isFalse);
    },
  );

  test('dry-run validates and deletes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateBottomSheetService().create(
      CreateBottomSheetInput(name: 'filter', projectRoot: root),
    );
    final beforeLocator = _locatorFile(root).readAsStringSync();
    final beforeBottomSheets = _bottomSheetsFile(root).readAsStringSync();

    final result = await DeleteBottomSheetService().delete(
      DeleteBottomSheetInput(name: 'filter', projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(result.plan.removesInfrastructure, isTrue);
    expect(
      File(
        '${root.path}/lib/shared/bottom_sheets/filter/filter_sheet.dart',
      ).existsSync(),
      isTrue,
    );
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
    expect(_bottomSheetsFile(root).readAsStringSync(), beforeBottomSheets);
  });

  test(
    'deleting a bottom sheet that was never created throws cleanly',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));

      await expectLater(
        DeleteBottomSheetService().delete(
          DeleteBottomSheetInput(name: 'ghost', projectRoot: root),
        ),
        throwsA(
          isA<DeleteBottomSheetException>().having(
            (error) => error.message,
            'message',
            contains('Bottom sheet not found'),
          ),
        ),
      );
    },
  );
}

Directory _projectRoot() {
  final root = Directory.systemTemp.createTempSync(
    'cuboid_delete_bottomsheet_',
  );
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  _locatorFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_locatorContents());
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

File _locatorFile(Directory root) =>
    File('${root.path}/lib/app/app.locator.dart');

File _bottomSheetsFile(Directory root) =>
    File('${root.path}/lib/app/app.bottomsheets.dart');

File _bottomSheetServiceFile(Directory root) =>
    File('${root.path}/lib/core/services/bottom_sheet_service.dart');
