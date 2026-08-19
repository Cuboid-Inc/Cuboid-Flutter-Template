import 'dart:io';

import 'package:cuboid/src/widget/create_widget.dart';
import 'package:cuboid/src/widget/delete_widget.dart';
import 'package:test/test.dart';

void main() {
  test(
    'deletes a shared widget without touching hand-written sibling widgets',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      File('${root.path}/lib/shared/widgets/app_button.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('class AppButton {}\n');
      await CreateWidgetService().create(
        CreateWidgetInput(name: 'card', projectRoot: root),
      );

      final result = await DeleteWidgetService().delete(
        DeleteWidgetInput(name: 'card', projectRoot: root),
      );

      expect(result.plan.isShared, isTrue);
      expect(
        Directory('${root.path}/lib/shared/widgets/card').existsSync(),
        isFalse,
      );
      expect(Directory('${root.path}/lib/shared/widgets').existsSync(), isTrue);
      expect(
        File('${root.path}/lib/shared/widgets/app_button.dart').existsSync(),
        isTrue,
      );
    },
  );

  test('deletes a feature-scoped widget without touching the feature\'s '
      'ui directory', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    File('${root.path}/lib/features/auth/ui/auth_view.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('class AuthView {}\n');
    await CreateWidgetService().create(
      CreateWidgetInput(
        name: 'password_field',
        feature: 'auth',
        projectRoot: root,
      ),
    );

    final result = await DeleteWidgetService().delete(
      DeleteWidgetInput(
        name: 'password_field',
        feature: 'auth',
        projectRoot: root,
      ),
    );

    expect(result.plan.isShared, isFalse);
    expect(
      Directory(
        '${root.path}/lib/features/auth/ui/widgets/password_field',
      ).existsSync(),
      isFalse,
    );
    expect(
      Directory('${root.path}/lib/features/auth/ui/widgets').existsSync(),
      isFalse,
    );
    expect(Directory('${root.path}/lib/features/auth/ui').existsSync(), isTrue);
    expect(
      File('${root.path}/lib/features/auth/ui/auth_view.dart').existsSync(),
      isTrue,
    );
  });

  test('deleting one shared widget leaves another untouched', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final createService = CreateWidgetService();
    await createService.create(
      CreateWidgetInput(name: 'card', projectRoot: root),
    );
    await createService.create(
      CreateWidgetInput(name: 'badge', projectRoot: root),
    );

    await DeleteWidgetService().delete(
      DeleteWidgetInput(name: 'card', projectRoot: root),
    );

    expect(
      Directory('${root.path}/lib/shared/widgets/card').existsSync(),
      isFalse,
    );
    expect(
      File(
        '${root.path}/lib/shared/widgets/badge/badge_widget.dart',
      ).existsSync(),
      isTrue,
    );
  });

  test(
    'deleting the same widget twice fails safely without corruption',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      await CreateWidgetService().create(
        CreateWidgetInput(name: 'card', projectRoot: root),
      );
      final service = DeleteWidgetService();
      await service.delete(DeleteWidgetInput(name: 'card', projectRoot: root));

      await expectLater(
        service.delete(DeleteWidgetInput(name: 'card', projectRoot: root)),
        throwsA(isA<DeleteWidgetException>()),
      );
    },
  );

  test('dry-run validates and deletes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    await CreateWidgetService().create(
      CreateWidgetInput(name: 'card', projectRoot: root),
    );

    final result = await DeleteWidgetService().delete(
      DeleteWidgetInput(name: 'card', projectRoot: root, dryRun: true),
    );

    expect(result.plan.dryRun, isTrue);
    expect(
      File(
        '${root.path}/lib/shared/widgets/card/card_widget.dart',
      ).existsSync(),
      isTrue,
    );
  });

  test('deleting a widget that was never created throws cleanly', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));

    await expectLater(
      DeleteWidgetService().delete(
        DeleteWidgetInput(name: 'ghost', projectRoot: root),
      ),
      throwsA(
        isA<DeleteWidgetException>().having(
          (error) => error.message,
          'message',
          contains('Widget not found'),
        ),
      ),
    );
  });
}

Directory _projectRoot() {
  final root = Directory.systemTemp.createTempSync('cuboid_delete_widget_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  return root;
}
