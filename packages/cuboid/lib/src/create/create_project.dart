import 'dart:convert';
import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:cuboid/src/templates/flutter_app/template_payload.g.dart'
    as embedded_payload;
import 'package:cuboid/src/templates/flutter_app/template_sync.dart'
    as template;

class CreateProjectInput {
  const CreateProjectInput({
    required this.displayName,
    required this.packageIdentifier,
    this.destinationParent,
    this.destinationName,
    this.dryRun = false,
    this.runPostSteps = true,
  });

  final String displayName;
  final String packageIdentifier;
  final Directory? destinationParent;
  final String? destinationName;
  final bool dryRun;
  final bool runPostSteps;
}

class CreateProjectPlan {
  const CreateProjectPlan({
    required this.values,
    required this.destination,
    required this.templateManifest,
    required this.postSteps,
    required this.dryRun,
  });

  final BootstrapValues values;
  final Directory destination;
  final template.TemplateManifest templateManifest;
  final List<PostStep> postSteps;
  final bool dryRun;

  List<String> get actionSummary {
    return [
      'Create ${values.displayName}',
      'Write ${templateManifest.files.length} template files',
      'Bootstrap package ${values.packageIdentifier}',
      if (postSteps.isNotEmpty)
        'Run ${postSteps.map((step) => step.label).join(', ')}',
    ];
  }
}

class CreateProjectResult {
  const CreateProjectResult({
    required this.plan,
    this.bootstrapResult,
    this.postStepResults = const [],
  });

  final CreateProjectPlan plan;
  final BootstrapApplyResult? bootstrapResult;
  final List<PostStepResult> postStepResults;
}

class PostStep {
  const PostStep(this.executable, this.arguments, {required this.label});

  final String executable;
  final List<String> arguments;
  final String label;

  String get command => [executable, ...arguments].join(' ');
}

class PostStepResult {
  const PostStepResult({required this.step, required this.exitCode});

  final PostStep step;
  final int exitCode;
}

class CreateProjectException implements Exception {
  const CreateProjectException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
    });

class CreateProjectService {
  CreateProjectService({ProcessRunner? processRunner})
    : _processRunner = processRunner ?? _defaultProcessRunner;

  final ProcessRunner _processRunner;

  Future<CreateProjectPlan> plan(CreateProjectInput input) async {
    final values = deriveBootstrapValues(
      BootstrapInput(
        displayName: input.displayName,
        packageIdentifier: input.packageIdentifier,
      ),
    );
    final destination = _resolveDestination(input, values.dartProjectName);
    final payload = await _loadBundledTemplatePayload();

    return CreateProjectPlan(
      values: values,
      destination: destination,
      templateManifest: payload.manifest,
      postSteps: input.runPostSteps ? defaultPostSteps : const [],
      dryRun: input.dryRun,
    );
  }

  Future<CreateProjectResult> create(CreateProjectInput input) async {
    final createPlan = await plan(input);
    _validateDestination(createPlan.destination);

    if (createPlan.dryRun) {
      return CreateProjectResult(plan: createPlan);
    }

    final parent = createPlan.destination.parent;
    final Directory staging;
    try {
      staging = parent.createTempSync(
        '.${createPlan.destination.uri.pathSegments.last}.cuboid-',
      );
    } on FileSystemException catch (error) {
      throw CreateProjectException(
        'Unable to create staging directory in ${parent.path}: ${error.message}',
      );
    }
    var completed = false;
    try {
      final payload = await _loadBundledTemplatePayload();
      _extractTemplate(payload, staging);

      final bootstrapPlan = planBootstrap(staging, createPlan.values);
      final bootstrapValidation = validateBootstrapPlan(staging, bootstrapPlan);
      if (!bootstrapValidation.isValid) {
        throw CreateProjectException(
          [
            'Extracted template could not be bootstrapped.',
            ...bootstrapValidation.failures.map((failure) => '- $failure'),
          ].join('\n'),
        );
      }
      final bootstrapResult = applyBootstrapPlan(staging, bootstrapPlan);

      final postStepResults = <PostStepResult>[];
      for (final step in createPlan.postSteps) {
        final ProcessResult result;
        try {
          result = await _processRunner(
            step.executable,
            step.arguments,
            workingDirectory: staging.path,
          );
        } on ProcessException catch (error) {
          throw CreateProjectException(
            '${step.command} could not be started: ${error.message}',
          );
        }
        postStepResults.add(
          PostStepResult(step: step, exitCode: result.exitCode),
        );
        if (result.exitCode != 0) {
          final stderrText = '${result.stderr}'.trim();
          throw CreateProjectException(
            [
              '${step.command} failed with exit code ${result.exitCode}.',
              if (stderrText.isNotEmpty) stderrText,
            ].join('\n'),
          );
        }
      }

      _validateDestination(createPlan.destination);
      try {
        staging.renameSync(createPlan.destination.path);
      } on FileSystemException catch (error) {
        throw CreateProjectException(
          'Unable to publish project at ${createPlan.destination.path}: ${error.message}',
        );
      }
      completed = true;
      return CreateProjectResult(
        plan: createPlan,
        bootstrapResult: bootstrapResult,
        postStepResults: postStepResults,
      );
    } on Object catch (error, stackTrace) {
      if (!completed) {
        final cleanupFailure = _deleteStagingDirectory(staging);
        if (cleanupFailure != null) {
          throw CreateProjectException(
            [
              _messageFor(error),
              'Also failed to remove temporary staging directory ${staging.path}: $cleanupFailure',
            ].join('\n'),
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

const defaultPostSteps = [
  PostStep('flutter', ['pub', 'get'], label: 'flutter pub get'),
  PostStep('dart', ['format', '.'], label: 'dart format'),
];

Future<ProcessResult> _defaultProcessRunner(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) {
  return Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
}

Directory _resolveDestination(CreateProjectInput input, String projectName) {
  final destinationName = input.destinationName ?? projectName;
  if (destinationName.trim().isEmpty ||
      destinationName.contains('/') ||
      destinationName.contains('\\') ||
      destinationName == '.' ||
      destinationName == '..' ||
      destinationName.split(RegExp(r'[/\\]')).contains('..')) {
    throw const CreateProjectException(
      'Destination name must be a simple directory name.',
    );
  }
  return Directory(
    '${(input.destinationParent ?? Directory.current).absolute.path}'
    '${Platform.pathSeparator}$destinationName',
  );
}

void _validateDestination(Directory destination) {
  final parent = destination.parent;
  if (!parent.existsSync()) {
    throw CreateProjectException(
      'Destination parent does not exist: ${parent.path}',
    );
  }
  if (destination.existsSync()) {
    throw CreateProjectException(
      'Destination already exists: ${destination.path}',
    );
  }
  if (File(destination.path).existsSync() ||
      Link(destination.path).existsSync()) {
    throw CreateProjectException(
      'Destination path is not an empty directory path: ${destination.path}',
    );
  }
}

class _TemplatePayload {
  const _TemplatePayload({required this.manifest, required this.files});

  final template.TemplateManifest manifest;
  final List<template.ExtractedTemplateFile> files;
}

Future<_TemplatePayload> _loadBundledTemplatePayload() async {
  // Reads the payload embedded as Dart source (see template_payload.g.dart)
  // rather than resolving `template.tar.gz`/`template_manifest.json` via
  // `package:` URI at runtime: `Isolate.resolvePackageUri` returns null
  // inside a `dart compile exe` binary, so that approach cannot work for a
  // compiled `cuboid` executable (see packages/cuboid/tool/install.dart).
  final manifestBytes = base64Decode(
    embedded_payload.templateManifestJsonBase64,
  );
  final archiveBytes = base64Decode(embedded_payload.templateArchiveBase64);
  final manifest = template.TemplateManifest.fromJson(
    jsonDecode(utf8.decode(manifestBytes)) as Map<String, Object?>,
  );
  if (template.sha256Hex(archiveBytes) != manifest.archiveSha256) {
    throw const CreateProjectException(
      'Bundled template archive failed SHA-256 verification.',
    );
  }

  final List<template.ExtractedTemplateFile> files;
  try {
    files = template.extractTarGz(archiveBytes);
  } on FormatException {
    throw const CreateProjectException('Bundled template archive is invalid.');
  }

  final fileFailures = _verifyExtractedFiles(manifest, files);
  if (fileFailures.isNotEmpty) {
    throw CreateProjectException(
      [
        'Bundled template archive does not match its manifest.',
        ...fileFailures.map((failure) => '- $failure'),
      ].join('\n'),
    );
  }
  return _TemplatePayload(manifest: manifest, files: files);
}

List<String> _verifyExtractedFiles(
  template.TemplateManifest manifest,
  List<template.ExtractedTemplateFile> files,
) {
  final failures = <String>[];
  final extractedPaths = files.map((file) => file.path).toList()..sort();
  final manifestPaths = manifest.files.map((file) => file.path).toList()
    ..sort();
  if (!_sameStrings(extractedPaths, manifestPaths)) {
    failures.add('Archive file list does not match manifest.');
  }

  final extractedByPath = {for (final file in files) file.path: file};
  for (final manifestFile in manifest.files) {
    final extracted = extractedByPath[manifestFile.path];
    if (extracted == null) {
      continue;
    }
    if (extracted.bytes.length != manifestFile.size) {
      failures.add('${manifestFile.path}: size does not match manifest.');
    }
    if (template.sha256Hex(extracted.bytes) != manifestFile.sha256) {
      failures.add('${manifestFile.path}: SHA-256 does not match manifest.');
    }
  }
  return failures;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

void _extractTemplate(_TemplatePayload payload, Directory destination) {
  for (final file in payload.files) {
    _rejectUnsafeArchivePath(file.path);
    final output = File(
      '${destination.path}${Platform.pathSeparator}${file.path.replaceAll('/', Platform.pathSeparator)}',
    );
    try {
      output.parent.createSync(recursive: true);
      output.writeAsBytesSync(file.bytes);
    } on FileSystemException catch (error) {
      throw CreateProjectException(
        'Unable to extract ${file.path}: ${error.message}',
      );
    }
  }
}

void _rejectUnsafeArchivePath(String path) {
  if (path.startsWith('/') ||
      path.contains('\\') ||
      path.split('/').contains('..')) {
    throw CreateProjectException('Unsafe template archive path: $path');
  }
}

String? _deleteStagingDirectory(Directory staging) {
  try {
    if (staging.existsSync()) {
      staging.deleteSync(recursive: true);
    }
    return null;
  } on FileSystemException catch (error) {
    return error.message;
  }
}

String _messageFor(Object error) {
  if (error is CreateProjectException) {
    return error.message;
  }
  if (error is BootstrapException) {
    return error.message;
  }
  if (error is FileSystemException) {
    return error.message;
  }
  return error.toString();
}
