import 'dart:io';

import 'package:cuboid/src/widget/create_widget.dart';
import 'package:test/test.dart';

void main() {
  group('shared widgets', () {
    test('creates a shared widget under lib/shared/widgets', () async {
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
      expect(result.plan.path, 'lib/shared/widgets/status_badge.dart');

      final contents = File(
        '${root.path}/lib/shared/widgets/status_badge.dart',
      ).readAsStringSync();
      expect(contents, contains("import 'package:flutter/material.dart';"));
      expect(contents, contains('class StatusBadge extends StatelessWidget {'));
      expect(contents, contains('const StatusBadge({super.key});'));
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
      final target = File('${root.path}/lib/shared/widgets/status_badge.dart')
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
      expect(
        result.plan.path,
        'lib/features/auth/ui/widgets/password_field.dart',
      );

      final contents = File(
        '${root.path}/lib/features/auth/ui/widgets/password_field.dart',
      ).readAsStringSync();
      expect(
        contents,
        contains('class PasswordField extends StatelessWidget {'),
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
          File('${root.path}/lib/features/auth/ui/widgets/password_field.dart')
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
          '${root.path}/lib/shared/widgets/password_field.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${root.path}/lib/features/auth/ui/widgets/password_field.dart',
        ).existsSync(),
        isTrue,
      );
    });
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
