import 'dart:io';

import 'package:cuboid/src/install/install_cuboid.dart';
import 'package:test/test.dart';

void main() {
  group('resolvePubCacheBinDirectory', () {
    test('honors PUB_CACHE when set', () {
      final directory = resolvePubCacheBinDirectory(
        environment: {'PUB_CACHE': '/custom/pub-cache'},
        isWindows: false,
      );

      expect(directory.path, '/custom/pub-cache/bin');
    });

    test('falls back to \$HOME/.pub-cache/bin on posix', () {
      final directory = resolvePubCacheBinDirectory(
        environment: {'HOME': '/home/dev'},
        isWindows: false,
      );

      expect(directory.path, '/home/dev/.pub-cache/bin');
    });

    test('throws when \$HOME is missing on posix', () {
      expect(
        () => resolvePubCacheBinDirectory(environment: {}, isWindows: false),
        throwsA(isA<InstallCuboidException>()),
      );
    });

    test('falls back to %LOCALAPPDATA%\\Pub\\Cache\\bin on windows', () {
      final directory = resolvePubCacheBinDirectory(
        environment: {'LOCALAPPDATA': r'C:\Users\dev\AppData\Local'},
        isWindows: true,
      );

      expect(directory.path, r'C:\Users\dev\AppData\Local\Pub\Cache\bin');
    });

    test('throws when %LOCALAPPDATA% is missing on windows', () {
      expect(
        () => resolvePubCacheBinDirectory(environment: {}, isWindows: true),
        throwsA(isA<InstallCuboidException>()),
      );
    });
  });

  group('cuboidExecutableFileName', () {
    test('has no extension on posix', () {
      expect(cuboidExecutableFileName(isWindows: false), 'cuboid');
    });

    test('uses .exe on windows', () {
      expect(cuboidExecutableFileName(isWindows: true), 'cuboid.exe');
    });
  });

  group('installCuboidExecutable orchestration', () {
    test('runs pub get, deactivate, then compile in order', () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_install_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final packageRoot = Directory('${temp.path}/pkg')..createSync();
      File('${packageRoot.path}/bin/cuboid.dart').createSync(recursive: true);
      final binDirectory = Directory('${temp.path}/bin');
      final calls = <String>[];

      final result = await installCuboidExecutable(
        packageRoot: packageRoot,
        binDirectory: binDirectory,
        isWindows: false,
        processRunner:
            (executable, arguments, {required workingDirectory}) async {
              calls.add([executable, ...arguments].join(' '));
              if (arguments.contains('exe')) {
                final outputIndex = arguments.indexOf('-o') + 1;
                File(arguments[outputIndex]).writeAsStringSync('fake binary');
              }
              return ProcessResult(0, 0, '', '');
            },
      );

      expect(calls[0], 'dart pub get');
      expect(calls[1], 'dart pub global deactivate cuboid');
      expect(calls[2], startsWith('dart compile exe'));
      expect(result.executablePath, '${binDirectory.path}/cuboid');
      expect(File(result.executablePath).existsSync(), isTrue);
      expect(File(result.executablePath).readAsStringSync(), 'fake binary');
    });

    test('throws when the entry point is missing', () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_install_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final packageRoot = Directory('${temp.path}/pkg')..createSync();

      await expectLater(
        installCuboidExecutable(
          packageRoot: packageRoot,
          binDirectory: Directory('${temp.path}/bin'),
          processRunner:
              (executable, arguments, {required workingDirectory}) async =>
                  ProcessResult(0, 0, '', ''),
        ),
        throwsA(isA<InstallCuboidException>()),
      );
    });

    test('surfaces a dart pub get failure without compiling', () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_install_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final packageRoot = Directory('${temp.path}/pkg')..createSync();
      File('${packageRoot.path}/bin/cuboid.dart').createSync(recursive: true);
      final calls = <String>[];

      await expectLater(
        installCuboidExecutable(
          packageRoot: packageRoot,
          binDirectory: Directory('${temp.path}/bin'),
          processRunner:
              (executable, arguments, {required workingDirectory}) async {
                calls.add([executable, ...arguments].join(' '));
                if (arguments.join(' ') == 'pub get') {
                  return ProcessResult(0, 1, '', 'resolution failed');
                }
                return ProcessResult(0, 0, '', '');
              },
        ),
        throwsA(
          isA<InstallCuboidException>().having(
            (error) => error.message,
            'message',
            contains('resolution failed'),
          ),
        ),
      );
      expect(calls, ['dart pub get']);
    });
  });

  group('installCuboidExecutable end-to-end regression', () {
    test('compiled executable runs correctly even when the install path '
        'contains a space (the dart pub global activate shim bug)', () async {
      final spaceRoot = Directory.systemTemp.createTempSync(
        'cuboid install regression ',
      );
      addTearDown(() => spaceRoot.deleteSync(recursive: true));
      expect(spaceRoot.path, contains(' '));

      final packageRoot = Directory('${spaceRoot.path}/pkg')..createSync();
      File('${packageRoot.path}/pubspec.yaml').writeAsStringSync('''
name: install_regression_fixture
environment:
  sdk: ^3.0.0
''');
      File('${packageRoot.path}/bin/cuboid.dart').createSync(recursive: true);
      File('${packageRoot.path}/bin/cuboid.dart').writeAsStringSync('''
void main() {
  print('cuboid fixture ok');
}
''');
      final binDirectory = Directory('${spaceRoot.path}/bin');

      final result = await installCuboidExecutable(
        packageRoot: packageRoot,
        binDirectory: binDirectory,
      );

      final invocation = await Process.run(result.executablePath, const []);

      expect(invocation.exitCode, 0);
      expect(invocation.stdout, contains('cuboid fixture ok'));
      expect(invocation.stderr, isNot(contains('too many arguments')));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
