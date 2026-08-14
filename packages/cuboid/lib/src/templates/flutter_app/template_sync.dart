import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const templateName = 'cuboid_flutter_app';
const templateVersion = 1;

const templateArchivePath =
    'packages/cuboid/lib/src/templates/flutter_app/template.tar.gz';
const templateManifestPath =
    'packages/cuboid/lib/src/templates/flutter_app/template_manifest.json';

const templateAllowedFiles = [
  '.gitignore',
  '.metadata',
  'ARCHITECTURE.md',
  'README.md',
  'RULES.md',
  'analysis_options.yaml',
  'devtools_options.yaml',
  'pubspec.lock',
  'pubspec.yaml',
  'stacked.json',
];

const templateAllowedDirectories = ['android', 'assets', 'ios', 'lib', 'test'];

const templateExcludedPatterns = [
  '.git/**',
  '.dart_tool/**',
  '.pub/**',
  '.pub-cache/**',
  '.flutter-plugins-dependencies',
  '.vscode/**',
  '.agents/**',
  '.codex/**',
  '.claude/**',
  'build/**',
  'coverage/**',
  'doc/**',
  'env/**',
  'packages/cuboid/**',
  'tool/**',
  'skills-lock.json',
  '**/.DS_Store',
  '**/*.env',
  '**/.env',
  '**/.env.*',
  '**/local.properties',
  '**/Pods/**',
  '**/.symlinks/**',
  '**/.last_build_id',
  '**/Generated.xcconfig',
  '**/GeneratedPluginRegistrant.*',
  '**/flutter_export_environment.sh',
  '**/ephemeral/**',
  'test/tool/**',
];

const _fixedTarModifiedTime = 0;
const _tarBlockSize = 512;

class TemplateSyncException implements Exception {
  const TemplateSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TemplateSyncResult {
  const TemplateSyncResult({
    required this.manifest,
    required this.archiveBytes,
    required this.manifestBytes,
  });

  final TemplateManifest manifest;
  final Uint8List archiveBytes;
  final Uint8List manifestBytes;
}

class TemplateCheckResult {
  const TemplateCheckResult({
    required this.inSync,
    required this.failures,
    required this.expected,
  });

  final bool inSync;
  final List<String> failures;
  final TemplateSyncResult expected;
}

class TemplateManifest {
  const TemplateManifest({
    required this.templateName,
    required this.templateVersion,
    required this.sourceCommit,
    required this.archiveSha256,
    required this.files,
    required this.excludedPatterns,
  });

  final String templateName;
  final int templateVersion;
  final String sourceCommit;
  final String archiveSha256;
  final List<TemplateManifestFile> files;
  final List<String> excludedPatterns;

  Map<String, Object?> toJson() {
    return {
      'template_name': templateName,
      'template_version': templateVersion,
      'source_commit': sourceCommit,
      'archive_sha256': archiveSha256,
      'files': files.map((file) => file.toJson()).toList(),
      'excluded_patterns': excludedPatterns,
    };
  }

  static TemplateManifest fromJson(Map<String, Object?> json) {
    return TemplateManifest(
      templateName: json['template_name']! as String,
      templateVersion: json['template_version']! as int,
      sourceCommit: json['source_commit']! as String,
      archiveSha256: json['archive_sha256']! as String,
      files: (json['files']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(TemplateManifestFile.fromJson)
          .toList(),
      excludedPatterns: (json['excluded_patterns']! as List<Object?>)
          .cast<String>(),
    );
  }
}

class TemplateManifestFile {
  const TemplateManifestFile({
    required this.path,
    required this.size,
    required this.sha256,
  });

  final String path;
  final int size;
  final String sha256;

  Map<String, Object?> toJson() {
    return {'path': path, 'size': size, 'sha256': sha256};
  }

  static TemplateManifestFile fromJson(Map<String, Object?> json) {
    return TemplateManifestFile(
      path: json['path']! as String,
      size: json['size']! as int,
      sha256: json['sha256']! as String,
    );
  }
}

class TemplateSourceFile {
  const TemplateSourceFile({required this.path, required this.bytes});

  final String path;
  final Uint8List bytes;

  int get size => bytes.length;

  String get sha256 => sha256Hex(bytes);
}

Future<TemplateSyncResult> buildTemplatePayload(Directory root) async {
  validateRepositoryRoot(root);
  final sourceCommit = await gitHeadCommit(root);
  final files = collectTemplateFiles(root);
  final archiveBytes = buildDeterministicTarGz(files);
  final manifest = TemplateManifest(
    templateName: templateName,
    templateVersion: templateVersion,
    sourceCommit: sourceCommit,
    archiveSha256: sha256Hex(archiveBytes),
    files: files
        .map(
          (file) => TemplateManifestFile(
            path: file.path,
            size: file.size,
            sha256: file.sha256,
          ),
        )
        .toList(),
    excludedPatterns: templateExcludedPatterns,
  );

  return TemplateSyncResult(
    manifest: manifest,
    archiveBytes: archiveBytes,
    manifestBytes: encodeManifest(manifest),
  );
}

Future<void> regenerateTemplatePayload(
  Directory root, {
  bool allowDirty = false,
}) async {
  validateRepositoryRoot(root);
  if (!allowDirty) {
    await validateCleanTemplateSources(root);
  }

  final result = await buildTemplatePayload(root);
  final archiveFile = fileFor(root, templateArchivePath);
  final manifestFile = fileFor(root, templateManifestPath);
  archiveFile.parent.createSync(recursive: true);
  manifestFile.parent.createSync(recursive: true);
  archiveFile.writeAsBytesSync(result.archiveBytes);
  manifestFile.writeAsBytesSync(result.manifestBytes);
}

Future<TemplateCheckResult> checkTemplatePayload(
  Directory root, {
  bool allowDirty = false,
}) async {
  validateRepositoryRoot(root);
  if (!allowDirty) {
    await validateCleanTemplateSources(root);
  }

  final expected = await buildTemplatePayload(root);
  final failures = <String>[];

  final archiveFile = fileFor(root, templateArchivePath);
  final manifestFile = fileFor(root, templateManifestPath);
  if (!archiveFile.existsSync()) {
    failures.add('$templateArchivePath is missing.');
  } else {
    final actualArchive = archiveFile.readAsBytesSync();
    if (!_bytesEqual(actualArchive, expected.archiveBytes)) {
      failures.add('$templateArchivePath is stale.');
    }
  }

  if (!manifestFile.existsSync()) {
    failures.add('$templateManifestPath is missing.');
  } else {
    final actualManifest = manifestFile.readAsBytesSync();
    if (!_bytesEqual(actualManifest, expected.manifestBytes)) {
      failures.add('$templateManifestPath is stale.');
    }
  }

  if (archiveFile.existsSync() && manifestFile.existsSync()) {
    failures.addAll(verifyTemplatePayload(root));
  }

  return TemplateCheckResult(
    inSync: failures.isEmpty,
    failures: failures,
    expected: expected,
  );
}

List<String> verifyTemplatePayload(Directory root) {
  final archiveFile = fileFor(root, templateArchivePath);
  final manifestFile = fileFor(root, templateManifestPath);
  final manifest = TemplateManifest.fromJson(
    jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>,
  );
  final archiveBytes = archiveFile.readAsBytesSync();
  final failures = <String>[];

  final archiveSha = sha256Hex(archiveBytes);
  if (archiveSha != manifest.archiveSha256) {
    failures.add('Archive SHA-256 does not match manifest.');
  }

  final List<ExtractedTemplateFile> extracted;
  try {
    extracted = extractTarGz(archiveBytes);
  } on FormatException {
    failures.add('Archive cannot be decoded.');
    return failures;
  }
  final extractedPaths = extracted.map((entry) => entry.path).toList()..sort();
  final manifestPaths = manifest.files.map((entry) => entry.path).toList()
    ..sort();
  if (!_listEqual(extractedPaths, manifestPaths)) {
    failures.add('Archive file list does not match manifest.');
  }

  final extractedByPath = {for (final entry in extracted) entry.path: entry};
  for (final file in manifest.files) {
    final extractedFile = extractedByPath[file.path];
    if (extractedFile == null) {
      continue;
    }
    if (extractedFile.bytes.length != file.size) {
      failures.add('${file.path}: size does not match manifest.');
    }
    if (sha256Hex(extractedFile.bytes) != file.sha256) {
      failures.add('${file.path}: SHA-256 does not match manifest.');
    }
  }

  return failures;
}

void validateRepositoryRoot(Directory root) {
  final requiredPaths = [
    'pubspec.yaml',
    'stacked.json',
    'packages/cuboid/pubspec.yaml',
  ];
  for (final path in requiredPaths) {
    if (!fileFor(root, path).existsSync()) {
      throw TemplateSyncException(
        'Run this tool from the repository root. Missing $path.',
      );
    }
  }
}

Future<void> validateCleanTemplateSources(Directory root) async {
  final result = await Process.run(
    'git',
    ['status', '--porcelain', '--untracked-files=all', '--', ...sourceRoots()],
    workingDirectory: root.path,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    throw TemplateSyncException('Unable to inspect Git working tree.');
  }
  final output = (result.stdout as String).trim();
  if (output.isNotEmpty) {
    throw TemplateSyncException(
      'Template source files are dirty. Commit or stash them, or pass --allow-dirty for maintenance regeneration.',
    );
  }
}

Future<String> gitHeadCommit(Directory root) async {
  final result = await Process.run(
    'git',
    ['rev-parse', 'HEAD'],
    workingDirectory: root.path,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    throw TemplateSyncException('Unable to read source Git commit.');
  }
  return (result.stdout as String).trim();
}

List<String> sourceRoots() {
  return [...templateAllowedFiles, ...templateAllowedDirectories]..sort();
}

List<TemplateSourceFile> collectTemplateFiles(Directory root) {
  validateRepositoryRoot(root);
  final files = <TemplateSourceFile>[];

  for (final path in templateAllowedFiles) {
    final file = fileFor(root, path);
    if (!file.existsSync()) {
      throw TemplateSyncException('Required template file is missing: $path');
    }
    _rejectUnsafePath(path);
    files.add(TemplateSourceFile(path: path, bytes: file.readAsBytesSync()));
  }

  for (final directoryPath in templateAllowedDirectories) {
    final directory = directoryFor(root, directoryPath);
    if (!directory.existsSync()) {
      throw TemplateSyncException(
        'Required template directory is missing: $directoryPath',
      );
    }
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final path = relativePath(root, entity);
      if (_isExcluded(path)) {
        continue;
      }
      _rejectUnsafePath(path);
      files.add(
        TemplateSourceFile(path: path, bytes: entity.readAsBytesSync()),
      );
    }
  }

  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

Uint8List buildDeterministicTarGz(List<TemplateSourceFile> files) {
  final sortedFiles = [...files]..sort((a, b) => a.path.compareTo(b.path));
  final tar = BytesBuilder(copy: false);
  for (final file in sortedFiles) {
    tar.add(_tarHeader(file));
    tar.add(file.bytes);
    final padding = _paddingFor(file.bytes.length);
    if (padding > 0) {
      tar.add(Uint8List(padding));
    }
  }
  tar
    ..add(Uint8List(_tarBlockSize))
    ..add(Uint8List(_tarBlockSize));
  return _stableGzipEncode(tar.takeBytes());
}

List<ExtractedTemplateFile> extractTarGz(List<int> archiveBytes) {
  final tarBytes = gzip.decode(archiveBytes);
  final files = <ExtractedTemplateFile>[];
  var offset = 0;
  while (offset + _tarBlockSize <= tarBytes.length) {
    final header = tarBytes.sublist(offset, offset + _tarBlockSize);
    offset += _tarBlockSize;
    if (header.every((byte) => byte == 0)) {
      break;
    }

    final path = _readNullTerminated(header, 0, 100);
    final prefix = _readNullTerminated(header, 345, 155);
    final fullPath = prefix.isEmpty ? path : '$prefix/$path';
    final size = int.parse(
      _readNullTerminated(header, 124, 12).trim().isEmpty
          ? '0'
          : _readNullTerminated(header, 124, 12).trim(),
      radix: 8,
    );
    final bytes = Uint8List.fromList(tarBytes.sublist(offset, offset + size));
    files.add(ExtractedTemplateFile(path: fullPath, bytes: bytes));
    offset += size + _paddingFor(size);
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

class ExtractedTemplateFile {
  const ExtractedTemplateFile({required this.path, required this.bytes});

  final String path;
  final Uint8List bytes;
}

Uint8List encodeManifest(TemplateManifest manifest) {
  const encoder = JsonEncoder.withIndent('  ');
  return Uint8List.fromList(
    utf8.encode('${encoder.convert(manifest.toJson())}\n'),
  );
}

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

File fileFor(Directory root, String relativePath) {
  return File(
    '${root.path}/${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

Directory directoryFor(Directory root, String relativePath) {
  return Directory(
    '${root.path}/${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

String relativePath(Directory root, FileSystemEntity entity) {
  final rootPath = root.absolute.path;
  final entityPath = entity.absolute.path;
  if (!entityPath.startsWith('$rootPath${Platform.pathSeparator}')) {
    return entityPath.replaceAll(Platform.pathSeparator, '/');
  }
  return entityPath
      .substring(rootPath.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

Uint8List _tarHeader(TemplateSourceFile file) {
  final header = Uint8List(_tarBlockSize);
  final pathParts = _splitTarPath(file.path);
  _writeString(header, 0, 100, pathParts.name);
  _writeOctal(header, 100, 8, int.parse('644', radix: 8));
  _writeOctal(header, 108, 8, 0);
  _writeOctal(header, 116, 8, 0);
  _writeOctal(header, 124, 12, file.bytes.length);
  _writeOctal(header, 136, 12, _fixedTarModifiedTime);
  for (var i = 148; i < 156; i += 1) {
    header[i] = 0x20;
  }
  header[156] = '0'.codeUnitAt(0);
  _writeString(header, 257, 6, 'ustar');
  _writeString(header, 263, 2, '00');
  _writeString(header, 265, 32, 'root');
  _writeString(header, 297, 32, 'root');
  if (pathParts.prefix.isNotEmpty) {
    _writeString(header, 345, 155, pathParts.prefix);
  }

  var checksum = 0;
  for (final byte in header) {
    checksum += byte;
  }
  final checksumText = checksum.toRadixString(8).padLeft(6, '0');
  _writeString(header, 148, 6, checksumText);
  header[154] = 0;
  header[155] = 0x20;
  return header;
}

({String name, String prefix}) _splitTarPath(String path) {
  final encoded = utf8.encode(path);
  if (encoded.length <= 100) {
    return (name: path, prefix: '');
  }

  final slashIndexes = <int>[];
  for (var i = 0; i < path.length; i += 1) {
    if (path.codeUnitAt(i) == '/'.codeUnitAt(0)) {
      slashIndexes.add(i);
    }
  }
  for (final index in slashIndexes.reversed) {
    final prefix = path.substring(0, index);
    final name = path.substring(index + 1);
    if (utf8.encode(prefix).length <= 155 && utf8.encode(name).length <= 100) {
      return (name: name, prefix: prefix);
    }
  }
  throw TemplateSyncException('Template path is too long for ustar: $path');
}

void _writeString(Uint8List output, int offset, int length, String value) {
  final bytes = utf8.encode(value);
  if (bytes.length > length) {
    throw TemplateSyncException('Value is too long for tar header: $value');
  }
  output.setRange(offset, offset + bytes.length, bytes);
}

void _writeOctal(Uint8List output, int offset, int length, int value) {
  final text = value.toRadixString(8).padLeft(length - 1, '0');
  _writeString(output, offset, length - 1, text);
  output[offset + length - 1] = 0;
}

int _paddingFor(int size) {
  final remainder = size % _tarBlockSize;
  return remainder == 0 ? 0 : _tarBlockSize - remainder;
}

String _readNullTerminated(List<int> bytes, int offset, int length) {
  final end = offset + length;
  var actualEnd = offset;
  while (actualEnd < end && bytes[actualEnd] != 0) {
    actualEnd += 1;
  }
  return utf8.decode(bytes.sublist(offset, actualEnd));
}

bool _isExcluded(String path) {
  if (path == 'test/tool/bootstrap_test.dart') {
    return true;
  }
  final segments = path.split('/');
  if (segments.contains('.dart_tool') ||
      segments.contains('build') ||
      segments.contains('coverage') ||
      segments.contains('.pub') ||
      segments.contains('.pub-cache') ||
      segments.contains('Pods') ||
      segments.contains('.symlinks') ||
      segments.contains('ephemeral')) {
    return true;
  }
  if (path.endsWith('/local.properties') ||
      path == 'android/local.properties' ||
      path.endsWith('/.last_build_id') ||
      path.endsWith('/Generated.xcconfig') ||
      path.endsWith('/flutter_export_environment.sh') ||
      path.contains('/GeneratedPluginRegistrant.') ||
      path.endsWith('/.DS_Store') ||
      path.endsWith('.env') ||
      path.contains('/.env.') ||
      path.contains('/env/')) {
    return true;
  }
  return false;
}

void _rejectUnsafePath(String path) {
  if (path.startsWith('/') ||
      path.contains('\\') ||
      path.split('/').contains('..') ||
      path.contains('/.git/') ||
      path.startsWith('.git/') ||
      path.startsWith('packages/cuboid/') ||
      path.startsWith('tool/')) {
    throw TemplateSyncException('Unsafe or disallowed template path: $path');
  }
  if (path.contains('/env/') ||
      path.startsWith('env/') ||
      path.endsWith('.env') ||
      path.contains('/.env') ||
      path.endsWith('local.properties')) {
    throw TemplateSyncException('Secret or local file rejected: $path');
  }
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _listEqual(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

Uint8List _stableGzipEncode(List<int> bytes) {
  final output = BytesBuilder(copy: false)
    ..add([0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff])
    ..add(ZLibEncoder(raw: true).convert(bytes));

  final crc = _crc32(bytes);
  output
    ..add([
      crc & 0xff,
      (crc >> 8) & 0xff,
      (crc >> 16) & 0xff,
      (crc >> 24) & 0xff,
    ])
    ..add([
      bytes.length & 0xff,
      (bytes.length >> 8) & 0xff,
      (bytes.length >> 16) & 0xff,
      (bytes.length >> 24) & 0xff,
    ]);
  return output.takeBytes();
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc = _crc32Table[(crc ^ byte) & 0xff] ^ (crc >> 8);
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

final _crc32Table = List<int>.generate(256, (index) {
  var crc = index;
  for (var bit = 0; bit < 8; bit += 1) {
    if (crc & 1 == 1) {
      crc = 0xedb88320 ^ (crc >> 1);
    } else {
      crc >>= 1;
    }
  }
  return crc;
}, growable: false);
