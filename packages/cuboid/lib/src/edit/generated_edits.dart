/// Shared, safety-critical text-surgery and filesystem helpers used by every
/// `delete_*.dart` service to reverse the exact-string insertions their
/// `create_*.dart` counterpart performs. This is the one shared module in
/// the delete system (mirroring why `register_route.dart` is already shared
/// between `create_feature.dart` and `create_view.dart`): the marker-based
/// removal logic here must be precise and is reused by roughly seven
/// different delete services, so duplicating it per-file would risk the
/// copies drifting out of sync on something that must never silently
/// corrupt a generated file.
library;

import 'dart:io';

/// Removes the first line in [contents] whose trimmed text equals
/// [line].trim(), including its line ending (or lack thereof, if it is the
/// last line). Returns the updated contents, or `null` if no such line
/// exists. Used to reverse the exact-string insertions every `create_*.dart`
/// `_apply*Plan` function performs, so removal is the precise structural
/// inverse of creation -- never a substring/text-replacement heuristic.
String? removeExactLine(String contents, String line) {
  final trimmed = line.trim();
  final pattern = RegExp(
    r'^[ \t]*' + RegExp.escape(trimmed) + r'[ \t]*$\r?\n?',
    multiLine: true,
  );
  final match = pattern.firstMatch(contents);
  if (match == null) {
    return null;
  }
  return contents.replaceRange(match.start, match.end, '');
}

/// Atomically replaces [file]'s contents with [contents] via a temp file in
/// the same directory followed by a rename, so a crash mid-write can never
/// leave the file partially written. Throws [FileSystemException] on
/// failure; callers should wrap that into their own domain exception.
void atomicReplaceFileContents(File file, String contents) {
  final temp = file.parent.createTempSync('.cuboid-edit-');
  final tempFile = File(
    '${temp.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
  );
  try {
    tempFile.writeAsStringSync(contents);
    tempFile.renameSync(file.path);
  } finally {
    try {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // Best-effort cleanup; preserve the actual write or publish result.
    }
  }
}

/// Restores each file to its original contents, best-effort (swallowing
/// [FileSystemException] so the original failure that triggered the
/// rollback is what surfaces to the caller).
void restoreFileContents(Map<File, String> originals) {
  for (final entry in originals.entries) {
    try {
      entry.key.writeAsStringSync(entry.value);
    } on FileSystemException {
      // Best-effort cleanup; preserve the original failure.
    }
  }
}

/// Deletes [file] if it exists, best-effort.
void deleteFileIfExists(File file) {
  try {
    if (file.existsSync()) {
      file.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup; preserve the original failure.
  }
}

/// Deletes [directory] (recursively) if it exists, best-effort.
void deleteDirectoryIfExists(Directory directory) {
  try {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  } on FileSystemException {
    // Best-effort cleanup; preserve the original failure.
  }
}

/// Deletes [start] if it exists and is empty, then walks up through each
/// ancestor doing the same, stopping as soon as it reaches [stopAt] or hits
/// a non-empty directory. Never deletes [stopAt] itself. Used so a
/// widget/dialog/bottom-sheet's own container directory (created solely to
/// hold it) disappears when it was the last thing inside, without ever
/// touching directories that predate it or hold unrelated content.
void pruneEmptyDirectories(Directory start, {required Directory stopAt}) {
  final stopPath = stopAt.absolute.path;
  var current = Directory(start.absolute.path);

  while (current.path != stopPath && current.path.startsWith(stopPath)) {
    try {
      if (current.existsSync()) {
        if (current.listSync().isNotEmpty) {
          return;
        }
        current.deleteSync();
      }
    } on FileSystemException {
      return;
    }
    current = current.parent;
  }
}

File targetFile(Directory projectRoot, String relativePath) {
  return File(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

Directory targetDirectory(Directory projectRoot, String relativePath) {
  return Directory(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

String relativePathFrom(Directory root, String absolutePath) {
  return absolutePath
      .substring(root.path.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

bool isRegularFile(String path) {
  return FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.file;
}

bool isRegularDirectory(String path) {
  return FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.directory;
}

bool pathExists(String path) {
  return FileSystemEntity.typeSync(path, followLinks: false) !=
      FileSystemEntityType.notFound;
}
