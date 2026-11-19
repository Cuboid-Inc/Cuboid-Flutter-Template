/// Loads and verifies the template payload compiled into this CLI binary
/// (see `template_payload.g.dart`) -- the single source of truth any
/// migration that *adds* a template-owned file reads from (see
/// `migrate/migrations/media_tools_migration.dart`), so a file `cuboid
/// upgrade` writes into an existing project is always byte-identical to the
/// same file in a project `cuboid create app` generates fresh.
library;

import 'dart:convert';

import 'package:cuboid/src/templates/flutter_app/template_payload.g.dart'
    as embedded_payload;
import 'package:cuboid/src/templates/flutter_app/template_sync.dart';

class BundledTemplateException implements Exception {
  const BundledTemplateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The decoded, verified contents of this CLI's bundled template.
class BundledTemplatePayload {
  const BundledTemplatePayload({required this.manifest, required this.files});

  final TemplateManifest manifest;
  final List<ExtractedTemplateFile> files;

  /// Decodes the UTF-8 contents of the template file at [path] (the
  /// template-relative, forward-slash path, e.g.
  /// `lib/app/app.snackbars.dart`), or returns `null` if the bundled
  /// template has no such file.
  String? utf8ContentsOf(String path) {
    for (final file in files) {
      if (file.path == path) {
        return utf8.decode(file.bytes);
      }
    }
    return null;
  }
}

BundledTemplatePayload? _cached;

/// Loads and SHA-256-verifies the payload embedded in this CLI binary.
/// Cached after the first call -- the bundled payload is immutable for the
/// lifetime of a single CLI invocation. Throws [BundledTemplateException]
/// if the embedded archive fails verification or cannot be decoded, which
/// would indicate a corrupted CLI build rather than anything about the
/// project being inspected.
BundledTemplatePayload loadBundledTemplatePayload() {
  final cached = _cached;
  if (cached != null) {
    return cached;
  }

  final manifestBytes = base64Decode(
    embedded_payload.templateManifestJsonBase64,
  );
  final archiveBytes = base64Decode(embedded_payload.templateArchiveBase64);
  final manifest = TemplateManifest.fromJson(
    jsonDecode(utf8.decode(manifestBytes)) as Map<String, Object?>,
  );
  if (sha256Hex(archiveBytes) != manifest.archiveSha256) {
    throw const BundledTemplateException(
      'Bundled template archive failed SHA-256 verification.',
    );
  }

  final List<ExtractedTemplateFile> files;
  try {
    files = extractTarGz(archiveBytes);
  } on FormatException {
    throw const BundledTemplateException(
      'Bundled template archive is invalid.',
    );
  }

  final payload = BundledTemplatePayload(manifest: manifest, files: files);
  _cached = payload;
  return payload;
}
