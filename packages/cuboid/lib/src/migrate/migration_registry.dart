/// The ordered catalogue of every [Migration] Cuboid ships, and the pure
/// chain-resolution logic `cuboid doctor`/`cuboid upgrade` both use to turn
/// "a project is on version X, the latest architecture is Y" into the
/// concrete, ordered sequence of migrations to run.
///
/// Adding a future migration (e.g. `0.2.0` -> `0.3.0`) is a two-line change:
/// implement a new [Migration] and add it to [migrationRegistry]. Nothing
/// else in `cuboid doctor`/`cuboid upgrade` needs to change -- chain
/// resolution below discovers and orders migrations automatically from
/// their declared [Migration.sourceVersion]/[Migration.targetVersion], the
/// same way `0.1.0 -> 0.2.0 -> 0.3.0 -> 0.4.0` would chain for a project two
/// or more versions behind.
library;

import 'package:cuboid/src/architecture/architecture_version.dart';
import 'package:cuboid/src/migrate/migration.dart';
import 'package:cuboid/src/migrate/migrations/navigation_cuboid_page_route_migration.dart';

/// Every migration Cuboid currently ships, in no particular order --
/// [resolveMigrationChain] does the ordering. Exactly one migration may
/// exist per `sourceVersion` (enforced by [validateMigrationRegistry]).
const migrationRegistry = <Migration>[NavigationCuboidPageRouteMigration()];

class MigrationChainException implements Exception {
  const MigrationChainException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolves the ordered sequence of migrations that would carry a project
/// from [fromVersion] to [toVersion], by walking [migrations] as a chain
/// keyed on `sourceVersion -> targetVersion` (there is at most one
/// migration per source version, so this is a simple linked walk, not a
/// general graph search).
///
/// Returns an empty list if [fromVersion] already equals [toVersion].
/// Throws [MigrationChainException] if [fromVersion] is not [toVersion] and
/// no migration starts there, or if the chain from [fromVersion] doesn't
/// reach [toVersion] (a broken/incomplete registry) -- both are registry
/// bugs, not user-facing "unknown version" states, which callers
/// (`doctor`/`upgrade`) detect earlier by checking [fromVersion] against
/// every known version first.
List<Migration> resolveMigrationChain({
  required String fromVersion,
  required String toVersion,
  List<Migration> migrations = migrationRegistry,
}) {
  if (fromVersion == toVersion) {
    return const [];
  }

  final bySource = <String, Migration>{};
  for (final migration in migrations) {
    if (bySource.containsKey(migration.sourceVersion)) {
      throw MigrationChainException(
        'Migration registry has more than one migration starting at '
        '${migration.sourceVersion}.',
      );
    }
    bySource[migration.sourceVersion] = migration;
  }

  final chain = <Migration>[];
  var current = fromVersion;
  final visited = <String>{};
  while (current != toVersion) {
    if (!visited.add(current)) {
      throw MigrationChainException(
        'Migration registry contains a cycle starting at $current.',
      );
    }
    final migration = bySource[current];
    if (migration == null) {
      throw MigrationChainException(
        'No migration path from $fromVersion to $toVersion (stuck at '
        '$current).',
      );
    }
    chain.add(migration);
    current = migration.targetVersion;
  }
  return chain;
}

/// Every architecture version any migration in [migrations] references,
/// either as a source or a target -- used to distinguish "this project's
/// version is simply older than the CLI's latest" (a normal, resolvable
/// upgrade) from "this project's version isn't one this CLI has ever heard
/// of" (an unknown/future version `cuboid doctor` must report distinctly,
/// never silently attempt to chain through).
Set<String> knownArchitectureVersions({
  List<Migration> migrations = migrationRegistry,
}) {
  return {
    legacyArchitectureVersion,
    currentArchitectureVersion,
    for (final migration in migrations) migration.sourceVersion,
    for (final migration in migrations) migration.targetVersion,
  };
}

/// The version at the end of [migrations]' chain -- the target version that
/// is never itself a source. Returns [fallback] if [migrations] is empty or
/// does not form a single unbroken chain (callers that care about a broken
/// chain should use [validateMigrationRegistry] instead, which reports
/// why).
String latestVersionIn(
  List<Migration> migrations, {
  String fallback = currentArchitectureVersion,
}) {
  if (migrations.isEmpty) {
    return fallback;
  }
  final targets = migrations
      .map((migration) => migration.targetVersion)
      .toSet();
  final sources = migrations
      .map((migration) => migration.sourceVersion)
      .toSet();
  final leaves = targets.difference(sources);
  if (leaves.length != 1) {
    return fallback;
  }
  return leaves.single;
}

/// Validates that [migrations] forms a single, unbroken, acyclic chain
/// ending at [currentArchitectureVersion] -- called from a test so a future
/// migration that's added but not wired into the chain correctly fails
/// fast instead of silently breaking `cuboid upgrade` for anyone more than
/// one version behind.
List<String> validateMigrationRegistry({
  List<Migration> migrations = migrationRegistry,
}) {
  final failures = <String>[];
  final bySource = <String, Migration>{};
  for (final migration in migrations) {
    if (bySource.containsKey(migration.sourceVersion)) {
      failures.add(
        'More than one migration starts at ${migration.sourceVersion}.',
      );
    }
    bySource[migration.sourceVersion] = migration;
  }

  if (migrations.isEmpty) {
    return failures;
  }

  final targets = migrations
      .map((migration) => migration.targetVersion)
      .toSet();
  final sources = migrations
      .map((migration) => migration.sourceVersion)
      .toSet();
  final roots = sources.difference(targets);
  if (roots.length != 1) {
    failures.add(
      'Expected exactly one chain root, found: ${roots.join(', ')}.',
    );
    return failures;
  }

  var current = roots.single;
  final visited = <String>{};
  while (bySource.containsKey(current)) {
    if (!visited.add(current)) {
      failures.add('Migration registry contains a cycle at $current.');
      return failures;
    }
    current = bySource[current]!.targetVersion;
  }
  if (current != currentArchitectureVersion) {
    failures.add(
      'Migration chain ends at $current, expected '
      '$currentArchitectureVersion.',
    );
  }
  return failures;
}
