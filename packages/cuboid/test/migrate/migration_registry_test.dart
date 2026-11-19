import 'dart:io';

import 'package:cuboid/src/architecture/architecture_version.dart';
import 'package:cuboid/src/migrate/migration.dart';
import 'package:cuboid/src/migrate/migration_registry.dart';
import 'package:test/test.dart';

class _StubMigration extends Migration {
  const _StubMigration(this.sourceVersion, this.targetVersion);

  @override
  final String sourceVersion;

  @override
  final String targetVersion;

  @override
  String get description => '$sourceVersion -> $targetVersion';

  @override
  MigrationAssessment assess(Directory projectRoot) {
    return MigrationAssessment(migration: this, fileChanges: const []);
  }
}

void main() {
  group('resolveMigrationChain', () {
    test('returns an empty chain when already at the target version', () {
      expect(
        resolveMigrationChain(
          fromVersion: '0.2.0',
          toVersion: '0.2.0',
          migrations: const [_StubMigration('0.1.0', '0.2.0')],
        ),
        isEmpty,
      );
    });

    test('resolves a single-hop chain', () {
      const migration = _StubMigration('0.1.0', '0.2.0');
      final chain = resolveMigrationChain(
        fromVersion: '0.1.0',
        toVersion: '0.2.0',
        migrations: const [migration],
      );
      expect(chain, [migration]);
    });

    test(
      'resolves and orders a multi-hop chain (0.1.0 -> 0.2.0 -> 0.3.0 -> 0.4.0) '
      'rather than jumping directly',
      () {
        const step1 = _StubMigration('0.1.0', '0.2.0');
        const step2 = _StubMigration('0.2.0', '0.3.0');
        const step3 = _StubMigration('0.3.0', '0.4.0');
        // Registered out of order to prove resolution walks the chain by
        // source/target linkage, not registration order.
        final migrations = [step3, step1, step2];

        final chain = resolveMigrationChain(
          fromVersion: '0.1.0',
          toVersion: '0.4.0',
          migrations: migrations,
        );

        expect(chain, [step1, step2, step3]);
      },
    );

    test('resolves a partial multi-hop chain starting mid-way', () {
      const step1 = _StubMigration('0.1.0', '0.2.0');
      const step2 = _StubMigration('0.2.0', '0.3.0');
      const step3 = _StubMigration('0.3.0', '0.4.0');

      final chain = resolveMigrationChain(
        fromVersion: '0.2.0',
        toVersion: '0.4.0',
        migrations: [step1, step2, step3],
      );

      expect(chain, [step2, step3]);
    });

    test('throws when no migration exists for the starting version', () {
      expect(
        () => resolveMigrationChain(
          fromVersion: '0.5.0',
          toVersion: '0.2.0',
          migrations: const [_StubMigration('0.1.0', '0.2.0')],
        ),
        throwsA(isA<MigrationChainException>()),
      );
    });

    test('throws when the chain does not reach the target version', () {
      expect(
        () => resolveMigrationChain(
          fromVersion: '0.1.0',
          toVersion: '0.4.0',
          migrations: const [_StubMigration('0.1.0', '0.2.0')],
        ),
        throwsA(isA<MigrationChainException>()),
      );
    });

    test(
      'throws when the registry has two migrations from the same source',
      () {
        expect(
          () => resolveMigrationChain(
            fromVersion: '0.1.0',
            toVersion: '0.3.0',
            migrations: const [
              _StubMigration('0.1.0', '0.2.0'),
              _StubMigration('0.1.0', '0.9.0'),
            ],
          ),
          throwsA(isA<MigrationChainException>()),
        );
      },
    );

    test('throws rather than looping forever on a cyclic registry', () {
      expect(
        () => resolveMigrationChain(
          fromVersion: '0.1.0',
          toVersion: '0.9.0',
          migrations: const [
            _StubMigration('0.1.0', '0.2.0'),
            _StubMigration('0.2.0', '0.1.0'),
          ],
        ),
        throwsA(isA<MigrationChainException>()),
      );
    });
  });

  group('knownArchitectureVersions', () {
    test('includes legacy, current, and every migration endpoint', () {
      final versions = knownArchitectureVersions(
        migrations: const [
          _StubMigration('0.1.0', '0.2.0'),
          _StubMigration('0.2.0', '0.3.0'),
        ],
      );
      expect(versions, containsAll(['0.1.0', '0.2.0', '0.3.0']));
      expect(versions, contains(legacyArchitectureVersion));
      expect(versions, contains(currentArchitectureVersion));
    });

    test('does not include an unrelated version', () {
      final versions = knownArchitectureVersions(
        migrations: const [_StubMigration('0.1.0', '0.2.0')],
      );
      expect(versions, isNot(contains('9.9.9')));
    });
  });

  group('latestVersionIn', () {
    test('returns the leaf of a multi-hop chain', () {
      expect(
        latestVersionIn(const [
          _StubMigration('0.1.0', '0.2.0'),
          _StubMigration('0.2.0', '0.3.0'),
          _StubMigration('0.3.0', '0.4.0'),
        ]),
        '0.4.0',
      );
    });

    test('returns fallback for an empty migration list', () {
      expect(latestVersionIn(const [], fallback: '9.9.9'), '9.9.9');
    });

    test('returns fallback for a broken (non-single-chain) registry', () {
      expect(
        latestVersionIn(const [
          _StubMigration('0.1.0', '0.2.0'),
          _StubMigration('0.1.0', '0.9.0'),
        ], fallback: '9.9.9'),
        '9.9.9',
      );
    });
  });

  group('the real migrationRegistry', () {
    test(
      'forms a single unbroken chain ending at currentArchitectureVersion',
      () {
        expect(validateMigrationRegistry(), isEmpty);
      },
    );

    test(
      'resolves from legacyArchitectureVersion to currentArchitectureVersion',
      () {
        final chain = resolveMigrationChain(
          fromVersion: legacyArchitectureVersion,
          toVersion: currentArchitectureVersion,
        );
        expect(chain, isNotEmpty);
        expect(chain.first.sourceVersion, legacyArchitectureVersion);
        expect(chain.last.targetVersion, currentArchitectureVersion);
      },
    );
  });
}
