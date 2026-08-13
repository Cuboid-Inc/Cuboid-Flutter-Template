import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuboid/src/templates/flutter_app/template_sync.dart';
import 'package:test/test.dart';

void main() {
  test('deterministic archive ordering is path sorted', () {
    final archive = buildDeterministicTarGz([
      TemplateSourceFile(path: 'lib/z.dart', bytes: utf8Bytes('z')),
      TemplateSourceFile(path: 'README.md', bytes: utf8Bytes('readme')),
      TemplateSourceFile(
        path: 'android/app/build.gradle.kts',
        bytes: utf8Bytes('android'),
      ),
    ]);

    final paths = extractTarGz(archive).map((file) => file.path).toList();

    expect(paths, ['README.md', 'android/app/build.gradle.kts', 'lib/z.dart']);
    expect(
      buildDeterministicTarGz([
        TemplateSourceFile(
          path: 'android/app/build.gradle.kts',
          bytes: utf8Bytes('android'),
        ),
        TemplateSourceFile(path: 'lib/z.dart', bytes: utf8Bytes('z')),
        TemplateSourceFile(path: 'README.md', bytes: utf8Bytes('readme')),
      ]),
      archive,
    );
  });

  test('manifest records file hashes and archive hash', () async {
    final root = await createTemplateRepo();

    final result = await buildTemplatePayload(root);
    final manifest = result.manifest;

    expect(manifest.templateName, templateName);
    expect(manifest.templateVersion, templateVersion);
    expect(manifest.sourceCommit, isNotEmpty);
    expect(manifest.archiveSha256, sha256Hex(result.archiveBytes));

    final readme = manifest.files.singleWhere(
      (file) => file.path == 'README.md',
    );
    expect(readme.size, utf8Bytes('# Test Template\n').length);
    expect(readme.sha256, sha256Hex(utf8Bytes('# Test Template\n')));
  });

  test('excluded files are not included', () async {
    final root = await createTemplateRepo();
    writeFixture(root, 'android/local.properties', 'sdk.dir=/private/sdk\n');
    writeFixture(
      root,
      'test/tool/bootstrap_test.dart',
      'should not be included\n',
    );
    writeFixture(root, 'android/app/build/generated.txt', 'generated\n');
    writeFixture(root, 'ios/Runner/GeneratedPluginRegistrant.m', 'generated\n');

    final files = collectTemplateFiles(root).map((file) => file.path).toList();

    expect(files, isNot(contains('android/local.properties')));
    expect(files, isNot(contains('test/tool/bootstrap_test.dart')));
    expect(files, isNot(contains('android/app/build/generated.txt')));
    expect(files, isNot(contains('ios/Runner/GeneratedPluginRegistrant.m')));
  });

  test('payload verification detects archive tampering', () async {
    final root = await createTemplateRepo();
    await regenerateTemplatePayload(root, allowDirty: true);

    expect(verifyTemplatePayload(root), isEmpty);

    final archive = fileFor(root, templateArchivePath);
    final bytes = archive.readAsBytesSync();
    archive.writeAsBytesSync([
      ...bytes.take(bytes.length - 1),
      bytes.last ^ 0x01,
    ]);

    expect(
      verifyTemplatePayload(root),
      contains('Archive SHA-256 does not match manifest.'),
    );
  });

  test('clean tree check succeeds when payload is current', () async {
    final root = await createTemplateRepo();
    await regenerateTemplatePayload(root, allowDirty: true);

    expect((await checkTemplatePayload(root)).inSync, isTrue);
  });

  test(
    'check detects stale payload drift with explicit dirty override',
    () async {
      final root = await createTemplateRepo();
      await regenerateTemplatePayload(root, allowDirty: true);

      writeFixture(root, 'README.md', '# Changed Template\n');

      final result = await checkTemplatePayload(root, allowDirty: true);

      expect(result.inSync, isFalse);
      expect(
        result.failures,
        contains(
          predicate<String>(
            (item) => item.contains(templateArchivePath),
            'contains $templateArchivePath',
          ),
        ),
      );
    },
  );

  test('dirty template source protection rejects check by default', () async {
    final root = await createTemplateRepo();
    await regenerateTemplatePayload(root, allowDirty: true);

    writeFixture(root, 'README.md', '# Dirty Template\n');

    expect(
      () => checkTemplatePayload(root),
      throwsA(isA<TemplateSyncException>()),
    );
  });

  test('dirty check override succeeds when payload matches', () async {
    final root = await createTemplateRepo();
    writeFixture(root, 'README.md', '# Dirty Template\n');
    await regenerateTemplatePayload(root, allowDirty: true);

    final result = await checkTemplatePayload(root, allowDirty: true);

    expect(result.inSync, isTrue);
  });

  test(
    'dirty template source protection rejects regeneration by default',
    () async {
      final root = await createTemplateRepo();
      writeFixture(root, 'README.md', '# Dirty Template\n');

      expect(
        () => regenerateTemplatePayload(root),
        throwsA(isA<TemplateSyncException>()),
      );
    },
  );

  test('dirty regeneration override writes matching payload', () async {
    final root = await createTemplateRepo();
    writeFixture(root, 'README.md', '# Dirty Template\n');

    await regenerateTemplatePayload(root, allowDirty: true);

    expect((await checkTemplatePayload(root, allowDirty: true)).inSync, isTrue);
  });

  test('generated payload can be extracted with expected structure', () async {
    final root = await createTemplateRepo();
    await regenerateTemplatePayload(root, allowDirty: true);

    final archive = fileFor(root, templateArchivePath).readAsBytesSync();
    final paths = extractTarGz(archive).map((file) => file.path).toList();

    expect(paths, contains('.metadata'));
    expect(paths, contains('android/app/build.gradle.kts'));
    expect(paths, contains('assets/icon/app_icon.png'));
    expect(paths, contains('ios/Runner/Info.plist'));
    expect(paths, contains('lib/main.dart'));
    expect(paths, contains('supabase/config.toml'));
    expect(paths, contains('test/widget_test.dart'));
    expect(paths, isNot(contains('packages/cuboid/pubspec.yaml')));
    expect(paths, isNot(contains('tool/bootstrap.dart')));
  });
}

Uint8List utf8Bytes(String value) => Uint8List.fromList(utf8.encode(value));

Future<Directory> createTemplateRepo() async {
  final root = Directory.systemTemp.createTempSync('template_sync_test_');
  addTearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  for (final file in templateAllowedFiles) {
    writeFixture(root, file, _fixtureContent(file));
  }
  writeFixture(root, 'packages/cuboid/pubspec.yaml', 'name: cuboid\n');

  writeFixture(root, 'android/app/build.gradle.kts', 'android {}\n');
  writeFixture(
    root,
    'android/app/src/main/AndroidManifest.xml',
    '<manifest />\n',
  );
  writeFixture(root, 'assets/icon/app_icon.png', 'png\n');
  writeFixture(root, 'ios/Runner/Info.plist', '<plist />\n');
  writeFixture(root, 'lib/main.dart', 'void main() {}\n');
  writeFixture(root, 'supabase/config.toml', 'project_id = "test"\n');
  writeFixture(root, 'test/widget_test.dart', 'void main() {}\n');

  for (final directory in templateAllowedDirectories) {
    Directory('${root.path}/$directory').createSync(recursive: true);
  }

  await runGit(root, ['init']);
  await runGit(root, ['add', '.']);
  await runGit(root, [
    '-c',
    'user.name=Test User',
    '-c',
    'user.email=test@example.com',
    '-c',
    'commit.gpgsign=false',
    'commit',
    '-m',
    'initial',
  ]);
  return root;
}

String _fixtureContent(String path) {
  if (path == 'README.md') {
    return '# Test Template\n';
  }
  return '$path\n';
}

void writeFixture(Directory root, String relativePath, String content) {
  final file = fileFor(root, relativePath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

Future<void> runGit(Directory root, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: root.path,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    fail('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}
