import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';

typedef DatabaseFileWriter = void Function(File file, String contents);

const _supportedProviders = <String>['supabase'];

class CreateDatabaseInput {
  const CreateDatabaseInput({
    required this.provider,
    this.projectRoot,
    this.dryRun = false,
    this.timestamp,
  });

  final String provider;
  final Directory? projectRoot;
  final bool dryRun;

  /// Injectable clock for deterministic migration filenames in tests.
  /// Defaults to the current UTC time.
  final DateTime? timestamp;
}

class CreateDatabasePlan {
  const CreateDatabasePlan({
    required this.provider,
    required this.packageName,
    required this.modelClassName,
    required this.repositoryClassName,
    required this.modelPath,
    required this.repositoryPath,
    required this.migrationPath,
    required this.appPath,
    required this.repositoryImportLine,
    required this.repositoryLine,
    required this.dryRun,
  });

  final String provider;
  final String packageName;
  final String modelClassName;
  final String repositoryClassName;
  final String modelPath;
  final String repositoryPath;
  final String migrationPath;
  final String appPath;
  final String repositoryImportLine;
  final String repositoryLine;
  final bool dryRun;

  List<String> get files => [modelPath, repositoryPath, migrationPath];
}

class CreateDatabaseResult {
  const CreateDatabaseResult({required this.plan});

  final CreateDatabasePlan plan;
}

class CreateDatabaseException implements Exception {
  const CreateDatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateDatabaseService {
  CreateDatabaseService({DatabaseFileWriter? fileWriter})
    : _fileWriter =
          fileWriter ?? ((file, contents) => file.writeAsStringSync(contents));

  final DatabaseFileWriter _fileWriter;

  Future<CreateDatabasePlan> plan(CreateDatabaseInput input) async {
    final provider = _normalizeProvider(input.provider);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final packageName = _readPackageName(projectRoot);
    final timestamp = (input.timestamp ?? DateTime.now()).toUtc();

    return CreateDatabasePlan(
      provider: provider,
      packageName: packageName,
      modelClassName: 'ExampleModel',
      repositoryClassName: 'ExampleRepository',
      modelPath: 'lib/supabase/example_model.dart',
      repositoryPath: 'lib/supabase/example_repository.dart',
      migrationPath:
          'supabase/migrations/${_migrationTimestamp(timestamp)}_create_examples.sql',
      appPath: 'lib/app/app.dart',
      repositoryImportLine:
          "import 'package:$packageName/supabase/example_repository.dart';",
      repositoryLine: '    LazySingleton(classType: ExampleRepository),',
      dryRun: input.dryRun,
    );
  }

  Future<CreateDatabaseResult> create(CreateDatabaseInput input) async {
    final createPlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final appFile = _targetFile(projectRoot, createPlan.appPath);
    final modelFile = _targetFile(projectRoot, createPlan.modelPath);
    final repositoryFile = _targetFile(projectRoot, createPlan.repositoryPath);
    final migrationFile = _targetFile(projectRoot, createPlan.migrationPath);

    final appContents = _validateApp(createPlan, appFile);
    _ensureSupabaseFoundation(projectRoot);
    _validateGeneratedTargets(
      projectRoot,
      createPlan,
      modelFile,
      repositoryFile,
      migrationFile,
    );

    final nextAppContents = _applyAppPlan(appContents, createPlan);

    if (createPlan.dryRun) {
      return CreateDatabaseResult(plan: createPlan);
    }

    final createdFiles = <File>[];
    final createdDirectories = <Directory>[];
    try {
      _createParentDirectories(
        projectRoot,
        modelFile.parent,
        createdDirectories,
      );
      _fileWriter(modelFile, _modelContents(createPlan));
      createdFiles.add(modelFile);
      _fileWriter(repositoryFile, _repositoryContents(createPlan));
      createdFiles.add(repositoryFile);
      _createParentDirectories(
        projectRoot,
        migrationFile.parent,
        createdDirectories,
      );
      _fileWriter(migrationFile, _migrationContents(createPlan));
      createdFiles.add(migrationFile);
      _replaceFileContents(appFile, nextAppContents, label: createPlan.appPath);
    } on FileSystemException catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {appFile: appContents},
      );
      throw CreateDatabaseException(
        'Unable to create database ${createPlan.provider}: ${error.message}',
      );
    } catch (error) {
      _rollback(
        createdFiles,
        createdDirectories,
        restoredFiles: {appFile: appContents},
      );
      throw CreateDatabaseException(
        'Unable to create database ${createPlan.provider}: $error',
      );
    }

    return CreateDatabaseResult(plan: createPlan);
  }
}

void _validateGeneratedTargets(
  Directory projectRoot,
  CreateDatabasePlan plan,
  File modelFile,
  File repositoryFile,
  File migrationFile,
) {
  _ensureSafeParentDirectories(projectRoot, modelFile.parent);
  _ensureSafeParentDirectories(projectRoot, migrationFile.parent);
  for (final entity in [modelFile, repositoryFile, migrationFile]) {
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      throw CreateDatabaseException(
        'Target already exists: ${_relativePath(projectRoot, entity.path)}',
      );
    }
  }
}

String _validateApp(CreateDatabasePlan plan, File appFile) {
  _ensureRegularFile(appFile.path, plan.appPath);
  final contents = _readFile(appFile, plan.appPath);

  _requireSingleMarker(contents, '// @stacked-import');
  _requireSingleMarker(contents, '// @stacked-service');
  if (_hasMatchingImport(contents, plan)) {
    throw CreateDatabaseException(
      'Repository import already exists for ${plan.repositoryClassName}.',
    );
  }
  if (_hasConflictingImport(contents, plan)) {
    throw CreateDatabaseException(
      'Conflicting repository import exists for ${plan.repositoryClassName}.',
    );
  }
  if (_hasRepositoryRegistration(contents, plan)) {
    throw CreateDatabaseException(
      'Repository already exists for ${plan.repositoryClassName}.',
    );
  }
  return contents;
}

void _ensureSupabaseFoundation(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  _ensureRegularFile(pubspecPath, 'pubspec.yaml');
  final pubspecContents = _readFile(File(pubspecPath), 'pubspec.yaml');
  if (!RegExp(
    r'^\s*supabase_flutter\s*:',
    multiLine: true,
  ).hasMatch(pubspecContents)) {
    throw const CreateDatabaseException(
      'pubspec.yaml must declare a supabase_flutter dependency before '
      'running cuboid create database supabase.',
    );
  }

  const requiredFiles = [
    'lib/core/network/supabase_guard.dart',
    'lib/core/errors/result.dart',
    'lib/core/errors/failures.dart',
  ];
  for (final path in requiredFiles) {
    _ensureRegularFile(
      '${projectRoot.path}${Platform.pathSeparator}'
      '${path.replaceAll('/', Platform.pathSeparator)}',
      path,
    );
  }
}

void _ensureSafeParentDirectories(Directory projectRoot, Directory parent) {
  final rootPath = projectRoot.absolute.path;
  final parentPath = parent.absolute.path;
  if (!parentPath.startsWith(_withTrailingSeparator(rootPath))) {
    throw const CreateDatabaseException(
      'Target path must stay inside the project.',
    );
  }

  final relative = parentPath.substring(rootPath.length + 1);
  var current = rootPath;
  for (final segment in relative.split(Platform.pathSeparator)) {
    current = '$current${Platform.pathSeparator}$segment';
    final type = FileSystemEntity.typeSync(current, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      continue;
    }
    if (type == FileSystemEntityType.link) {
      throw CreateDatabaseException(
        'Refusing to create database files through a symlink: '
        '${_relativePath(projectRoot, current)}',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw CreateDatabaseException('$current must be a directory.');
    }
  }
}

void _ensureRegularFile(String path, String label) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    throw CreateDatabaseException('$label was not found.');
  }
  if (type == FileSystemEntityType.link) {
    throw CreateDatabaseException('$label must not be a symlink.');
  }
  if (type != FileSystemEntityType.file) {
    throw CreateDatabaseException('$label must be a regular file.');
  }
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw CreateDatabaseException('Unable to read $label: ${error.message}');
  }
}

void _requireSingleMarker(String contents, String marker) {
  final count = marker.allMatches(contents).length;
  if (count == 0) {
    throw CreateDatabaseException('Missing marker: $marker');
  }
  if (count > 1) {
    throw CreateDatabaseException('Duplicate marker: $marker');
  }
}

bool _hasMatchingImport(String contents, CreateDatabasePlan plan) {
  return _repositoryImports(contents).contains(plan.repositoryImportLine);
}

bool _hasConflictingImport(String contents, CreateDatabasePlan plan) {
  return _repositoryImports(
    contents,
  ).any((line) => line != plan.repositoryImportLine);
}

List<String> _repositoryImports(String contents) {
  final pattern = RegExp(
    r'''^import\s+(['"])([^'"]*/supabase/example_repository\.dart)\1\s*;''',
    multiLine: true,
  );
  return pattern
      .allMatches(contents)
      .map((match) => "import '${match.group(2)}';")
      .toList();
}

bool _hasRepositoryRegistration(String contents, CreateDatabasePlan plan) {
  final pattern = RegExp(
    r'classType\s*:\s*' + RegExp.escape(plan.repositoryClassName) + r'\b',
  );
  return pattern.hasMatch(contents);
}

String _applyAppPlan(String contents, CreateDatabasePlan plan) {
  final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
  return contents
      .replaceFirst(
        RegExp(r'^[ \t]*// @stacked-import', multiLine: true),
        '${plan.repositoryImportLine}$lineEnding// @stacked-import',
      )
      .replaceFirst(
        RegExp(r'^[ \t]*// @stacked-service', multiLine: true),
        '${plan.repositoryLine}$lineEnding    // @stacked-service',
      );
}

void _replaceFileContents(File file, String contents, {required String label}) {
  final Directory temp;
  try {
    temp = file.parent.createTempSync('.cuboid-database-');
  } on FileSystemException catch (error) {
    throw CreateDatabaseException('Unable to update $label: ${error.message}');
  }
  final tempFile = File(
    '${temp.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
  );
  try {
    tempFile.writeAsStringSync(contents);
    tempFile.renameSync(file.path);
  } on FileSystemException catch (error) {
    throw CreateDatabaseException('Unable to update $label: ${error.message}');
  } finally {
    try {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // Best-effort cleanup; preserve the actual write or publish result.
    }
  }
}

File _targetFile(Directory projectRoot, String path) {
  return File(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${path.replaceAll('/', Platform.pathSeparator)}',
  );
}

void _createParentDirectories(
  Directory projectRoot,
  Directory targetDirectory,
  List<Directory> createdDirectories,
) {
  final missing = <Directory>[];
  var current = targetDirectory;
  while (current.path != projectRoot.path && !current.existsSync()) {
    missing.add(current);
    current = current.parent;
  }

  targetDirectory.createSync(recursive: true);
  createdDirectories.addAll(missing);
}

void _rollback(
  List<File> createdFiles,
  List<Directory> createdDirectories, {
  Map<File, String> restoredFiles = const {},
}) {
  for (final entry in restoredFiles.entries) {
    try {
      entry.key.writeAsStringSync(entry.value);
    } on FileSystemException {
      // Best-effort cleanup; preserve the original creation failure.
    }
  }

  for (final file in createdFiles.reversed) {
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on FileSystemException {
      // Best-effort cleanup; preserve the original creation failure.
    }
  }

  final directories = createdDirectories.toSet().toList()
    ..sort((a, b) => b.path.length.compareTo(a.path.length));
  for (final directory in directories) {
    try {
      if (directory.existsSync() && directory.listSync().isEmpty) {
        directory.deleteSync();
      }
    } on FileSystemException {
      // Best-effort cleanup; preserve the original creation failure.
    }
  }
}

String _withTrailingSeparator(String path) {
  return path.endsWith(Platform.pathSeparator)
      ? path
      : '$path${Platform.pathSeparator}';
}

String _relativePath(Directory root, String path) {
  return path
      .substring(root.path.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

String _readPackageName(Directory projectRoot) {
  final pubspecPath =
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml';
  _ensureRegularFile(pubspecPath, 'pubspec.yaml');

  final contents = _readFile(File(pubspecPath), 'pubspec.yaml');
  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const CreateDatabaseException(
      'pubspec.yaml must contain a valid Dart package name.',
    );
  }

  final packageName = match.group(1) ?? match.group(2) ?? match.group(3)!;
  if (dartKeywords.contains(packageName)) {
    throw const CreateDatabaseException(
      'pubspec.yaml package name must not be a Dart keyword.',
    );
  }
  return packageName;
}

String _normalizeProvider(String input) {
  final value = input.trim().toLowerCase();
  if (value.isEmpty) {
    throw const CreateDatabaseException('Database provider must not be empty.');
  }
  if (!_supportedProviders.contains(value)) {
    throw CreateDatabaseException(
      'Unsupported database provider "$input". '
      'Currently supported providers: ${_supportedProviders.join(', ')}.',
    );
  }
  return value;
}

String _migrationTimestamp(DateTime timestamp) {
  String pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');
  return '${timestamp.year}${pad(timestamp.month)}${pad(timestamp.day)}'
      '${pad(timestamp.hour)}${pad(timestamp.minute)}${pad(timestamp.second)}';
}

String _modelContents(CreateDatabasePlan plan) {
  return '''
/// Example row model for the `examples` table.
///
/// Replace this with your own domain model once you introduce real
/// persistent data; this exists as a working starting point.
class ${plan.modelClassName} {
  const ${plan.modelClassName}({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ${plan.modelClassName}.fromJson(Map<String, dynamic> json) {
    return ${plan.modelClassName}(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
''';
}

String _repositoryContents(CreateDatabasePlan plan) {
  return '''
import 'package:${plan.packageName}/core/errors/result.dart';
import 'package:${plan.packageName}/core/network/supabase_guard.dart';
import 'package:${plan.packageName}/supabase/example_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Example repository demonstrating CRUD against the `examples` table.
///
/// Replace this with your own domain repository once you introduce real
/// persistent data; this exists as a working starting point wired to
/// `Result<T>`, guard(), and the Stacked locator.
class ${plan.repositoryClassName} {
  const ${plan.repositoryClassName}();

  static const _table = 'examples';

  Future<Result<List<${plan.modelClassName}>>> getAll() => guard(() async {
    final rows = await Supabase.instance.client
        .from(_table)
        .select()
        .order('created_at');
    return rows.map(${plan.modelClassName}.fromJson).toList();
  });

  Future<Result<${plan.modelClassName}>> getById(String id) => guard(() async {
    final row = await Supabase.instance.client
        .from(_table)
        .select()
        .eq('id', id)
        .single();
    return ${plan.modelClassName}.fromJson(row);
  });

  Future<Result<${plan.modelClassName}>> create(String title) =>
      guard(() async {
        final row = await Supabase.instance.client
            .from(_table)
            .insert({'title': title})
            .select()
            .single();
        return ${plan.modelClassName}.fromJson(row);
      });

  Future<Result<${plan.modelClassName}>> update(String id, String title) =>
      guard(() async {
        final row = await Supabase.instance.client
            .from(_table)
            .update({'title': title})
            .eq('id', id)
            .select()
            .single();
        return ${plan.modelClassName}.fromJson(row);
      });

  Future<Result<void>> delete(String id) => guard(() async {
    await Supabase.instance.client.from(_table).delete().eq('id', id);
  });
}
''';
}

String _migrationContents(CreateDatabasePlan plan) {
  return '''
-- Example table demonstrating Cuboid's repository + RLS pattern.
-- Replace or remove this once your application defines its own domain
-- schema; this exists as a working starting point.

create table if not exists public.examples (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.examples enable row level security;

create policy "Individuals can view their own examples"
  on public.examples for select
  using (auth.uid() = user_id);

create policy "Individuals can insert their own examples"
  on public.examples for insert
  with check (auth.uid() = user_id);

create policy "Individuals can update their own examples"
  on public.examples for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Individuals can delete their own examples"
  on public.examples for delete
  using (auth.uid() = user_id);

create or replace function public.set_examples_updated_at()
returns trigger
language plpgsql
as \$\$
begin
  new.updated_at = now();
  return new;
end;
\$\$;

create trigger examples_set_updated_at
  before update on public.examples
  for each row
  execute function public.set_examples_updated_at();
''';
}
