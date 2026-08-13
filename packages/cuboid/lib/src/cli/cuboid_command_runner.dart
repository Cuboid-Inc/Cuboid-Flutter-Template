import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

const cuboidVersion = '0.1.0';

class CuboidCommandRunner extends CommandRunner<int> {
  CuboidCommandRunner({IOSink? stdout})
    : _stdout = stdout ?? ioStdout,
      super('cuboid', 'Command-line tools for Cuboid Flutter projects.') {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the Cuboid CLI version.',
    );
    addCommand(CreateCommand(stdout: _stdout));
  }

  final IOSink _stdout;

  @override
  Future<int?> run(Iterable<String> args) async {
    final results = parse(args);
    if (results['help'] as bool) {
      _stdout.writeln(usage);
      return 0;
    }
    if (results['version'] as bool) {
      _stdout.writeln(cuboidVersion);
      return 0;
    }
    return runCommand(results);
  }
}

class CreateCommand extends Command<int> {
  CreateCommand({IOSink? stdout}) : _stdout = stdout ?? ioStdout;

  final IOSink _stdout;

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Cuboid Flutter project.';

  @override
  FutureOr<int> run() {
    _stdout.writeln(
      'Project creation is not implemented yet. Run "cuboid create --help" for usage.',
    );
    return 64;
  }
}

Future<int> runCuboid(
  List<String> arguments, {
  IOSink? stdout,
  IOSink? stderr,
}) async {
  final output = stdout ?? ioStdout;
  final errorOutput = stderr ?? ioStderr;
  final runner = CuboidCommandRunner(stdout: output);

  try {
    return await runner.run(arguments) ?? 0;
  } on UsageException catch (error) {
    errorOutput.writeln(error.message);
    errorOutput.writeln();
    errorOutput.writeln(error.usage);
    return 64;
  }
}

IOSink get ioStdout => stdout;
IOSink get ioStderr => stderr;
