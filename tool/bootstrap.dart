import 'dart:io';

// ignore: avoid_relative_lib_imports
import '../packages/cuboid/lib/src/bootstrap/bootstrap.dart';

class BootstrapArguments {
  const BootstrapArguments({
    required this.displayName,
    required this.packageIdentifier,
    required this.dryRun,
    required this.help,
  });

  final String displayName;
  final String packageIdentifier;
  final bool dryRun;
  final bool help;
}

void main(List<String> args) {
  try {
    final parsed = parseArguments(args);
    if (parsed.help) {
      printUsage();
      return;
    }

    validateArguments(parsed);

    final values = deriveBootstrapValues(
      BootstrapInput(
        displayName: parsed.displayName,
        packageIdentifier: parsed.packageIdentifier,
      ),
    );

    final root = Directory.current;
    final plan = planBootstrap(root, values);
    validatePlan(root, plan);

    if (parsed.dryRun) {
      printDryRun(values, plan);
      return;
    }

    applyBootstrapPlan(root, plan);
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
  var help = false;

  for (var i = 0; i < args.length; i += 1) {
    final arg = args[i];
    if (arg == '--help') {
      help = true;
    } else if (arg == '--dry-run') {
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

  if (!help && name == null) {
    throw const BootstrapException('Missing required argument: --name.');
  }
  if (!help && package == null) {
    throw const BootstrapException('Missing required argument: --package.');
  }

  if (help) {
    return BootstrapArguments(
      displayName: name ?? '',
      packageIdentifier: package ?? '',
      dryRun: dryRun,
      help: help,
    );
  }

  if (name == null || package == null) {
    throw const BootstrapException('Required arguments: --name and --package.');
  }

  return BootstrapArguments(
    displayName: name,
    packageIdentifier: package,
    dryRun: dryRun,
    help: help,
  );
}

void validateArguments(BootstrapArguments args) {
  ensureValidBootstrapInput(
    BootstrapInput(
      displayName: args.displayName,
      packageIdentifier: args.packageIdentifier,
    ),
  );
}

void printDryRun(BootstrapValues values, BootstrapPlan plan) {
  stdout.write(buildDryRunReport(values, plan));
}

void printUsage() {
  stdout.write(buildUsage());
}

String buildUsage() {
  return '''
Usage:
dart run tool/bootstrap.dart --name "App Name" --package "com.example.app" [--dry-run]

Options:
--name       Human-readable application name.
--package    Application package identifier.
--dry-run    Print planned changes without modifying files.
--help       Print this help text.
''';
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
    'Documentation',
    'Manual configuration',
  ]) {
    output.writeln('');
    output.writeln('$category:');
    if (category == 'Manual configuration') {
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

void _printNextCommands() {
  _writeNextCommands(stdout);
}

void _writeNextCommands(StringSink output) {
  output.writeln('');
  output.writeln('Next commands:');
  output.writeln('flutter pub get');
  output.writeln('flutter clean');
  output.writeln('flutter run');
}
