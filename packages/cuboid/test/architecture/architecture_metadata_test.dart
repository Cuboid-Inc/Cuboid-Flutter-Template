import 'dart:io';

import 'package:cuboid/src/architecture/architecture_metadata.dart';
import 'package:cuboid/src/architecture/architecture_version.dart';
import 'package:test/test.dart';

void main() {
  group('ArchitectureVersion', () {
    test('parses plain MAJOR.MINOR.PATCH strings', () {
      expect(
        ArchitectureVersion.tryParse('0.2.0'),
        const ArchitectureVersion(0, 2, 0),
      );
      expect(
        ArchitectureVersion.tryParse('1.10.3'),
        const ArchitectureVersion(1, 10, 3),
      );
    });

    test('returns null for malformed input', () {
      expect(ArchitectureVersion.tryParse('0.2'), isNull);
      expect(ArchitectureVersion.tryParse('not-a-version'), isNull);
      expect(ArchitectureVersion.tryParse('0.2.0-beta'), isNull);
    });

    test('compares numerically, not lexically', () {
      final v9 = ArchitectureVersion.tryParse('0.9.0')!;
      final v10 = ArchitectureVersion.tryParse('0.10.0')!;
      expect(v9 < v10, isTrue);
      expect(v10 > v9, isTrue);
      expect(v9.compareTo(v9), 0);
    });

    test('equality is value-based', () {
      expect(
        ArchitectureVersion.tryParse('0.2.0'),
        ArchitectureVersion.tryParse('0.2.0'),
      );
    });
  });

  group('readArchitectureMetadata / writeArchitectureMetadata', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('cuboid_metadata_test_');
    });

    tearDown(() {
      root.deleteSync(recursive: true);
    });

    test('returns null when .cuboid/project.json does not exist', () {
      expect(readArchitectureMetadata(root), isNull);
    });

    test('round-trips a full metadata record', () {
      writeArchitectureMetadata(
        root,
        const ArchitectureMetadata(
          architectureVersion: '0.2.0',
          generatedByCuboidVersion: '0.1.0',
          generatedByCuboidFlutterVersion: '0.2.0',
        ),
      );

      final file = File('${root.path}/.cuboid/project.json');
      expect(file.existsSync(), isTrue);

      final metadata = readArchitectureMetadata(root)!;
      expect(metadata.architectureVersion, '0.2.0');
      expect(metadata.generatedByCuboidVersion, '0.1.0');
      expect(metadata.generatedByCuboidFlutterVersion, '0.2.0');
    });

    test('round-trips a record with only the required field', () {
      writeArchitectureMetadata(
        root,
        const ArchitectureMetadata(architectureVersion: '0.1.0'),
      );

      final metadata = readArchitectureMetadata(root)!;
      expect(metadata.architectureVersion, '0.1.0');
      expect(metadata.generatedByCuboidVersion, isNull);
      expect(metadata.generatedByCuboidFlutterVersion, isNull);
    });

    test('creates the .cuboid directory if missing', () {
      expect(Directory('${root.path}/.cuboid').existsSync(), isFalse);
      writeArchitectureMetadata(
        root,
        const ArchitectureMetadata(architectureVersion: '0.2.0'),
      );
      expect(Directory('${root.path}/.cuboid').existsSync(), isTrue);
    });

    test('throws when the file is not valid JSON', () {
      File('${root.path}/.cuboid/project.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('not json');

      expect(
        () => readArchitectureMetadata(root),
        throwsA(isA<ArchitectureMetadataException>()),
      );
    });

    test('throws when architecture_version is missing', () {
      File('${root.path}/.cuboid/project.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{"generated_by_cuboid_version": "0.1.0"}');

      expect(
        () => readArchitectureMetadata(root),
        throwsA(isA<ArchitectureMetadataException>()),
      );
    });

    test('throws when the JSON root is not an object', () {
      File('${root.path}/.cuboid/project.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('[1, 2, 3]');

      expect(
        () => readArchitectureMetadata(root),
        throwsA(isA<ArchitectureMetadataException>()),
      );
    });
  });

  group('inferArchitectureVersionFromSource', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('cuboid_infer_test_');
    });

    tearDown(() {
      root.deleteSync(recursive: true);
    });

    test('returns null when app.router.dart does not exist', () {
      expect(inferArchitectureVersionFromSource(root), isNull);
    });

    test('detects the legacy MaterialPageRoute shape as 0.1.0', () {
      File('${root.path}/lib/app/app.router.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          'Route<dynamic>? onGenerateRoute(RouteSettings settings) {\n'
          '  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);\n'
          '}\n',
        );

      expect(
        inferArchitectureVersionFromSource(root),
        legacyArchitectureVersion,
      );
    });

    test('detects the current CuboidPageRoute shape as 0.2.0', () {
      File('${root.path}/lib/app/app.router.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          'Route<dynamic>? onGenerateRoute(RouteSettings settings) {\n'
          '  return CuboidPageRoute<dynamic>(builder: builder, settings: settings);\n'
          '}\n',
        );

      expect(
        inferArchitectureVersionFromSource(root),
        currentArchitectureVersion,
      );
    });
  });
}
