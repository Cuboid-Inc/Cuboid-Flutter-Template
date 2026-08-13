import 'dart:io';

import 'package:cuboid/src/feature/create_feature.dart';
import 'package:test/test.dart';

void main() {
  test('creates an auth feature with Stacked view and viewmodel', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    final result = await service.create(
      CreateFeatureInput(name: 'auth', projectRoot: root),
    );

    expect(result.plan.displayName, 'Auth');
    expect(result.plan.files, [
      'lib/features/auth/ui/views/auth_view.dart',
      'lib/features/auth/ui/viewmodels/auth_viewmodel.dart',
    ]);

    final view = File(
      '${root.path}/lib/features/auth/ui/views/auth_view.dart',
    ).readAsStringSync();
    final viewModel = File(
      '${root.path}/lib/features/auth/ui/viewmodels/auth_viewmodel.dart',
    ).readAsStringSync();

    expect(
      view,
      contains(
        "import 'package:test_app/features/auth/ui/viewmodels/auth_viewmodel.dart';",
      ),
    );
    expect(view, contains('class AuthView extends StackedView<AuthViewModel>'));
    expect(
      view,
      contains('AuthViewModel viewModelBuilder(BuildContext context)'),
    );
    expect(view, contains("AppBar(title: const Text('Auth'))"));
    expect(view, contains("body: const Center(child: Text('Auth'))"));
    expect(viewModel, contains('class AuthViewModel extends BaseViewModel {}'));
  });

  test('creates a user_profile feature with PascalCase class names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    await service.create(
      CreateFeatureInput(name: 'user_profile', projectRoot: root),
    );

    final view = File(
      '${root.path}/lib/features/user_profile/ui/views/user_profile_view.dart',
    ).readAsStringSync();
    final viewModel = File(
      '${root.path}/lib/features/user_profile/ui/viewmodels/user_profile_viewmodel.dart',
    ).readAsStringSync();

    expect(
      view,
      contains(
        'class UserProfileView extends StackedView<UserProfileViewModel>',
      ),
    );
    expect(view, contains("AppBar(title: const Text('User Profile'))"));
    expect(
      viewModel,
      contains('class UserProfileViewModel extends BaseViewModel {}'),
    );
  });

  test('normalizes hyphenated feature names to lower snake case', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    final result = await service.create(
      CreateFeatureInput(name: 'user-profile', projectRoot: root),
    );

    expect(result.plan.name, 'user_profile');
    expect(
      File(
        '${root.path}/lib/features/user_profile/ui/views/user_profile_view.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${root.path}/lib/features/user_profile/ui/viewmodels/user_profile_viewmodel.dart',
      ).existsSync(),
      isTrue,
    );
  });

  test(
    'reads quoted package names and inline comments from pubspec.yaml',
    () async {
      final root = _projectRoot(pubspec: 'name: "custom_app" # app package\n');
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateFeatureService();

      await service.create(
        CreateFeatureInput(name: 'billing', projectRoot: root),
      );

      final view = File(
        '${root.path}/lib/features/billing/ui/views/billing_view.dart',
      ).readAsStringSync();

      expect(
        view,
        contains(
          "import 'package:custom_app/features/billing/ui/viewmodels/billing_viewmodel.dart';",
        ),
      );
    },
  );

  test(
    'dry-run validates and reports files without creating directories',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final service = CreateFeatureService();

      final result = await service.create(
        CreateFeatureInput(name: 'auth', projectRoot: root, dryRun: true),
      );

      expect(result.plan.dryRun, isTrue);
      expect(result.plan.files, [
        'lib/features/auth/ui/views/auth_view.dart',
        'lib/features/auth/ui/viewmodels/auth_viewmodel.dart',
      ]);
      expect(Directory('${root.path}/lib/features/auth').existsSync(), isFalse);
    },
  );

  test('rejects invalid names', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    for (final name in ['', '   ', 'user profile', '_auth', '2fa', 'class']) {
      await expectLater(
        service.create(CreateFeatureInput(name: name, projectRoot: root)),
        throwsA(isA<CreateFeatureException>()),
        reason: name,
      );
    }
  });

  test('rejects traversal and path separator attempts', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final service = CreateFeatureService();

    for (final name in ['.', '..', '../auth', 'auth/child', r'auth\child']) {
      await expectLater(
        service.create(CreateFeatureInput(name: name, projectRoot: root)),
        throwsA(isA<CreateFeatureException>()),
        reason: name,
      );
    }
  });

  test('does not overwrite an existing feature', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final existing = Directory('${root.path}/lib/features/auth')
      ..createSync(recursive: true);
    File('${existing.path}/keep.txt').writeAsStringSync('keep\n');
    final service = CreateFeatureService();

    await expectLater(
      service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
      throwsA(
        isA<CreateFeatureException>().having(
          (error) => error.message,
          'message',
          'Feature already exists: lib/features/auth',
        ),
      ),
    );
    expect(File('${existing.path}/keep.txt').readAsStringSync(), 'keep\n');
  });

  test('detects existing features during dry-run', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    Directory('${root.path}/lib/features/auth').createSync(recursive: true);
    final service = CreateFeatureService();

    await expectLater(
      service.create(
        CreateFeatureInput(name: 'auth', projectRoot: root, dryRun: true),
      ),
      throwsA(isA<CreateFeatureException>()),
    );
  });

  test('does not overwrite an existing target file', () async {
    final root = _projectRoot();
    addTearDown(() => root.deleteSync(recursive: true));
    final target =
        File('${root.path}/lib/features/auth/ui/views/auth_view.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('keep\n');
    final service = CreateFeatureService();

    await expectLater(
      service.create(CreateFeatureInput(name: 'auth', projectRoot: root)),
      throwsA(isA<CreateFeatureException>()),
    );
    expect(target.readAsStringSync(), 'keep\n');
  });

  test(
    'leaves app registration untouched and creates no unrelated files',
    () async {
      final root = _projectRoot();
      addTearDown(() => root.deleteSync(recursive: true));
      final appFile = File('${root.path}/lib/app/app.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('app registration\n');
      final service = CreateFeatureService();

      await service.create(CreateFeatureInput(name: 'auth', projectRoot: root));

      expect(appFile.readAsStringSync(), 'app registration\n');
      expect(_relativeFiles(root), [
        'lib/app/app.dart',
        'lib/features/auth/ui/viewmodels/auth_viewmodel.dart',
        'lib/features/auth/ui/views/auth_view.dart',
        'pubspec.yaml',
      ]);
    },
  );
}

Directory _projectRoot({String pubspec = 'name: test_app\n'}) {
  final root = Directory.systemTemp.createTempSync('cuboid_feature_test_');
  File('${root.path}/pubspec.yaml').writeAsStringSync(pubspec);
  Directory('${root.path}/lib/features').createSync(recursive: true);
  return root;
}

List<String> _relativeFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.substring(root.path.length + 1))
      .map((path) => path.replaceAll(Platform.pathSeparator, '/'))
      .toList()
    ..sort();
}
