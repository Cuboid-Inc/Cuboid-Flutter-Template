import 'dart:io';

const oldDartProjectName = 'cuboid_flutter_template';
const oldDisplayName = 'Cuboid Flutter Template';
const oldProductName = 'Cuboid Flutter Template';
const oldPackageIdentifier = 'com.cuboidllc.cuboid_flutter_template';
const oldStorageNamespace = 'cuboid_flutter_template';
const oldKotlinPackagePath = 'com/cuboidllc/cuboid_flutter_template';

const bootstrapGeneratedFiles = {
  'lib/app/app.locator.dart',
  'lib/app/app.logger.dart',
  'lib/app/app.router.dart',
};

const bootstrapManualConfiguration = [
  'Supabase project_id in supabase/config.toml.',
  'Supabase hosted project URL, anon key, and publishable keys in env files.',
  'Launcher icon and splash image artwork, if the new app needs different branding.',
  'Apple development team, signing, and provisioning settings.',
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

class BootstrapInput {
  const BootstrapInput({
    required this.displayName,
    required this.packageIdentifier,
  });

  final String displayName;
  final String packageIdentifier;
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

class BootstrapReplacement {
  const BootstrapReplacement({
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

class BootstrapMoveOperation {
  const BootstrapMoveOperation({
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

  final List<BootstrapReplacement> replacements;
  final List<BootstrapMoveOperation> moves;
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

class BootstrapValidationResult {
  const BootstrapValidationResult._(this.failures);

  const BootstrapValidationResult.success() : this._(const []);

  const BootstrapValidationResult.failure(List<String> failures)
    : this._(failures);

  final List<String> failures;

  bool get isValid => failures.isEmpty;
}

class BootstrapApplyResult {
  const BootstrapApplyResult({
    required this.modifiedFiles,
    required this.movedDirectories,
    required this.generatedFiles,
  });

  final List<String> modifiedFiles;
  final List<BootstrapMoveOperation> movedDirectories;
  final List<String> generatedFiles;
}

class BootstrapException implements Exception {
  const BootstrapException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef Replacement = BootstrapReplacement;
typedef MoveOperation = BootstrapMoveOperation;

BootstrapValidationResult validateBootstrapInput(BootstrapInput input) {
  final failures = <String>[];
  final name = input.displayName.trim();
  if (name.isEmpty) {
    failures.add('--name must not be empty.');
  } else {
    if (name.length > 80) {
      failures.add('--name must be 80 characters or fewer.');
    }
    if (RegExp(r'[\x00-\x1F<>:"/\\|?*]').hasMatch(name)) {
      failures.add('--name must be a normal human-readable application name.');
    }
    if (!RegExp(r'[A-Za-z0-9]').hasMatch(name)) {
      failures.add('--name must contain at least one letter or number.');
    }
  }

  failures.addAll(validatePackageIdentifierValue(input.packageIdentifier));

  if (failures.isEmpty) {
    return const BootstrapValidationResult.success();
  }
  return BootstrapValidationResult.failure(failures);
}

void ensureValidBootstrapInput(BootstrapInput input) {
  final result = validateBootstrapInput(input);
  if (!result.isValid) {
    throw BootstrapException(result.failures.first);
  }
}

List<String> validatePackageIdentifierValue(String packageIdentifier) {
  final failures = <String>[];
  final value = packageIdentifier.trim();
  if (value.isEmpty) {
    return const ['--package must not be empty.'];
  }
  if (value.contains(' ')) {
    failures.add('--package must not contain spaces.');
  }
  if (value.endsWith('.')) {
    failures.add('--package must not end with a dot.');
  }

  final parts = value.split('.');
  if (parts.length < 2) {
    failures.add(
      '--package must contain at least two dot-separated components.',
    );
  }

  final componentPattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]*$');
  for (final part in parts) {
    if (!componentPattern.hasMatch(part)) {
      failures.add(
        'Invalid package component "$part". Use letters, numbers, and underscores; start with a letter.',
      );
    }
  }
  return failures;
}

void validatePackageIdentifier(String packageIdentifier) {
  final failures = validatePackageIdentifierValue(packageIdentifier);
  if (failures.isNotEmpty) {
    throw BootstrapException(failures.first);
  }
}

BootstrapValues deriveBootstrapValues(BootstrapInput input) {
  ensureValidBootstrapInput(input);
  final dartProjectName = deriveProjectName(input.displayName);
  return BootstrapValues(
    displayName: input.displayName.trim(),
    dartProjectName: dartProjectName,
    packageIdentifier: input.packageIdentifier.trim(),
    storageNamespace: dartProjectName,
  );
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

BootstrapPlan planBootstrap(Directory root, BootstrapValues values) {
  final replacements = <BootstrapReplacement>[
    BootstrapReplacement(
      path: 'pubspec.yaml',
      oldValue: 'name: $oldDartProjectName',
      newValue: 'name: ${values.dartProjectName}',
      label: 'Dart project name',
      category: 'Project identity',
    ),
    BootstrapReplacement(
      path: 'pubspec.yaml',
      oldValue: 'description: "Template for Cuboid Flutter projects"',
      newValue:
          'description: "Flutter application created from the Cuboid Flutter Template"',
      label: 'description',
      category: 'Project identity',
    ),
    BootstrapReplacement(
      path: 'lib/core/constants/app_constants.dart',
      oldValue: "static const appName = '$oldDisplayName';",
      newValue:
          "static const appName = '${escapeDartString(values.displayName)}';",
      label: 'app display name',
      category: 'Project identity',
    ),
    BootstrapReplacement(
      path: 'lib/features/home/ui/views/home_view.dart',
      oldValue: "AppBar(title: const Text('$oldDisplayName'))",
      newValue:
          "AppBar(title: const Text('${escapeDartString(values.displayName)}'))",
      label: 'home view title',
      category: 'Project identity',
    ),
    BootstrapReplacement(
      path: 'lib/main.dart',
      oldValue: "'$oldDisplayName release build without Supabase config. '",
      newValue:
          "'${escapeDartString(values.displayName)} release build without Supabase config. '",
      label: 'release configuration error app name',
      category: 'Project identity',
    ),
    BootstrapReplacement(
      path: 'lib/core/constants/storage_keys.dart',
      oldValue:
          "static const supabaseSession = '${oldStorageNamespace}_supabase_session';",
      newValue:
          "static const supabaseSession = '${values.storageNamespace}_supabase_session';",
      label: 'Supabase session storage key',
      category: 'Project identity',
    ),
    BootstrapReplacement(
      path: 'lib/core/constants/storage_keys.dart',
      oldValue:
          "static const authStorageNamespace = '${oldStorageNamespace}_auth';",
      newValue:
          "static const authStorageNamespace = '${values.storageNamespace}_auth';",
      label: 'auth storage namespace',
      category: 'Project identity',
    ),
    BootstrapReplacement(
      path: 'android/app/build.gradle.kts',
      oldValue: 'namespace = "$oldPackageIdentifier"',
      newValue: 'namespace = "${values.packageIdentifier}"',
      label: 'Android namespace',
      category: 'Android',
    ),
    BootstrapReplacement(
      path: 'android/app/build.gradle.kts',
      oldValue: 'applicationId = "$oldPackageIdentifier"',
      newValue: 'applicationId = "${values.packageIdentifier}"',
      label: 'Android applicationId',
      category: 'Android',
    ),
    BootstrapReplacement(
      path: 'android/app/src/main/AndroidManifest.xml',
      oldValue: 'android:label="$oldDisplayName"',
      newValue: 'android:label="${escapeXmlAttribute(values.displayName)}"',
      label: 'Android app label',
      category: 'Android',
    ),
    BootstrapReplacement(
      path: 'android/app/src/main/AndroidManifest.xml',
      oldValue: 'android:scheme="$oldPackageIdentifier"',
      newValue: 'android:scheme="${values.packageIdentifier}"',
      label: 'Android auth callback scheme',
      category: 'Android',
    ),
    BootstrapReplacement(
      path: 'ios/Runner/Info.plist',
      oldValue: '<string>$oldDisplayName</string>',
      newValue: '<string>${escapeXmlText(values.displayName)}</string>',
      label: 'iOS display name',
      category: 'iOS',
    ),
    BootstrapReplacement(
      path: 'ios/Runner/Info.plist',
      oldValue: '<string>$oldPackageIdentifier</string>',
      newValue: '<string>${values.packageIdentifier}</string>',
      label: 'iOS URL scheme',
      category: 'iOS',
    ),
    BootstrapReplacement(
      path: 'ios/Runner.xcodeproj/project.pbxproj',
      oldValue:
          'INFOPLIST_KEY_CFBundleDisplayName = ${escapePbxprojValue(oldProductName)};',
      newValue:
          'INFOPLIST_KEY_CFBundleDisplayName = ${escapePbxprojValue(values.displayName)};',
      label: 'iOS project display name',
      category: 'iOS',
    ),
    BootstrapReplacement(
      path: 'ios/Runner.xcodeproj/project.pbxproj',
      oldValue: 'PRODUCT_BUNDLE_IDENTIFIER = $oldPackageIdentifier;',
      newValue: 'PRODUCT_BUNDLE_IDENTIFIER = ${values.packageIdentifier};',
      label: 'iOS bundle identifier',
      category: 'iOS',
    ),
    BootstrapReplacement(
      path: 'ios/Runner.xcodeproj/project.pbxproj',
      oldValue:
          'PRODUCT_BUNDLE_IDENTIFIER = $oldPackageIdentifier.RunnerTests;',
      newValue:
          'PRODUCT_BUNDLE_IDENTIFIER = ${values.packageIdentifier}.RunnerTests;',
      label: 'iOS test bundle identifier',
      category: 'iOS',
    ),
    BootstrapReplacement(
      path: 'supabase/config.toml',
      oldValue:
          'additional_redirect_urls = ["$oldPackageIdentifier://auth-callback"]',
      newValue:
          'additional_redirect_urls = ["${values.packageIdentifier}://auth-callback"]',
      label: 'Supabase auth redirect URL',
      category: 'Supabase',
    ),
    BootstrapReplacement(
      path: 'README.md',
      oldValue: '# $oldProductName',
      newValue: '# ${values.displayName}',
      label: 'README title',
      category: 'Documentation',
    ),
    BootstrapReplacement(
      path: 'README.md',
      oldValue:
          'Reusable Flutter + Stacked starter template for Cuboid applications.',
      newValue: 'This project was created from the Cuboid Flutter Template.',
      label: 'README app summary',
      category: 'Documentation',
    ),
    BootstrapReplacement(
      path: 'README.md',
      oldValue:
          'This repository is infrastructure for starting a new app. It is not a production\n'
          'domain application and does not contain application-specific business workflows,\n'
          'database schema, or repository/data layers.',
      newValue:
          'It is a Flutter application built with Stacked MVVM and Supabase. Replace this section with product-specific documentation when the generated application is ready.',
      label: 'README app description',
      category: 'Documentation',
    ),
    BootstrapReplacement(
      path: 'ARCHITECTURE.md',
      oldValue: '# $oldProductName Architecture',
      newValue: '# ${values.displayName} Architecture',
      label: 'architecture title',
      category: 'Documentation',
    ),
    BootstrapReplacement(
      path: 'RULES.md',
      oldValue: '$oldProductName DEVELOPMENT AND AI AGENT RULES',
      newValue: '${values.displayName} DEVELOPMENT AND AI AGENT RULES',
      label: 'rules title',
      category: 'Documentation',
    ),
    BootstrapReplacement(
      path: 'RULES.md',
      oldValue:
          'NAME-11. Use package:$oldDartProjectName imports in handwritten Dart until a\n'
          'generated app is bootstrapped to a new package name. Generated files are exempt.',
      newValue:
          'NAME-11. Use package:${values.dartProjectName} imports in handwritten Dart. Generated files\n'
          'are exempt.',
      label: 'rules package import guidance',
      category: 'Documentation',
    ),
    BootstrapReplacement(
      path: '.vscode/launch.json',
      oldValue: '$oldProductName - Debug',
      newValue: '${values.displayName} - Debug',
      label: 'VS Code debug launch name',
      category: 'Documentation',
    ),
    BootstrapReplacement(
      path: '.vscode/launch.json',
      oldValue: '$oldProductName - Release',
      newValue: '${values.displayName} - Release',
      label: 'VS Code release launch name',
      category: 'Documentation',
    ),
    BootstrapReplacement(
      path: '.vscode/launch.json',
      oldValue: '$oldProductName - Profile',
      newValue: '${values.displayName} - Profile',
      label: 'VS Code profile launch name',
      category: 'Documentation',
    ),
  ];

  replacements.addAll(_dartImportReplacements(root, values.dartProjectName));
  replacements.addAll(_kotlinReplacements(root, values.packageIdentifier));
  replacements.addAll(_widgetTestReplacements(root, values.displayName));

  final oldKotlinDir = directoryFor(
    root,
    'android/app/src/main/kotlin/$oldKotlinPackagePath',
  );
  final newKotlinPath =
      'android/app/src/main/kotlin/${values.packageIdentifier.replaceAll('.', '/')}';
  final newKotlinDir = directoryFor(root, newKotlinPath);
  final moves = <BootstrapMoveOperation>[];
  if (oldKotlinDir.existsSync() && oldKotlinDir.path != newKotlinDir.path) {
    moves.add(
      BootstrapMoveOperation(
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
    manualConfiguration: bootstrapManualConfiguration,
  );
}

BootstrapPlan createBootstrapPlan(Directory root, BootstrapValues values) =>
    planBootstrap(root, values);

List<BootstrapReplacement> _dartImportReplacements(
  Directory root,
  String dartProjectName,
) {
  final replacements = <BootstrapReplacement>[];
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
      if (bootstrapGeneratedFiles.contains(relativePath)) {
        continue;
      }
      final content = entity.readAsStringSync();
      if (containsDartPackageImport(content, oldDartProjectName)) {
        replacements.add(
          BootstrapReplacement(
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

List<BootstrapReplacement> _widgetTestReplacements(
  Directory root,
  String displayName,
) {
  final widgetTest = pathFor(root, 'test/widget_test.dart');
  if (!widgetTest.existsSync()) {
    return const [];
  }
  return [
    BootstrapReplacement(
      path: 'test/widget_test.dart',
      oldValue: "Text('$oldDisplayName')",
      newValue: "Text('${escapeDartString(displayName)}')",
      label: 'widget test display text',
      category: 'Project identity',
    ),
    BootstrapReplacement(
      path: 'test/widget_test.dart',
      oldValue: "find.text('$oldDisplayName')",
      newValue: "find.text('${escapeDartString(displayName)}')",
      label: 'widget test display assertion',
      category: 'Project identity',
    ),
  ];
}

List<BootstrapReplacement> _kotlinReplacements(
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
    BootstrapReplacement(
      path: 'android/app/src/main/kotlin/$oldKotlinPackagePath/MainActivity.kt',
      oldValue: 'package $oldPackageIdentifier',
      newValue: 'package $packageIdentifier',
      label: 'Kotlin package declaration',
      category: 'Android',
    ),
  ];
}

List<String> _existingGeneratedFiles(Directory root) {
  return bootstrapGeneratedFiles
      .where((path) => pathFor(root, path).existsSync())
      .toList()
    ..sort();
}

BootstrapValidationResult validateBootstrapPlan(
  Directory root,
  BootstrapPlan plan,
) {
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

  if (failures.isEmpty) {
    return const BootstrapValidationResult.success();
  }
  return BootstrapValidationResult.failure(failures);
}

void validatePlan(Directory root, BootstrapPlan plan) {
  final result = validateBootstrapPlan(root, plan);
  if (!result.isValid) {
    throw BootstrapException(
      [
        'Expected template values were missing. No files were modified.',
        ...result.failures.map((failure) => '- $failure'),
      ].join('\n'),
    );
  }
}

BootstrapApplyResult applyBootstrapPlan(Directory root, BootstrapPlan plan) {
  final byPath = <String, List<BootstrapReplacement>>{};
  for (final replacement in plan.replacements) {
    byPath.putIfAbsent(replacement.path, () => []).add(replacement);
  }

  final changedFiles = <String>[];
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
    changedFiles.add(entry.key);
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

  return BootstrapApplyResult(
    modifiedFiles: changedFiles..sort(),
    movedDirectories: plan.moves,
    generatedFiles: plan.generatedFiles,
  );
}

void applyPlan(Directory root, BootstrapPlan plan) {
  applyBootstrapPlan(root, plan);
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
