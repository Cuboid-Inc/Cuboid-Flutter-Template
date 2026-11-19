/// `cuboid doctor` -- inspects the current directory and reports whether it
/// is a Cuboid-generated project, which project architecture version it is
/// on, and which migrations (see `migrate/migration.dart`) are available.
/// Read-only: never modifies anything. `cuboid upgrade`
/// (`migrate/upgrade.dart`) is the only command that writes, and reuses
/// [DoctorService] internally so the two commands can never disagree about
/// a project's state.
library;

import 'dart:io';

import 'package:cuboid/src/architecture/architecture_metadata.dart';
import 'package:cuboid/src/architecture/architecture_version.dart';
import 'package:cuboid/src/migrate/migration.dart';
import 'package:cuboid/src/migrate/migration_registry.dart';

class DoctorInput {
  const DoctorInput({this.projectRoot});

  final Directory? projectRoot;
}

enum ArchitectureVersionSource {
  /// Read from `.cuboid/project.json`.
  metadata,

  /// `.cuboid/project.json` was absent; inferred from `lib/app/app.router.dart`.
  inferred,
}

/// The full result of diagnosing a project. Rendered to text by
/// [renderDoctorReport]; `cuboid upgrade` consumes the structured fields
/// directly instead of re-parsing text.
class DoctorReport {
  const DoctorReport({
    required this.projectName,
    required this.isFlutterProject,
    required this.isCuboidProject,
    required this.latestVersion,
    this.currentVersion,
    this.versionSource,
    this.knownVersions = const {},
    this.assessments = const [],
  });

  final String projectName;
  final bool isFlutterProject;
  final bool isCuboidProject;

  /// The newest architecture version this diagnosis targets -- normally
  /// [currentArchitectureVersion], but overridable (see [DoctorService]) so
  /// tests can exercise chain resolution against a synthetic registry.
  final String latestVersion;

  /// `null` only when [isCuboidProject] is `false`.
  final String? currentVersion;
  final ArchitectureVersionSource? versionSource;

  /// Every architecture version [DoctorService] recognizes -- see
  /// [knownArchitectureVersions].
  final Set<String> knownVersions;

  /// One assessment per migration in the resolved chain from
  /// [currentVersion] to [latestVersion] -- empty if the project is already
  /// current, or if [currentVersion] is unknown.
  final List<MigrationAssessment> assessments;

  bool get isKnownVersion =>
      currentVersion != null && knownVersions.contains(currentVersion);

  bool get isUpToDate =>
      isCuboidProject && isKnownVersion && currentVersion == latestVersion;

  bool get hasPendingMigrations =>
      assessments.any((assessment) => assessment.hasChanges);

  bool get hasSuspiciousFiles =>
      assessments.any((assessment) => assessment.hasUnsafeFiles);

  List<MigrationFileChange> get suspiciousFiles => [
    for (final assessment in assessments) ...assessment.unsafeFiles,
  ];
}

class DoctorService {
  const DoctorService({
    this.migrations = migrationRegistry,
    this.latestVersion = currentArchitectureVersion,
  });

  /// The migration catalogue this diagnosis walks. Defaults to Cuboid's
  /// real [migrationRegistry]; overridable purely for testing chain
  /// resolution against a synthetic registry (see `migrate/upgrade.dart`,
  /// which threads the same override through to keep `doctor`/`upgrade`
  /// agreeing on a project's state).
  final List<Migration> migrations;

  /// The newest architecture version this diagnosis targets. Defaults to
  /// [currentArchitectureVersion].
  final String latestVersion;

  DoctorReport diagnose(DoctorInput input) {
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final pathSegments = projectRoot.uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    final projectName = pathSegments.isEmpty
        ? projectRoot.path
        : pathSegments.last;

    final pubspec = File(
      '${projectRoot.path}${Platform.pathSeparator}pubspec.yaml',
    );
    final isFlutterProject =
        pubspec.existsSync() &&
        pubspec.readAsStringSync().contains('sdk: flutter');

    if (!isFlutterProject) {
      return DoctorReport(
        projectName: projectName,
        isFlutterProject: false,
        isCuboidProject: false,
        latestVersion: latestVersion,
      );
    }

    ArchitectureMetadata? metadata;
    try {
      metadata = readArchitectureMetadata(projectRoot);
    } on ArchitectureMetadataException {
      metadata = null;
    }

    String? currentVersion;
    ArchitectureVersionSource? source;
    if (metadata != null) {
      currentVersion = metadata.architectureVersion;
      source = ArchitectureVersionSource.metadata;
    } else {
      currentVersion = inferArchitectureVersionFromSource(projectRoot);
      source = ArchitectureVersionSource.inferred;
    }

    final isCuboidProject = currentVersion != null;
    if (!isCuboidProject) {
      return DoctorReport(
        projectName: projectName,
        isFlutterProject: true,
        isCuboidProject: false,
        latestVersion: latestVersion,
      );
    }

    final knownVersions = knownArchitectureVersions(migrations: migrations)
      ..add(latestVersion);

    var assessments = const <MigrationAssessment>[];
    if (knownVersions.contains(currentVersion) &&
        currentVersion != latestVersion) {
      try {
        final chain = resolveMigrationChain(
          fromVersion: currentVersion,
          toVersion: latestVersion,
          migrations: migrations,
        );
        assessments = [
          for (final migration in chain) migration.assess(projectRoot),
        ];
      } on MigrationChainException {
        assessments = const [];
      }
    }

    return DoctorReport(
      projectName: projectName,
      isFlutterProject: true,
      isCuboidProject: true,
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      versionSource: source,
      knownVersions: knownVersions,
      assessments: assessments,
    );
  }
}

/// Renders [report] the way `cuboid doctor` prints it to stdout.
String renderDoctorReport(DoctorReport report) {
  if (!report.isFlutterProject || !report.isCuboidProject) {
    return 'This directory does not appear to be a Cuboid project.';
  }

  final buffer = StringBuffer()
    ..writeln('Cuboid Doctor')
    ..writeln()
    ..writeln('Project: ${report.projectName}')
    ..writeln('Cuboid project: yes');

  if (!report.isKnownVersion) {
    buffer
      ..writeln(
        'Current architecture: ${report.currentVersion} (not recognized by '
        'this Cuboid CLI)',
      )
      ..writeln(
        'Latest compatible architecture: '
        '${_versionFamily(report.latestVersion)}',
      )
      ..writeln()
      ..writeln(
        "! This project's architecture version is not recognized by this "
        'Cuboid CLI.',
      )
      ..writeln(
        '! It may have been generated or migrated by a newer Cuboid release.',
      )
      ..writeln(
        '! Automatic migration is not available; upgrade the Cuboid CLI or '
        'inspect this project manually.',
      );
    return buffer.toString().trimRight();
  }

  if (report.isUpToDate && !report.hasSuspiciousFiles) {
    buffer
      ..writeln('Architecture: ${_versionFamily(report.currentVersion!)}')
      ..writeln()
      ..writeln('✓ Project is up to date.')
      ..writeln('✓ No migrations required.');
    return buffer.toString().trimRight();
  }

  buffer
    ..writeln('Current architecture: ${_versionFamily(report.currentVersion!)}')
    ..writeln(
      'Latest compatible architecture: '
      '${_versionFamily(report.latestVersion)}',
    )
    ..writeln()
    ..writeln('Migration status:');

  if (!report.hasPendingMigrations && !report.hasSuspiciousFiles) {
    buffer.writeln('  ✓ No further migrations required.');
  }

  for (final assessment in report.assessments) {
    if (assessment.hasChanges) {
      buffer.writeln('  ! ${assessment.migration.description}');
    }
    for (final unsafe in assessment.unsafeFiles) {
      buffer.writeln(
        '  ! ${unsafe.path} could not be automatically assessed: '
        '${unsafe.reason}',
      );
    }
  }

  buffer
    ..writeln()
    ..write('Run `cuboid upgrade` to migrate this project.');
  return buffer.toString();
}

String _versionFamily(String version) {
  final parsed = ArchitectureVersion.tryParse(version);
  if (parsed == null) {
    return version;
  }
  return '${parsed.major}.${parsed.minor}.x';
}
