import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../packages/cuboid/lib/src/bootstrap/bootstrap.dart';
import '../../tool/bootstrap.dart';

void main() {
  group('parseArguments', () {
    test('accepts valid name and package', () {
      final parsed = parseArguments([
        '--name',
        'Acme Starter',
        '--package',
        'com.cuboidllc.acme_starter',
      ]);

      expect(parsed.displayName, 'Acme Starter');
      expect(parsed.packageIdentifier, 'com.cuboidllc.acme_starter');
      expect(parsed.dryRun, isFalse);
      expect(parsed.help, isFalse);
    });

    test('accepts dry-run with valid identity arguments', () {
      final parsed = parseArguments([
        '--dry-run',
        '--name',
        'Acme Starter',
        '--package',
        'com.cuboidllc.acme_starter',
      ]);

      expect(parsed.displayName, 'Acme Starter');
      expect(parsed.packageIdentifier, 'com.cuboidllc.acme_starter');
      expect(parsed.dryRun, isTrue);
      expect(parsed.help, isFalse);
    });

    test('accepts help without identity arguments', () {
      final parsed = parseArguments(['--help']);

      expect(parsed.displayName, isEmpty);
      expect(parsed.packageIdentifier, isEmpty);
      expect(parsed.dryRun, isFalse);
      expect(parsed.help, isTrue);
      expect(buildUsage(), contains('dart run tool/bootstrap.dart'));
    });

    test('rejects missing name', () {
      expect(
        () => parseArguments(['--package', 'com.cuboidllc.acme_starter']),
        throwsA(
          isA<BootstrapException>().having(
            (error) => error.message,
            'message',
            'Missing required argument: --name.',
          ),
        ),
      );
    });

    test('rejects missing package', () {
      expect(
        () => parseArguments(['--name', 'Acme Starter']),
        throwsA(
          isA<BootstrapException>().having(
            (error) => error.message,
            'message',
            'Missing required argument: --package.',
          ),
        ),
      );
    });

    test('rejects unknown arguments', () {
      expect(
        () => parseArguments([
          '--name',
          'Acme Starter',
          '--package',
          'com.cuboidllc.acme_starter',
          '--verbose',
        ]),
        throwsA(
          isA<BootstrapException>().having(
            (error) => error.message,
            'message',
            'Unknown argument: --verbose',
          ),
        ),
      );
    });
  });

  test('dry-run output groups planned changes', () {
    final root = Directory.systemTemp.createTempSync('bootstrap_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    _writeMinimalFixture(root);

    final values = BootstrapValues(
      displayName: 'Nemara Homes',
      dartProjectName: deriveProjectName('Nemara Homes'),
      packageIdentifier: 'com.cuboidllc.nemarahomes',
      storageNamespace: deriveProjectName('Nemara Homes'),
    );
    final plan = createBootstrapPlan(root, values);

    final printed = buildDryRunReport(values, plan);

    expect(printed, contains('Project identity:'));
    expect(printed, contains('Dart:'));
    expect(printed, contains('Android:'));
    expect(printed, contains('iOS:'));
    expect(printed, contains('Supabase:'));
    expect(printed, contains('Documentation:'));
    expect(printed, contains('Generated files:'));
    expect(printed, contains('Manual configuration:'));
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

final error = StateError(
  'Cuboid Flutter Template release build without Supabase config. '
  'Build with --dart-define-from-file=env/prod.json.',
);
''');
  _writeFixture(root, 'lib/core/constants/app_constants.dart', '''
abstract final class AppConfig {
  static const appName = 'Cuboid Flutter Template';
}
''');
  _writeFixture(root, 'lib/core/constants/storage_keys.dart', '''
abstract final class StorageKeys {
  static const supabaseSession = 'cuboid_flutter_template_supabase_session';
  static const authStorageNamespace = 'cuboid_flutter_template_auth';
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
<string>com.cuboidllc.cuboid_flutter_template</string>
<string>Cuboid Flutter Template</string>
</dict>
</plist>
''');
  _writeFixture(root, 'ios/Runner.xcodeproj/project.pbxproj', '''
INFOPLIST_KEY_CFBundleDisplayName = "Cuboid Flutter Template";
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidllc.cuboid_flutter_template;
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidllc.cuboid_flutter_template.RunnerTests;
''');
  _writeFixture(root, 'supabase/config.toml', '''
project_id = "Cuboid Flutter Template"
additional_redirect_urls = ["com.cuboidllc.cuboid_flutter_template://auth-callback"]
''');
  _writeFixture(root, 'README.md', '''
# Cuboid Flutter Template
Reusable Flutter + Stacked starter template for Cuboid applications.
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
generated app is bootstrapped to a new package name. Generated files are exempt.
''');
  _writeFixture(root, '.vscode/launch.json', '''
{"name":"Cuboid Flutter Template - Debug"},{"name":"Cuboid Flutter Template - Release"},{"name":"Cuboid Flutter Template - Profile"}
''');
}
