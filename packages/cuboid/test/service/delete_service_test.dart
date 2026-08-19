import 'dart:io';

import 'package:cuboid/src/service/delete_service.dart';
import 'package:cuboid/src/service/register_service.dart';
import 'package:test/test.dart';

void main() {
  test('deletes a service file and its locator registration', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await RegisterServiceService().create(
      RegisterServiceInput(name: 'auth', projectRoot: root),
    );

    final result = await DeleteServiceService().delete(
      DeleteServiceInput(name: 'auth', projectRoot: root),
    );

    expect(result.plan.serviceClassName, 'AuthService');
    expect(
      File('${root.path}/lib/core/services/auth_service.dart').existsSync(),
      isFalse,
    );
    final locator = _appFile(root).readAsStringSync();
    expect(locator, isNot(contains('AuthService')));
    expect(locator, contains('// @cuboid-import'));
    expect(locator, contains('// @cuboid-service'));
    expect(_appFile(root).existsSync(), isTrue);
  });

  test('deleting one service leaves another untouched', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final registerService = RegisterServiceService();
    await registerService.create(
      RegisterServiceInput(name: 'auth', projectRoot: root),
    );
    await registerService.create(
      RegisterServiceInput(name: 'payment', projectRoot: root),
    );

    await DeleteServiceService().delete(
      DeleteServiceInput(name: 'auth', projectRoot: root),
    );

    expect(
      File('${root.path}/lib/core/services/auth_service.dart').existsSync(),
      isFalse,
    );
    expect(
      File('${root.path}/lib/core/services/payment_service.dart').existsSync(),
      isTrue,
    );
    final locator = _appFile(root).readAsStringSync();
    expect(locator, isNot(contains('AuthService')));
    expect(locator, contains('PaymentService'));
    expect('// @cuboid-import'.allMatches(locator), hasLength(1));
    expect('// @cuboid-service'.allMatches(locator), hasLength(1));
  });

  test(
    'deleting the same service twice fails safely without corruption',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await RegisterServiceService().create(
        RegisterServiceInput(name: 'auth', projectRoot: root),
      );
      final service = DeleteServiceService();
      await service.delete(DeleteServiceInput(name: 'auth', projectRoot: root));
      final afterFirst = _appFile(root).readAsStringSync();

      await expectLater(
        service.delete(DeleteServiceInput(name: 'auth', projectRoot: root)),
        throwsA(isA<DeleteServiceException>()),
      );

      expect(_appFile(root).readAsStringSync(), afterFirst);
    },
  );

  test('dry-run validates and deletes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await RegisterServiceService().create(
      RegisterServiceInput(name: 'auth', projectRoot: root),
    );
    final beforeLocator = _appFile(root).readAsStringSync();

    final result = await DeleteServiceService().delete(
      DeleteServiceInput(name: 'auth', projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(
      File('${root.path}/lib/core/services/auth_service.dart').existsSync(),
      isTrue,
    );
    expect(_appFile(root).readAsStringSync(), beforeLocator);
  });

  test('deleting a service that was never created throws cleanly', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteServiceService().delete(
        DeleteServiceInput(name: 'ghost', projectRoot: root),
      ),
      throwsA(
        isA<DeleteServiceException>().having(
          (error) => error.message,
          'message',
          contains('Service not found'),
        ),
      ),
    );
  });

  test('refuses to delete reserved automatically-managed services', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    for (final name in [
      'navigation',
      'dialog',
      'bottom_sheet',
      'BottomSheet',
    ]) {
      await expectLater(
        DeleteServiceService().delete(
          DeleteServiceInput(name: name, projectRoot: root),
        ),
        throwsA(isA<DeleteServiceException>()),
        reason: name,
      );
    }
    // Reserved-name rejection happens before any filesystem interaction.
    expect(
      File(
        '${root.path}/lib/core/services/navigation_service.dart',
      ).existsSync(),
      isFalse,
    );
  });

  test('rejects invalid names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    for (final name in [
      '',
      'two words',
      '1login',
      '_login',
      'login_',
      '.',
      '..',
      'auth/login',
      r'auth\login',
      'class',
    ]) {
      await expectLater(
        DeleteServiceService().delete(
          DeleteServiceInput(name: name, projectRoot: root),
        ),
        throwsA(isA<DeleteServiceException>()),
        reason: name,
      );
    }
  });
}

String _appContents({String extra = ''}) {
  return '''
import 'package:get_it/get_it.dart';
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
$extra  // @cuboid-service
}
''';
}

File _appFile(Directory root) => File('${root.path}/lib/app/app.locator.dart');

Directory _projectRoot({String pubspec = 'name: test_app\n'}) {
  final root = Directory.systemTemp.createTempSync('cuboid_delete_service_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  _appFile(root)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_appContents());
  return root;
}
