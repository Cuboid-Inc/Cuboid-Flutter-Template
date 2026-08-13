import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cuboid/cuboid.dart';
import 'package:test/test.dart';

const _knownCreateArtifacts = <String>[
  'app',
  'service',
  'feature',
  'bottomsheet',
  'dialog',
  'storage',
  'database',
];

void main() {
  test('command runner starts', () {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.executableName, 'cuboid');
    expect(runner.commands, contains('create'));
    expect(runner.commands, contains('feature'));
    expect(runner.commands, contains('route'));
    expect(runner.commands, contains('service'));
    expect(runner.commands, contains('view'));
  });

  test('--help works', () async {
    final output = _memorySink();
    final exitCode = await runCuboid(['--help'], stdout: output);

    expect(exitCode, 0);
    expect(
      output.content,
      contains('Command-line tools for Cuboid Flutter projects.'),
    );
    expect(output.content, contains('create'));
    expect(output.content, contains('feature'));
    expect(output.content, contains('route'));
    expect(output.content, contains('service'));
    expect(output.content, contains('view'));
  });

  test('--version works', () async {
    final output = _memorySink();
    final exitCode = await runCuboid(['--version'], stdout: output);

    expect(exitCode, 0);
    expect(output.content.trim(), cuboidVersion);
  });

  test('create command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['create'], isA<CreateCommand>());
    expect(runner.commands['create']!.description, contains('Create a new'));
  });

  test('feature command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['feature'], isA<FeatureCommand>());
    expect(
      runner.commands['feature']!.description,
      contains('Create a new Cuboid feature'),
    );
  });

  test('route command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['route'], isA<RouteCommand>());
    expect(
      runner.commands['route']!.description,
      contains('Register an existing feature View'),
    );
  });

  test('view command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['view'], isA<ViewCommand>());
    expect(
      runner.commands['view']!.description,
      contains('Create an additional Stacked View'),
    );
  });

  test('service command is registered', () async {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(runner.commands['service'], isA<ServiceCommand>());
    expect(
      runner.commands['service']!.description,
      contains('Register an existing core service'),
    );
  });

  test(
    'create dry-run reports the planned project without writing files',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        [
          'create',
          '--dry-run',
          '--output-dir',
          temp.path,
          'My App',
          'com.example.myapp',
        ],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Dry run: no files were written.'));
      expect(
        output.content,
        contains('Destination: ${temp.absolute.path}/my_app'),
      );
      expect(output.content, contains('Planned actions:'));
      expect(errorOutput.content, isEmpty);
      expect(Directory('${temp.path}/my_app').existsSync(), isFalse);
    },
  );

  test('create validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'My App'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a display name and package identifier.'),
    );
  });

  test('bare create keeps existing project creation usage behavior', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a display name and package identifier.'),
    );
    expect(errorOutput.content, contains('Usage: cuboid create'));
  });

  test(
    'create help describes namespace without claiming artifacts work',
    () async {
      final output = _memorySink();
      final exitCode = await runCuboid(
        ['create', '--help'],
        stdout: output,
        stderr: _memorySink(),
      );

      expect(exitCode, 0);
      expect(
        output.content,
        contains('Canonical namespace: cuboid create <artifact>'),
      );
      expect(output.content, contains('Known artifact categories'));
      expect(output.content, contains('app, service, feature'));
      expect(
        output.content,
        contains('artifact commands are not yet implemented'),
      );
      expect(output.content, isNot(contains('cuboid create feature <name>')));
      expect(output.content, isNot(contains('cuboid create service <name>')));
    },
  );

  for (final artifact in _knownCreateArtifacts) {
    test('create $artifact fails cleanly as unimplemented', () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      final previousCurrent = Directory.current;
      addTearDown(() {
        Directory.current = previousCurrent;
        temp.deleteSync(recursive: true);
      });
      Directory.current = temp;
      final beforeFiles = _relativeFiles(temp);
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['create', artifact],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 64);
      expect(output.content, isEmpty);
      expect(
        errorOutput.content,
        contains('cuboid create $artifact is not implemented yet.'),
      );
      expect(_relativeFiles(temp), beforeFiles);
    });

    test(
      'create $artifact with arguments does not fall back to app creation',
      () async {
        final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
        final previousCurrent = Directory.current;
        addTearDown(() {
          Directory.current = previousCurrent;
          temp.deleteSync(recursive: true);
        });
        Directory.current = temp;
        final beforeFiles = _relativeFiles(temp);
        final output = _memorySink();
        final errorOutput = _memorySink();
        final exitCode = await runCuboid(
          ['create', artifact, 'auth'],
          stdout: output,
          stderr: errorOutput,
        );

        expect(exitCode, 64);
        expect(output.content, isEmpty);
        expect(
          errorOutput.content,
          contains('cuboid create $artifact is not implemented yet.'),
        );
        expect(errorOutput.content, isNot(contains('Destination:')));
        expect(_relativeFiles(temp), beforeFiles);
      },
    );
  }

  test('create known artifact with multiple arguments fails cleanly', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'feature', 'auth', 'extra'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(output.content, isEmpty);
    expect(
      errorOutput.content,
      contains('cuboid create feature is not implemented yet.'),
    );
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create known artifact with dry-run still fails cleanly', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', '--dry-run', 'feature', 'auth'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(output.content, isEmpty);
    expect(
      errorOutput.content,
      contains('cuboid create feature is not implemented yet.'),
    );
    expect(errorOutput.content, isNot(contains('Destination:')));
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create unknown artifact fails cleanly', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    Directory.current = temp;
    final beforeFiles = _relativeFiles(temp);
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['create', 'gizmo'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(output.content, isEmpty);
    expect(errorOutput.content, contains('Unknown create artifact "gizmo".'));
    expect(errorOutput.content, contains('Known artifacts:'));
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('create preserves legacy app creation for non-artifact names', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      [
        'create',
        '--dry-run',
        '--output-dir',
        temp.path,
        'Customer Portal',
        'com.example.customer',
      ],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(
      output.content,
      contains('Destination: ${temp.absolute.path}/customer_portal'),
    );
    expect(output.content, contains('App package: com.example.customer'));
    expect(errorOutput.content, isEmpty);
    expect(Directory('${temp.path}/customer_portal').existsSync(), isFalse);
  });

  test('feature dry-run reports planned files without writing files', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    File('${temp.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['feature', 'auth', '--dry-run'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Feature: Auth'));
    expect(
      output.content,
      contains('- lib/features/auth/ui/views/auth_view.dart'),
    );
    expect(
      output.content,
      contains('- lib/features/auth/ui/viewmodels/auth_viewmodel.dart'),
    );
    expect(errorOutput.content, isEmpty);
    expect(Directory('${temp.path}/lib/features/auth').existsSync(), isFalse);
  });

  test('feature validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['feature'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(errorOutput.content, contains('Expected a feature name.'));
  });

  test('route dry-run reports planned registration without writing', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'user_profile');
    final before = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['route', 'user-profile', '--dry-run'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('Route: UserProfileView'));
    expect(output.content, contains('- lib/app/app.dart'));
    expect(
      output.content,
      contains(
        "import 'package:my_app/features/user_profile/ui/views/user_profile_view.dart';",
      ),
    );
    expect(output.content, contains('MaterialRoute(page: UserProfileView),'));
    expect(errorOutput.content, isEmpty);
    expect(File('${temp.path}/lib/app/app.dart').readAsStringSync(), before);
  });

  test('route command registers an existing feature View', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'auth');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['route', 'auth'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Registered route AuthView.'));
    expect(
      output.content,
      contains('Next step: dart run build_runner build -d'),
    );
    expect(errorOutput.content, isEmpty);
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:my_app/features/auth/ui/views/auth_view.dart';",
      ),
    );
    expect(app, contains('    MaterialRoute(page: AuthView),'));
  });

  test('route validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['route'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(errorOutput.content, contains('Expected a feature name.'));
  });

  test('route service failures return non-zero and write stderr', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeRouteProject(temp, 'auth');
    File('${temp.path}/lib/features/auth/ui/views/auth_view.dart').deleteSync();
    Directory.current = temp;
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['route', 'auth'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 1);
    expect(
      errorOutput.content,
      contains('lib/features/auth/ui/views/auth_view.dart was not found.'),
    );
  });

  test(
    'service dry-run reports planned registration without writing',
    () async {
      final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
      final previousCurrent = Directory.current;
      addTearDown(() {
        Directory.current = previousCurrent;
        temp.deleteSync(recursive: true);
      });
      _writeServiceProject(temp, 'auth_session');
      final before = File('${temp.path}/lib/app/app.dart').readAsStringSync();
      Directory.current = temp;
      final output = _memorySink();
      final errorOutput = _memorySink();
      final exitCode = await runCuboid(
        ['service', 'auth-session', '--dry-run'],
        stdout: output,
        stderr: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.content, contains('Dry run: no files were written.'));
      expect(output.content, contains('Service: AuthSessionService'));
      expect(output.content, contains('- lib/app/app.dart'));
      expect(
        output.content,
        contains(
          "import 'package:my_app/core/services/auth_session_service.dart';",
        ),
      );
      expect(
        output.content,
        contains('LazySingleton(classType: AuthSessionService),'),
      );
      expect(errorOutput.content, isEmpty);
      expect(File('${temp.path}/lib/app/app.dart').readAsStringSync(), before);
    },
  );

  test('service command registers an existing core service', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeServiceProject(temp, 'auth_session');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['service', 'AuthSession'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Registered service AuthSessionService.'));
    expect(
      output.content,
      contains('Next step: dart run build_runner build -d'),
    );
    expect(errorOutput.content, isEmpty);
    final app = File('${temp.path}/lib/app/app.dart').readAsStringSync();
    expect(
      app,
      contains(
        "import 'package:my_app/core/services/auth_session_service.dart';",
      ),
    );
    expect(app, contains('    LazySingleton(classType: AuthSessionService),'));
  });

  test('service validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['service'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(errorOutput.content, contains('Expected a service name.'));
  });

  test('service failures return non-zero and write stderr', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeServiceProject(temp, 'auth_session');
    File(
      '${temp.path}/lib/core/services/auth_session_service.dart',
    ).deleteSync();
    Directory.current = temp;
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['service', 'auth-session'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 1);
    expect(
      errorOutput.content,
      contains('lib/core/services/auth_session_service.dart was not found.'),
    );
  });

  test('view dry-run reports planned files without writing', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeViewProject(temp, 'auth');
    final beforeFiles = _relativeFiles(temp);
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['view', 'auth', 'forgot-password', '--dry-run'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Dry run: no files were written.'));
    expect(output.content, contains('View: Forgot Password'));
    expect(output.content, contains('Feature: auth'));
    expect(
      output.content,
      contains('- lib/features/auth/ui/views/forgot_password_view.dart'),
    );
    expect(
      output.content,
      contains(
        '- lib/features/auth/ui/viewmodels/forgot_password_viewmodel.dart',
      ),
    );
    expect(errorOutput.content, isEmpty);
    expect(_relativeFiles(temp), beforeFiles);
  });

  test('view command creates an additional feature View', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    _writeViewProject(temp, 'auth');
    Directory.current = temp;
    final output = _memorySink();
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['view', 'auth', 'forgot-password'],
      stdout: output,
      stderr: errorOutput,
    );

    expect(exitCode, 0);
    expect(output.content, contains('Created view Forgot Password.'));
    expect(errorOutput.content, isEmpty);
    final view = File(
      '${temp.path}/lib/features/auth/ui/views/forgot_password_view.dart',
    ).readAsStringSync();
    final viewModel = File(
      '${temp.path}/lib/features/auth/ui/viewmodels/forgot_password_viewmodel.dart',
    ).readAsStringSync();
    expect(
      view,
      contains(
        "import 'package:my_app/features/auth/ui/viewmodels/forgot_password_viewmodel.dart';",
      ),
    );
    expect(
      view,
      contains(
        'class ForgotPasswordView extends StackedView<ForgotPasswordViewModel>',
      ),
    );
    expect(
      viewModel,
      contains('class ForgotPasswordViewModel extends BaseViewModel {}'),
    );
  });

  test('view validates required positional arguments', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['view', 'auth'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 64);
    expect(
      errorOutput.content,
      contains('Expected a feature name and view name.'),
    );
  });

  test('view service failures return non-zero and write stderr', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    final previousCurrent = Directory.current;
    addTearDown(() {
      Directory.current = previousCurrent;
      temp.deleteSync(recursive: true);
    });
    File('${temp.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
    Directory.current = temp;
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['view', 'auth', 'login'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, 1);
    expect(errorOutput.content, contains('lib/features/auth was not found.'));
  });

  test('runner can use an injected create service', () async {
    final temp = Directory.systemTemp.createTempSync('cuboid_cli_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final output = _memorySink();
    final service = CreateProjectService(
      processRunner:
          (executable, arguments, {required workingDirectory}) async {
            return ProcessResult(0, 0, '', '');
          },
    );
    final runner = CuboidCommandRunner(
      stdout: output,
      stderr: _memorySink(),
      createProjectService: service,
    );

    final exitCode = await runner.run([
      'create',
      '--no-post-steps',
      '--output-dir',
      temp.path,
      'My App',
      'com.example.myapp',
    ]);

    expect(exitCode, 0);
    expect(output.content, contains('Created My App.'));
    expect(Directory('${temp.path}/my_app').existsSync(), isTrue);
  });

  test('invalid command returns non-zero and writes usage', () async {
    final errorOutput = _memorySink();
    final exitCode = await runCuboid(
      ['missing'],
      stdout: _memorySink(),
      stderr: errorOutput,
    );

    expect(exitCode, isNot(0));
    expect(
      errorOutput.content,
      contains('Could not find a command named "missing".'),
    );
    expect(errorOutput.content, contains('Usage:'));
  });

  test('runner throws UsageException for invalid command', () {
    final runner = CuboidCommandRunner(stdout: _memorySink());

    expect(() => runner.run(['missing']), throwsA(isA<UsageException>()));
  });
}

_MemorySink _memorySink() => _MemorySink();

void _writeRouteProject(Directory root, String featureName) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/features/startup/ui/views/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    // @stacked-route
  ],
)
class App {}
''');
  File(
      '${root.path}/lib/features/$featureName/ui/views/${featureName}_view.dart',
    )
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class View {}\n');
}

void _writeViewProject(Directory root, String featureName) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  Directory(
    '${root.path}/lib/features/$featureName',
  ).createSync(recursive: true);
}

void _writeServiceProject(Directory root, String serviceName) {
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: my_app\n');
  File('${root.path}/lib/app/app.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:my_app/core/services/shell_service.dart';
import 'package:stacked/stacked_annotations.dart';
// @stacked-import

@StackedApp(
  dependencies: [
    LazySingleton(classType: ShellService),
    // @stacked-service
  ],
)
class App {}
''');
  final className = serviceName
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
  File('${root.path}/lib/core/services/${serviceName}_service.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('class ${className}Service {}\n');
}

List<String> _relativeFiles(Directory root) {
  return root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((file) => file.path.substring(root.path.length + 1))
      .map((path) => path.replaceAll(Platform.pathSeparator, '/'))
      .toList()
    ..sort();
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  Encoding encoding = utf8;

  @override
  void write(Object? object) {
    _buffer.write(object);
  }

  @override
  void writeln([Object? object = '']) {
    _buffer.writeln(object);
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    _buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
  }

  @override
  void add(List<int> data) {
    _buffer.write(encoding.decode(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> close() async {
    await Future<void>.value();
  }

  @override
  Future<void> get done => Future.value();

  @override
  Future<void> flush() async {}
}
