import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/bootstrap.dart';

void main() {
  group('deriveProjectName', () {
    test('converts a human name into a valid Dart project name', () {
      expect(deriveProjectName('Nemara Homes'), 'nemara_homes');
    });

    test('converts multi-word names to snake case', () {
      expect(deriveProjectName('My Cool App'), 'my_cool_app');
      expect(deriveProjectName('Property Manager'), 'property_manager');
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
    });

    test('accepts valid package identifiers', () {
      expect(
        () => validatePackageIdentifier('com.cuboidllc.nemarahomes'),
        returnsNormally,
      );
      expect(
        () => validatePackageIdentifier('com.example.my_app2'),
        returnsNormally,
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
      '''
import 'package:nemara_homes/app/app.dart';

const note = 'package:cuboid_flutter_template/not_an_import.dart';
// package:cuboid_flutter_template/comment.dart
''',
    );
  });

  test('dry-run planning performs no modifications', () {
    final root = Directory.systemTemp.createTempSync('bootstrap_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    _writeFixture(root, 'pubspec.yaml', '''
name: cuboid_flutter_template
description: "Template for Cuboid Flutter projects"
''');
    _writeFixture(
      root,
      'lib/main.dart',
      "import 'package:cuboid_flutter_template/app/app_root.dart';\n",
    );
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
  static const currency = 'AED';
}
''');
    _writeFixture(
      root,
      'lib/features/home/ui/views/home_view.dart',
      "const title = 'Cuboid Flutter Template';\n",
    );
    _writeFixture(root, 'lib/core/constants/storage_keys.dart', '''
abstract final class StorageKeys {
  static const supabaseSession = 'fleetgo_supabase_session';
  static const authStorageNamespace = 'fleetgo_auth';
}
''');
    _writeFixture(root, 'android/app/build.gradle.kts', '''
android {
    namespace = "com.cuboidinc.fleetgo"
    defaultConfig {
        applicationId = "com.cuboidinc.fleetgo"
    }
}
''');
    _writeFixture(root, 'android/app/src/main/AndroidManifest.xml', '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="Cuboid Flutter Template">
        <activity>
            <intent-filter>
                <data android:scheme="com.cuboidinc.fleetgo" />
            </intent-filter>
        </activity>
    </application>
</manifest>
''');
    _writeFixture(
      root,
      'android/app/src/main/kotlin/com/cuboidinc/fleetgo/MainActivity.kt',
      '''
package com.cuboidinc.fleetgo

class MainActivity
''',
    );
    _writeFixture(root, 'ios/Runner/Info.plist', '''
<plist>
<dict>
<string>Cuboid Flutter Template</string>
<string>com.cuboidinc.fleetgo</string>
<string>FleetGo</string>
</dict>
</plist>
''');
    _writeFixture(root, 'ios/Runner.xcodeproj/project.pbxproj', '''
INFOPLIST_KEY_CFBundleDisplayName = FleetGo;
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidinc.fleetgo;
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidinc.fleetgo.RunnerTests;
''');
    _writeFixture(root, 'supabase/config.toml', '''
project_id = "Cuboid Flutter Template"
additional_redirect_urls = ["com.cuboidinc.fleetgo://auth-callback"]
''');
    _writeFixture(
      root,
      'lib/app/app.router.dart',
      "import 'package:cuboid_flutter_template/features/home/home_view.dart';\n",
    );
    _writeFixture(root, 'README.md', '''
# FleetGo — UAE Transport Fleet MVP
This repo contains the FleetGo Flutter app plus the product and system blueprint for a small UAE transport operator.
FleetGo is a fleet operations & money app (Home / Work / Money / More): work orders, invoicing, supplier settlements, payments, and operational profit for a single pilot operator. Flutter + Stacked MVVM + Supabase.
''');
    _writeFixture(root, '.vscode/launch.json', '''
{"name":"FleetGo - Debug"},{"name":"FleetGo - Release"},{"name":"FleetGo - Profile"}
''');

    final values = BootstrapValues(
      displayName: 'Nemara Homes',
      dartProjectName: deriveProjectName('Nemara Homes'),
      packageIdentifier: 'com.cuboidllc.nemarahomes',
      storageNamespace: deriveProjectName('Nemara Homes'),
    );
    final before = File('${root.path}/pubspec.yaml').readAsStringSync();

    final plan = createBootstrapPlan(root, values);
    validatePlan(root, plan);

    expect(plan.modifiedFiles, contains('pubspec.yaml'));
    expect(
      plan.modifiedFiles,
      contains('android/app/src/main/kotlin/com/cuboidinc/fleetgo'),
    );
    expect(plan.modifiedFiles, contains('lib/app/app.router.dart'));
    expect(
      plan.replacements.where((replacement) {
        return replacement.path == 'supabase/config.toml' &&
            replacement.oldValue.startsWith('project_id');
      }),
      isEmpty,
    );
    expect(
      plan.manualConfiguration,
      contains('Supabase project_id in supabase/config.toml.'),
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
        return replacement.path == 'lib/features/home/ui/views/home_view.dart';
      }),
      isFalse,
    );
    expect(
      plan.replacements.any((replacement) {
        return replacement.path == 'test/tool/bootstrap_fixture_test.dart';
      }),
      isFalse,
    );
    expect(File('${root.path}/pubspec.yaml').readAsStringSync(), before);
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
''');
  _writeFixture(root, 'lib/core/constants/app_constants.dart', '''
abstract final class AppConfig {
  static const appName = 'Cuboid Flutter Template';
}
''');
  _writeFixture(root, 'lib/core/constants/storage_keys.dart', '''
abstract final class StorageKeys {
  static const supabaseSession = 'fleetgo_supabase_session';
  static const authStorageNamespace = 'fleetgo_auth';
}
''');
  _writeFixture(root, 'android/app/build.gradle.kts', '''
android {
    namespace = "com.cuboidinc.fleetgo"
    defaultConfig {
        applicationId = "com.cuboidinc.fleetgo"
    }
}
''');
  _writeFixture(root, 'android/app/src/main/AndroidManifest.xml', '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="Cuboid Flutter Template">
        <activity>
            <intent-filter>
                <data android:scheme="com.cuboidinc.fleetgo" />
            </intent-filter>
        </activity>
    </application>
</manifest>
''');
  _writeFixture(
    root,
    'android/app/src/main/kotlin/com/cuboidinc/fleetgo/MainActivity.kt',
    '''
package com.cuboidinc.fleetgo

class MainActivity
''',
  );
  _writeFixture(root, 'ios/Runner/Info.plist', '''
<plist>
<dict>
<string>Cuboid Flutter Template</string>
<string>com.cuboidinc.fleetgo</string>
<string>FleetGo</string>
</dict>
</plist>
''');
  _writeFixture(root, 'ios/Runner.xcodeproj/project.pbxproj', '''
INFOPLIST_KEY_CFBundleDisplayName = FleetGo;
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidinc.fleetgo;
PRODUCT_BUNDLE_IDENTIFIER = com.cuboidinc.fleetgo.RunnerTests;
''');
  _writeFixture(root, 'supabase/config.toml', '''
project_id = "Cuboid Flutter Template"
additional_redirect_urls = ["com.cuboidinc.fleetgo://auth-callback"]
''');
  _writeFixture(root, 'README.md', '''
# FleetGo — UAE Transport Fleet MVP
This repo contains the FleetGo Flutter app plus the product and system blueprint for a small UAE transport operator.
FleetGo is a fleet operations & money app (Home / Work / Money / More): work orders, invoicing, supplier settlements, payments, and operational profit for a single pilot operator. Flutter + Stacked MVVM + Supabase.
''');
  _writeFixture(root, '.vscode/launch.json', '''
{"name":"FleetGo - Debug"},{"name":"FleetGo - Release"},{"name":"FleetGo - Profile"}
''');
}
