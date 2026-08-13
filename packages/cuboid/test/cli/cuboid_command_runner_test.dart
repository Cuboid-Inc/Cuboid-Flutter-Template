import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cuboid/cuboid.dart';
import 'package:test/test.dart';

void main() {
  test('command runner starts', () {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.executableName, 'cuboid');
    expect(runner.commands, contains('create'));
    expect(runner.commands, contains('feature'));
  });

  test('--help works', () async {
    final output = _memorySink();
    final exitCode = await runCuboid(['--help'], stdout: output);

    expect(exitCode, 0);
    expect(
      output.content,
      contains('Command-line tools for Cuboid Flutter projects.'),
    );
    expect(output.content, contains('create'));
    expect(output.content, contains('feature'));
  });

  test('--version works', () async {
    final output = _memorySink();
    final exitCode = await runCuboid(['--version'], stdout: output);

    expect(exitCode, 0);
    expect(output.content.trim(), cuboidVersion);
  });

  test('create command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['create'], isA<CreateCommand>());
    expect(runner.commands['create']!.description, contains('Create a new'));
  });

  test('feature command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['feature'], isA<FeatureCommand>());
    expect(
      runner.commands['feature']!.description,
      contains('Create a new Cuboid feature'),
    );
  });

  test(
    'create dry-run reports the planned project without writing files',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        [
          'create',
          '--dry-run',
          '--output-dir',
          temp.path,
          'My App',
          'com.example.myapp',
        ],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Dry run: no files were written.'));
      expect(
        output.content,
        contains('Destination: ${temp.absolute.path}/my_app'),
      );
      expect(output.content, contains('Planned actions:'));
      expect(errorOutput.content, isEmpty);
      expect(Directory('${temp.path}/my_app').existsSync(), isFalse);
    },
  );

  test('create validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'My App'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a display name and package identifier.'),
    );
  });

  test('feature dry-run reports planned files without writing files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    File('${temp.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['feature', 'auth', '--dry-run'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Feature: Auth'));
    expect(
      output.content,
      contains('- lib/features/auth/ui/views/auth_view.dart'),
    );
    expect(
      output.content,
      contains('- lib/features/auth/ui/viewmodels/auth_viewmodel.dart'),
    );
    expect(errorOutput.content, isEmpty);
    expect(Directory('${temp.path}/lib/features/auth').existsSync(), isFalse);
  });

  test('feature validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['feature'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(errorOutput.content, contains('Expected a feature name.'));
  });

  test('runner can use an injected create service', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final output = _memorySink();
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            return ProcessResult(0, 0, '', '');
          },
    );
    final runner = CuboidCommandRunner(
      stdout: output,
      stderr: _memorySink(),
      createProjectService: service,
    );

    final exitCode = await runner.run([
      'create',
      '--no-post-steps',
      '--output-dir',
      temp.path,
      'My App',
      'com.example.myapp',
    ]);

    expect(exitCode, 0);
    expect(output.content, contains('Created My App.'));
    expect(Directory('${temp.path}/my_app').existsSync(), isTrue);
  });

  test('invalid command returns non-zero and writes usage', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['missing'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, isNot(0));
    expect(
      errorOutput.content,
      contains('Could not find a command named "missing".'),
    );
    expect(errorOutput.content, contains('Usage:'));
  });

  test('runner throws UsageException for invalid command', () {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(() => runner.run(['missing']), throwsA(isA<UsageException>()));
  });
}

_MemorySink _memorySink() => _MemorySink();

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  Encoding encoding = utf8;

  @override
  void write(Object? object) {
    _buffer.write(object);
  }

  @override
  void writeln([Object? object = '']) {
    _buffer.writeln(object);
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    _buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
  }

  @override
  void add(List<int> data) {
    _buffer.write(encoding.decode(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> close() async {
    await Future<void>.value();
  }

  @override
  Future<void> get done => Future.value();

  @override
  Future<void> flush() async {}
}
