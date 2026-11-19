/// The migration abstraction `cuboid doctor`/`cuboid upgrade` are built on.
///
/// A [Migration] never touches disk itself -- [Migration.assess] is a pure
/// read-only inspection of a project directory that reports, file by file,
/// what would happen. [UpgradeService] (`migrate/upgrade.dart`) is the only
/// place that writes: it takes the [MigrationAssessment]s a chain of
/// migrations produced and applies them under one atomic,
/// backed-up, all-or-nothing transaction (see `migrate/upgrade.dart`). This
/// split keeps each migration's logic trivially unit-testable (assess a
/// fixture directory, assert on the plan) without any filesystem mutation
/// or rollback machinery duplicated per migration.
library;

import 'dart:io';

/// What a migration would do to one file it owns.
enum MigrationFileOutcome {
  /// The file matches this migration's known "before" shape and would be
  /// rewritten to its "after" shape.
  modify,

  /// The file already matches the "after" shape -- nothing to do.
  alreadyCurrent,

  /// The file exists but matches neither the known "before" nor "after"
  /// shape closely enough to rewrite safely. Reported to the user; left
  /// untouched.
  unsafeToMigrate,

  /// The file this migration would otherwise touch does not exist in this
  /// project (for example a deleted `NavigationService`). Not an error --
  /// just nothing for this migration to do to it.
  missing,
}

/// One file's assessed change under a single [Migration].
class MigrationFileChange {
  const MigrationFileChange({
    required this.path,
    required this.outcome,
    this.reason,
    this.newContents,
  });

  /// Project-relative, forward-slash path, e.g. `lib/app/app.router.dart`.
  final String path;

  final MigrationFileOutcome outcome;

  /// Human-readable explanation, populated for [MigrationFileOutcome.unsafeToMigrate].
  final String? reason;

  /// The file's full replacement contents, populated only when
  /// [outcome] is [MigrationFileOutcome.modify]. [UpgradeService] writes
  /// this verbatim; no migration performs its own I/O.
  final String? newContents;
}

/// The full result of assessing one [Migration] against a project.
class MigrationAssessment {
  const MigrationAssessment({
    required this.migration,
    required this.fileChanges,
  });

  final Migration migration;
  final List<MigrationFileChange> fileChanges;

  bool get hasChanges => fileChanges.any(
    (change) => change.outcome == MigrationFileOutcome.modify,
  );

  bool get hasUnsafeFiles => fileChanges.any(
    (change) => change.outcome == MigrationFileOutcome.unsafeToMigrate,
  );

  List<MigrationFileChange> get changes => fileChanges
      .where((change) => change.outcome == MigrationFileOutcome.modify)
      .toList();

  List<MigrationFileChange> get unsafeFiles => fileChanges
      .where((change) => change.outcome == MigrationFileOutcome.unsafeToMigrate)
      .toList();
}

/// A single step in Cuboid's project architecture migration chain --
/// upgrades Cuboid-owned project infrastructure from [sourceVersion] to
/// [targetVersion]. See `migrate/migration_registry.dart` for how a chain
/// of these is resolved and ordered, and
/// `migrate/migrations/navigation_cuboid_page_route_migration.dart` for the
/// first concrete implementation.
abstract class Migration {
  const Migration();

  /// The architecture version a project must be on for this migration to
  /// apply, e.g. `0.1.0`.
  String get sourceVersion;

  /// The architecture version a project is on after this migration
  /// completes, e.g. `0.2.0`.
  String get targetVersion;

  /// A short, user-facing description of what this migration changes --
  /// shown by both `cuboid doctor` and `cuboid upgrade`.
  String get description;

  /// Inspects [projectRoot] (read-only) and reports what this migration
  /// would do to each file it owns, without writing anything.
  MigrationAssessment assess(Directory projectRoot);
}
