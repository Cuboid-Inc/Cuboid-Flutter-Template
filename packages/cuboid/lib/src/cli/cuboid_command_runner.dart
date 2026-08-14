import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cuboid/src/bottomsheet/create_bottomsheet.dart';
import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/create/create_project.dart';
import 'package:cuboid/src/database/create_database.dart';
import 'package:cuboid/src/dialog/create_dialog.dart';
import 'package:cuboid/src/feature/create_feature.dart';
import 'package:cuboid/src/route/register_route.dart';
import 'package:cuboid/src/service/register_service.dart';
import 'package:cuboid/src/storage/create_storage.dart';
import 'package:cuboid/src/view/create_view.dart';

const cuboidVersion = '0.1.0';
const _knownCreateArtifacts = <String>[
  'app',
  'service',
  'feature',
  'bottomsheet',
  'dialog',
  'storage',
  'database',
];

class CuboidCommandRunner extends CommandRunner<int> {
  CuboidCommandRunner({
    IOSink? stdout,
    IOSink? stderr,
    CreateProjectService? createProjectService,
    CreateFeatureService? createFeatureService,
    CreateBottomSheetService? createBottomSheetService,
    CreateDialogService? createDialogService,
    CreateStorageService? createStorageService,
    CreateDatabaseService? createDatabaseService,
    RegisterRouteService? registerRouteService,
    RegisterServiceService? registerServiceService,
    CreateViewService? createViewService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _createProjectService = createProjectService ?? CreateProjectService(),
       _createFeatureService = createFeatureService ?? CreateFeatureService(),
       _createBottomSheetService =
           createBottomSheetService ?? CreateBottomSheetService(),
       _createDialogService = createDialogService ?? CreateDialogService(),
       _createStorageService = createStorageService ?? CreateStorageService(),
       _createDatabaseService =
           createDatabaseService ?? CreateDatabaseService(),
       _registerRouteService = registerRouteService ?? RegisterRouteService(),
       _registerServiceService =
           registerServiceService ?? RegisterServiceService(),
       _createViewService = createViewService ?? CreateViewService(),
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
        createFeatureService: _createFeatureService,
        createBottomSheetService: _createBottomSheetService,
        createDialogService: _createDialogService,
        createStorageService: _createStorageService,
        createDatabaseService: _createDatabaseService,
        registerServiceService: _registerServiceService,
      ),
    );
    addCommand(
      FeatureCommand(
        stdout: _stdout,
        stderr: _stderr,
        createFeatureService: _createFeatureService,
      ),
    );
    addCommand(
      RouteCommand(
        stdout: _stdout,
        stderr: _stderr,
        registerRouteService: _registerRouteService,
      ),
    );
    addCommand(
      ServiceCommand(
        stdout: _stdout,
        stderr: _stderr,
        registerServiceService: _registerServiceService,
      ),
    );
    addCommand(
      ViewCommand(
        stdout: _stdout,
        stderr: _stderr,
        createViewService: _createViewService,
      ),
    );
  }

  final IOSink _stdout;
  final IOSink _stderr;
  final CreateProjectService _createProjectService;
  final CreateFeatureService _createFeatureService;
  final CreateBottomSheetService _createBottomSheetService;
  final CreateDialogService _createDialogService;
  final CreateStorageService _createStorageService;
  final CreateDatabaseService _createDatabaseService;
  final RegisterRouteService _registerRouteService;
  final RegisterServiceService _registerServiceService;
  final CreateViewService _createViewService;

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
    CreateFeatureService? createFeatureService,
    CreateBottomSheetService? createBottomSheetService,
    CreateDialogService? createDialogService,
    CreateStorageService? createStorageService,
    CreateDatabaseService? createDatabaseService,
    RegisterServiceService? registerServiceService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _createProjectService = createProjectService ?? CreateProjectService(),
       _createFeatureService = createFeatureService ?? CreateFeatureService(),
       _createBottomSheetService =
           createBottomSheetService ?? CreateBottomSheetService(),
       _createDialogService = createDialogService ?? CreateDialogService(),
       _createStorageService = createStorageService ?? CreateStorageService(),
       _createDatabaseService =
           createDatabaseService ?? CreateDatabaseService(),
       _registerServiceService =
           registerServiceService ?? RegisterServiceService() {
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
  final CreateFeatureService _createFeatureService;
  final CreateBottomSheetService _createBottomSheetService;
  final CreateDialogService _createDialogService;
  final CreateStorageService _createStorageService;
  final CreateDatabaseService _createDatabaseService;
  final RegisterServiceService _registerServiceService;

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Cuboid Flutter project.';

  @override
  String get invocation =>
      'cuboid create [options] <display-name> <package-identifier>';

  @override
  String get usageFooter =>
      'Canonical namespace: cuboid create <artifact> [arguments] [options]\n'
      'Implemented artifact commands: cuboid create feature <name>, '
      'cuboid create service <name>, '
      'cuboid create bottomsheet <name>, '
      'cuboid create dialog <name>, '
      'cuboid create storage <name>, '
      'cuboid create database <provider>.\n'
      'Known artifact categories: '
      '${_knownCreateArtifacts.join(', ')}.\n'
      'other artifact commands are not yet implemented.';

  @override
  void printUsage() {
    _stdout.writeln(usage);
  }

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isNotEmpty) {
      final artifact = rest.first;
      if (_knownCreateArtifacts.contains(artifact)) {
        if (artifact == 'feature') {
          return _runCreateFeature(rest.skip(1).toList());
        }
        if (artifact == 'service') {
          return _runCreateService(rest.skip(1).toList());
        }
        if (artifact == 'bottomsheet') {
          return _runCreateBottomSheet(rest.skip(1).toList());
        }
        if (artifact == 'dialog') {
          return _runCreateDialog(rest.skip(1).toList());
        }
        if (artifact == 'storage') {
          return _runCreateStorage(rest.skip(1).toList());
        }
        if (artifact == 'database') {
          return _runCreateDatabase(rest.skip(1).toList());
        }
        _stderr.writeln('cuboid create $artifact is not implemented yet.');
        return 64;
      }
      if (rest.length == 1 && _looksLikeCreateArtifact(artifact)) {
        _stderr.writeln('Unknown create artifact "$artifact".');
        _stderr.writeln(
          'Known artifacts: ${_knownCreateArtifacts.join(', ')}.',
        );
        return 64;
      }
    }
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

  Future<int> _runCreateFeature(List<String> rest) async {
    if (rest.length != 1) {
      throw UsageException('Expected a feature name.', usage);
    }

    final input = CreateFeatureInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _createFeatureService.create(input);
      writeFeatureResult(_stdout, result);
      return 0;
    } on CreateFeatureException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runCreateService(List<String> rest) async {
    if (argResults!.wasParsed('output-dir') ||
        argResults!.wasParsed('directory') ||
        argResults!.wasParsed('post-steps')) {
      throw UsageException(
        'Only --dry-run is supported for cuboid create service.',
        usage,
      );
    }
    if (rest.length != 1) {
      throw UsageException('Expected a service name.', usage);
    }

    final input = RegisterServiceInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _registerServiceService.create(input);
      writeCreatedServiceResult(_stdout, result);
      return 0;
    } on RegisterServiceException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runCreateBottomSheet(List<String> rest) async {
    if (argResults!.wasParsed('output-dir') ||
        argResults!.wasParsed('directory') ||
        argResults!.wasParsed('post-steps')) {
      throw UsageException(
        'Only --dry-run is supported for cuboid create bottomsheet.',
        usage,
      );
    }
    if (rest.length != 1) {
      throw UsageException('Expected a bottom sheet name.', usage);
    }

    final input = CreateBottomSheetInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _createBottomSheetService.create(input);
      writeBottomSheetResult(_stdout, result);
      return 0;
    } on CreateBottomSheetException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runCreateDialog(List<String> rest) async {
    if (argResults!.wasParsed('output-dir') ||
        argResults!.wasParsed('directory') ||
        argResults!.wasParsed('post-steps')) {
      throw UsageException(
        'Only --dry-run is supported for cuboid create dialog.',
        usage,
      );
    }
    if (rest.length != 1) {
      throw UsageException('Expected a dialog name.', usage);
    }

    final input = CreateDialogInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _createDialogService.create(input);
      writeDialogResult(_stdout, result);
      return 0;
    } on CreateDialogException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runCreateStorage(List<String> rest) async {
    if (argResults!.wasParsed('output-dir') ||
        argResults!.wasParsed('directory') ||
        argResults!.wasParsed('post-steps')) {
      throw UsageException(
        'Only --dry-run is supported for cuboid create storage.',
        usage,
      );
    }
    if (rest.length != 1) {
      throw UsageException('Expected a storage name.', usage);
    }

    final input = CreateStorageInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _createStorageService.create(input);
      writeStorageResult(_stdout, result);
      return 0;
    } on CreateStorageException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runCreateDatabase(List<String> rest) async {
    if (argResults!.wasParsed('output-dir') ||
        argResults!.wasParsed('directory') ||
        argResults!.wasParsed('post-steps')) {
      throw UsageException(
        'Only --dry-run is supported for cuboid create database.',
        usage,
      );
    }
    if (rest.length != 1) {
      throw UsageException('Expected a database provider.', usage);
    }

    final input = CreateDatabaseInput(
      provider: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _createDatabaseService.create(input);
      writeDatabaseResult(_stdout, result);
      return 0;
    } on CreateDatabaseException catch (error) {
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

bool _looksLikeCreateArtifact(String value) {
  return RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(value);
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
      writeFeatureResult(_stdout, result);
      return 0;
    } on CreateFeatureException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }
}

void writeFeatureResult(IOSink stdout, CreateFeatureResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('Feature: ${plan.displayName}');
  } else {
    stdout.writeln('Created feature ${plan.displayName}.');
  }
  stdout.writeln('Files:');
  for (final file in plan.files) {
    stdout.writeln('- $file');
  }
}

void writeCreatedServiceResult(IOSink stdout, RegisterServiceResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('Service: ${plan.serviceClassName}');
  } else {
    stdout.writeln('Created service ${plan.serviceClassName}.');
  }
  stdout.writeln('Files:');
  stdout.writeln('- ${plan.servicePath}');
  stdout.writeln('- ${plan.appPath}');
  if (plan.dryRun) {
    stdout.writeln('Planned changes:');
    stdout.writeln('- class ${plan.serviceClassName} {}');
    stdout.writeln('- ${plan.importLine}');
    stdout.writeln('- ${plan.serviceLine.trim()}');
  } else {
    stdout.writeln('Next step: dart run build_runner build -d');
  }
}

void writeBottomSheetResult(IOSink stdout, CreateBottomSheetResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('Bottom sheet: ${plan.sheetClassName}');
  } else {
    stdout.writeln('Created bottom sheet ${plan.sheetClassName}.');
  }
  stdout.writeln('Files:');
  stdout.writeln('- ${plan.sheetPath}');
  stdout.writeln('- ${plan.modelPath}');
  stdout.writeln('- ${plan.appPath}');
  stdout.writeln('- ${plan.mainPath}');
  if (plan.dryRun) {
    stdout.writeln('Planned changes:');
    stdout.writeln('- ${plan.sheetImportLine}');
    stdout.writeln('- ${plan.bottomSheetLine.trim()}');
    stdout.writeln('- ${plan.serviceLine.trim()}');
    stdout.writeln('- ${plan.bottomSheetsImportLine}');
    stdout.writeln('- ${plan.setupLine.trim()}');
  } else {
    stdout.writeln('Next step: dart run build_runner build -d');
  }
}

void writeDialogResult(IOSink stdout, CreateDialogResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('Dialog: ${plan.dialogClassName}');
  } else {
    stdout.writeln('Created dialog ${plan.dialogClassName}.');
  }
  stdout.writeln('Files:');
  stdout.writeln('- ${plan.dialogPath}');
  stdout.writeln('- ${plan.modelPath}');
  stdout.writeln('- ${plan.appPath}');
  stdout.writeln('- ${plan.mainPath}');
  if (plan.dryRun) {
    stdout.writeln('Planned changes:');
    stdout.writeln('- ${plan.dialogImportLine}');
    stdout.writeln('- ${plan.dialogLine.trim()}');
    stdout.writeln('- ${plan.serviceLine.trim()}');
    stdout.writeln('- ${plan.dialogsImportLine}');
    stdout.writeln('- ${plan.setupLine.trim()}');
  } else {
    stdout.writeln('Next step: dart run build_runner build -d');
  }
}

void writeStorageResult(IOSink stdout, CreateStorageResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('Storage: ${plan.className}');
  } else {
    stdout.writeln('Created storage ${plan.className}.');
  }
  stdout.writeln('Files:');
  stdout.writeln('- ${plan.path}');
}

void writeDatabaseResult(IOSink stdout, CreateDatabaseResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('Database: ${plan.provider}');
  } else {
    stdout.writeln('Created ${plan.provider} database example.');
  }
  stdout.writeln('Files:');
  for (final file in plan.files) {
    stdout.writeln('- $file');
  }
  stdout.writeln('- ${plan.appPath}');
  if (plan.dryRun) {
    stdout.writeln('Planned changes:');
    stdout.writeln('- ${plan.repositoryImportLine}');
    stdout.writeln('- ${plan.repositoryLine.trim()}');
  } else {
    stdout.writeln('Next steps:');
    stdout.writeln('- dart run build_runner build -d');
    stdout.writeln(
      '- supabase db push (or `supabase migration up` for local dev)',
    );
  }
}

class RouteCommand extends Command<int> {
  RouteCommand({
    IOSink? stdout,
    IOSink? stderr,
    RegisterRouteService? registerRouteService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _registerRouteService = registerRouteService ?? RegisterRouteService() {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Print the route registration plan without writing files.',
    );
  }

  final IOSink _stdout;
  final IOSink _stderr;
  final RegisterRouteService _registerRouteService;

  @override
  String get name => 'route';

  @override
  String get description => 'Register an existing feature View as a route.';

  @override
  String get invocation => 'cuboid route [options] <feature>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Expected a feature name.', usage);
    }

    final input = RegisterRouteInput(
      feature: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _registerRouteService.register(input);
      _writeResult(result);
      return 0;
    } on RegisterRouteException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  void _writeResult(RegisterRouteResult result) {
    final plan = result.plan;
    if (plan.dryRun) {
      _stdout.writeln('Dry run: no files were written.');
      _stdout.writeln('Route: ${plan.viewClassName}');
    } else {
      _stdout.writeln('Registered route ${plan.viewClassName}.');
    }
    _stdout.writeln('Files:');
    _stdout.writeln('- ${plan.appPath}');
    if (plan.dryRun) {
      _stdout.writeln('Planned changes:');
      _stdout.writeln('- ${plan.importLine}');
      _stdout.writeln('- ${plan.routeLine.trim()}');
    } else {
      _stdout.writeln('Next step: dart run build_runner build -d');
    }
  }
}

class ViewCommand extends Command<int> {
  ViewCommand({
    IOSink? stdout,
    IOSink? stderr,
    CreateViewService? createViewService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _createViewService = createViewService ?? CreateViewService() {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Print the view creation plan without writing files.',
    );
  }

  final IOSink _stdout;
  final IOSink _stderr;
  final CreateViewService _createViewService;

  @override
  String get name => 'view';

  @override
  String get description =>
      'Create an additional Stacked View inside an existing feature.';

  @override
  String get invocation => 'cuboid view [options] <feature> <name>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException('Expected a feature name and view name.', usage);
    }

    final input = CreateViewInput(
      feature: rest[0],
      name: rest[1],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _createViewService.create(input);
      _writeResult(result);
      return 0;
    } on CreateViewException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  void _writeResult(CreateViewResult result) {
    final plan = result.plan;
    if (plan.dryRun) {
      _stdout.writeln('Dry run: no files were written.');
      _stdout.writeln('View: ${plan.displayName}');
    } else {
      _stdout.writeln('Created view ${plan.displayName}.');
    }
    _stdout.writeln('Feature: ${plan.featureName}');
    _stdout.writeln('Files:');
    for (final file in plan.files) {
      _stdout.writeln('- $file');
    }
  }
}

class ServiceCommand extends Command<int> {
  ServiceCommand({
    IOSink? stdout,
    IOSink? stderr,
    RegisterServiceService? registerServiceService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _registerServiceService =
           registerServiceService ?? RegisterServiceService() {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Print the service registration plan without writing files.',
    );
  }

  final IOSink _stdout;
  final IOSink _stderr;
  final RegisterServiceService _registerServiceService;

  @override
  String get name => 'service';

  @override
  String get description => 'Register an existing core service.';

  @override
  String get invocation => 'cuboid service [options] <name>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Expected a service name.', usage);
    }

    final input = RegisterServiceInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _registerServiceService.register(input);
      _writeResult(result);
      return 0;
    } on RegisterServiceException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  void _writeResult(RegisterServiceResult result) {
    final plan = result.plan;
    if (plan.dryRun) {
      _stdout.writeln('Dry run: no files were written.');
      _stdout.writeln('Service: ${plan.serviceClassName}');
    } else {
      _stdout.writeln('Registered service ${plan.serviceClassName}.');
    }
    _stdout.writeln('Files:');
    _stdout.writeln('- ${plan.appPath}');
    if (plan.dryRun) {
      _stdout.writeln('Planned changes:');
      _stdout.writeln('- ${plan.importLine}');
      _stdout.writeln('- ${plan.serviceLine.trim()}');
    } else {
      _stdout.writeln('Next step: dart run build_runner build -d');
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
