/// `cuboid upgrade` -- migrates a Cuboid-generated project from its current
/// architecture version to the latest one this CLI knows, by resolving and
/// applying the sequential chain of [Migration]s `migrate/migration_registry.dart`
/// produces.
///
/// Split into [UpgradeService.plan] (read-only -- reuses [DoctorService] so
/// `doctor`/`upgrade` can never disagree about a project's state) and
/// [UpgradeService.apply] (the only method that writes), mirroring the
/// `plan()`/`create()` split `create/create_project.dart` already uses.
/// Confirmation and all user-facing printing live in the CLI command layer
/// (`cli/cuboid_command_runner.dart`), not here -- no *Service in this
/// package does its own I/O prompting, and this keeps [UpgradeService]
/// trivially testable without faking stdin.
library;

import 'dart:io';

import 'package:cuboid/src/architecture/architecture_metadata.dart';
import 'package:cuboid/src/architecture/architecture_version.dart';
import 'package:cuboid/src/doctor/doctor.dart';
import 'package:cuboid/src/edit/generated_edits.dart'
    show atomicReplaceFileContents;
import 'package:cuboid/src/migrate/backup_location.dart';
import 'package:cuboid/src/migrate/migration.dart';
import 'package:cuboid/src/migrate/migration_registry.dart';

class UpgradeInput {
  const UpgradeInput({this.projectRoot});

  final Directory? projectRoot;
}

enum UpgradePlanOutcome { notAProject, unknownVersion, alreadyUpToDate, ready }

/// The chain of migrations, and what each would do, to carry a project from
/// its current architecture version to [toVersion].
class UpgradePlan {
  const UpgradePlan({
    required this.fromVersion,
    required this.toVersion,
    required this.chain,
    required this.assessments,
  });

  final String fromVersion;
  final String toVersion;
  final List<Migration> chain;
  final List<MigrationAssessment> assessments;

  List<MigrationFileChange> get changes => [
    for (final assessment in assessments) ...assessment.changes,
  ];

  List<MigrationFileChange> get unsafeFiles => [
    for (final assessment in assessments) ...assessment.unsafeFiles,
  ];

  List<MigrationFileChange> get skippedFiles => [
    for (final assessment in assessments) ...assessment.skippedFiles,
  ];

  bool get hasChanges => changes.isNotEmpty;
  bool get hasUnsafeFiles => unsafeFiles.isNotEmpty;
  bool get hasSkippedFiles => skippedFiles.isNotEmpty;
}

/// The result of [UpgradeService.plan]: either a reason `cuboid upgrade`
/// cannot proceed ([notAProject], [unknownVersion], [alreadyUpToDate]) or a
/// [plan] ([ready]) the caller can show the user and, once confirmed, pass
/// to [UpgradeService.apply].
class UpgradePlanResult {
  const UpgradePlanResult({
    required this.outcome,
    required this.projectRoot,
    required this.doctorReport,
    this.plan,
  });

  final UpgradePlanOutcome outcome;
  final Directory projectRoot;
  final DoctorReport doctorReport;

  /// Non-null only when [outcome] is [UpgradePlanOutcome.ready].
  final UpgradePlan? plan;
}

enum UpgradeApplyOutcome { completed, failed }

class VerificationResult {
  const VerificationResult({
    required this.ran,
    this.analyzeExitCode,
    this.analyzeOutput,
    this.testExitCode,
    this.testOutput,
    this.skippedReason,
  });

  final bool ran;
  final int? analyzeExitCode;
  final String? analyzeOutput;
  final int? testExitCode;
  final String? testOutput;
  final String? skippedReason;

  bool get analyzePassed => analyzeExitCode == 0;
  bool get testsPassed => testExitCode == 0;
  bool get passed => ran && analyzePassed && testsPassed;
}

/// The result of [UpgradeService.apply]. [outcome] is [UpgradeApplyOutcome.failed]
/// only when an unexpected I/O error interrupted the write itself -- every
/// change already made in this call is rolled back first (see
/// [UpgradeService.apply]), so a failed apply never leaves the project
/// partially migrated.
///
/// A *safety-blocked* file (one [Migration.assess] reported as
/// [MigrationFileOutcome.unsafeToMigrate]) is not a failure: [outcome] is
/// still [UpgradeApplyOutcome.completed], every file that *could* be
/// migrated safely was, [blockedFiles] lists what was skipped and why, and
/// [metadataUpdated] is `false` so the project's recorded architecture
/// version does not claim more than what actually happened.
class UpgradeApplyResult {
  const UpgradeApplyResult({
    required this.outcome,
    required this.fromVersion,
    required this.toVersion,
    required this.modifiedFiles,
    required this.blockedFiles,
    required this.metadataUpdated,
    this.addedFiles = const [],
    this.skippedFiles = const [],
    this.backupDirectoryPath,
    this.verification,
    this.error,
  });

  final UpgradeApplyOutcome outcome;
  final String fromVersion;

  /// The project's architecture version after this call: [fromVersion]
  /// unchanged if nothing was migrated (a failure, or every file blocked),
  /// otherwise the target version [metadataUpdated] confirms was recorded.
  final String toVersion;

  /// Paths rewritten in place ([MigrationFileOutcome.modify]). Disjoint
  /// from [addedFiles].
  final List<String> modifiedFiles;

  /// Paths written for the first time ([MigrationFileOutcome.create]).
  /// Disjoint from [modifiedFiles].
  final List<String> addedFiles;

  final List<MigrationFileChange> blockedFiles;

  /// Files a [create] migration found already present and left untouched
  /// ([MigrationFileOutcome.skippedExisting]) -- never a failure, just
  /// reported so the user knows nothing was overwritten.
  final List<MigrationFileChange> skippedFiles;
  final bool metadataUpdated;

  /// The absolute path this run's pre-migration file snapshots were backed
  /// up to (see [backupDirectoryFor]) -- always outside [projectRoot], under
  /// Cuboid's own cache directory. `null` only when nothing was backed up
  /// (nothing to migrate). Not surfaced in normal CLI output (see
  /// [renderUpgradeApplyResult]) -- callers needing it for debugging a
  /// [UpgradeApplyOutcome.failed] result read this field directly.
  final String? backupDirectoryPath;
  final VerificationResult? verification;
  final String? error;
}

typedef UpgradeProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
    });

class UpgradeService {
  UpgradeService({
    this.migrations = migrationRegistry,
    this.latestVersion = currentArchitectureVersion,
    UpgradeProcessRunner? processRunner,
    DateTime Function()? now,
    Directory? backupsRootDirectory,
  }) : _processRunner = processRunner ?? _defaultProcessRunner,
       _now = now ?? DateTime.now,
       _backupsRootDirectory = backupsRootDirectory;

  /// The migration catalogue this service walks. Defaults to Cuboid's real
  /// [migrationRegistry]; overridable purely for testing.
  final List<Migration> migrations;

  /// The newest architecture version this service upgrades projects to.
  /// Defaults to [currentArchitectureVersion].
  final String latestVersion;

  final UpgradeProcessRunner _processRunner;
  final DateTime Function() _now;

  /// Where [apply] writes migration backups, under a per-project
  /// subdirectory (see `migrate/backup_location.dart`). `null` (the real
  /// default) resolves to [cuboidBackupsRootDirectory] -- the platform
  /// cache directory -- at [apply] time; overridable purely for testing so
  /// tests never write into a developer's real cache directory.
  final Directory? _backupsRootDirectory;

  /// Read-only: diagnoses [input]'s project (via [DoctorService], built
  /// from the same [migrations]/[latestVersion] this service uses) and
  /// resolves the migration chain, without writing anything.
  UpgradePlanResult plan(UpgradeInput input) {
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final doctorService = DoctorService(
      migrations: migrations,
      latestVersion: latestVersion,
    );
    final report = doctorService.diagnose(
      DoctorInput(projectRoot: projectRoot),
    );

    if (!report.isCuboidProject) {
      return UpgradePlanResult(
        outcome: UpgradePlanOutcome.notAProject,
        projectRoot: projectRoot,
        doctorReport: report,
      );
    }
    if (!report.isKnownVersion) {
      return UpgradePlanResult(
        outcome: UpgradePlanOutcome.unknownVersion,
        projectRoot: projectRoot,
        doctorReport: report,
      );
    }
    if (report.currentVersion == latestVersion) {
      return UpgradePlanResult(
        outcome: UpgradePlanOutcome.alreadyUpToDate,
        projectRoot: projectRoot,
        doctorReport: report,
      );
    }

    final chain = resolveMigrationChain(
      fromVersion: report.currentVersion!,
      toVersion: latestVersion,
      migrations: migrations,
    );
    final assessments = [
      for (final migration in chain) migration.assess(projectRoot),
    ];

    return UpgradePlanResult(
      outcome: UpgradePlanOutcome.ready,
      projectRoot: projectRoot,
      doctorReport: report,
      plan: UpgradePlan(
        fromVersion: report.currentVersion!,
        toVersion: latestVersion,
        chain: chain,
        assessments: assessments,
      ),
    );
  }

  /// Applies [planResult] (which must have `outcome == ready`, from a prior
  /// [plan] call the caller has already shown the user and had confirmed).
  ///
  /// Every migration in the chain is re-assessed against the project
  /// immediately before it is applied -- not [planResult]'s original
  /// assessments -- so a later migration in a multi-hop chain always sees
  /// the *actual* on-disk effect of the ones before it, even if two
  /// migrations happen to touch the same file.
  ///
  /// Before the first write, this snapshots every file it is about to
  /// touch (original content in memory, for rollback, and a copy under
  /// [backupDirectoryFor] -- Cuboid's own cache directory, never inside
  /// [projectRoot]). Every write itself goes through
  /// [atomicReplaceFileContents] (temp file + rename). If anything throws
  /// partway through, every snapshotted file is restored from the in-memory
  /// copy before the failure is reported -- the project is never left
  /// half-migrated.
  Future<UpgradeApplyResult> apply(
    UpgradePlanResult planResult, {
    bool verify = true,
  }) async {
    if (planResult.outcome != UpgradePlanOutcome.ready ||
        planResult.plan == null) {
      throw StateError(
        'UpgradeService.apply requires a plan() result with outcome == ready.',
      );
    }
    final projectRoot = planResult.projectRoot;
    final plan = planResult.plan!;

    final timestamp = _timestampSlug(_now());
    final backupDirectory = backupDirectoryFor(
      projectRoot,
      timestamp,
      backupsRoot: _backupsRootDirectory,
    );

    final snapshots = <_FileSnapshot>[];
    final snapshotted = <String>{};
    final modifiedFiles = <String>[];
    final addedFiles = <String>[];
    final blockedFiles = <MigrationFileChange>[];
    final skippedFiles = <MigrationFileChange>[];

    void snapshotAndBackup(File file, String relativePath) {
      if (!snapshotted.add(relativePath)) {
        return;
      }
      final original = file.existsSync() ? file.readAsStringSync() : null;
      snapshots.add(_FileSnapshot(file: file, originalContents: original));
      if (original != null) {
        final backupFile = _fileFor(backupDirectory, relativePath);
        backupFile.parent.createSync(recursive: true);
        backupFile.writeAsStringSync(original);
      }
    }

    try {
      for (final migration in plan.chain) {
        final assessment = migration.assess(projectRoot);
        blockedFiles.addAll(assessment.unsafeFiles);
        skippedFiles.addAll(assessment.skippedFiles);
        for (final change in assessment.changes) {
          final file = _fileFor(projectRoot, change.path);
          snapshotAndBackup(file, change.path);
          if (change.outcome == MigrationFileOutcome.create) {
            file.parent.createSync(recursive: true);
          }
          atomicReplaceFileContents(file, change.newContents!);
          if (change.outcome == MigrationFileOutcome.create) {
            addedFiles.add(change.path);
          } else {
            modifiedFiles.add(change.path);
          }
        }
      }

      final pubspecChanged =
          modifiedFiles.contains('pubspec.yaml') ||
          addedFiles.contains('pubspec.yaml');
      // Only pre-fetch new dependencies when verification is actually going
      // to run `flutter analyze`/`flutter test` against them -- `--no-verify`
      // means "don't invoke the Flutter toolchain at all", and a bare
      // `cuboid upgrade` with no further commands shouldn't either.
      if (verify && pubspecChanged) {
        try {
          await _processRunner('flutter', [
            'pub',
            'get',
          ], workingDirectory: projectRoot.path);
        } on ProcessException {
          // Best-effort: `flutter analyze`/`flutter test` below will
          // surface an unresolved-dependency failure clearly enough if
          // this didn't work; `cuboid upgrade` should not fail outright
          // just because it could not pre-fetch packages.
        }
      }

      var metadataUpdated = false;
      if (blockedFiles.isEmpty) {
        ArchitectureMetadata? priorMetadata;
        try {
          priorMetadata = readArchitectureMetadata(projectRoot);
        } on ArchitectureMetadataException {
          priorMetadata = null;
        }
        final metadataFile = architectureMetadataFile(projectRoot);
        snapshotAndBackup(metadataFile, architectureMetadataRelativePath);
        writeArchitectureMetadata(
          projectRoot,
          ArchitectureMetadata(
            architectureVersion: plan.toVersion,
            generatedByCuboidVersion: priorMetadata?.generatedByCuboidVersion,
            generatedByCuboidFlutterVersion:
                priorMetadata?.generatedByCuboidFlutterVersion,
          ),
        );
        metadataUpdated = true;
      }

      final verification = verify ? await _runVerification(projectRoot) : null;

      return UpgradeApplyResult(
        outcome: UpgradeApplyOutcome.completed,
        fromVersion: plan.fromVersion,
        toVersion: metadataUpdated ? plan.toVersion : plan.fromVersion,
        modifiedFiles: modifiedFiles,
        addedFiles: addedFiles,
        blockedFiles: blockedFiles,
        skippedFiles: skippedFiles,
        metadataUpdated: metadataUpdated,
        backupDirectoryPath: snapshots.isEmpty ? null : backupDirectory.path,
        verification: verification,
      );
    } on Object catch (error) {
      for (final snapshot in snapshots.reversed) {
        snapshot.restore();
      }
      return UpgradeApplyResult(
        outcome: UpgradeApplyOutcome.failed,
        fromVersion: plan.fromVersion,
        toVersion: plan.fromVersion,
        modifiedFiles: const [],
        blockedFiles: blockedFiles,
        skippedFiles: skippedFiles,
        metadataUpdated: false,
        backupDirectoryPath: snapshots.isEmpty ? null : backupDirectory.path,
        error: '$error',
      );
    }
  }

  Future<VerificationResult> _runVerification(Directory projectRoot) async {
    final ProcessResult analyzeResult;
    try {
      analyzeResult = await _processRunner('flutter', [
        'analyze',
      ], workingDirectory: projectRoot.path);
    } on ProcessException catch (error) {
      return VerificationResult(
        ran: false,
        skippedReason: 'Unable to run `flutter analyze`: ${error.message}',
      );
    }

    final ProcessResult testResult;
    try {
      testResult = await _processRunner('flutter', [
        'test',
      ], workingDirectory: projectRoot.path);
    } on ProcessException catch (error) {
      return VerificationResult(
        ran: false,
        analyzeExitCode: analyzeResult.exitCode,
        analyzeOutput: _combinedOutput(analyzeResult),
        skippedReason: 'Unable to run `flutter test`: ${error.message}',
      );
    }

    return VerificationResult(
      ran: true,
      analyzeExitCode: analyzeResult.exitCode,
      analyzeOutput: _combinedOutput(analyzeResult),
      testExitCode: testResult.exitCode,
      testOutput: _combinedOutput(testResult),
    );
  }
}

/// Renders a [UpgradePlanResult] the way `cuboid upgrade` (and `cuboid
/// upgrade --dry-run`) prints it before any confirmation or write happens.
String renderUpgradePlan(UpgradePlanResult result) {
  switch (result.outcome) {
    case UpgradePlanOutcome.notAProject:
      return renderDoctorReport(result.doctorReport);
    case UpgradePlanOutcome.unknownVersion:
      return renderDoctorReport(result.doctorReport);
    case UpgradePlanOutcome.alreadyUpToDate:
      final version = _versionFamily(result.doctorReport.currentVersion!);
      return 'Cuboid Upgrade\n\n'
          'Architecture: $version\n\n'
          '✓ Project is already up to date. No changes were made.';
    case UpgradePlanOutcome.ready:
      final plan = result.plan!;
      final buffer = StringBuffer()
        ..writeln('Cuboid Upgrade')
        ..writeln()
        ..writeln('Current architecture: ${_versionFamily(plan.fromVersion)}')
        ..writeln('Target architecture: ${_versionFamily(plan.toVersion)}')
        ..writeln()
        ..writeln('Planned changes:')
        ..writeln();
      for (final change in plan.changes) {
        final verb = change.outcome == MigrationFileOutcome.create
            ? 'ADD'
            : 'MODIFY';
        buffer.writeln('  $verb ${change.path}');
      }
      if (plan.hasChanges) {
        buffer.writeln('  UPDATE Cuboid architecture metadata');
      }
      for (final skipped in plan.skippedFiles) {
        buffer
          ..writeln()
          ..writeln('⚠ Skipped ${skipped.path}')
          ..writeln('  File already exists and was not modified.');
      }
      for (final unsafe in plan.unsafeFiles) {
        buffer
          ..writeln()
          ..writeln('Could not safely migrate:')
          ..writeln('  ${unsafe.path}')
          ..writeln()
          ..writeln('Reason:')
          ..writeln('  ${unsafe.reason}');
      }
      if (!plan.hasChanges &&
          plan.unsafeFiles.isEmpty &&
          plan.skippedFiles.isEmpty) {
        buffer.writeln('  (nothing to change; only metadata will be updated)');
      }
      return buffer.toString().trimRight();
  }
}

/// Renders the result of a successful [UpgradeService.apply] call (an
/// `outcome == completed` result -- possibly only a *partial* migration if
/// some files were safety-blocked, see [UpgradeApplyResult]).
String renderUpgradeApplyResult(UpgradeApplyResult result) {
  final buffer = StringBuffer();

  if (result.outcome == UpgradeApplyOutcome.failed) {
    buffer
      ..writeln('✗ Migration failed. All changes were rolled back.')
      ..writeln(result.error ?? '');
    if (result.backupDirectoryPath != null) {
      buffer.writeln(
        'A backup of the original files was saved to '
        '${result.backupDirectoryPath} for troubleshooting.',
      );
    }
    return buffer.toString().trimRight();
  }

  buffer.writeln('✓ Migration completed.');
  for (final path in result.addedFiles) {
    buffer.writeln('✓ Added $path.');
  }
  for (final path in result.modifiedFiles) {
    buffer.writeln('✓ Updated $path.');
  }
  if (result.metadataUpdated) {
    buffer.writeln('✓ Architecture metadata updated to ${result.toVersion}.');
  } else {
    buffer.writeln(
      '! Architecture metadata was not updated -- one or more files could '
      'not be migrated safely. Run `cuboid doctor` for details.',
    );
  }
  for (final skipped in result.skippedFiles) {
    buffer
      ..writeln('⚠ Skipped ${skipped.path}')
      ..writeln('  File already exists and was not modified.');
  }
  for (final unsafe in result.blockedFiles) {
    buffer.writeln('! ${unsafe.path} was left unchanged: ${unsafe.reason}');
  }

  final verification = result.verification;
  if (verification != null) {
    if (!verification.ran) {
      buffer.writeln(
        '! Project verification skipped: ${verification.skippedReason}',
      );
    } else if (verification.passed) {
      buffer.writeln('✓ Project verification passed.');
    } else {
      buffer.writeln('✗ Project verification failed.');
      if (!verification.analyzePassed) {
        buffer.writeln(
          '  flutter analyze exited with code ${verification.analyzeExitCode}.',
        );
      }
      if (!verification.testsPassed) {
        buffer.writeln(
          '  flutter test exited with code ${verification.testExitCode}.',
        );
      }
    }
  }

  return buffer.toString().trimRight();
}

class _FileSnapshot {
  const _FileSnapshot({required this.file, required this.originalContents});

  final File file;

  /// `null` means the file did not exist before this migration touched it.
  final String? originalContents;

  void restore() {
    try {
      if (originalContents == null) {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } else {
        atomicReplaceFileContents(file, originalContents!);
      }
    } on FileSystemException {
      // Best-effort rollback; preserve the original failure that triggered it.
    }
  }
}

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

String _combinedOutput(ProcessResult result) {
  final out = '${result.stdout}'.trim();
  final err = '${result.stderr}'.trim();
  return [out, err].where((text) => text.isNotEmpty).join('\n');
}

String _timestampSlug(DateTime dateTime) {
  return dateTime
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
}

File _fileFor(Directory baseDirectory, String relativePath) {
  return File(
    '${baseDirectory.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

String _versionFamily(String version) {
  final parsed = ArchitectureVersion.tryParse(version);
  if (parsed == null) {
    return version;
  }
  return '${parsed.major}.${parsed.minor}.x';
}
