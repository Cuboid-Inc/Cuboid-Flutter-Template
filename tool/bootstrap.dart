import 'dart:io';

const oldDartProjectName = 'cuboid_flutter_template';
const oldDisplayName = 'Cuboid Flutter Template';
const oldProductName = 'Cuboid Flutter Template';
const oldPackageIdentifier = 'com.cuboidllc.cuboid_flutter_template';
const oldStorageNamespace = 'cuboid_flutter_template';
const oldKotlinPackagePath = 'com/cuboidllc/cuboid_flutter_template';

const generatedFiles = {
  'lib/app/app.locator.dart',
  'lib/app/app.logger.dart',
  'lib/app/app.router.dart',
};

const buildRunnerCommand = [
  'dart',
  'run',
  'build_runner',
  'build',
  '--delete-conflicting-outputs',
];

final dartKeywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'part',
  'required',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

class BootstrapArguments {
  const BootstrapArguments({
    required this.displayName,
    required this.packageIdentifier,
    required this.dryRun,
  });

  final String displayName;
  final String packageIdentifier;
  final bool dryRun;
}

class BootstrapValues {
  const BootstrapValues({
    required this.displayName,
    required this.dartProjectName,
    required this.packageIdentifier,
    required this.storageNamespace,
  });

  final String displayName;
  final String dartProjectName;
  final String packageIdentifier;
  final String storageNamespace;
}

class Replacement {
  const Replacement({
    required this.path,
    required this.oldValue,
    required this.newValue,
    required this.label,
    required this.category,
    this.dartImportOnly = false,
  });

  final String path;
  final String oldValue;
  final String newValue;
  final String label;
  final String category;
  final bool dartImportOnly;
}

class MoveOperation {
  const MoveOperation({
    required this.from,
    required this.to,
    required this.category,
    required this.label,
  });

  final String from;
  final String to;
  final String category;
  final String label;
}

class BootstrapPlan {
  const BootstrapPlan({
    required this.replacements,
    required this.moves,
    required this.generatedFiles,
    required this.manualConfiguration,
  });

  final List<Replacement> replacements;
  final List<MoveOperation> moves;
  final List<String> generatedFiles;
  final List<String> manualConfiguration;

  List<String> get modifiedFiles {
    final files = <String>{};
    for (final replacement in replacements) {
      files.add(replacement.path);
    }
    for (final move in moves) {
      files
        ..add(move.from)
        ..add(move.to);
    }
    files.addAll(generatedFiles);
    return files.toList()..sort();
  }
}

class BootstrapException implements Exception {
  const BootstrapException(this.message);

  final String message;

  @override
  String toString() => message;
}

void main(List<String> args) {
  try {
    final parsed = parseArguments(args);
    validateArguments(parsed);

    final values = BootstrapValues(
      displayName: parsed.displayName.trim(),
      dartProjectName: deriveProjectName(parsed.displayName),
      packageIdentifier: parsed.packageIdentifier.trim(),
      storageNamespace: deriveProjectName(parsed.displayName),
    );

    final root = Directory.current;
    final plan = createBootstrapPlan(root, values);
    validatePlan(root, plan);

    if (parsed.dryRun) {
      printDryRun(values, plan);
      return;
    }

    applyPlan(root, plan);
    printSummary(values, plan);
  } on BootstrapException catch (error) {
    stderr.writeln('Bootstrap failed: ${error.message}');
    exitCode = 64;
  }
}

BootstrapArguments parseArguments(List<String> args) {
  String? name;
  String? package;
  var dryRun = false;

  for (var i = 0; i < args.length; i += 1) {
    final arg = args[i];
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--name') {
      if (i + 1 >= args.length) {
        throw const BootstrapException('Missing value for --name.');
      }
      name = args[++i];
    } else if (arg == '--package') {
      if (i + 1 >= args.length) {
        throw const BootstrapException('Missing value for --package.');
      }
      package = args[++i];
    } else {
      throw BootstrapException('Unknown argument: $arg');
    }
  }

  if (name == null || package == null) {
    throw const BootstrapException('Required arguments: --name and --package.');
  }

  return BootstrapArguments(
    displayName: name,
    packageIdentifier: package,
    dryRun: dryRun,
  );
}

void validateArguments(BootstrapArguments args) {
  final name = args.displayName.trim();
  if (name.isEmpty) {
    throw const BootstrapException('--name must not be empty.');
  }
  if (name.length > 80) {
    throw const BootstrapException('--name must be 80 characters or fewer.');
  }
  if (RegExp(r'[\x00-\x1F<>:"/\\|?*]').hasMatch(name)) {
    throw const BootstrapException(
      '--name must be a normal human-readable application name.',
    );
  }
  if (!RegExp(r'[A-Za-z0-9]').hasMatch(name)) {
    throw const BootstrapException(
      '--name must contain at least one letter or number.',
    );
  }

  validatePackageIdentifier(args.packageIdentifier);
}

void validatePackageIdentifier(String packageIdentifier) {
  final value = packageIdentifier.trim();
  if (value.isEmpty) {
    throw const BootstrapException('--package must not be empty.');
  }
  if (value.contains(' ')) {
    throw const BootstrapException('--package must not contain spaces.');
  }
  if (value.endsWith('.')) {
    throw const BootstrapException('--package must not end with a dot.');
  }

  final parts = value.split('.');
  if (parts.length < 2) {
    throw const BootstrapException(
      '--package must contain at least two dot-separated components.',
    );
  }

  final componentPattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]*$');
  for (final part in parts) {
    if (!componentPattern.hasMatch(part)) {
      throw BootstrapException(
        'Invalid package component "$part". Use letters, numbers, and underscores; start with a letter.',
      );
    }
  }
}

String deriveProjectName(String displayName) {
  final words = RegExp(
    r'[A-Za-z0-9]+',
  ).allMatches(displayName).map((match) => match.group(0)!.toLowerCase());
  var projectName = words.join('_');
  projectName = projectName.replaceAll(RegExp(r'_+'), '_');

  if (projectName.isEmpty) {
    throw const BootstrapException(
      'Could not derive a Dart project name from --name.',
    );
  }
  if (RegExp(r'^[0-9]').hasMatch(projectName)) {
    projectName = 'app_$projectName';
  }
  if (dartKeywords.contains(projectName)) {
    projectName = '${projectName}_app';
  }

  return projectName;
}

BootstrapPlan createBootstrapPlan(Directory root, BootstrapValues values) {
  final replacements = <Replacement>[
    Replacement(
      path: 'pubspec.yaml',
      oldValue: 'name: $oldDartProjectName',
      newValue: 'name: ${values.dartProjectName}',
      label: 'Dart project name',
      category: 'Project identity',
    ),
    Replacement(
      path: 'pubspec.yaml',
      oldValue: 'description: "Template for Cuboid Flutter projects"',
      newValue:
          'description: "Flutter application created from the Cuboid Flutter Template"',
      label: 'description',
      category: 'Project identity',
    ),
    Replacement(
      path: 'lib/core/constants/app_constants.dart',
      oldValue: "static const appName = '$oldDisplayName';",
      newValue:
          "static const appName = '${escapeDartString(values.displayName)}';",
      label: 'app display name',
      category: 'Project identity',
    ),
    Replacement(
      path: 'lib/core/constants/storage_keys.dart',
      oldValue:
          "static const supabaseSession = '${oldStorageNamespace}_supabase_session';",
      newValue:
          "static const supabaseSession = '${values.storageNamespace}_supabase_session';",
      label: 'Supabase session storage key',
      category: 'Project identity',
    ),
    Replacement(
      path: 'lib/core/constants/storage_keys.dart',
      oldValue:
          "static const authStorageNamespace = '${oldStorageNamespace}_auth';",
      newValue:
          "static const authStorageNamespace = '${values.storageNamespace}_auth';",
      label: 'auth storage namespace',
      category: 'Project identity',
    ),
    Replacement(
      path: 'android/app/build.gradle.kts',
      oldValue: 'namespace = "$oldPackageIdentifier"',
      newValue: 'namespace = "${values.packageIdentifier}"',
      label: 'Android namespace',
      category: 'Android',
    ),
    Replacement(
      path: 'android/app/build.gradle.kts',
      oldValue: 'applicationId = "$oldPackageIdentifier"',
      newValue: 'applicationId = "${values.packageIdentifier}"',
      label: 'Android applicationId',
      category: 'Android',
    ),
    Replacement(
      path: 'android/app/src/main/AndroidManifest.xml',
      oldValue: 'android:label="$oldDisplayName"',
      newValue: 'android:label="${escapeXmlAttribute(values.displayName)}"',
      label: 'Android app label',
      category: 'Android',
    ),
    Replacement(
      path: 'android/app/src/main/AndroidManifest.xml',
      oldValue: 'android:scheme="$oldPackageIdentifier"',
      newValue: 'android:scheme="${values.packageIdentifier}"',
      label: 'Android auth callback scheme',
      category: 'Android',
    ),
    Replacement(
      path: 'ios/Runner/Info.plist',
      oldValue: '<string>$oldDisplayName</string>',
      newValue: '<string>${escapeXmlText(values.displayName)}</string>',
      label: 'iOS display name',
      category: 'iOS',
    ),
    Replacement(
      path: 'ios/Runner/Info.plist',
      oldValue: '<string>$oldPackageIdentifier</string>',
      newValue: '<string>${values.packageIdentifier}</string>',
      label: 'iOS URL scheme',
      category: 'iOS',
    ),
    Replacement(
      path: 'ios/Runner.xcodeproj/project.pbxproj',
      oldValue:
          'INFOPLIST_KEY_CFBundleDisplayName = ${escapePbxprojValue(oldProductName)};',
      newValue:
          'INFOPLIST_KEY_CFBundleDisplayName = ${escapePbxprojValue(values.displayName)};',
      label: 'iOS project display name',
      category: 'iOS',
    ),
    Replacement(
      path: 'ios/Runner.xcodeproj/project.pbxproj',
      oldValue: 'PRODUCT_BUNDLE_IDENTIFIER = $oldPackageIdentifier;',
      newValue: 'PRODUCT_BUNDLE_IDENTIFIER = ${values.packageIdentifier};',
      label: 'iOS bundle identifier',
      category: 'iOS',
    ),
    Replacement(
      path: 'ios/Runner.xcodeproj/project.pbxproj',
      oldValue:
          'PRODUCT_BUNDLE_IDENTIFIER = $oldPackageIdentifier.RunnerTests;',
      newValue:
          'PRODUCT_BUNDLE_IDENTIFIER = ${values.packageIdentifier}.RunnerTests;',
      label: 'iOS test bundle identifier',
      category: 'iOS',
    ),
    Replacement(
      path: 'supabase/config.toml',
      oldValue:
          'additional_redirect_urls = ["$oldPackageIdentifier://auth-callback"]',
      newValue:
          'additional_redirect_urls = ["${values.packageIdentifier}://auth-callback"]',
      label: 'Supabase auth redirect URL',
      category: 'Supabase',
    ),
    Replacement(
      path: 'supabase/functions/invite-staff/index.ts',
      oldValue: "const redirectTo = '$oldPackageIdentifier://auth-callback'",
      newValue:
          "const redirectTo = '${values.packageIdentifier}://auth-callback'",
      label: 'Supabase invite staff auth redirect URL',
      category: 'Supabase',
    ),
    Replacement(
      path: 'README.md',
      oldValue: '# $oldProductName',
      newValue: '# ${values.displayName}',
      label: 'README title',
      category: 'Documentation',
    ),
    Replacement(
      path: 'README.md',
      oldValue: 'Reusable Flutter starter for Cuboid applications.',
      newValue: 'This project was created from the Cuboid Flutter Template.',
      label: 'README app summary',
      category: 'Documentation',
    ),
    Replacement(
      path: 'README.md',
      oldValue:
          'This template is built with Stacked MVVM and Supabase. Use `tool/bootstrap.dart` to create an application-specific project identity before product development.',
      newValue:
          'It is a Flutter application built with Stacked MVVM and Supabase. Replace this section with product-specific documentation when the generated application is ready.',
      label: 'README app description',
      category: 'Documentation',
    ),
    Replacement(
      path: '.vscode/launch.json',
      oldValue: '$oldProductName - Debug',
      newValue: '${values.displayName} - Debug',
      label: 'VS Code debug launch name',
      category: 'Documentation',
    ),
    Replacement(
      path: '.vscode/launch.json',
      oldValue: '$oldProductName - Release',
      newValue: '${values.displayName} - Release',
      label: 'VS Code release launch name',
      category: 'Documentation',
    ),
    Replacement(
      path: '.vscode/launch.json',
      oldValue: '$oldProductName - Profile',
      newValue: '${values.displayName} - Profile',
      label: 'VS Code profile launch name',
      category: 'Documentation',
    ),
  ];

  replacements.addAll(_dartImportReplacements(root, values.dartProjectName));
  replacements.addAll(_kotlinReplacements(root, values.packageIdentifier));

  final oldKotlinDir = directoryFor(
    root,
    'android/app/src/main/kotlin/$oldKotlinPackagePath',
  );
  final newKotlinPath =
      'android/app/src/main/kotlin/${values.packageIdentifier.replaceAll('.', '/')}';
  final newKotlinDir = directoryFor(root, newKotlinPath);
  final moves = <MoveOperation>[];
  if (oldKotlinDir.existsSync() && oldKotlinDir.path != newKotlinDir.path) {
    moves.add(
      MoveOperation(
        from: 'android/app/src/main/kotlin/$oldKotlinPackagePath',
        to: newKotlinPath,
        category: 'Android',
        label: 'Kotlin package directory',
      ),
    );
  }

  return BootstrapPlan(
    replacements: replacements,
    moves: moves,
    generatedFiles: _existingGeneratedFiles(root),
    manualConfiguration: const [
      'Supabase project_id in supabase/config.toml.',
      'Supabase hosted project URL, anon key, and publishable keys in env files.',
      'Supabase helper script production URLs and secret-key environment variables.',
      'Launcher icon and splash image artwork, if the new app needs different branding.',
      'Apple development team, signing, and provisioning settings.',
    ],
  );
}

List<Replacement> _dartImportReplacements(
  Directory root,
  String dartProjectName,
) {
  final replacements = <Replacement>[];
  for (final directoryName in const ['lib', 'test']) {
    final directory = directoryFor(root, directoryName);
    if (!directory.existsSync()) {
      continue;
    }
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final relativePath = relativeTo(root, entity);
      if (generatedFiles.contains(relativePath)) {
        continue;
      }
      final content = entity.readAsStringSync();
      if (containsDartPackageImport(content, oldDartProjectName)) {
        replacements.add(
          Replacement(
            path: relativePath,
            oldValue: 'package:$oldDartProjectName/',
            newValue: 'package:$dartProjectName/',
            label: 'Dart package import',
            category: 'Dart',
            dartImportOnly: true,
          ),
        );
      }
    }
  }
  return replacements;
}

List<Replacement> _kotlinReplacements(
  Directory root,
  String packageIdentifier,
) {
  final mainActivity = pathFor(
    root,
    'android/app/src/main/kotlin/$oldKotlinPackagePath/MainActivity.kt',
  );
  if (!mainActivity.existsSync()) {
    return const [];
  }
  return [
    Replacement(
      path: 'android/app/src/main/kotlin/$oldKotlinPackagePath/MainActivity.kt',
      oldValue: 'package $oldPackageIdentifier',
      newValue: 'package $packageIdentifier',
      label: 'Kotlin package declaration',
      category: 'Android',
    ),
  ];
}

List<String> _existingGeneratedFiles(Directory root) {
  return generatedFiles
      .where((path) => pathFor(root, path).existsSync())
      .toList()
    ..sort();
}

void validatePlan(Directory root, BootstrapPlan plan) {
  final failures = <String>[];

  for (final replacement in plan.replacements) {
    final file = pathFor(root, replacement.path);
    if (!file.existsSync()) {
      failures.add('${replacement.path}: file not found.');
      continue;
    }

    final content = file.readAsStringSync();
    final hasExpectedValue = replacement.dartImportOnly
        ? containsDartPackageImport(content, oldDartProjectName)
        : content.contains(replacement.oldValue);
    if (!hasExpectedValue) {
      failures.add(
        '${replacement.path}: expected ${replacement.label} value was not found.',
      );
    }
  }

  for (final move in plan.moves) {
    final from = directoryFor(root, move.from);
    final to = directoryFor(root, move.to);
    if (!from.existsSync()) {
      failures.add(
        '${move.from}: source directory for package move not found.',
      );
    }
    if (to.existsSync()) {
      failures.add('${move.to}: target package directory already exists.');
    }
  }

  if (failures.isNotEmpty) {
    throw BootstrapException(
      [
        'Expected template values were missing. No files were modified.',
        ...failures.map((failure) => '- $failure'),
      ].join('\n'),
    );
  }
}

void applyPlan(Directory root, BootstrapPlan plan) {
  final byPath = <String, List<Replacement>>{};
  for (final replacement in plan.replacements) {
    byPath.putIfAbsent(replacement.path, () => []).add(replacement);
  }

  for (final entry in byPath.entries) {
    final file = pathFor(root, entry.key);
    var content = file.readAsStringSync();
    for (final replacement in entry.value) {
      content = replacement.dartImportOnly
          ? replaceDartPackageImportsInContent(
              content,
              oldDartProjectName,
              replacement.newValue
                  .substring('package:'.length)
                  .replaceAll('/', ''),
              context: '${replacement.path} (${replacement.label})',
            )
          : replaceExactInContent(
              content,
              replacement.oldValue,
              replacement.newValue,
              context: '${replacement.path} (${replacement.label})',
            );
    }
    file.writeAsStringSync(content);
  }

  for (final move in plan.moves) {
    final from = directoryFor(root, move.from);
    final to = directoryFor(root, move.to);
    to.parent.createSync(recursive: true);
    from.renameSync(to.path);
    removeEmptyParentDirectories(
      from.parent,
      directoryFor(root, 'android/app/src/main/kotlin'),
    );
  }

  regenerateGeneratedFiles(root);
}

void regenerateGeneratedFiles(Directory root) {
  final result = Process.runSync(
    buildRunnerCommand.first,
    buildRunnerCommand.skip(1).toList(),
    workingDirectory: root.path,
    runInShell: false,
  );

  if (result.exitCode != 0) {
    throw BootstrapException(
      [
        'Generated file regeneration failed.',
        'Command: ${buildRunnerCommand.join(' ')}',
        if ((result.stdout as String).trim().isNotEmpty)
          'stdout:\n${(result.stdout as String).trim()}',
        if ((result.stderr as String).trim().isNotEmpty)
          'stderr:\n${(result.stderr as String).trim()}',
      ].join('\n'),
    );
  }
}

String replaceExactInContent(
  String content,
  String oldValue,
  String newValue, {
  String context = 'replacement',
}) {
  if (!content.contains(oldValue)) {
    throw BootstrapException('Expected value missing for $context.');
  }
  return content.replaceAll(oldValue, newValue);
}

bool containsDartPackageImport(String content, String projectName) {
  return _replaceDartPackageImportLines(
    content,
    projectName,
    projectName,
  ).changed;
}

String replaceDartPackageImportsInContent(
  String content,
  String oldProjectName,
  String newProjectName, {
  String context = 'Dart package imports',
}) {
  final result = _replaceDartPackageImportLines(
    content,
    oldProjectName,
    newProjectName,
  );
  if (!result.changed) {
    throw BootstrapException('Expected value missing for $context.');
  }
  return result.content;
}

({String content, bool changed}) _replaceDartPackageImportLines(
  String content,
  String oldProjectName,
  String newProjectName,
) {
  final pattern = RegExp(
    '^(\\s*import\\s+[\\\'"])package:${RegExp.escape(oldProjectName)}/',
  );
  final output = StringBuffer();
  var changed = false;
  var inBlockComment = false;
  var inTripleSingleString = false;
  var inTripleDoubleString = false;

  final lines = content.split('\n');
  for (var index = 0; index < lines.length; index += 1) {
    var line = lines[index];
    final wasInsideMultiline =
        inBlockComment || inTripleSingleString || inTripleDoubleString;

    if (!wasInsideMultiline) {
      final replaced = line.replaceFirstMapped(pattern, (match) {
        changed = true;
        return '${match.group(1)}package:$newProjectName/';
      });
      line = replaced;
    }

    output.write(line);
    if (index < lines.length - 1) {
      output.write('\n');
    }

    final stateLine = _withoutLineComment(line);
    if (!inBlockComment &&
        !inTripleDoubleString &&
        _hasOddOccurrences(stateLine, "'''")) {
      inTripleSingleString = !inTripleSingleString;
    }
    if (!inBlockComment &&
        !inTripleSingleString &&
        _hasOddOccurrences(stateLine, '"""')) {
      inTripleDoubleString = !inTripleDoubleString;
    }
    if (!inTripleSingleString && !inTripleDoubleString) {
      inBlockComment = _nextBlockCommentState(stateLine, inBlockComment);
    }
  }

  return (content: output.toString(), changed: changed);
}

String _withoutLineComment(String line) {
  final commentIndex = line.indexOf('//');
  if (commentIndex == -1) {
    return line;
  }
  return line.substring(0, commentIndex);
}

bool _hasOddOccurrences(String line, String needle) {
  var count = 0;
  var index = line.indexOf(needle);
  while (index != -1) {
    count += 1;
    index = line.indexOf(needle, index + needle.length);
  }
  return count.isOdd;
}

bool _nextBlockCommentState(String line, bool startsInBlockComment) {
  var inBlockComment = startsInBlockComment;
  var index = 0;
  while (index < line.length) {
    if (inBlockComment) {
      final end = line.indexOf('*/', index);
      if (end == -1) {
        return true;
      }
      inBlockComment = false;
      index = end + 2;
    } else {
      final start = line.indexOf('/*', index);
      if (start == -1) {
        return false;
      }
      inBlockComment = true;
      index = start + 2;
    }
  }
  return inBlockComment;
}

void printDryRun(BootstrapValues values, BootstrapPlan plan) {
  stdout.write(buildDryRunReport(values, plan));
}

String buildDryRunReport(BootstrapValues values, BootstrapPlan plan) {
  final output = StringBuffer();
  output.writeln('Dry run complete. No files were modified.');
  output.writeln('');
  _writeIdentity(output, values);

  for (final category in const [
    'Project identity',
    'Dart',
    'Android',
    'iOS',
    'Supabase',
    'Documentation',
    'Generated files',
    'Manual configuration',
  ]) {
    output.writeln('');
    output.writeln('$category:');
    if (category == 'Generated files') {
      _writeGeneratedFiles(output, plan);
    } else if (category == 'Manual configuration') {
      _writeManualConfigurationItems(output, plan);
    } else {
      _writeCategoryChanges(output, plan, category);
    }
  }

  output.writeln('');
  output.writeln('Files that would be modified:');
  for (final file in plan.modifiedFiles) {
    output.writeln('- $file');
  }
  _writeNextCommands(output);
  return output.toString();
}

void printSummary(BootstrapValues values, BootstrapPlan plan) {
  stdout.writeln('Bootstrap complete.');
  stdout.writeln('');
  _printIdentity(values);
  stdout.writeln('');
  stdout.writeln('Modified files:');
  for (final file in plan.modifiedFiles) {
    stdout.writeln('- $file');
  }
  if (plan.generatedFiles.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('Regenerated generated files with:');
    stdout.writeln(buildRunnerCommand.join(' '));
  }
  _printManualConfiguration(plan);
  _printNextCommands();
}

void _printIdentity(BootstrapValues values) {
  _writeIdentity(stdout, values);
}

void _writeIdentity(StringSink output, BootstrapValues values) {
  output.writeln('Project name: ${values.dartProjectName}');
  output.writeln('Display name: ${values.displayName}');
  output.writeln('Package identifier: ${values.packageIdentifier}');
}

void _printManualConfiguration(BootstrapPlan plan) {
  stdout.writeln('');
  stdout.writeln('Manual configuration still required:');
  _writeManualConfigurationItems(stdout, plan);
}

void _writeManualConfigurationItems(StringSink output, BootstrapPlan plan) {
  for (final item in plan.manualConfiguration) {
    output.writeln('- $item');
  }
}

void _writeCategoryChanges(
  StringSink output,
  BootstrapPlan plan,
  String category,
) {
  var printed = false;
  for (final replacement in plan.replacements) {
    if (replacement.category != category) {
      continue;
    }
    printed = true;
    output.writeln('- ${replacement.path}: ${replacement.label}');
    output.writeln('  old: ${replacement.oldValue}');
    output.writeln('  new: ${replacement.newValue}');
  }
  for (final move in plan.moves) {
    if (move.category != category) {
      continue;
    }
    printed = true;
    output.writeln('- ${move.label}: ${move.from} -> ${move.to}');
  }
  if (!printed) {
    output.writeln('- No deterministic changes planned.');
  }
}

void _writeGeneratedFiles(StringSink output, BootstrapPlan plan) {
  if (plan.generatedFiles.isEmpty) {
    output.writeln('- No existing generated Stacked files found.');
    return;
  }
  output.writeln('- Regenerate using: ${buildRunnerCommand.join(' ')}');
  for (final file in plan.generatedFiles) {
    output.writeln('- $file');
  }
}

void _printNextCommands() {
  _writeNextCommands(stdout);
}

void _writeNextCommands(StringSink output) {
  output.writeln('');
  output.writeln('Next commands:');
  output.writeln('flutter pub get');
  output.writeln('dart run build_runner build --delete-conflicting-outputs');
  output.writeln('flutter clean');
  output.writeln('flutter run');
}

File pathFor(Directory root, String relativePath) {
  return File(
    '${root.path}/${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

Directory directoryFor(Directory root, String relativePath) {
  return Directory(
    '${root.path}/${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

String relativeTo(Directory root, FileSystemEntity entity) {
  final rootPath = root.absolute.path;
  final entityPath = entity.absolute.path;
  if (!entityPath.startsWith('$rootPath${Platform.pathSeparator}')) {
    return entityPath;
  }
  return entityPath
      .substring(rootPath.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

void removeEmptyParentDirectories(Directory start, Directory boundary) {
  var current = start;
  final boundaryPath = boundary.absolute.path;
  while (current.absolute.path.startsWith(boundaryPath) &&
      current.absolute.path != boundaryPath) {
    if (current.listSync().isNotEmpty) {
      return;
    }
    final parent = current.parent;
    current.deleteSync();
    current = parent;
  }
}

String escapeDartString(String value) =>
    value.replaceAll('\\', r'\\').replaceAll("'", r"\'");

String escapeXmlText(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String escapeXmlAttribute(String value) =>
    escapeXmlText(value).replaceAll('"', '&quot;');

String escapePbxprojValue(String value) {
  if (RegExp(r'^[A-Za-z0-9_]+$').hasMatch(value)) {
    return value;
  }
  return '"${value.replaceAll('\\', r'\\').replaceAll('"', r'\"')}"';
}
