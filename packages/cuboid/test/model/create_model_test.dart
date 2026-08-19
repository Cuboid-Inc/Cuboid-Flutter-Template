import 'dart:io';

import 'package:cuboid/src/model/create_model.dart';
import 'package:test/test.dart';

void main() {
  test('creates a bare model shell', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateModelService();

    final result = await service.create(
      CreateModelInput(name: 'invoice', projectRoot: root),
    );

    expect(result.plan.name, 'invoice');
    expect(result.plan.className, 'Invoice');
    expect(result.plan.path, 'lib/core/models/invoice.dart');

    final contents = File(
      '${root.path}/lib/core/models/invoice.dart',
    ).readAsStringSync();
    expect(
      contents,
      'class Invoice {\n'
      '  const Invoice();\n'
      '}\n',
    );
  });

  test('pascal-cases multi-word names without a suffix', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateModelService();

    final result = await service.create(
      CreateModelInput(name: 'invoice-line-item', projectRoot: root),
    );

    expect(result.plan.name, 'invoice_line_item');
    expect(result.plan.className, 'InvoiceLineItem');
    expect(
      File('${root.path}/lib/core/models/invoice_line_item.dart').existsSync(),
      isTrue,
    );
  });

  test('dry-run validates and writes nothing', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final service = CreateModelService();

    final result = await service.create(
      CreateModelInput(name: 'Draft-Order', projectRoot: root, dryRun: true),
    );

    expect(result.plan.name, 'draft_order');
    expect(result.plan.dryRun, isTrue);
    expect(_relativeFiles(root), beforeFiles);
    expect(Directory('${root.path}/lib/core/models').existsSync(), isFalse);
  });

  test('rejects invalid names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateModelService();

    for (final name in [
      '',
      'two words',
      '1invoice',
      '_invoice',
      'invoice_',
      'invoice__line',
      '.',
      '..',
      'auth/invoice',
      r'auth\invoice',
      'class',
    ]) {
      await expectLater(
        service.create(CreateModelInput(name: name, projectRoot: root)),
        throwsA(isA<CreateModelException>()),
        reason: name,
      );
    }
  });

  test('rejects a project without pubspec.yaml', () async {
    final root = Directory.systemTemp.createTempSync('cuboid_model_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateModelService();

    await expectLater(
      service.create(CreateModelInput(name: 'invoice', projectRoot: root)),
      throwsA(isA<CreateModelException>()),
    );
  });

  test('does not overwrite an existing target file', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = File('${root.path}/lib/core/models/invoice.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('keep\n');
    final service = CreateModelService();

    await expectLater(
      service.create(CreateModelInput(name: 'invoice', projectRoot: root)),
      throwsA(
        isA<CreateModelException>().having(
          (error) => error.message,
          'message',
          'Target already exists: lib/core/models/invoice.dart',
        ),
      ),
    );
    expect(target.readAsStringSync(), 'keep\n');
  });

  test('rejects symlink ancestors', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target = Directory('${root.path}/target_core')..createSync();
    final core = Link('${root.path}/lib/core');
    core.parent.createSync(recursive: true);
    core.createSync(target.path);
    final service = CreateModelService();

    await expectLater(
      service.create(CreateModelInput(name: 'invoice', projectRoot: root)),
      throwsA(isA<CreateModelException>()),
    );
  });

  test('leaves unrelated files untouched and creates no extra files', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final appFile = File('${root.path}/lib/app/app.dart')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('app registration\n');
    final service = CreateModelService();

    await service.create(CreateModelInput(name: 'invoice', projectRoot: root));

    expect(appFile.readAsStringSync(), 'app registration\n');
    expect(_relativeFiles(root), [
      'lib/app/app.dart',
      'lib/core/models/invoice.dart',
      'pubspec.yaml',
    ]);
  });

  test('rolls back and creates no directory when the write fails', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final beforeFiles = _relativeFiles(root);
    final service = CreateModelService(
      fileWriter: (file, contents) {
        throw const FileSystemException('simulated write failure');
      },
    );

    await expectLater(
      service.create(CreateModelInput(name: 'invoice', projectRoot: root)),
      throwsA(
        isA<CreateModelException>().having(
          (error) => error.message,
          'message',
          contains('Unable to create model Invoice'),
        ),
      ),
    );

    expect(_relativeFiles(root), beforeFiles);
    expect(Directory('${root.path}/lib/core/models').existsSync(), isFalse);
  });
}

Directory _projectRoot({String pubspec = 'name: test_app\n'}) {
  final root = Directory.systemTemp.createTempSync('cuboid_model_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
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
