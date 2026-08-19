import 'dart:io';

import 'package:cuboid/src/dialog/create_dialog.dart';
import 'package:cuboid/src/dialog/delete_dialog.dart';
import 'package:test/test.dart';

void main() {
  test(
    'deleting the last dialog removes app.dialogs.dart and DialogService',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateDialogService().create(
        CreateDialogInput(name: 'confirm_delete', projectRoot: root),
      );

      final result = await DeleteDialogService().delete(
        DeleteDialogInput(name: 'confirm_delete', projectRoot: root),
      );

      expect(result.plan.removesInfrastructure, isTrue);
      expect(
        Directory(
          '${root.path}/lib/shared/dialogs/confirm_delete',
        ).existsSync(),
        isFalse,
      );
      expect(
        Directory('${root.path}/lib/shared/dialogs').existsSync(),
        isFalse,
      );
      expect(_dialogsFile(root).existsSync(), isFalse);
      expect(_dialogServiceFile(root).existsSync(), isFalse);
      final locator = _locatorFile(root).readAsStringSync();
      expect(locator, isNot(contains('DialogService')));
      expect(_locatorFile(root).existsSync(), isTrue);
      expect(locator, contains('// @cuboid-import'));
      expect(locator, contains('// @cuboid-service'));
    },
  );

  test('deleting one of several dialogs keeps app.dialogs.dart and '
      'DialogService intact', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final createService = CreateDialogService();
    await createService.create(
      CreateDialogInput(name: 'confirm_delete', projectRoot: root),
    );
    await createService.create(
      CreateDialogInput(name: 'confirm_logout', projectRoot: root),
    );

    final result = await DeleteDialogService().delete(
      DeleteDialogInput(name: 'confirm_delete', projectRoot: root),
    );

    expect(result.plan.removesInfrastructure, isFalse);
    expect(
      Directory('${root.path}/lib/shared/dialogs/confirm_delete').existsSync(),
      isFalse,
    );
    expect(
      Directory('${root.path}/lib/shared/dialogs/confirm_logout').existsSync(),
      isTrue,
    );
    final dialogs = _dialogsFile(root).readAsStringSync();
    expect(dialogs, isNot(contains('ConfirmDeleteDialog')));
    expect(dialogs, contains('ConfirmLogoutDialog'));
    expect('// @cuboid-dialog'.allMatches(dialogs), hasLength(1));
    expect(_dialogServiceFile(root).existsSync(), isTrue);
    final locator = _locatorFile(root).readAsStringSync();
    expect(locator, contains('DialogService'));
    expect(
      'registerLazySingleton<DialogService>'.allMatches(locator),
      hasLength(1),
    );
  });

  test(
    'deleting the same dialog twice fails safely without corruption',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateDialogService().create(
        CreateDialogInput(name: 'confirm_delete', projectRoot: root),
      );
      final service = DeleteDialogService();
      await service.delete(
        DeleteDialogInput(name: 'confirm_delete', projectRoot: root),
      );

      await expectLater(
        service.delete(
          DeleteDialogInput(name: 'confirm_delete', projectRoot: root),
        ),
        throwsA(isA<DeleteDialogException>()),
      );
      expect(_locatorFile(root).existsSync(), isTrue);
      expect(_dialogsFile(root).existsSync(), isFalse);
    },
  );

  test('dry-run validates and deletes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateDialogService().create(
      CreateDialogInput(name: 'confirm_delete', projectRoot: root),
    );
    final beforeLocator = _locatorFile(root).readAsStringSync();
    final beforeDialogs = _dialogsFile(root).readAsStringSync();

    final result = await DeleteDialogService().delete(
      DeleteDialogInput(
        name: 'confirm_delete',
        projectRoot: root,
        dryRun: true,
      ),
    );

    expect(result.plan.dryRun, isTrue);
    expect(result.plan.removesInfrastructure, isTrue);
    expect(
      File(
        '${root.path}/lib/shared/dialogs/confirm_delete/'
        'confirm_delete_dialog.dart',
      ).existsSync(),
      isTrue,
    );
    expect(_locatorFile(root).readAsStringSync(), beforeLocator);
    expect(_dialogsFile(root).readAsStringSync(), beforeDialogs);
  });

  test('deleting a dialog that was never created throws cleanly', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteDialogService().delete(
        DeleteDialogInput(name: 'ghost', projectRoot: root),
      ),
      throwsA(
        isA<DeleteDialogException>().having(
          (error) => error.message,
          'message',
          contains('Dialog not found'),
        ),
      ),
    );
  });
}

Directory _projectRoot() {
  final root = Directory.systemTemp.createTempSync('cuboid_delete_dialog_');
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

File _dialogsFile(Directory root) =>
    File('${root.path}/lib/app/app.dialogs.dart');

File _dialogServiceFile(Directory root) =>
    File('${root.path}/lib/core/services/dialog_service.dart');
