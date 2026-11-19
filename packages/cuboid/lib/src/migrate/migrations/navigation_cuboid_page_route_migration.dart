/// Cuboid's first real migration: `0.1.0` -> `0.2.0`, moving generated
/// navigation infrastructure from building routes with Flutter's
/// [MaterialPageRoute] directly to Cuboid's own `CuboidPageRoute` (added to
/// `cuboid_flutter` in 0.2.0 for its swipe-back gesture -- see
/// `packages/cuboid_flutter/lib/src/cuboid_page_route.dart`), and adding
/// `NavigationService`'s direct-widget navigation methods where they don't
/// already exist.
///
/// Two files are Cuboid-owned infrastructure here (see ARCHITECTURE.md §8):
/// `lib/app/app.router.dart` and `lib/core/services/navigation_service.dart`.
/// Real generated projects customize both -- extra routes and conditional
/// branches in `onGenerateRoute`, extra imports/methods/comments in
/// `NavigationService` -- so this migration never requires either file to
/// match a known template byte-for-byte. Instead it locates the specific
/// Cuboid-owned *constructs* it needs (the `onGenerateRoute` function body;
/// the `NavigationService` class body) via [dart_source_scanner]'s
/// comment/string-aware bracket matching, then:
///
/// * renames every `MaterialPageRoute` constructor call found inside those
///   constructs to `CuboidPageRoute` -- and *only* the class-name token,
///   leaving builders, arguments, settings, and generic types untouched --
///   whether that call is the canonical boilerplate line or inside a
///   condition/branch the application added later;
/// * appends whichever of `NavigationService`'s 0.2.0-era methods
///   (`navigateToView`, `replaceWithView`, `pushAndRemoveUntil`,
///   `clearStackAndShowView`, `pushNamedAndRemoveUntil`, `clearStackAndShow`,
///   `canPop`, `backTo`, `popUntil`) are entirely missing -- so a project
///   still on the bare pre-0.2 API gets the full surface added, while a
///   project that already has some or all of them (however it got there)
///   only gets what's actually missing;
/// * never touches `navigateTo`/`replaceWith`/`back` (present since 0.1.0)
///   or any other existing method, import, or comment.
///
/// A file this migration cannot confidently recognize as Cuboid-owned --
/// `onGenerateRoute`/`NavigationService` missing entirely, structurally
/// broken, or not constructing routes through `MaterialPageRoute`/
/// `CuboidPageRoute` at all -- is left completely untouched and reported as
/// unsafe to migrate automatically, per [MigrationFileOutcome.unsafeToMigrate].
library;

import 'dart:io';

import 'package:cuboid/src/migrate/dart_source_scanner.dart';
import 'package:cuboid/src/migrate/migration.dart';

const _routerRelativePath = 'lib/app/app.router.dart';
const _navigationServiceRelativePath =
    'lib/core/services/navigation_service.dart';

const _cuboidFlutterImportLine =
    "import 'package:cuboid_flutter/cuboid_flutter.dart';";

final _onGenerateRouteSignature = RegExp(
  r'Route\s*<\s*dynamic\s*>\s*\?\s*onGenerateRoute\s*\(\s*RouteSettings\s+settings\s*\)',
);

final _navigationServiceClassSignature = RegExp(
  r'\bclass\s+NavigationService\b[^{]*',
);

class NavigationCuboidPageRouteMigration extends Migration {
  const NavigationCuboidPageRouteMigration();

  @override
  String get sourceVersion => '0.1.0';

  @override
  String get targetVersion => '0.2.0';

  @override
  String get description =>
      'Move navigation infrastructure from MaterialPageRoute to '
      "cuboid_flutter's CuboidPageRoute (adds the swipe-back gesture).";

  @override
  MigrationAssessment assess(Directory projectRoot) {
    return MigrationAssessment(
      migration: this,
      fileChanges: [
        _assessRouter(projectRoot),
        _assessNavigationService(projectRoot),
      ],
    );
  }

  MigrationFileChange _assessRouter(Directory projectRoot) {
    final file = _fileFor(projectRoot, _routerRelativePath);
    if (!file.existsSync()) {
      return const MigrationFileChange(
        path: _routerRelativePath,
        outcome: MigrationFileOutcome.missing,
      );
    }

    final contents = _normalize(file.readAsStringSync());
    final sigMatch = _onGenerateRouteSignature.firstMatch(contents);
    if (sigMatch == null) {
      return const MigrationFileChange(
        path: _routerRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'Could not locate the onGenerateRoute function that builds '
            'routes for lib/app/app.router.dart.',
      );
    }

    final braceStart = contents.indexOf('{', sigMatch.end);
    if (braceStart == -1) {
      return const MigrationFileChange(
        path: _routerRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: 'onGenerateRoute has no function body to inspect.',
      );
    }

    final int braceEnd;
    try {
      braceEnd = matchingBracketEnd(contents, braceStart);
    } on UnbalancedSourceException {
      return const MigrationFileChange(
        path: _routerRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'onGenerateRoute has unbalanced brackets; cannot safely '
            'locate its function body.',
      );
    }

    final legacyCalls = findConstructorIdentifierSpans(
      contents,
      'MaterialPageRoute',
      start: braceStart,
      end: braceEnd,
    );
    final currentCalls = findConstructorIdentifierSpans(
      contents,
      'CuboidPageRoute',
      start: braceStart,
      end: braceEnd,
    );

    if (legacyCalls.isEmpty && currentCalls.isNotEmpty) {
      return const MigrationFileChange(
        path: _routerRelativePath,
        outcome: MigrationFileOutcome.alreadyCurrent,
      );
    }
    if (legacyCalls.isEmpty) {
      return const MigrationFileChange(
        path: _routerRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'onGenerateRoute does not appear to construct routes with '
            'MaterialPageRoute or CuboidPageRoute; cannot determine how to '
            'migrate it automatically.',
      );
    }

    var updated = _renameConstructorCalls(
      contents,
      legacyCalls,
      'CuboidPageRoute',
    );
    if (!_hasCuboidFlutterImport(updated)) {
      updated = _insertImportAtTop(updated, _cuboidFlutterImportLine);
    }

    return _validated(
      path: _routerRelativePath,
      updated: updated,
      unsafeReason:
          'The navigation migration produced invalid source for '
          'lib/app/app.router.dart; no changes were made.',
    );
  }

  MigrationFileChange _assessNavigationService(Directory projectRoot) {
    final file = _fileFor(projectRoot, _navigationServiceRelativePath);
    if (!file.existsSync()) {
      return const MigrationFileChange(
        path: _navigationServiceRelativePath,
        outcome: MigrationFileOutcome.missing,
      );
    }

    final contents = _normalize(file.readAsStringSync());
    final classMatch = _navigationServiceClassSignature.firstMatch(contents);
    if (classMatch == null) {
      return const MigrationFileChange(
        path: _navigationServiceRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: 'Could not locate a NavigationService class.',
      );
    }

    final braceStart = contents.indexOf('{', classMatch.end);
    if (braceStart == -1) {
      return const MigrationFileChange(
        path: _navigationServiceRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason: 'The NavigationService class has no body to inspect.',
      );
    }

    final int braceEnd;
    try {
      braceEnd = matchingBracketEnd(contents, braceStart);
    } on UnbalancedSourceException {
      return const MigrationFileChange(
        path: _navigationServiceRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'The NavigationService class has unbalanced brackets; cannot '
            'safely locate its body.',
      );
    }

    if (!_hasBaselineNavigationServiceApi(contents, braceStart, braceEnd)) {
      return const MigrationFileChange(
        path: _navigationServiceRelativePath,
        outcome: MigrationFileOutcome.unsafeToMigrate,
        reason:
            'Could not recognize this as a Cuboid-managed NavigationService '
            '(expected navigatorKey, navigateTo, and back to be present).',
      );
    }

    final legacyCalls = findConstructorIdentifierSpans(
      contents,
      'MaterialPageRoute',
      start: braceStart,
      end: braceEnd,
    );
    final missingMethods = [
      for (final method in _newNavigationServiceMethods)
        if (!containsOutsideCommentsAndStrings(
          contents,
          method.detectionSignature,
          start: braceStart,
          end: braceEnd,
        ))
          method,
    ];

    if (legacyCalls.isEmpty && missingMethods.isEmpty) {
      return const MigrationFileChange(
        path: _navigationServiceRelativePath,
        outcome: MigrationFileOutcome.alreadyCurrent,
      );
    }

    var updated = _renameConstructorCalls(
      contents,
      legacyCalls,
      'CuboidPageRoute',
    );
    if (missingMethods.isNotEmpty) {
      // Recompute the class closing brace against `updated`: renaming
      // above only changes text *inside* [braceStart, braceEnd), so the
      // class's own closing-brace offset shifts by the same amount the
      // file grew/shrank before it, which is zero here (renames are
      // same-length-or-not, so recompute defensively rather than assume).
      final newBraceStart = updated.indexOf(
        '{',
        _navigationServiceClassSignature.firstMatch(updated)!.end,
      );
      final newBraceEnd = matchingBracketEnd(updated, newBraceStart);
      updated = _insertMethodsBeforeClassClose(
        updated,
        newBraceEnd,
        missingMethods,
      );
    }
    if (!_hasCuboidFlutterImport(updated)) {
      updated = _insertImportAtTop(updated, _cuboidFlutterImportLine);
    }

    return _validated(
      path: _navigationServiceRelativePath,
      updated: updated,
      unsafeReason:
          'The navigation migration produced invalid source for '
          'lib/core/services/navigation_service.dart; no changes were made.',
    );
  }
}

MigrationFileChange _validated({
  required String path,
  required String updated,
  required String unsafeReason,
}) {
  try {
    validateBalancedBrackets(updated);
  } on UnbalancedSourceException {
    return MigrationFileChange(
      path: path,
      outcome: MigrationFileOutcome.unsafeToMigrate,
      reason: unsafeReason,
    );
  }
  return MigrationFileChange(
    path: path,
    outcome: MigrationFileOutcome.modify,
    newContents: updated,
  );
}

bool _hasBaselineNavigationServiceApi(String contents, int start, int end) {
  return containsOutsideCommentsAndStrings(
        contents,
        'navigatorKey',
        start: start,
        end: end,
      ) &&
      containsOutsideCommentsAndStrings(
        contents,
        'GlobalKey<NavigatorState>',
        start: start,
        end: end,
      ) &&
      containsOutsideCommentsAndStrings(
        contents,
        'Future<T?> navigateTo<T>(',
        start: start,
        end: end,
      ) &&
      containsOutsideCommentsAndStrings(
        contents,
        'void back<T>(',
        start: start,
        end: end,
      );
}

/// Replaces each identifier span in [spans] (as found by
/// [findConstructorIdentifierSpans], sorted ascending) with [replacement].
/// Applies from the end of [source] backward so earlier spans' offsets
/// stay valid as later ones are rewritten.
String _renameConstructorCalls(
  String source,
  List<SourceSpan> spans,
  String replacement,
) {
  var updated = source;
  for (final span in spans.reversed) {
    updated = updated.replaceRange(span.$1, span.$2, replacement);
  }
  return updated;
}

bool _hasCuboidFlutterImport(String contents) {
  return contents.contains(_cuboidFlutterImportLine) ||
      RegExp(
        r'''import\s+['"]package:cuboid_flutter/cuboid_flutter\.dart['"]\s*;''',
      ).hasMatch(contents);
}

String _insertImportAtTop(String contents, String importLine) {
  final importPattern = RegExp(r'^import\s+', multiLine: true);
  final match = importPattern.firstMatch(contents);
  if (match == null) {
    return '$importLine\n\n$contents';
  }
  return contents.replaceRange(match.start, match.start, '$importLine\n');
}

/// Inserts [methods]' canonical source, each separated by a blank line,
/// immediately before the class's closing brace at [classBraceEnd] (the
/// index right after `}`, as returned by [matchingBracketEnd]).
String _insertMethodsBeforeClassClose(
  String contents,
  int classBraceEnd,
  List<_NavigationServiceMethod> methods,
) {
  final closingBraceIndex = classBraceEnd - 1;
  final insertion = methods
      .map((method) => '\n${method.canonicalSource}\n')
      .join();
  return contents.replaceRange(closingBraceIndex, closingBraceIndex, insertion);
}

File _fileFor(Directory projectRoot, String relativePath) {
  return File(
    '${projectRoot.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
}

String _normalize(String contents) => contents.replaceAll('\r\n', '\n');

class _NavigationServiceMethod {
  const _NavigationServiceMethod({
    required this.detectionSignature,
    required this.canonicalSource,
  });

  /// A literal substring unique enough to detect whether this method
  /// already exists somewhere in the class body (searched outside
  /// comments/strings via [containsOutsideCommentsAndStrings]).
  final String detectionSignature;

  /// The exact source to insert (already indented for the class body,
  /// including its doc comment) when [detectionSignature] is absent.
  final String canonicalSource;
}

/// Every `NavigationService` method introduced in 0.2.0 that didn't exist
/// in the bare 0.1.0 API (`navigateTo`/`replaceWith`/`back` predate this
/// migration and are never touched). Each is inserted independently, so a
/// project missing only some of them only gets those added.
final _newNavigationServiceMethods = <_NavigationServiceMethod>[
  const _NavigationServiceMethod(
    detectionSignature: 'Future<T?> pushNamedAndRemoveUntil<T>(',
    canonicalSource: '''
  /// Pushes the route registered as [routeName], then removes every earlier
  /// route for which [predicate] returns `false`.
  Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName, {
    required RoutePredicate predicate,
    Object? arguments,
  }) async {
    final result = await _navigator.pushNamedAndRemoveUntil<dynamic>(
      routeName,
      predicate,
      arguments: arguments,
    );
    return result as T?;
  }''',
  ),
  const _NavigationServiceMethod(
    detectionSignature: 'Future<T?> clearStackAndShow<T>(',
    canonicalSource: '''
  /// Pushes the route registered as [routeName] and removes every other
  /// route, leaving [routeName] as the only entry on the stack.
  Future<T?> clearStackAndShow<T>(String routeName, {Object? arguments}) {
    return pushNamedAndRemoveUntil<T>(
      routeName,
      predicate: (route) => false,
      arguments: arguments,
    );
  }''',
  ),
  const _NavigationServiceMethod(
    detectionSignature: 'Future<T?> navigateToView<T>(',
    canonicalSource: '''
  /// Pushes [view] directly, without going through a registered named
  /// route. Pass [settings] to give the pushed route a name (for example so
  /// [backTo] or [popUntil] can target it later).
  Future<T?> navigateToView<T>(Widget view, {RouteSettings? settings}) {
    return _navigator.push<T>(
      CuboidPageRoute<T>(builder: (_) => view, settings: settings),
    );
  }''',
  ),
  const _NavigationServiceMethod(
    detectionSignature: 'Future<T?> replaceWithView<T, TO>(',
    canonicalSource: '''
  /// Replaces the current route with [view], pushed directly.
  Future<T?> replaceWithView<T, TO>(Widget view, {RouteSettings? settings}) {
    return _navigator.pushReplacement<T, TO>(
      CuboidPageRoute<T>(builder: (_) => view, settings: settings),
    );
  }''',
  ),
  const _NavigationServiceMethod(
    detectionSignature: 'Future<T?> pushAndRemoveUntil<T>(',
    canonicalSource: '''
  /// Pushes [view] directly, then removes every earlier route for which
  /// [predicate] returns `false`.
  Future<T?> pushAndRemoveUntil<T>(
    Widget view, {
    required RoutePredicate predicate,
    RouteSettings? settings,
  }) {
    return _navigator.pushAndRemoveUntil<T>(
      CuboidPageRoute<T>(builder: (_) => view, settings: settings),
      predicate,
    );
  }''',
  ),
  const _NavigationServiceMethod(
    detectionSignature: 'Future<T?> clearStackAndShowView<T>(',
    canonicalSource: '''
  /// Pushes [view] directly and removes every other route, leaving it as
  /// the only entry on the stack.
  Future<T?> clearStackAndShowView<T>(Widget view, {RouteSettings? settings}) {
    return pushAndRemoveUntil<T>(
      view,
      predicate: (route) => false,
      settings: settings,
    );
  }''',
  ),
  const _NavigationServiceMethod(
    detectionSignature: 'bool get canPop',
    canonicalSource: '''
  /// Whether [back] would pop a route right now.
  bool get canPop => _navigator.canPop();''',
  ),
  const _NavigationServiceMethod(
    detectionSignature: 'void backTo(',
    canonicalSource: '''
  /// Pops routes until the route named [routeName] is current. [routeName]
  /// must already be on the stack -- typically the target of an earlier
  /// [navigateTo] call.
  void backTo(String routeName) {
    _navigator.popUntil(ModalRoute.withName(routeName));
  }''',
  ),
  const _NavigationServiceMethod(
    detectionSignature: 'void popUntil(',
    canonicalSource: '''
  /// Pops routes until [predicate] returns `true` for the current route.
  void popUntil(RoutePredicate predicate) {
    _navigator.popUntil(predicate);
  }''',
  ),
];
