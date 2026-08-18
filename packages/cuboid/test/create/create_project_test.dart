import 'dart:io';

import 'package:cuboid/src/create/create_project.dart';
import 'package:test/test.dart';

void main() {
  test(
    'dry-run resolves and validates without mutating the filesystem',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final calls = <String>[];
      final service = CreateProjectService(
        processRunner:
            (executable, arguments, {required workingDirectory}) async {
              calls.add([executable, ...arguments].join(' '));
              return ProcessResult(0, 0, '', '');
            },
      );

      final result = await service.create(
        CreateProjectInput(
          displayName: 'My App',
          packageIdentifier: 'com.example.myapp',
          destinationParent: temp,
          dryRun: true,
        ),
      );

      expect(result.plan.destination.path, endsWith('my_app'));
      expect(result.plan.templateManifest.files, isNotEmpty);
      expect(result.plan.actionSummary, contains('Create My App'));
      expect(Directory('${temp.path}/my_app').existsSync(), isFalse);
      expect(
        temp.listSync().where(
          (entity) => entity.uri.pathSegments.last.contains('cuboid'),
        ),
        isEmpty,
      );
      expect(calls, isEmpty);
    },
  );

  test('creates a bootstrapped project through the real template path', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final calls = <String>[];
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            calls.add([executable, ...arguments].join(' '));
            expect(Directory(workingDirectory).existsSync(), isTrue);
            return ProcessResult(0, 0, '', '');
          },
    );

    final result = await service.create(
      CreateProjectInput(
        displayName: 'My App',
        packageIdentifier: 'com.example.myapp',
        destinationParent: temp,
      ),
    );
    final destination = Directory('${temp.path}/my_app');

    expect(destination.existsSync(), isTrue);
    expect(
      File('${destination.path}/pubspec.yaml').readAsStringSync(),
      contains('name: my_app'),
    );
    expect(
      File(
        '${destination.path}/android/app/build.gradle.kts',
      ).readAsStringSync(),
      contains('applicationId = "com.example.myapp"'),
    );
    expect(
      File('${destination.path}/README.md').readAsStringSync(),
      contains('# My App'),
    );
    expect(
      File(
        '${destination.path}/android/app/src/main/kotlin/com/example/myapp/MainActivity.kt',
      ).existsSync(),
      isTrue,
    );
    expect(result.bootstrapResult!.modifiedFiles, contains('pubspec.yaml'));
    expect(calls, ['flutter pub get', 'dart format .']);

    for (final shellFile in [
      'lib/app/shell_view.dart',
      'lib/app/shell_viewmodel.dart',
      'lib/core/services/shell_service.dart',
      'test/app/shell_viewmodel_test.dart',
      'test/core/services/shell_service_test.dart',
    ]) {
      expect(
        File('${destination.path}/$shellFile').existsSync(),
        isFalse,
        reason: shellFile,
      );
    }
    final dartFiles = destination
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in dartFiles) {
      final contents = file.readAsStringSync();
      for (final shellSymbol in [
        'ShellView',
        'ShellViewModel',
        'ShellService',
        'Routes.shellView',
      ]) {
        expect(
          contents,
          isNot(contains(shellSymbol)),
          reason: '${file.path} should not reference $shellSymbol',
        );
      }
    }
  });

  test('refuses to overwrite an existing destination', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    Directory('${temp.path}/my_app').createSync();
    File('${temp.path}/my_app/keep.txt').writeAsStringSync('keep\n');
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            fail('post-steps should not run for invalid destinations');
          },
    );

    await expectLater(
      service.create(
        CreateProjectInput(
          displayName: 'My App',
          packageIdentifier: 'com.example.myapp',
          destinationParent: temp,
        ),
      ),
      throwsA(isA<CreateProjectException>()),
    );
    expect(File('${temp.path}/my_app/keep.txt').readAsStringSync(), 'keep\n');
  });

  test('refuses a destination path that is already a file', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    File('${temp.path}/my_app').writeAsStringSync('not a directory\n');
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            fail('post-steps should not run for invalid destinations');
          },
    );

    await expectLater(
      service.create(
        CreateProjectInput(
          displayName: 'My App',
          packageIdentifier: 'com.example.myapp',
          destinationParent: temp,
        ),
      ),
      throwsA(
        isA<CreateProjectException>().having(
          (error) => error.message,
          'message',
          contains('Destination path is not an empty directory path:'),
        ),
      ),
    );
    expect(File('${temp.path}/my_app').readAsStringSync(), 'not a directory\n');
  });

  test('rejects path traversal destination names', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final service = CreateProjectService();

    await expectLater(
      service.create(
        CreateProjectInput(
          displayName: 'My App',
          packageIdentifier: 'com.example.myapp',
          destinationParent: temp,
          destinationName: '../outside',
          dryRun: true,
        ),
      ),
      throwsA(
        isA<CreateProjectException>().having(
          (error) => error.message,
          'message',
          'Destination name must be a simple directory name.',
        ),
      ),
    );
  });

  test('requires the destination parent to exist', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final missingParent = Directory('${temp.path}/missing');
    final service = CreateProjectService();

    await expectLater(
      service.create(
        CreateProjectInput(
          displayName: 'My App',
          packageIdentifier: 'com.example.myapp',
          destinationParent: missingParent,
          dryRun: true,
        ),
      ),
      throwsA(
        isA<CreateProjectException>().having(
          (error) => error.message,
          'message',
          contains('Destination parent does not exist:'),
        ),
      ),
    );
    expect(missingParent.existsSync(), isFalse);
  });

  test('post-step failure leaves no destination behind', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            return ProcessResult(0, 70, '', 'tool failed');
          },
    );

    await expectLater(
      service.create(
        CreateProjectInput(
          displayName: 'My App',
          packageIdentifier: 'com.example.myapp',
          destinationParent: temp,
        ),
      ),
      throwsA(
        isA<CreateProjectException>().having(
          (error) => error.message,
          'message',
          contains('flutter pub get failed with exit code 70.'),
        ),
      ),
    );
    expect(Directory('${temp.path}/my_app').existsSync(), isFalse);
  });

  test('later post-step failure leaves no destination behind', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final calls = <String>[];
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            final command = [executable, ...arguments].join(' ');
            calls.add(command);
            if (command.startsWith('dart format')) {
              return ProcessResult(0, 65, '', 'format failed');
            }
            return ProcessResult(0, 0, '', '');
          },
    );

    await expectLater(
      service.create(
        CreateProjectInput(
          displayName: 'My App',
          packageIdentifier: 'com.example.myapp',
          destinationParent: temp,
        ),
      ),
      throwsA(
        isA<CreateProjectException>().having(
          (error) => error.message,
          'message',
          contains('dart format . failed with exit code 65.'),
        ),
      ),
    );
    expect(calls, ['flutter pub get', 'dart format .']);
    expect(Directory('${temp.path}/my_app').existsSync(), isFalse);
  });

  test('subprocess startup failure is reported without publishing', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            throw const ProcessException('flutter', ['pub', 'get'], 'missing');
          },
    );

    await expectLater(
      service.create(
        CreateProjectInput(
          displayName: 'My App',
          packageIdentifier: 'com.example.myapp',
          destinationParent: temp,
        ),
      ),
      throwsA(
        isA<CreateProjectException>().having(
          (error) => error.message,
          'message',
          contains('flutter pub get could not be started: missing'),
        ),
      ),
    );
    expect(Directory('${temp.path}/my_app').existsSync(), isFalse);
  });

  test('can skip post-steps explicitly', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_create_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            fail('post-steps should not run when disabled');
          },
    );

    await service.create(
      CreateProjectInput(
        displayName: 'My App',
        packageIdentifier: 'com.example.myapp',
        destinationParent: temp,
        runPostSteps: false,
      ),
    );

    expect(Directory('${temp.path}/my_app').existsSync(), isTrue);
  });
}
