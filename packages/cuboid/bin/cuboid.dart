import 'dart:io';

import 'package:cuboid/cuboid.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runCuboid(arguments, stdout: stdout, stderr: stderr);
}
