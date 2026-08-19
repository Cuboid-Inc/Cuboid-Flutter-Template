import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cuboid/src/bottomsheet/create_bottomsheet.dart';
import 'package:cuboid/src/bottomsheet/delete_bottomsheet.dart';
import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/create/create_project.dart';
import 'package:cuboid/src/database/create_database.dart';
import 'package:cuboid/src/database/delete_database.dart';
import 'package:cuboid/src/dialog/create_dialog.dart';
import 'package:cuboid/src/dialog/delete_dialog.dart';
import 'package:cuboid/src/feature/create_feature.dart';
import 'package:cuboid/src/feature/delete_feature.dart';
import 'package:cuboid/src/model/create_model.dart';
import 'package:cuboid/src/route/delete_route.dart';
import 'package:cuboid/src/service/delete_service.dart';
import 'package:cuboid/src/service/register_service.dart';
import 'package:cuboid/src/storage/create_storage.dart';
import 'package:cuboid/src/storage/delete_storage.dart';
import 'package:cuboid/src/view/create_view.dart';
import 'package:cuboid/src/view/delete_view.dart';
import 'package:cuboid/src/widget/create_widget.dart';
import 'package:cuboid/src/widget/delete_widget.dart';

const cuboidVersion = '0.1.0';
const _knownCreateArtifacts = <String>[
  'app',
  'service',
  'feature',
  'bottomsheet',
  'dialog',
  'storage',
  'database',
  'view',
  'model',
  'widget',
];

/// Artifacts `cuboid delete` supports. Deliberately excludes `model` and
/// `app`: there is no per-artifact ownership state to reverse for a model
/// (it is a single bare file with no registration), and deleting a whole
/// generated app is just deleting its directory -- outside this command's
/// scope.
const _knownDeleteArtifacts = <String>[
  'service',
  'feature',
  'bottomsheet',
  'dialog',
  'storage',
  'database',
  'view',
  'widget',
  'route',
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
    RegisterServiceService? registerServiceService,
    CreateViewService? createViewService,
    CreateModelService? createModelService,
    CreateWidgetService? createWidgetService,
    DeleteServiceService? deleteServiceService,
    DeleteFeatureService? deleteFeatureService,
    DeleteBottomSheetService? deleteBottomSheetService,
    DeleteDialogService? deleteDialogService,
    DeleteStorageService? deleteStorageService,
    DeleteDatabaseService? deleteDatabaseService,
    DeleteViewService? deleteViewService,
    DeleteWidgetService? deleteWidgetService,
    DeleteRouteService? deleteRouteService,
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
           registerServiceService ?? RegisterServiceService(),
       _createViewService = createViewService ?? CreateViewService(),
       _createModelService = createModelService ?? CreateModelService(),
       _createWidgetService = createWidgetService ?? CreateWidgetService(),
       _deleteServiceService = deleteServiceService ?? DeleteServiceService(),
       _deleteFeatureService = deleteFeatureService ?? DeleteFeatureService(),
       _deleteBottomSheetService =
           deleteBottomSheetService ?? DeleteBottomSheetService(),
       _deleteDialogService = deleteDialogService ?? DeleteDialogService(),
       _deleteStorageService = deleteStorageService ?? DeleteStorageService(),
       _deleteDatabaseService =
           deleteDatabaseService ?? DeleteDatabaseService(),
       _deleteViewService = deleteViewService ?? DeleteViewService(),
       _deleteWidgetService = deleteWidgetService ?? DeleteWidgetService(),
       _deleteRouteService = deleteRouteService ?? DeleteRouteService(),
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
        createViewService: _createViewService,
        createModelService: _createModelService,
        createWidgetService: _createWidgetService,
      ),
    );
    addCommand(
      DeleteCommand(
        stdout: _stdout,
        stderr: _stderr,
        deleteServiceService: _deleteServiceService,
        deleteFeatureService: _deleteFeatureService,
        deleteBottomSheetService: _deleteBottomSheetService,
        deleteDialogService: _deleteDialogService,
        deleteStorageService: _deleteStorageService,
        deleteDatabaseService: _deleteDatabaseService,
        deleteViewService: _deleteViewService,
        deleteWidgetService: _deleteWidgetService,
        deleteRouteService: _deleteRouteService,
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
  final RegisterServiceService _registerServiceService;
  final CreateViewService _createViewService;
  final CreateModelService _createModelService;
  final CreateWidgetService _createWidgetService;
  final DeleteServiceService _deleteServiceService;
  final DeleteFeatureService _deleteFeatureService;
  final DeleteBottomSheetService _deleteBottomSheetService;
  final DeleteDialogService _deleteDialogService;
  final DeleteStorageService _deleteStorageService;
  final DeleteDatabaseService _deleteDatabaseService;
  final DeleteViewService _deleteViewService;
  final DeleteWidgetService _deleteWidgetService;
  final DeleteRouteService _deleteRouteService;

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
    CreateViewService? createViewService,
    CreateModelService? createModelService,
    CreateWidgetService? createWidgetService,
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
           registerServiceService ?? RegisterServiceService(),
       _createViewService = createViewService ?? CreateViewService(),
       _createModelService = createModelService ?? CreateModelService(),
       _createWidgetService = createWidgetService ?? CreateWidgetService() {
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
        help: 'Run flutter pub get and dart format.',
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
  final CreateViewService _createViewService;
  final CreateModelService _createModelService;
  final CreateWidgetService _createWidgetService;

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
      'Implemented artifact commands: '
      'cuboid create app <display-name> <package-identifier>, '
      'cuboid create feature <name>, '
      'cuboid create service <name>, '
      'cuboid create bottomsheet <name>, '
      'cuboid create dialog <name>, '
      'cuboid create storage, '
      'cuboid create database <provider>, '
      'cuboid create view <view-name> (shared) or '
      'cuboid create view <view-name> <feature> (feature-scoped), '
      'cuboid create model <name>, '
      'cuboid create widget <name> (shared) or '
      'cuboid create widget <name> <feature> (feature-scoped).\n'
      'cuboid create feature <name> also creates the feature\'s repository '
      'and registers its route; there is no separate route or repository '
      'command.\n'
      'Known artifact categories: '
      '${_knownCreateArtifacts.join(', ')}.\n'
      'other artifact commands are not yet implemented.\n'
      'cuboid delete <artifact> <name> reverses most of the above -- see '
      'cuboid delete --help.';

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
        if (artifact == 'app') {
          return _runCreateApp(rest.skip(1).toList());
        }
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
        if (artifact == 'view') {
          return _runCreateView(rest.skip(1).toList());
        }
        if (artifact == 'model') {
          return _runCreateModel(rest.skip(1).toList());
        }
        if (artifact == 'widget') {
          return _runCreateWidget(rest.skip(1).toList());
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
    return _runCreateApp(rest);
  }

  Future<int> _runCreateApp(List<String> rest) async {
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
    if (rest.isNotEmpty) {
      throw UsageException(
        'cuboid create storage does not take a storage name.',
        usage,
      );
    }

    final input = CreateStorageInput(dryRun: argResults!['dry-run'] as bool);

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

  Future<int> _runCreateView(List<String> rest) async {
    if (argResults!.wasParsed('output-dir') ||
        argResults!.wasParsed('directory') ||
        argResults!.wasParsed('post-steps')) {
      throw UsageException(
        'Only --dry-run is supported for cuboid create view.',
        usage,
      );
    }
    if (rest.length != 1 && rest.length != 2) {
      throw UsageException(
        'Expected a view name, or a view name and feature name.',
        usage,
      );
    }

    final input = rest.length == 1
        ? CreateViewInput(name: rest[0], dryRun: argResults!['dry-run'] as bool)
        : CreateViewInput(
            name: rest[0],
            feature: rest[1],
            dryRun: argResults!['dry-run'] as bool,
          );

    try {
      final result = await _createViewService.create(input);
      writeViewResult(_stdout, result);
      return 0;
    } on CreateViewException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runCreateModel(List<String> rest) async {
    if (argResults!.wasParsed('output-dir') ||
        argResults!.wasParsed('directory') ||
        argResults!.wasParsed('post-steps')) {
      throw UsageException(
        'Only --dry-run is supported for cuboid create model.',
        usage,
      );
    }
    if (rest.length != 1) {
      throw UsageException('Expected a model name.', usage);
    }

    final input = CreateModelInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _createModelService.create(input);
      writeModelResult(_stdout, result);
      return 0;
    } on CreateModelException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runCreateWidget(List<String> rest) async {
    if (argResults!.wasParsed('output-dir') ||
        argResults!.wasParsed('directory') ||
        argResults!.wasParsed('post-steps')) {
      throw UsageException(
        'Only --dry-run is supported for cuboid create widget.',
        usage,
      );
    }
    if (rest.length != 1 && rest.length != 2) {
      throw UsageException(
        'Expected a widget name, or a widget name and feature name.',
        usage,
      );
    }

    final input = rest.length == 1
        ? CreateWidgetInput(
            name: rest[0],
            dryRun: argResults!['dry-run'] as bool,
          )
        : CreateWidgetInput(
            name: rest[0],
            feature: rest[1],
            dryRun: argResults!['dry-run'] as bool,
          );

    try {
      final result = await _createWidgetService.create(input);
      writeWidgetResult(_stdout, result);
      return 0;
    } on CreateWidgetException catch (error) {
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

class DeleteCommand extends Command<int> {
  DeleteCommand({
    IOSink? stdout,
    IOSink? stderr,
    DeleteServiceService? deleteServiceService,
    DeleteFeatureService? deleteFeatureService,
    DeleteBottomSheetService? deleteBottomSheetService,
    DeleteDialogService? deleteDialogService,
    DeleteStorageService? deleteStorageService,
    DeleteDatabaseService? deleteDatabaseService,
    DeleteViewService? deleteViewService,
    DeleteWidgetService? deleteWidgetService,
    DeleteRouteService? deleteRouteService,
  }) : _stdout = stdout ?? ioStdout,
       _stderr = stderr ?? ioStderr,
       _deleteServiceService = deleteServiceService ?? DeleteServiceService(),
       _deleteFeatureService = deleteFeatureService ?? DeleteFeatureService(),
       _deleteBottomSheetService =
           deleteBottomSheetService ?? DeleteBottomSheetService(),
       _deleteDialogService = deleteDialogService ?? DeleteDialogService(),
       _deleteStorageService = deleteStorageService ?? DeleteStorageService(),
       _deleteDatabaseService =
           deleteDatabaseService ?? DeleteDatabaseService(),
       _deleteViewService = deleteViewService ?? DeleteViewService(),
       _deleteWidgetService = deleteWidgetService ?? DeleteWidgetService(),
       _deleteRouteService = deleteRouteService ?? DeleteRouteService() {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Print the deletion plan without deleting or modifying files.',
    );
  }

  final IOSink _stdout;
  final IOSink _stderr;
  final DeleteServiceService _deleteServiceService;
  final DeleteFeatureService _deleteFeatureService;
  final DeleteBottomSheetService _deleteBottomSheetService;
  final DeleteDialogService _deleteDialogService;
  final DeleteStorageService _deleteStorageService;
  final DeleteDatabaseService _deleteDatabaseService;
  final DeleteViewService _deleteViewService;
  final DeleteWidgetService _deleteWidgetService;
  final DeleteRouteService _deleteRouteService;

  @override
  String get name => 'delete';

  @override
  String get description =>
      'Delete a Cuboid-generated resource and any infrastructure it '
      'solely required.';

  @override
  String get invocation => 'cuboid delete <artifact> [arguments] [options]';

  @override
  void printUsage() {
    _stdout.writeln(usage);
  }

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw UsageException('Expected an artifact and a name.', usage);
    }

    final artifact = rest.first;
    if (!_knownDeleteArtifacts.contains(artifact)) {
      _stderr.writeln('Unknown delete artifact "$artifact".');
      _stderr.writeln('Known artifacts: ${_knownDeleteArtifacts.join(', ')}.');
      return 64;
    }

    final args = rest.skip(1).toList();
    switch (artifact) {
      case 'service':
        return _runDeleteService(args);
      case 'feature':
        return _runDeleteFeature(args);
      case 'bottomsheet':
        return _runDeleteBottomSheet(args);
      case 'dialog':
        return _runDeleteDialog(args);
      case 'storage':
        return _runDeleteStorage(args);
      case 'database':
        return _runDeleteDatabase(args);
      case 'view':
        return _runDeleteView(args);
      case 'widget':
        return _runDeleteWidget(args);
      case 'route':
        return _runDeleteRoute(args);
    }
    _stderr.writeln('cuboid delete $artifact is not implemented yet.');
    return 64;
  }

  Future<int> _runDeleteService(List<String> rest) async {
    if (rest.length != 1) {
      throw UsageException('Expected a service name.', usage);
    }

    final input = DeleteServiceInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _deleteServiceService.delete(input);
      writeServiceDeleteResult(_stdout, result);
      return 0;
    } on DeleteServiceException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runDeleteFeature(List<String> rest) async {
    if (rest.length != 1) {
      throw UsageException('Expected a feature name.', usage);
    }

    final input = DeleteFeatureInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _deleteFeatureService.delete(input);
      writeFeatureDeleteResult(_stdout, result);
      return 0;
    } on DeleteFeatureException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runDeleteBottomSheet(List<String> rest) async {
    if (rest.length != 1) {
      throw UsageException('Expected a bottom sheet name.', usage);
    }

    final input = DeleteBottomSheetInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _deleteBottomSheetService.delete(input);
      writeBottomSheetDeleteResult(_stdout, result);
      return 0;
    } on DeleteBottomSheetException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runDeleteDialog(List<String> rest) async {
    if (rest.length != 1) {
      throw UsageException('Expected a dialog name.', usage);
    }

    final input = DeleteDialogInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _deleteDialogService.delete(input);
      writeDialogDeleteResult(_stdout, result);
      return 0;
    } on DeleteDialogException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runDeleteStorage(List<String> rest) async {
    if (rest.isNotEmpty) {
      throw UsageException(
        'cuboid delete storage does not take a storage name.',
        usage,
      );
    }

    final input = DeleteStorageInput(dryRun: argResults!['dry-run'] as bool);

    try {
      final result = await _deleteStorageService.delete(input);
      writeStorageDeleteResult(_stdout, result);
      return 0;
    } on DeleteStorageException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runDeleteDatabase(List<String> rest) async {
    if (rest.length != 1) {
      throw UsageException('Expected a database provider.', usage);
    }

    final input = DeleteDatabaseInput(
      provider: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _deleteDatabaseService.delete(input);
      writeDatabaseDeleteResult(_stdout, result);
      return 0;
    } on DeleteDatabaseException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runDeleteView(List<String> rest) async {
    if (rest.length != 1 && rest.length != 2) {
      throw UsageException(
        'Expected a view name, or a view name and feature name.',
        usage,
      );
    }

    final input = rest.length == 1
        ? DeleteViewInput(name: rest[0], dryRun: argResults!['dry-run'] as bool)
        : DeleteViewInput(
            name: rest[0],
            feature: rest[1],
            dryRun: argResults!['dry-run'] as bool,
          );

    try {
      final result = await _deleteViewService.delete(input);
      writeViewDeleteResult(_stdout, result);
      return 0;
    } on DeleteViewException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runDeleteWidget(List<String> rest) async {
    if (rest.length != 1 && rest.length != 2) {
      throw UsageException(
        'Expected a widget name, or a widget name and feature name.',
        usage,
      );
    }

    final input = rest.length == 1
        ? DeleteWidgetInput(
            name: rest[0],
            dryRun: argResults!['dry-run'] as bool,
          )
        : DeleteWidgetInput(
            name: rest[0],
            feature: rest[1],
            dryRun: argResults!['dry-run'] as bool,
          );

    try {
      final result = await _deleteWidgetService.delete(input);
      writeWidgetDeleteResult(_stdout, result);
      return 0;
    } on DeleteWidgetException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }

  Future<int> _runDeleteRoute(List<String> rest) async {
    if (rest.length != 1) {
      throw UsageException('Expected a view name.', usage);
    }

    final input = DeleteRouteInput(
      name: rest[0],
      dryRun: argResults!['dry-run'] as bool,
    );

    try {
      final result = await _deleteRouteService.delete(input);
      writeRouteDeleteResult(_stdout, result);
      return 0;
    } on DeleteRouteException catch (error) {
      _stderr.writeln(error.message);
      return 1;
    }
  }
}

void writeServiceDeleteResult(IOSink stdout, DeleteServiceResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
    stdout.writeln('Service: ${plan.serviceClassName}');
  } else {
    stdout.writeln('Deleted service ${plan.serviceClassName}.');
  }
  stdout.writeln('Removed:');
  stdout.writeln('- ${plan.servicePath}');
  stdout.writeln('- ${plan.importLine}');
  stdout.writeln('- ${plan.serviceLine.trim()}');
}

void writeFeatureDeleteResult(IOSink stdout, DeleteFeatureResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
    stdout.writeln('Feature: ${plan.displayName}');
  } else {
    stdout.writeln('Deleted feature ${plan.displayName}.');
  }
  stdout.writeln('Removed:');
  stdout.writeln('- ${plan.featureDirectoryPath}');
  stdout.writeln(
    '- route registrations for every View under '
    '${plan.featureDirectoryPath}/ui',
  );
  stdout.writeln(
    '- ${plan.repositoryClassName} registration in ${plan.locatorPath} '
    '(if present)',
  );
}

void writeBottomSheetDeleteResult(
  IOSink stdout,
  DeleteBottomSheetResult result,
) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
    stdout.writeln('Bottom sheet: ${plan.sheetClassName}');
  } else {
    stdout.writeln('Deleted bottom sheet ${plan.sheetClassName}.');
  }
  stdout.writeln('Removed:');
  stdout.writeln('- ${plan.sheetPath}');
  stdout.writeln('- ${plan.modelPath}');
  if (plan.removesInfrastructure) {
    stdout.writeln('- ${plan.bottomSheetsPath} (no bottom sheets remain)');
    stdout.writeln(
      '- ${plan.bottomSheetServicePath} and its ${plan.locatorPath} '
      'registration (no bottom sheets remain)',
    );
  }
}

void writeDialogDeleteResult(IOSink stdout, DeleteDialogResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
    stdout.writeln('Dialog: ${plan.dialogClassName}');
  } else {
    stdout.writeln('Deleted dialog ${plan.dialogClassName}.');
  }
  stdout.writeln('Removed:');
  stdout.writeln('- ${plan.dialogPath}');
  stdout.writeln('- ${plan.modelPath}');
  if (plan.removesInfrastructure) {
    stdout.writeln('- ${plan.dialogsPath} (no dialogs remain)');
    stdout.writeln(
      '- ${plan.dialogServicePath} and its ${plan.locatorPath} '
      'registration (no dialogs remain)',
    );
  }
}

void writeStorageDeleteResult(IOSink stdout, DeleteStorageResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
    stdout.writeln('Storage: ${plan.className}');
  } else {
    stdout.writeln('Deleted storage ${plan.className}.');
  }
  stdout.writeln('Removed:');
  stdout.writeln('- ${plan.path}');
}

void writeDatabaseDeleteResult(IOSink stdout, DeleteDatabaseResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
    stdout.writeln('Database: ${plan.provider}');
  } else {
    stdout.writeln('Deleted ${plan.provider} database example.');
  }
  stdout.writeln('Removed:');
  stdout.writeln('- ${plan.modelPath}');
  stdout.writeln('- ${plan.repositoryPath}');
  stdout.writeln('- supabase/migrations/*_create_examples.sql');
  stdout.writeln('- lib/core/network/supabase_guard.dart (if present)');
  stdout.writeln('- ${plan.repositoryImportLine}');
  stdout.writeln('- ${plan.repositoryLine.trim()}');
  stdout.writeln('- supabase_flutter dependency in pubspec.yaml (if present)');
}

void writeViewDeleteResult(IOSink stdout, DeleteViewResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
    stdout.writeln('View: ${plan.displayName}');
  } else {
    stdout.writeln('Deleted view ${plan.displayName}.');
  }
  if (!plan.isShared) {
    stdout.writeln('Feature: ${plan.featureName}');
  }
  stdout.writeln('Removed:');
  for (final file in plan.files) {
    stdout.writeln('- $file');
  }
  stdout.writeln('- ${plan.routeRegistration.importLine}');
  stdout.writeln('- ${plan.routeRegistration.routeConstLine}');
  stdout.writeln('- ${plan.routeRegistration.routeMapLine}');
}

void writeWidgetDeleteResult(IOSink stdout, DeleteWidgetResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
    stdout.writeln('Widget: ${plan.className}');
  } else {
    stdout.writeln('Deleted widget ${plan.className}.');
  }
  if (!plan.isShared) {
    stdout.writeln('Feature: ${plan.feature}');
  }
  stdout.writeln('Removed:');
  stdout.writeln('- ${plan.path}');
  stdout.writeln('- ${plan.viewModelPath}');
}

void writeRouteDeleteResult(IOSink stdout, DeleteRouteResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: nothing was deleted.');
  } else {
    stdout.writeln('Deleted route for ${plan.name}.');
  }
  stdout.writeln(
    'Removed the route registration from ${plan.routerPath} only; View '
    'files were not touched.',
  );
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
  stdout.writeln('- ${plan.routerPath}');
  stdout.writeln('- ${plan.locatorPath}');
  if (plan.dryRun) {
    stdout.writeln('Planned changes:');
    stdout.writeln('- ${plan.routeRegistration.importLine}');
    stdout.writeln('- ${plan.routeRegistration.routeConstLine}');
    stdout.writeln('- ${plan.routeRegistration.routeMapLine}');
    stdout.writeln('- ${plan.repositoryImportLine}');
    stdout.writeln('- ${plan.repositoryLine.trim()}');
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
  stdout.writeln('- ${plan.bottomSheetsPath}');
  stdout.writeln('- ${plan.bottomSheetServicePath} (first use only)');
  stdout.writeln('- ${plan.locatorPath} (first use only)');
  if (plan.dryRun) {
    stdout.writeln('Planned changes:');
    stdout.writeln('- ${plan.sheetImportLine}');
    stdout.writeln('- ${plan.modelImportLine}');
    stdout.writeln('- ${plan.bottomSheetEntryLine}');
    stdout.writeln('- ${plan.serviceImportLine}');
    stdout.writeln('- ${plan.serviceLine.trim()}');
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
  stdout.writeln('- ${plan.dialogsPath}');
  stdout.writeln('- ${plan.dialogServicePath} (first use only)');
  stdout.writeln('- ${plan.locatorPath} (first use only)');
  if (plan.dryRun) {
    stdout.writeln('Planned changes:');
    stdout.writeln('- ${plan.dialogImportLine}');
    stdout.writeln('- ${plan.modelImportLine}');
    stdout.writeln('- ${plan.dialogEntryLine}');
    stdout.writeln('- ${plan.serviceImportLine}');
    stdout.writeln('- ${plan.serviceLine.trim()}');
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
    stdout.writeln('- flutter pub get');
    stdout.writeln(
      '- supabase db push (or `supabase migration up` for local dev)',
    );
  }
}

void writeViewResult(IOSink stdout, CreateViewResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('View: ${plan.displayName}');
  } else {
    stdout.writeln('Created view ${plan.displayName}.');
  }
  if (!plan.isShared) {
    stdout.writeln('Feature: ${plan.featureName}');
  }
  stdout.writeln('Files:');
  for (final file in plan.files) {
    stdout.writeln('- $file');
  }
  stdout.writeln('- ${plan.routerPath}');
  if (plan.dryRun) {
    stdout.writeln('Planned changes:');
    stdout.writeln('- ${plan.routeRegistration.importLine}');
    stdout.writeln('- ${plan.routeRegistration.routeConstLine}');
    stdout.writeln('- ${plan.routeRegistration.routeMapLine}');
  }
}

void writeModelResult(IOSink stdout, CreateModelResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('Model: ${plan.className}');
  } else {
    stdout.writeln('Created model ${plan.className}.');
  }
  stdout.writeln('Files:');
  stdout.writeln('- ${plan.path}');
}

void writeWidgetResult(IOSink stdout, CreateWidgetResult result) {
  final plan = result.plan;
  if (plan.dryRun) {
    stdout.writeln('Dry run: no files were written.');
    stdout.writeln('Widget: ${plan.className}');
  } else {
    stdout.writeln('Created widget ${plan.className}.');
  }
  if (!plan.isShared) {
    stdout.writeln('Feature: ${plan.feature}');
  }
  stdout.writeln('Files:');
  stdout.writeln('- ${plan.path}');
  stdout.writeln('- ${plan.viewModelPath}');
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
      'Create an additional Cuboid View inside an existing feature.';

  @override
  String get invocation => 'cuboid view [options] <name> <feature>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException('Expected a view name and feature name.', usage);
    }

    final input = CreateViewInput(
      name: rest[0],
      feature: rest[1],
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
    _stdout.writeln('- ${plan.routerPath}');
    if (plan.dryRun) {
      _stdout.writeln('Planned changes:');
      _stdout.writeln('- ${plan.routeRegistration.importLine}');
      _stdout.writeln('- ${plan.routeRegistration.routeConstLine}');
      _stdout.writeln('- ${plan.routeRegistration.routeMapLine}');
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
