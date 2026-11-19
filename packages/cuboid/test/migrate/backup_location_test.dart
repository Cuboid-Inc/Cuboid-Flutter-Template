import 'dart:io';

import 'package:cuboid/src/migrate/backup_location.dart';
import 'package:test/test.dart';

void main() {
  group('cuboidCacheRootDirectory', () {
    test('macOS uses ~/Library/Caches/Cuboid', () {
      final dir = cuboidCacheRootDirectory(
        environment: {'HOME': '/Users/dev'},
        operatingSystem: 'macos',
      );
      expect(dir.path, '/Users/dev/Library/Caches/Cuboid');
    });

    test('Linux prefers XDG_CACHE_HOME when set', () {
      final dir = cuboidCacheRootDirectory(
        environment: {
          'XDG_CACHE_HOME': '/home/dev/.cache',
          'HOME': '/home/dev',
        },
        operatingSystem: 'linux',
      );
      expect(dir.path, '/home/dev/.cache/cuboid');
    });

    test('Linux falls back to ~/.cache when XDG_CACHE_HOME is unset', () {
      final dir = cuboidCacheRootDirectory(
        environment: {'HOME': '/home/dev'},
        operatingSystem: 'linux',
      );
      expect(dir.path, '/home/dev/.cache/cuboid');
    });

    test('Windows uses %LOCALAPPDATA%\\Cuboid\\Cache', () {
      final dir = cuboidCacheRootDirectory(
        environment: {r'LOCALAPPDATA': r'C:\Users\dev\AppData\Local'},
        operatingSystem: 'windows',
      );
      expect(dir.path, r'C:\Users\dev\AppData\Local\Cuboid\Cache');
    });

    test('Windows falls back to APPDATA then USERPROFILE', () {
      final withAppData = cuboidCacheRootDirectory(
        environment: {r'APPDATA': r'C:\Users\dev\AppData\Roaming'},
        operatingSystem: 'windows',
      );
      expect(withAppData.path, r'C:\Users\dev\AppData\Roaming\Cuboid\Cache');

      final withProfile = cuboidCacheRootDirectory(
        environment: {r'USERPROFILE': r'C:\Users\dev'},
        operatingSystem: 'windows',
      );
      expect(withProfile.path, r'C:\Users\dev\Cuboid\Cache');
    });

    test('falls back to the system temp directory when no relevant env var is '
        'set, rather than guessing a relative path', () {
      final dir = cuboidCacheRootDirectory(environment: const {});
      expect(dir.path, startsWith(Directory.systemTemp.path));
      expect(dir.path, contains('cuboid-cache'));
    });
  });

  group('cuboidBackupsRootDirectory', () {
    test('is a backups/ subdirectory of the cache root', () {
      final dir = cuboidBackupsRootDirectory(
        environment: {'HOME': '/home/dev'},
        operatingSystem: 'linux',
      );
      expect(dir.path, '/home/dev/.cache/cuboid/backups');
    });
  });

  group('projectBackupSlug', () {
    test('is stable for the same project path', () {
      final projectRoot = Directory('/some/project');
      expect(
        projectBackupSlug(projectRoot),
        projectBackupSlug(Directory('/some/project')),
      );
    });

    test('differs for different project paths', () {
      expect(
        projectBackupSlug(Directory('/some/project-a')),
        isNot(projectBackupSlug(Directory('/some/project-b'))),
      );
    });

    test('is filesystem-safe and human-recognizable', () {
      final slug = projectBackupSlug(Directory('/home/dev/My App!'));
      expect(slug, matches(RegExp(r'^[A-Za-z0-9._-]+$')));
      expect(slug, startsWith('My_App_-'));
    });
  });

  group('backupDirectoryFor', () {
    test('nests under <backupsRoot>/<projectBackupSlug>/<timestampSlug>', () {
      final backupsRoot = Directory('/cache/cuboid/backups');
      final projectRoot = Directory('/some/project');
      final dir = backupDirectoryFor(
        projectRoot,
        '2026-08-24T10-00-00-000Z',
        backupsRoot: backupsRoot,
      );

      final slug = projectBackupSlug(projectRoot);
      expect(
        dir.path,
        '${backupsRoot.path}${Platform.pathSeparator}$slug'
        '${Platform.pathSeparator}2026-08-24T10-00-00-000Z',
      );
    });

    test('two different projects never collide under the same root', () {
      final backupsRoot = Directory('/cache/cuboid/backups');
      final dirA = backupDirectoryFor(
        Directory('/some/project-a'),
        'ts',
        backupsRoot: backupsRoot,
      );
      final dirB = backupDirectoryFor(
        Directory('/some/project-b'),
        'ts',
        backupsRoot: backupsRoot,
      );
      expect(dirA.path, isNot(dirB.path));
    });
  });
}
