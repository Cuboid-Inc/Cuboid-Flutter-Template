import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/create/create_project.dart';
import 'package:cuboid/src/feature/create_feature.dart';

const cuboidVersion = '0.1.0';

class CuboidCommandRunner extends CommandRunner<int> {
  CuboidCommandRunner({
    IOSink? stdout,
    IOSink? stderr,
    CreateProjectService? createProjectService,
    CreateFeatureService? createFeatureService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _createProjectService = createProjectService ?? CreateProjectService(),
       _createFeatureService = createFeatureService ?? CreateFeatureService(),
       super('cuboid', 'Command-line tools for Cuboid Flutter projects.') {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the Cuboid CLI version.',
    );
    addCommand(
      CreateCommand(
        stdout: _stdout,
        stderr: _stderr,
        createProjectService: _createProjectService,
      ),
    );
    addCommand(
      FeatureCommand(
        stdout: _stdout,
        stderr: _stderr,
        createFeatureService: _createFeatureService,
      ),
    );
  }

  final IOSink _stdout;
  final IOSink _stderr;
  final CreateProjectService _createProjectService;
  final CreateFeatureService _createFeatureService;

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
  CreateCommand({
    IOSink? stdout,
    IOSink? stderr,
    CreateProjectService? createProjectService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _createProjectService = createProjectService ?? CreateProjectService() {
    argParser
      ..addOption(
        'output-dir',
        abbr: 'o',
        help: 'Directory where the project directory will be created.',
      )
      ..addOption(
        'directory',
        help: 'Project directory name. Defaults to the derived Dart name.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Print the creation plan without writing files or running tools.',
      )
      ..addFlag(
        'post-steps',
        defaultsTo: true,
        help: 'Run flutter pub get, build_runner, and dart format.',
      );
  }

  final IOSink _stdout;
  final IOSink _stderr;
  final CreateProjectService _createProjectService;

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Cuboid Flutter project.';

  @override
  String get invocation =>
      'cuboid create [options] <display-name> <package-identifier>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException(
        'Expected a display name and package identifier.',
        usage,
      );
    }

    final outputDir = argResults!['output-dir'] as String?;
    final input = CreateProjectInput(
      displayName: rest[0],
      packageIdentifier: rest[1],
      destinationParent: outputDir == null ? null : Directory(outputDir),
      destinationName: argResults!['directory'] as String?,
      dryRun: argResults!['dry-run'] as bool,
      runPostSteps: argResults!['post-steps'] as bool,
    );

    try {
      final result = await _createProjectService.create(input);
      _writeResult(result);
      return 0;
    } on BootstrapException catch (error) {
      _stderr.writeln(error.message);
      return 64;
    } on CreateProjectException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  void _writeResult(CreateProjectResult result) {
    final plan = result.plan;
    if (plan.dryRun) {
      _stdout.writeln('Dry run: no files were written.');
    } else {
      _stdout.writeln('Created ${plan.values.displayName}.');
    }
    _stdout.writeln('Destination: ${plan.destination.path}');
    _stdout.writeln('Dart package: ${plan.values.dartProjectName}');
    _stdout.writeln('App package: ${plan.values.packageIdentifier}');
    _stdout.writeln('Template files: ${plan.templateManifest.files.length}');
    if (plan.dryRun) {
      _stdout.writeln('Planned actions:');
      for (final action in plan.actionSummary) {
        _stdout.writeln('- $action');
      }
      return;
    }
    if (result.postStepResults.isNotEmpty) {
      _stdout.writeln('Post-steps:');
      for (final postStep in result.postStepResults) {
        _stdout.writeln('- ${postStep.step.label}: ok');
      }
    }
    _stdout.writeln('Done.');
  }
}

class FeatureCommand extends Command<int> {
  FeatureCommand({
    IOSink? stdout,
    IOSink? stderr,
    CreateFeatureService? createFeatureService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _createFeatureService = createFeatureService ?? CreateFeatureService() {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Print the feature creation plan without writing files.',
    );
  }

  final IOSink _stdout;
  final IOSink _stderr;
  final CreateFeatureService _createFeatureService;

  @override
  String get name => 'feature';

  @override
  String get description => 'Create a new Cuboid feature scaffold.';

  @override
  String get invocation => 'cuboid feature [options] <name>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Expected a feature name.', usage);
    }

    final input = CreateFeatureInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _createFeatureService.create(input);
      _writeResult(result);
      return 0;
    } on CreateFeatureException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  void _writeResult(CreateFeatureResult result) {
    final plan = result.plan;
    if (plan.dryRun) {
      _stdout.writeln('Dry run: no files were written.');
      _stdout.writeln('Feature: ${plan.displayName}');
    } else {
      _stdout.writeln('Created feature ${plan.displayName}.');
    }
    _stdout.writeln('Files:');
    for (final file in plan.files) {
      _stdout.writeln('- $file');
    }
  }
}

Future<int> runCuboid(
  List<String> arguments, {
  IOSink? stdout,
  IOSink? stderr,
}) async {
  final output = stdout ?? ioStdout;
  final errorOutput = stderr ?? ioStderr;
  final runner = CuboidCommandRunner(stdout: output, stderr: errorOutput);

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
