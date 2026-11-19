/// Cuboid's second migration: `0.2.0` -> `0.3.0`, adding four new
/// template-owned files -- `lib/app/app.snackbars.dart`,
/// `lib/core/services/message_service.dart`,
/// `lib/core/services/media_utils.dart`, and
/// `lib/shared/widgets/app_image_cropper.dart` -- plus the small wiring
/// that makes them work in an existing project: registering `MessageService`
/// in `lib/app/app.locator.dart`, attaching its `scaffoldMessengerKey` to
/// the `MaterialApp` in `lib/app/app_root.dart`, and adding the
/// `image_picker`/`crop_your_image` dependencies `media_utils.dart`/
/// `app_image_cropper.dart` need.
///
/// Unlike `NavigationCuboidPageRouteMigration` (which rewrites an existing
/// file's *shape*), the four new files are never rewritten once they exist
/// -- each is either entirely new ([MigrationFileOutcome.create], content
/// taken from [loadBundledTemplatePayload] so a migrated project ends up
/// byte-identical to a freshly generated one) or already present
/// ([MigrationFileOutcome.skippedExisting], left completely untouched, even
/// if its content doesn't match what `cuboid create app` would have
/// written -- this is `cuboid upgrade`'s core safety guarantee). The
/// locator/`app_root.dart`/`pubspec.yaml` edits *are* modifications of an
/// existing file, but -- like the navigation migration -- each is anchored
/// on an exact, known substring and reported as
/// [MigrationFileOutcome.unsafeToMigrate] rather than guessed at when that
/// anchor isn't found.
library;

import 'dart:io';

import 'package:cuboid/src/migrate/migration.dart';
import 'package:cuboid/src/templates/flutter_app/bundled_template.dart';

const _appSnackbarsRelativePath = 'lib/app/app.snackbars.dart';
const _messageServiceRelativePath = 'lib/core/services/message_service.dart';
const _mediaUtilsRelativePath = 'lib/core/services/media_utils.dart';
const _cropperRelativePath = 'lib/shared/widgets/app_image_cropper.dart';
const _locatorRelativePath = 'lib/app/app.locator.dart';
const _appRootRelativePath = 'lib/app/app_root.dart';
const _pubspecRelativePath = 'pubspec.yaml';

const _newFileRelativePaths = [
  _appSnackbarsRelativePath,
  _messageServiceRelativePath,
  _mediaUtilsRelativePath,
  _cropperRelativePath,
];

/// Dependencies the new files require, with the version constraint Cuboid
/// ships in its own template `pubspec.yaml` -- kept in sync with it, not
/// independently chosen, so a migrated project resolves the same package
/// versions a freshly generated one would.
const _requiredDependencies = {
  'image_picker': '^1.2.4',
  'crop_your_image': '^2.0.1',
};

const _cuboidImportMarker = '// @cuboid-import';
const _cuboidServiceMarker = '// @cuboid-service';
const _navigatorKeyAnchor = 'navigatorKey: NavigationService.navigatorKey,';
const _dependenciesHeaderPattern = r'^dependencies:[ \t]*$';

class MediaToolsMigration extends Migration {
  const MediaToolsMigration();

  @override
  String get sourceVersion => '0.2.0';

  @override
  String get targetVersion => '0.3.0';

  @override
  String get description =>
      'Add messaging (MessageService) and image picking/cropping '
      '(MediaUtils, AppImageCropper) utilities, registering MessageService '
      'and their image_picker/crop_your_image dependencies.';

  @override
  MigrationAssessment assess(Directory projectRoot) {
    return MigrationAssessment(
      migration: this,
      fileChanges: [
        for (final path in _newFileRelativePaths)
          _assessNewFile(projectRoot, path),
        _assessLocator(projectRoot),
        _assessAppRoot(projectRoot),
        _assessPubspec(projectRoot),
      ],
    );
  }

  MigrationFileChange _assessNewFile(Directory projectRoot, String path) {
    final file = _fileFor(projectRoot, path);
    if (file.existsSync()) {
      return MigrationFileChange(
        path: path,
        outcome: MigrationFileOutcome.skippedExisting,
        reason: 'File already exists and was not modified.',
      );
    }

    final String? contents;
    try {
      contents = loadBundledTemplatePayload().utf8ContentsOf(path);
    } on BundledTemplateException catch (error) {
      return MigrationFileChange(
        path: path,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: 'Could not read this CLI\'s bundled template: ${error.message}',
      );
    }
    if (contents == null) {
      return MigrationFileChange(
        path: path,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'This Cuboid CLI build does not have $path in its bundled '
            'template.',
      );
    }

    return MigrationFileChange(
      path: path,
      outcome: MigrationFileOutcome.create,
      newContents: contents,
    );
  }

  MigrationFileChange _assessLocator(Directory projectRoot) {
    final file = _fileFor(projectRoot, _locatorRelativePath);
    if (!file.existsSync()) {
      return const MigrationFileChange(
        path: _locatorRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: 'lib/app/app.locator.dart was not found.',
      );
    }

    final contents = file.readAsStringSync();
    if (RegExp(r'register\w*\s*<\s*MessageService\s*>').hasMatch(contents)) {
      return const MigrationFileChange(
        path: _locatorRelativePath,
        outcome: MigrationFileOutcome.alreadyCurrent,
      );
    }

    if (_countOccurrences(contents, _cuboidImportMarker) != 1 ||
        _countOccurrences(contents, _cuboidServiceMarker) != 1) {
      return const MigrationFileChange(
        path: _locatorRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'Could not find exactly one "$_cuboidImportMarker" and one '
            '"$_cuboidServiceMarker" marker to register MessageService at.',
      );
    }

    final packageName = _readPackageName(projectRoot);
    if (packageName == null) {
      return const MigrationFileChange(
        path: _locatorRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: "Could not read this project's package name from pubspec.yaml.",
      );
    }

    final importLine =
        "import 'package:$packageName/core/services/message_service.dart';";
    var updated = contents;
    if (!updated.contains(importLine)) {
      updated = updated.replaceFirst(
        RegExp(r'^[ \t]*// @cuboid-import', multiLine: true),
        '$importLine\n// @cuboid-import',
      );
    }
    updated = updated.replaceFirst(
      RegExp(r'^[ \t]*// @cuboid-service', multiLine: true),
      '  locator.registerLazySingleton<MessageService>(() => MessageService());\n  // @cuboid-service',
    );

    return MigrationFileChange(
      path: _locatorRelativePath,
      outcome: MigrationFileOutcome.modify,
      newContents: updated,
    );
  }

  MigrationFileChange _assessAppRoot(Directory projectRoot) {
    final file = _fileFor(projectRoot, _appRootRelativePath);
    if (!file.existsSync()) {
      return const MigrationFileChange(
        path: _appRootRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: 'lib/app/app_root.dart was not found.',
      );
    }

    final contents = file.readAsStringSync();
    if (contents.contains('scaffoldMessengerKey:')) {
      return const MigrationFileChange(
        path: _appRootRelativePath,
        outcome: MigrationFileOutcome.alreadyCurrent,
      );
    }

    if (!contents.contains(_navigatorKeyAnchor)) {
      return const MigrationFileChange(
        path: _appRootRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'Could not find "$_navigatorKeyAnchor" in lib/app/app_root.dart '
            'to anchor the new scaffoldMessengerKey. Add '
            '`scaffoldMessengerKey: MessageService.scaffoldMessengerKey` to '
            "the MaterialApp in lib/app/app_root.dart manually, so MessageService "
            'can show snackbars without a BuildContext.',
      );
    }

    final packageName = _readPackageName(projectRoot);
    if (packageName == null) {
      return const MigrationFileChange(
        path: _appRootRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: "Could not read this project's package name from pubspec.yaml.",
      );
    }

    final importLine =
        "import 'package:$packageName/core/services/message_service.dart';";
    final navigationImportAnchor =
        "import 'package:$packageName/core/services/navigation_service.dart';";

    var updated = contents;
    if (!updated.contains(importLine)) {
      if (!updated.contains(navigationImportAnchor)) {
        return MigrationFileChange(
          path: _appRootRelativePath,
          outcome: MigrationFileOutcome.unsafeToMigrate,
          reason:
              'Could not find "$navigationImportAnchor" in '
              'lib/app/app_root.dart to anchor the new MessageService import.',
        );
      }
      updated = updated.replaceFirst(
        navigationImportAnchor,
        '$importLine\n$navigationImportAnchor',
      );
    }
    updated = updated.replaceFirst(
      _navigatorKeyAnchor,
      '$_navigatorKeyAnchor\n      scaffoldMessengerKey: MessageService.scaffoldMessengerKey,',
    );

    return MigrationFileChange(
      path: _appRootRelativePath,
      outcome: MigrationFileOutcome.modify,
      newContents: updated,
    );
  }

  MigrationFileChange _assessPubspec(Directory projectRoot) {
    final file = _fileFor(projectRoot, _pubspecRelativePath);
    if (!file.existsSync()) {
      return const MigrationFileChange(
        path: _pubspecRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: 'pubspec.yaml was not found.',
      );
    }

    final contents = file.readAsStringSync();
    final missing = <String, String>{};
    for (final entry in _requiredDependencies.entries) {
      final declared = RegExp(
        '^[ \t]*${RegExp.escape(entry.key)}:',
        multiLine: true,
      ).hasMatch(contents);
      if (!declared) {
        missing[entry.key] = entry.value;
      }
    }

    if (missing.isEmpty) {
      return const MigrationFileChange(
        path: _pubspecRelativePath,
        outcome: MigrationFileOutcome.alreadyCurrent,
      );
    }

    final headerMatch = RegExp(
      _dependenciesHeaderPattern,
      multiLine: true,
    ).firstMatch(contents);
    if (headerMatch == null) {
      return MigrationFileChange(
        path: _pubspecRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'Could not find a top-level "dependencies:" section in '
            'pubspec.yaml. Add ${missing.entries.map((e) => '${e.key}: ${e.value}').join(', ')} manually.',
      );
    }

    final lineEnding = contents.contains('\r\n') ? '\r\n' : '\n';
    final insertion = missing.entries
        .map((entry) => '  ${entry.key}: ${entry.value}')
        .join(lineEnding);
    final insertAt = headerMatch.end;
    final updated = contents.replaceRange(
      insertAt,
      insertAt,
      '$lineEnding$insertion',
    );

    return MigrationFileChange(
      path: _pubspecRelativePath,
      outcome: MigrationFileOutcome.modify,
      newContents: updated,
    );
  }
}

int _countOccurrences(String haystack, String needle) {
  if (needle.isEmpty) {
    return 0;
  }
  var count = 0;
  var index = haystack.indexOf(needle);
  while (index != -1) {
    count += 1;
    index = haystack.indexOf(needle, index + needle.length);
  }
  return count;
}

/// Reads the Dart package name declared in [projectRoot]'s `pubspec.yaml`,
/// or `null` if it is missing or malformed -- mirrors
/// `service/register_service.dart`'s `_readPackageName`, duplicated here
/// (rather than shared) since that one throws
/// `RegisterServiceException` on failure where a [Migration] must instead
/// report [MigrationFileOutcome.unsafeToMigrate] and never throw.
String? _readPackageName(Directory projectRoot) {
  final pubspec = _fileFor(projectRoot, 'pubspec.yaml');
  if (!pubspec.existsSync()) {
    return null;
  }

  final String contents;
  try {
    contents = pubspec.readAsStringSync();
  } on FileSystemException {
    return null;
  }

  final match = RegExp(
    r'''^\s*name:\s*(?:"([A-Za-z_][A-Za-z0-9_]*)"|'([A-Za-z_][A-Za-z0-9_]*)'|([A-Za-z_][A-Za-z0-9_]*))\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    return null;
  }
  return match.group(1) ?? match.group(2) ?? match.group(3);
}

File _fileFor(Directory projectRoot, String relativePath) {
  return File(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}
