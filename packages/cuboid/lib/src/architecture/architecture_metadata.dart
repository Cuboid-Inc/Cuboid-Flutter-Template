/// Reads and writes `.cuboid/project.json` -- the explicit metadata file a
/// generated project carries so a later Cuboid CLI can answer "which Cuboid
/// architecture generated (or last migrated) this project?" without
/// guessing from source.
///
/// `cuboid create app` writes this file into every newly generated project
/// (see `create/create_project.dart`) so a brand-new project never needs
/// `cuboid upgrade` immediately after creation. `cuboid doctor`/`cuboid
/// upgrade` fall back to structural inference (see
/// [inferArchitectureVersionFromSource]) only for older projects generated
/// before this file existed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:cuboid/src/architecture/architecture_version.dart';

const architectureMetadataRelativePath = '.cuboid/project.json';

class ArchitectureMetadataException implements Exception {
  const ArchitectureMetadataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The parsed contents of `.cuboid/project.json`.
class ArchitectureMetadata {
  const ArchitectureMetadata({
    required this.architectureVersion,
    this.generatedByCuboidVersion,
    this.generatedByCuboidFlutterVersion,
  });

  /// The project architecture version this project currently follows --
  /// see `architecture_version.dart` for how this differs from the CLI and
  /// `cuboid_flutter` package versions.
  final String architectureVersion;

  /// The Cuboid CLI version (`cuboidVersion`) that generated this project,
  /// recorded for diagnostics -- never used to drive migration logic.
  final String? generatedByCuboidVersion;

  /// The `cuboid_flutter` package version bundled with the CLI that
  /// generated this project, recorded for diagnostics only.
  final String? generatedByCuboidFlutterVersion;

  Map<String, Object?> toJson() {
    return {
      'architecture_version': architectureVersion,
      if (generatedByCuboidVersion != null)
        'generated_by_cuboid_version': generatedByCuboidVersion,
      if (generatedByCuboidFlutterVersion != null)
        'generated_by_cuboid_flutter_version': generatedByCuboidFlutterVersion,
    };
  }

  static ArchitectureMetadata fromJson(Map<String, Object?> json) {
    final architectureVersion = json['architecture_version'];
    if (architectureVersion is! String || architectureVersion.trim().isEmpty) {
      throw const ArchitectureMetadataException(
        '$architectureMetadataRelativePath is missing "architecture_version".',
      );
    }
    return ArchitectureMetadata(
      architectureVersion: architectureVersion,
      generatedByCuboidVersion: json['generated_by_cuboid_version'] as String?,
      generatedByCuboidFlutterVersion:
          json['generated_by_cuboid_flutter_version'] as String?,
    );
  }

  ArchitectureMetadata copyWith({String? architectureVersion}) {
    return ArchitectureMetadata(
      architectureVersion: architectureVersion ?? this.architectureVersion,
      generatedByCuboidVersion: generatedByCuboidVersion,
      generatedByCuboidFlutterVersion: generatedByCuboidFlutterVersion,
    );
  }
}

File architectureMetadataFile(Directory projectRoot) {
  return File(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${architectureMetadataRelativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

/// Reads `.cuboid/project.json` from [projectRoot], or returns `null` if it
/// does not exist. Throws [ArchitectureMetadataException] if it exists but
/// is not valid JSON or is missing required fields -- callers should treat
/// that the same as "suspicious/unexpected infrastructure", not silently
/// fall back to inference.
ArchitectureMetadata? readArchitectureMetadata(Directory projectRoot) {
  final file = architectureMetadataFile(projectRoot);
  if (!file.existsSync()) {
    return null;
  }

  final String contents;
  try {
    contents = file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw ArchitectureMetadataException(
      'Unable to read $architectureMetadataRelativePath: ${error.message}',
    );
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(contents);
  } on FormatException {
    throw const ArchitectureMetadataException(
      '$architectureMetadataRelativePath is not valid JSON.',
    );
  }
  if (decoded is! Map<String, Object?>) {
    throw const ArchitectureMetadataException(
      '$architectureMetadataRelativePath must contain a JSON object.',
    );
  }
  return ArchitectureMetadata.fromJson(decoded);
}

/// Writes [metadata] to `.cuboid/project.json` under [projectRoot],
/// creating the `.cuboid/` directory if needed. Used both by `cuboid create
/// app` (initial write) and `cuboid upgrade` (updating the version after a
/// successful migration).
void writeArchitectureMetadata(
  Directory projectRoot,
  ArchitectureMetadata metadata,
) {
  final file = architectureMetadataFile(projectRoot);
  file.parent.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(metadata.toJson())}\n');
}

/// Best-effort inference of a project's architecture version from its
/// source, used only when `.cuboid/project.json` is absent (a project
/// generated before this metadata file existed). Returns `null` if
/// [projectRoot] does not look like a Cuboid project at all.
///
/// This is deliberately narrow: it only distinguishes the one boundary
/// Cuboid currently has a migration for (legacy `MaterialPageRoute` routing
/// vs. `CuboidPageRoute`). A project on some later architecture that also
/// predates metadata recording would still infer as
/// [currentArchitectureVersion] here, since its router already looks
/// current -- there is nothing yet that would tell them apart.
String? inferArchitectureVersionFromSource(Directory projectRoot) {
  final routerFile = File(
    '${projectRoot.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
    'app${Platform.pathSeparator}app.router.dart',
  );
  if (!routerFile.existsSync()) {
    return null;
  }

  final contents = routerFile.readAsStringSync();
  if (contents.contains('CuboidPageRoute')) {
    return currentArchitectureVersion;
  }
  if (contents.contains('MaterialPageRoute')) {
    return legacyArchitectureVersion;
  }
  // The router exists but matches neither known shape (hand-rewritten
  // `onGenerateRoute`, for example). Report as legacy so `cuboid doctor`
  // surfaces it as needing a look rather than silently calling it current.
  return legacyArchitectureVersion;
}
