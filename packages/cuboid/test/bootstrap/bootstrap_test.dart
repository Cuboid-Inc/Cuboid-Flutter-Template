import 'dart:io';

import 'package:cuboid/src/bootstrap/bootstrap.dart';
import 'package:test/test.dart';

void main() {
  group('deriveProjectName', () {
    test('converts a human name into a valid Dart project name', () {
      expect(deriveProjectName('Nemara Homes'), 'nemara_homes');
    });

    test('converts multi-word names to snake case', () {
      expect(deriveProjectName('My Cool App'), 'my_cool_app');
      expect(deriveProjectName('Property Manager'), 'property_manager');
    });

    test('keeps derived Dart names valid for keywords and leading digits', () {
      expect(deriveProjectName('class'), 'class_app');
      expect(deriveProjectName('123 App'), 'app_123_app');
    });
  });

  group('package validation', () {
    test('rejects invalid package identifiers', () {
      expect(
        () => validatePackageIdentifier('com.example.'),
        throwsA(isA<BootstrapException>()),
      );
      expect(
        () => validatePackageIdentifier('com.example.my-app'),
        throwsA(isA<BootstrapException>()),
      );
      expect(
        () => validatePackageIdentifier('example'),
        throwsA(isA<BootstrapException>()),
      );
      expect(
        () => validatePackageIdentifier('com.example.my app'),
        throwsA(isA<BootstrapException>()),
      );
      expect(
        () => validatePackageIdentifier('com.example.my_app'),
        throwsA(isA<BootstrapException>()),
      );
      expect(
        () => validatePackageIdentifier('com.example.2myapp'),
        throwsA(isA<BootstrapException>()),
      );
    });

    test('accepts valid package identifiers', () {
      expect(
        () => validatePackageIdentifier('com.cuboidllc.nemarahomes'),
        returnsNormally,
      );
      expect(
        () => validatePackageIdentifier('com.someapp.someapp'),
        returnsNormally,
      );
      expect(
        () => validatePackageIdentifier('com.example.myapp2'),
        returnsNormally,
      );
      expect(
        () => validatePackageIdentifier('com.example2.myapp'),
        returnsNormally,
      );
    });
  });

  group('deriveAppClassName', () {
    test('converts a human name into a valid PascalCase class name', () {
      expect(deriveAppClassName('Nemara Homes'), 'NemaraHomes');
      expect(deriveAppClassName('my app'), 'MyApp');
      expect(deriveAppClassName('hello world'), 'HelloWorld');
    });

    test('keeps derived class names valid for keywords and leading digits', () {
      expect(deriveAppClassName('Function'), 'FunctionApp');
      expect(deriveAppClassName('123 App'), 'App123App');
    });
  });

  group('input validation', () {
    test('derives trimmed deterministic bootstrap values', () {
      final values = deriveBootstrapValues(
        const BootstrapInput(
          displayName: ' Nemara Homes ',
          packageIdentifier: ' com.cuboidllc.nemarahomes ',
        ),
      );

      expect(values.displayName, 'Nemara Homes');
      expect(values.dartProjectName, 'nemara_homes');
      expect(values.appClassName, 'NemaraHomes');
      expect(values.packageIdentifier, 'com.cuboidllc.nemarahomes');
      expect(values.storageNamespace, 'nemara_homes');
    });

    test('reports invalid display names without throwing', () {
      final result = validateBootstrapInput(
        const BootstrapInput(
          displayName: '///',
          packageIdentifier: 'com.cuboidllc.valid',
        ),
      );

      expect(result.isValid, isFalse);
      expect(
        result.failures,
        contains('--name must be a normal human-readable application name.'),
      );
    });

    test('plans escaped Dart and XML display-name values', () {
      final root = Directory.systemTemp.createTempSync('bootstrap_test_');
      addTearDown(() => root.deleteSync(recursive: true));

      _writeMinimalFixture(root);
      _writeFixture(
        root,
        'lib/features/home/ui/home_view.dart',
        "appBar: AppBar(title: const Text('Cuboid Flutter Template')),\n",
      );

      const values = BootstrapValues(
        displayName: 'Bob\'s <App> & "Co"',
        dartProjectName: 'bobs_app_co',
        appClassName: 'BobsAppCo',
        packageIdentifier: 'com.example.bobsapp',
        storageNamespace: 'bobs_app_co',
      );

      final plan = planBootstrap(root, values);

      expect(
        plan.replacements,
        contains(
          isA<Replacement>()
              .having(
                (item) => item.path,
                'path',
                'lib/core/constants/app_constants.dart',
              )
              .having(
                (item) => item.newValue,
                'newValue',
                "static const appName = 'Bob\\'s <App> & \"Co\"';",
              ),
        ),
      );
      expect(
        plan.replacements,
        contains(
          isA<Replacement>()
              .having(
                (item) => item.path,
                'path',
                'android/app/src/main/AndroidManifest.xml',
              )
              .having(
                (item) => item.newValue,
                'newValue',
                'android:label="Bob\'s &lt;App&gt; &amp; &quot;Co&quot;"',
              ),
        ),
      );
      expect(
        plan.replacements,
        contains(
          isA<Replacement>()
              .having((item) => item.path, 'path', 'ios/Runner/Info.plist')
              .having(
                (item) => item.newValue,
                'newValue',
                '<string>Bob\'s &lt;App&gt; &amp; "Co"</string>',
              ),
        ),
      );
    });
  });

  test('replacement logic replaces exact values', () {
    const content = 'name: cuboid_flutter_template\n';

    expect(
      replaceExactInContent(
        content,
        'name: cuboid_flutter_template',
        'name: nemara_homes',
      ),
      'name: nemara_homes\n',
    );
  });

  test('Dart package import replacement only changes imports', () {
    const content = '''
import 'package:cuboid_flutter_template/app/app.dart';

const note = 'package:cuboid_flutter_template/not_an_import.dart';
// package:cuboid_flutter_template/comment.dart
''';

    expect(
      replaceDartPackageImportsInContent(
        content,
        'cuboid_flutter_template',
        'nemara_homes',
      ),
      "import 'package:${'nemara_homes'}/app/app.dart';\n"
      '\n'
      "const note = 'package:cuboid_flutter_template/not_an_import.dart';\n"
      '// package:cuboid_flutter_template/comment.dart\n',
    );
  });

  test('dry-run planning performs no modifications', () {
    final root = Directory.systemTemp.createTempSync('bootstrap_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    _writeFixture(root, 'pubspec.yaml', '''
name: cuboid_flutter_template
description: "Template for Cuboid Flutter projects"
''');
    _writeFixture(root, 'lib/main.dart', '''
import 'package:cuboid_flutter_template/app/app_root.dart';

void main() {
  runApp(const MyApp());
}
''');
    _writeFixture(root, 'lib/app/app_root.dart', '''
class MyApp extends StatelessWidget {
  const MyApp({super.key});
}
''');
    _writeFixture(
      root,
      'test/widget_test.dart',
      "import 'package:cuboid_flutter_template/main.dart';\n",
    );
    _writeFixture(root, 'test/tool/bootstrap_fixture_test.dart', '''
const fixture = """
import 'package:cuboid_flutter_template/not_a_real_import.dart';
""";
''');
    _writeFixture(root, 'lib/core/constants/app_constants.dart', '''
abstract final class AppConfig {
  static const appName = 'Cuboid Flutter Template';
  static const locale = 'en_US';
}
''');
    _writeFixture(
      root,
      'lib/features/home/ui/home_view.dart',
      "appBar: AppBar(title: const Text('Cuboid Flutter Template')),\n",
    );
    _writeFixture(root, 'android/app/build.gradle.kts', '''
android {
    namespace = "com.cuboidllc.cuboid_flutter_template"
    defaultConfig {
        applicationId = "com.cuboidllc.cuboid_flutter_template"
    }
}
''');
    _writeFixture(root, 'android/app/src/main/AndroidManifest.xml', '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="Cuboid Flutter Template">
        <activity>
            <intent-filter>
                <data android:scheme="com.cuboidllc.cuboid_flutter_template" />
            </intent-filter>
        </activity>
    </application>
</manifest>
''');
    _writeFixture(
      root,
      'android/app/src/main/kotlin/com/cuboidllc/cuboid_flutter_template/MainActivity.kt',
      '''
package com.cuboidllc.cuboid_flutter_template

class MainActivity
''',
    );
    _writeFixture(root, 'ios/Runner/Info.plist', '''
<plist>
<dict>
<string>Cuboid Flutter Template</string>
<string>Cuboid Flutter Template</string>
</dict>
</plist>
''');
    _writeFixture(root, 'ios/Runner.xcodeproj/project.pbxproj', '''
INFOPLIST_KEY_CFBundleDisplayName = "Cuboid Flutter Template";
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidllc.cuboid_flutter_template;
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidllc.cuboid_flutter_template.RunnerTests;
''');
    _writeFixture(
      root,
      'lib/app/app.router.dart',
      "import 'package:cuboid_flutter_template/features/home/home_view.dart';\n",
    );
    _writeFixture(root, 'README.md', '''
# Cuboid Flutter Template
Reusable Flutter starter template for Cuboid applications, built on Cuboid's
own MVVM, dependency injection, and routing.
This repository is infrastructure for starting a new app. It is not a production
domain application and does not contain application-specific business workflows,
database schema, or repository/data layers.
''');
    _writeFixture(root, 'ARCHITECTURE.md', '''
# Cuboid Flutter Template Architecture
''');
    _writeFixture(root, 'RULES.md', '''
Cuboid Flutter Template DEVELOPMENT AND AI AGENT RULES

NAME-11. Use package:cuboid_flutter_template imports in handwritten Dart until a
generated app is bootstrapped to a new package name.
''');
    _writeFixture(root, '.vscode/launch.json', '''
{"name":"Cuboid Flutter Template - Debug"},{"name":"Cuboid Flutter Template - Release"},{"name":"Cuboid Flutter Template - Profile"}
''');
    _writeFixture(root, 'test/widget_test.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Cuboid Flutter Template'))),
    );
    expect(find.text('Cuboid Flutter Template'), findsOneWidget);
  });
}
''');

    final values = BootstrapValues(
      displayName: 'Nemara Homes',
      dartProjectName: deriveProjectName('Nemara Homes'),
      appClassName: deriveAppClassName('Nemara Homes'),
      packageIdentifier: 'com.cuboidllc.nemarahomes',
      storageNamespace: deriveProjectName('Nemara Homes'),
    );
    final before = File('${root.path}/pubspec.yaml').readAsStringSync();

    final plan = createBootstrapPlan(root, values);
    validatePlan(root, plan);

    expect(plan.modifiedFiles, contains('pubspec.yaml'));
    expect(
      plan.modifiedFiles,
      contains(
        'android/app/src/main/kotlin/com/cuboidllc/cuboid_flutter_template',
      ),
    );
    expect(plan.modifiedFiles, contains('lib/app/app.router.dart'));
    expect(
      plan.manualConfiguration,
      contains(
        'Optional backend/storage technology, if the app needs one -- e.g. '
        '`cuboid create database supabase` or `cuboid create storage <name>`.',
      ),
    );
    expect(
      plan.replacements,
      contains(
        isA<Replacement>()
            .having((item) => item.path, 'path', 'pubspec.yaml')
            .having((item) => item.label, 'label', 'description')
            .having(
              (item) => item.newValue,
              'newValue',
              'description: "Flutter application created from the Cuboid Flutter Template"',
            ),
      ),
    );
    expect(
      plan.replacements,
      contains(
        isA<Replacement>()
            .having((item) => item.path, 'path', 'README.md')
            .having(
              (item) => item.newValue,
              'newValue',
              'This project was created from the Cuboid Flutter Template.',
            ),
      ),
    );
    expect(
      plan.replacements.any((replacement) {
        return replacement.path == 'test/tool/bootstrap_fixture_test.dart';
      }),
      isFalse,
    );
    expect(
      plan.replacements,
      contains(
        isA<Replacement>()
            .having(
              (item) => item.path,
              'path',
              'lib/features/home/ui/home_view.dart',
            )
            .having((item) => item.label, 'label', 'home view title')
            .having(
              (item) => item.newValue,
              'newValue',
              "AppBar(title: const Text('Nemara Homes'))",
            ),
      ),
    );
    expect(
      plan.replacements,
      contains(
        isA<Replacement>()
            .having((item) => item.path, 'path', 'ARCHITECTURE.md')
            .having((item) => item.label, 'label', 'architecture title')
            .having(
              (item) => item.newValue,
              'newValue',
              '# Nemara Homes Architecture',
            ),
      ),
    );
    expect(
      plan.replacements,
      contains(
        isA<Replacement>()
            .having((item) => item.path, 'path', 'RULES.md')
            .having(
              (item) => item.label,
              'label',
              'rules package import guidance',
            )
            .having(
              (item) => item.newValue,
              'newValue',
              'NAME-11. Use package:nemara_homes imports in handwritten Dart.',
            ),
      ),
    );
    expect(
      plan.replacements,
      contains(
        isA<Replacement>()
            .having((item) => item.path, 'path', 'test/widget_test.dart')
            .having(
              (item) => item.label,
              'label',
              'widget test display assertion',
            )
            .having(
              (item) => item.newValue,
              'newValue',
              "find.text('Nemara Homes')",
            ),
      ),
    );
    expect(File('${root.path}/pubspec.yaml').readAsStringSync(), before);
  });

  test('applyBootstrapPlan applies file operations without a build step', () {
    final root = Directory.systemTemp.createTempSync('bootstrap_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    _writeMinimalFixture(root);
    _writeFixture(
      root,
      'lib/features/home/ui/home_view.dart',
      "appBar: AppBar(title: const Text('Cuboid Flutter Template')),\n",
    );
    _writeFixture(
      root,
      'lib/app/app.router.dart',
      "import 'package:cuboid_flutter_template/features/home/home_view.dart';\n",
    );

    final values = deriveBootstrapValues(
      const BootstrapInput(
        displayName: 'Nemara Homes',
        packageIdentifier: 'com.cuboidllc.nemarahomes',
      ),
    );
    final plan = planBootstrap(root, values);
    validatePlan(root, plan);

    final result = applyBootstrapPlan(root, plan);

    expect(
      result.movedDirectories.single.from,
      contains('cuboid_flutter_template'),
    );
    expect(
      File('${root.path}/pubspec.yaml').readAsStringSync(),
      contains('name: nemara_homes'),
    );
    expect(
      File(
        '${root.path}/lib/features/home/ui/home_view.dart',
      ).readAsStringSync(),
      contains("AppBar(title: const Text('Nemara Homes'))"),
    );

    final oldKotlinDirectory = Directory(
      '${root.path}/android/app/src/main/kotlin/com/cuboidllc/cuboid_flutter_template',
    );
    final newKotlinFile = File(
      '${root.path}/android/app/src/main/kotlin/com/cuboidllc/nemarahomes/MainActivity.kt',
    );
    expect(oldKotlinDirectory.existsSync(), isFalse);
    expect(newKotlinFile.existsSync(), isTrue);
    expect(
      newKotlinFile.readAsStringSync(),
      contains('package com.cuboidllc.nemarahomes'),
    );

    // lib/app/app.router.dart is plain, hand-maintained Dart -- not build
    // step output -- so its package import is rewritten like any other file.
    expect(
      File('${root.path}/lib/app/app.router.dart').readAsStringSync(),
      "import 'package:nemara_homes/features/home/home_view.dart';\n",
    );
  });

  test('locator/router files are planned as Dart import replacements like '
      'any other source file', () {
    final root = Directory.systemTemp.createTempSync('bootstrap_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    _writeMinimalFixture(root);
    _writeFixture(
      root,
      'lib/features/home/ui/home_view.dart',
      "appBar: AppBar(title: const Text('Cuboid Flutter Template')),\n",
    );
    _writeFixture(
      root,
      'lib/app/app.router.dart',
      "import 'package:cuboid_flutter_template/features/home/home_view.dart';\n",
    );
    _writeFixture(
      root,
      'lib/features/home/ui/extra_view.dart',
      "import 'package:cuboid_flutter_template/app/app.locator.dart';\n",
    );

    final values = deriveBootstrapValues(
      const BootstrapInput(
        displayName: 'Nemara Homes',
        packageIdentifier: 'com.cuboidllc.nemarahomes',
      ),
    );
    final plan = planBootstrap(root, values);

    expect(
      plan.replacements,
      contains(
        isA<Replacement>()
            .having((item) => item.path, 'path', 'lib/app/app.router.dart')
            .having((item) => item.dartImportOnly, 'dartImportOnly', isTrue),
      ),
    );
    expect(
      plan.replacements,
      contains(
        isA<Replacement>()
            .having(
              (item) => item.path,
              'path',
              'lib/features/home/ui/extra_view.dart',
            )
            .having((item) => item.dartImportOnly, 'dartImportOnly', isTrue),
      ),
    );
  });

  test('validation failure does not modify files', () {
    final root = Directory.systemTemp.createTempSync('bootstrap_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    _writeMinimalFixture(root);

    final pubspec = File('${root.path}/pubspec.yaml');
    final before = pubspec.readAsStringSync();

    // Deliberately break an expected template value.
    pubspec.writeAsStringSync(
      before.replaceFirst(
        'name: cuboid_flutter_template',
        'name: something_else',
      ),
    );

    final values = BootstrapValues(
      displayName: 'Nemara Homes',
      dartProjectName: deriveProjectName('Nemara Homes'),
      appClassName: deriveAppClassName('Nemara Homes'),
      packageIdentifier: 'com.cuboidllc.nemarahomes',
      storageNamespace: deriveProjectName('Nemara Homes'),
    );

    expect(
      () => validatePlan(root, createBootstrapPlan(root, values)),
      throwsA(isA<BootstrapException>()),
    );

    expect(pubspec.readAsStringSync(), isNot(contains('name: nemara_homes')));
    expect(pubspec.readAsStringSync(), contains('name: something_else'));
  });
}

void _writeFixture(Directory root, String relativePath, String content) {
  final file = File(
    '${root.path}/${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _writeMinimalFixture(Directory root) {
  _writeFixture(root, 'pubspec.yaml', '''
name: cuboid_flutter_template
description: "Template for Cuboid Flutter projects"
''');
  _writeFixture(root, 'lib/main.dart', '''
import 'package:cuboid_flutter_template/app/app_root.dart';

void main() {
  runApp(const MyApp());
}
''');
  _writeFixture(root, 'lib/app/app_root.dart', '''
class MyApp extends StatelessWidget {
  const MyApp({super.key});
}
''');
  _writeFixture(root, 'lib/core/constants/app_constants.dart', '''
abstract final class AppConfig {
  static const appName = 'Cuboid Flutter Template';
}
''');
  _writeFixture(root, 'android/app/build.gradle.kts', '''
android {
    namespace = "com.cuboidllc.cuboid_flutter_template"
    defaultConfig {
        applicationId = "com.cuboidllc.cuboid_flutter_template"
    }
}
''');
  _writeFixture(root, 'android/app/src/main/AndroidManifest.xml', '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="Cuboid Flutter Template">
        <activity>
            <intent-filter>
                <data android:scheme="com.cuboidllc.cuboid_flutter_template" />
            </intent-filter>
        </activity>
    </application>
</manifest>
''');
  _writeFixture(
    root,
    'android/app/src/main/kotlin/com/cuboidllc/cuboid_flutter_template/MainActivity.kt',
    '''
package com.cuboidllc.cuboid_flutter_template

class MainActivity
''',
  );
  _writeFixture(root, 'ios/Runner/Info.plist', '''
<plist>
<dict>
<string>Cuboid Flutter Template</string>
<string>Cuboid Flutter Template</string>
</dict>
</plist>
''');
  _writeFixture(root, 'ios/Runner.xcodeproj/project.pbxproj', '''
INFOPLIST_KEY_CFBundleDisplayName = "Cuboid Flutter Template";
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidllc.cuboid_flutter_template;
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidllc.cuboid_flutter_template.RunnerTests;
''');
  _writeFixture(root, 'README.md', '''
# Cuboid Flutter Template
Reusable Flutter starter template for Cuboid applications, built on Cuboid's
own MVVM, dependency injection, and routing.
This repository is infrastructure for starting a new app. It is not a production
domain application and does not contain application-specific business workflows,
database schema, or repository/data layers.
''');
  _writeFixture(root, 'ARCHITECTURE.md', '''
# Cuboid Flutter Template Architecture
''');
  _writeFixture(root, 'RULES.md', '''
Cuboid Flutter Template DEVELOPMENT AND AI AGENT RULES

NAME-11. Use package:cuboid_flutter_template imports in handwritten Dart until a
generated app is bootstrapped to a new package name.
''');
  _writeFixture(root, '.vscode/launch.json', '''
{"name":"Cuboid Flutter Template - Debug"},{"name":"Cuboid Flutter Template - Release"},{"name":"Cuboid Flutter Template - Profile"}
''');
}
