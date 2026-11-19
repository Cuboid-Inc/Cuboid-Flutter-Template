/// Resolves where `cuboid upgrade` stores its migration backups -- always
/// outside the project being migrated, under a directory Cuboid owns,
/// following each platform's convention for application cache data:
///
///   macOS:   ~/Library/Caches/Cuboid
///   Windows: %LOCALAPPDATA%\Cuboid\Cache
///   Linux:   $XDG_CACHE_HOME/cuboid (or ~/.cache/cuboid if unset)
///
/// [migrate/upgrade.dart] is the only writer: it stores each run's snapshot
/// under `<cache root>/backups/<projectBackupSlug>/<timestamp>/`, so a
/// consuming project's own `.cuboid/` directory only ever holds
/// `project.json` (see `architecture/architecture_metadata.dart`), never
/// Cuboid's internal migration bookkeeping.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// The root directory Cuboid uses for its own cache data on this platform.
/// Not created by this function -- callers create subdirectories as needed.
///
/// [environment] and [operatingSystem] exist purely so tests can exercise
/// every platform's path convention from a single host; real callers should
/// leave both unset and get [Platform.environment] / [Platform.operatingSystem].
Directory cuboidCacheRootDirectory({
  Map<String, String>? environment,
  String? operatingSystem,
}) {
  final env = environment ?? Platform.environment;
  final os = operatingSystem ?? Platform.operatingSystem;
  return Directory(_cacheRootPath(env, os));
}

/// Where `cuboid upgrade` writes migration backups: a `backups` directory
/// under [cuboidCacheRootDirectory].
Directory cuboidBackupsRootDirectory({
  Map<String, String>? environment,
  String? operatingSystem,
}) {
  final os = operatingSystem ?? Platform.operatingSystem;
  final root = cuboidCacheRootDirectory(
    environment: environment,
    operatingSystem: os,
  );
  return Directory('${root.path}${_separatorFor(os)}backups');
}

/// A short, stable identifier for [projectRoot]: the same project path
/// always yields the same slug, and different projects yield different
/// slugs, so many projects' backups can share [cuboidBackupsRootDirectory]
/// without colliding -- see `migrate/upgrade.dart`.
String projectBackupSlug(Directory projectRoot) {
  final normalized = projectRoot.absolute.path
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+$'), '');
  final digest = sha256.convert(utf8.encode(normalized)).toString();
  final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
  final name = segments.isEmpty ? 'project' : segments.last;
  final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return '$safeName-${digest.substring(0, 12)}';
}

/// The directory a single `cuboid upgrade` run backs up to:
/// `<backupsRoot>/<projectBackupSlug>/<timestampSlug>`. [backupsRoot]
/// defaults to [cuboidBackupsRootDirectory] and, like it, is a real
/// filesystem [Directory] -- always joined with [Platform.pathSeparator],
/// since (unlike [cuboidCacheRootDirectory]'s pure path-format resolution)
/// this always operates against an actual directory on the current host.
Directory backupDirectoryFor(
  Directory projectRoot,
  String timestampSlug, {
  Directory? backupsRoot,
}) {
  final root = backupsRoot ?? cuboidBackupsRootDirectory();
  final slug = projectBackupSlug(projectRoot);
  return Directory(
    '${root.path}${Platform.pathSeparator}$slug${Platform.pathSeparator}'
    '$timestampSlug',
  );
}

String _cacheRootPath(Map<String, String> env, String operatingSystem) {
  final separator = _separatorFor(operatingSystem);
  switch (operatingSystem) {
    case 'macos':
      final home = _nonEmpty(env['HOME']);
      if (home != null) {
        return '$home${separator}Library${separator}Caches${separator}Cuboid';
      }
      return '${Directory.systemTemp.path}${separator}cuboid-cache';
    case 'windows':
      final base =
          _nonEmpty(env['LOCALAPPDATA']) ??
          _nonEmpty(env['APPDATA']) ??
          _nonEmpty(env['USERPROFILE']);
      if (base != null) {
        return '$base${separator}Cuboid${separator}Cache';
      }
      return '${Directory.systemTemp.path}${separator}cuboid-cache';
    default:
      // Linux and other POSIX platforms.
      final xdgCache = _nonEmpty(env['XDG_CACHE_HOME']);
      if (xdgCache != null) {
        return '$xdgCache${separator}cuboid';
      }
      final home = _nonEmpty(env['HOME']);
      if (home != null) {
        return '$home$separator.cache${separator}cuboid';
      }
      return '${Directory.systemTemp.path}${separator}cuboid-cache';
  }
}

String _separatorFor(String operatingSystem) =>
    operatingSystem == 'windows' ? r'\' : '/';

String? _nonEmpty(String? value) =>
    (value == null || value.isEmpty) ? null : value;
