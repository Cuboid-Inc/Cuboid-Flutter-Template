import 'dart:io';

import 'package:cuboid/src/widget/create_widget.dart';
import 'package:test/test.dart';

void main() {
  group('shared widgets', () {
    test('creates a shared widget under lib/shared/widgets/<name>/', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateWidgetService();

      final result = await service.create(
        CreateWidgetInput(name: 'status_badge', projectRoot: root),
      );

      expect(result.plan.name, 'status_badge');
      expect(result.plan.feature, isNull);
      expect(result.plan.isShared, isTrue);
      expect(result.plan.className, 'StatusBadge');
      expect(result.plan.viewModelClassName, 'StatusBadgeViewModel');
      expect(
        result.plan.path,
        'lib/shared/widgets/status_badge/status_badge_widget.dart',
      );
      expect(
        result.plan.viewModelPath,
        'lib/shared/widgets/status_badge/status_badge_view_model.dart',
      );

      final contents = File(
        '${root.path}/lib/shared/widgets/status_badge/status_badge_widget.dart',
      ).readAsStringSync();
      expect(
        contents,
        contains("import 'package:cuboid_flutter/cuboid_flutter.dart';"),
      );
      expect(
        contents,
        contains(
          "import 'package:test_app/shared/widgets/status_badge/"
          "status_badge_view_model.dart';",
        ),
      );
      expect(contents, contains("import 'package:flutter/material.dart';"));
      expect(
        contents,
        contains(
          'class StatusBadge extends CuboidView<StatusBadgeViewModel> {',
        ),
      );
      expect(contents, contains('const StatusBadge({super.key});'));

      final viewModelContents = File(
        '${root.path}/lib/shared/widgets/status_badge/status_badge_view_model.dart',
      ).readAsStringSync();
      expect(
        viewModelContents,
        contains("import 'package:cuboid_flutter/cuboid_flutter.dart';"),
      );
      expect(
        viewModelContents,
        contains('class StatusBadgeViewModel extends CuboidViewModel {}'),
      );
    });

    test('never creates a lib/ui directory', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateWidgetService();

      await service.create(
        CreateWidgetInput(name: 'status_badge', projectRoot: root),
      );

      expect(Directory('${root.path}/lib/ui').existsSync(), isFalse);
    });

    test('dry-run validates and writes nothing', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final beforeFiles = _relativeFiles(root);
      final service = CreateWidgetService();

      final result = await service.create(
        CreateWidgetInput(
          name: 'Status-Badge',
          projectRoot: root,
          dryRun: true,
        ),
      );

      expect(result.plan.name, 'status_badge');
      expect(result.plan.dryRun, isTrue);
      expect(_relativeFiles(root), beforeFiles);
      expect(
        Directory('${root.path}/lib/shared/widgets').existsSync(),
        isFalse,
      );
    });

    test('rejects invalid names', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateWidgetService();

      for (final name in ['', 'two words', '1badge', '_badge', 'class']) {
        await expectLater(
          service.create(CreateWidgetInput(name: name, projectRoot: root)),
          throwsA(isA<CreateWidgetException>()),
          reason: name,
        );
      }
    });

    test('does not overwrite an existing target file', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final target =
          File(
              '${root.path}/lib/shared/widgets/status_badge/status_badge_widget.dart',
            )
            ..parent.createSync(recursive: true)
            ..writeAsStringSync('keep\n');
      final service = CreateWidgetService();

      await expectLater(
        service.create(
          CreateWidgetInput(name: 'status_badge', projectRoot: root),
        ),
        throwsA(isA<CreateWidgetException>()),
      );
      expect(target.readAsStringSync(), 'keep\n');
    });

    test('rejects symlink ancestors', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final target = Directory('${root.path}/target_shared')..createSync();
      final shared = Link('${root.path}/lib/shared');
      shared.parent.createSync(recursive: true);
      shared.createSync(target.path);
      final service = CreateWidgetService();

      await expectLater(
        service.create(
          CreateWidgetInput(name: 'status_badge', projectRoot: root),
        ),
        throwsA(isA<CreateWidgetException>()),
      );
    });

    test('rolls back and creates no directory when the write fails', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final beforeFiles = _relativeFiles(root);
      final service = CreateWidgetService(
        fileWriter: (file, contents) {
          throw const FileSystemException('simulated write failure');
        },
      );

      await expectLater(
        service.create(
          CreateWidgetInput(name: 'status_badge', projectRoot: root),
        ),
        throwsA(isA<CreateWidgetException>()),
      );

      expect(_relativeFiles(root), beforeFiles);
      expect(
        Directory('${root.path}/lib/shared/widgets').existsSync(),
        isFalse,
      );
    });
  });

  group('feature-scoped widgets', () {
    test('creates a widget under an existing feature', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/lib/features/auth').createSync(recursive: true);
      final service = CreateWidgetService();

      final result = await service.create(
        CreateWidgetInput(
          feature: 'auth',
          name: 'password_field',
          projectRoot: root,
        ),
      );

      expect(result.plan.feature, 'auth');
      expect(result.plan.isShared, isFalse);
      expect(result.plan.className, 'PasswordField');
      expect(result.plan.viewModelClassName, 'PasswordFieldViewModel');
      expect(
        result.plan.path,
        'lib/features/auth/ui/widgets/password_field/password_field_widget.dart',
      );
      expect(
        result.plan.viewModelPath,
        'lib/features/auth/ui/widgets/password_field/password_field_view_model.dart',
      );

      final contents = File(
        '${root.path}/lib/features/auth/ui/widgets/password_field/password_field_widget.dart',
      ).readAsStringSync();
      expect(
        contents,
        contains(
          "import 'package:test_app/features/auth/ui/widgets/"
          "password_field/password_field_view_model.dart';",
        ),
      );
      expect(
        contents,
        contains(
          'class PasswordField extends CuboidView<PasswordFieldViewModel> {',
        ),
      );

      final viewModelContents = File(
        '${root.path}/lib/features/auth/ui/widgets/password_field/password_field_view_model.dart',
      ).readAsStringSync();
      expect(
        viewModelContents,
        contains('class PasswordFieldViewModel extends CuboidViewModel {}'),
      );
    });

    test('rejects a nonexistent feature', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateWidgetService();

      await expectLater(
        service.create(
          CreateWidgetInput(
            feature: 'missing',
            name: 'password_field',
            projectRoot: root,
          ),
        ),
        throwsA(
          isA<CreateWidgetException>().having(
            (error) => error.message,
            'message',
            'lib/features/missing was not found.',
          ),
        ),
      );
    });

    test('dry-run validates and writes nothing', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/lib/features/auth').createSync(recursive: true);
      final beforeFiles = _relativeFiles(root);
      final service = CreateWidgetService();

      final result = await service.create(
        CreateWidgetInput(
          feature: 'auth',
          name: 'password_field',
          projectRoot: root,
          dryRun: true,
        ),
      );

      expect(result.plan.dryRun, isTrue);
      expect(_relativeFiles(root), beforeFiles);
    });

    test('does not overwrite an existing target file', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final target =
          File(
              '${root.path}/lib/features/auth/ui/widgets/password_field/password_field_widget.dart',
            )
            ..parent.createSync(recursive: true)
            ..writeAsStringSync('keep\n');
      final service = CreateWidgetService();

      await expectLater(
        service.create(
          CreateWidgetInput(
            feature: 'auth',
            name: 'password_field',
            projectRoot: root,
          ),
        ),
        throwsA(isA<CreateWidgetException>()),
      );
      expect(target.readAsStringSync(), 'keep\n');
    });

    test('a shared widget and a feature-scoped widget with the same name '
        'coexist', () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/lib/features/auth').createSync(recursive: true);
      final service = CreateWidgetService();

      await service.create(
        CreateWidgetInput(name: 'password_field', projectRoot: root),
      );
      await service.create(
        CreateWidgetInput(
          feature: 'auth',
          name: 'password_field',
          projectRoot: root,
        ),
      );

      expect(
        File(
          '${root.path}/lib/shared/widgets/password_field/password_field_widget.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${root.path}/lib/features/auth/ui/widgets/password_field/password_field_widget.dart',
        ).existsSync(),
        isTrue,
      );
    });

    test(
      'creates both the widget and its view model for "bar" in "login"',
      () async {
        final root = _projectRoot();
        addTearDown(() => root.deleteSync(recursive: true));
        Directory(
          '${root.path}/lib/features/login',
        ).createSync(recursive: true);
        final service = CreateWidgetService();

        final result = await service.create(
          CreateWidgetInput(feature: 'login', name: 'bar', projectRoot: root),
        );

        expect(
          result.plan.path,
          'lib/features/login/ui/widgets/bar/bar_widget.dart',
        );
        expect(
          result.plan.viewModelPath,
          'lib/features/login/ui/widgets/bar/bar_view_model.dart',
        );

        final widgetFile = File(
          '${root.path}/lib/features/login/ui/widgets/bar/bar_widget.dart',
        );
        final viewModelFile = File(
          '${root.path}/lib/features/login/ui/widgets/bar/bar_view_model.dart',
        );
        expect(widgetFile.existsSync(), isTrue);
        expect(viewModelFile.existsSync(), isTrue);
        expect(Directory('${root.path}/lib/ui').existsSync(), isFalse);

        final widgetContents = widgetFile.readAsStringSync();
        expect(
          widgetContents,
          contains(
            "import 'package:test_app/features/login/ui/widgets/bar/"
            "bar_view_model.dart';",
          ),
        );
        expect(
          widgetContents,
          contains('class Bar extends CuboidView<BarViewModel> {'),
        );
        expect(
          widgetContents,
          contains('BarViewModel viewModelBuilder(BuildContext context) =>'),
        );

        final viewModelContents = viewModelFile.readAsStringSync();
        expect(
          viewModelContents,
          contains('class BarViewModel extends CuboidViewModel {}'),
        );
      },
    );
  });
}

Directory _projectRoot() {
  final root = Directory.systemTemp.createTempSync('cuboid_widget_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
  return root;
}

List<String> _relativeFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.substring(root.path.length + 1))
      .map((path) => path.replaceAll(Platform.pathSeparator, '/'))
      .toList()
    ..sort();
}
