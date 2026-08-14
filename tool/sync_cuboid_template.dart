import 'dart:io';

// ignore: avoid_relative_lib_imports
import '../packages/cuboid/lib/src/templates/flutter_app/template_sync.dart';

Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  final allowDirty = arguments.contains('--allow-dirty');
  final help = arguments.contains('--help') || arguments.contains('-h');
  final unknown = arguments.where((argument) {
    return !{'--check', '--allow-dirty', '--help', '-h'}.contains(argument);
  }).toList();

  if (help) {
    stdout.write(_usage);
    return;
  }
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown argument: ${unknown.first}');
    stderr.write(_usage);
    exitCode = 64;
    return;
  }

  final root = Directory.current;
  try {
    if (check) {
      final result = await checkTemplatePayload(root, allowDirty: allowDirty);
      if (result.inSync) {
        stdout.writeln('Cuboid Flutter template payload is in sync.');
        return;
      }
      stderr.writeln('Cuboid Flutter template payload is stale.');
      for (final failure in result.failures) {
        stderr.writeln('- $failure');
      }
      exitCode = 1;
      return;
    }

    await regenerateTemplatePayload(root, allowDirty: allowDirty);
    stdout.writeln('Cuboid Flutter template payload regenerated.');
  } on TemplateSyncException catch (error) {
    stderr.writeln('Template sync failed: ${error.message}');
    exitCode = 64;
  }
}

const _usage = '''
Usage:
dart run tool/sync_cuboid_template.dart [--check] [--allow-dirty]

Options:
--check         Verify the generated template payload is current.
--allow-dirty   Allow maintenance regeneration with dirty template source files.
--help          Print this help text.
''';
