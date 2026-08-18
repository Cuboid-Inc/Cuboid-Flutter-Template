/// Internal route-registration helpers.
///
/// There is no longer a standalone `cuboid create route` (or legacy
/// `cuboid route`) command: creating a feature or an additional view
/// registers its route automatically, matching the intended architecture
/// where a View always has a corresponding route. This module is the shared
/// implementation both `create_feature.dart` and `create_view.dart` patch
/// `lib/app/app.router.dart` with; it performs no file I/O itself so callers
/// can compose it into their own validate/write/rollback sequence.
class RouteRegistrationException implements Exception {
  const RouteRegistrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RouteRegistration {
  const RouteRegistration({
    required this.viewClassName,
    required this.routeConstantName,
    required this.routePath,
    required this.importLine,
    required this.routeConstLine,
    required this.routeMapLine,
  });

  final String viewClassName;
  final String routeConstantName;
  final String routePath;
  final String importLine;
  final String routeConstLine;
  final String routeMapLine;
}

RouteRegistration planRouteRegistration({
  required String packageName,
  required String featureName,
  required String viewName,
}) {
  return _planRouteRegistration(
    viewName: viewName,
    importLine:
        "import 'package:$packageName/features/$featureName/ui/${viewName}_view.dart';",
  );
}

/// Same as [planRouteRegistration] but for a shared View that lives under
/// `lib/shared/views/` instead of a feature directory.
RouteRegistration planSharedRouteRegistration({
  required String packageName,
  required String viewName,
}) {
  return _planRouteRegistration(
    viewName: viewName,
    importLine:
        "import 'package:$packageName/shared/views/${viewName}_view.dart';",
  );
}

RouteRegistration _planRouteRegistration({
  required String viewName,
  required String importLine,
}) {
  final words = viewName.split('_');
  final viewClassName = '${_pascalCase(words)}View';
  final routeConstantName = '${_camelCase(words)}View';
  final routePath = '/${viewName.replaceAll('_', '-')}-view';

  return RouteRegistration(
    viewClassName: viewClassName,
    routeConstantName: routeConstantName,
    routePath: routePath,
    importLine: importLine,
    routeConstLine: "static const $routeConstantName = '$routePath';",
    routeMapLine: 'Routes.$routeConstantName: (_) => const $viewClassName(),',
  );
}

/// Marker comments patched in `lib/app/app.router.dart`. `route` is
/// deliberately not a prefix of `routeConst` (or vice versa); [_markerPattern]
/// also anchors each marker to its own line so a prefix relationship would
/// not cause double-counting or a misplaced insertion regardless.
const _importMarker = '// @cuboid-import';
const _routeConstMarker = '// @cuboid-route-const';
const _routeMapMarker = '// @cuboid-route';

/// Validates that [routerContents] (the contents of `lib/app/app.router.dart`)
/// can accept [registration] without conflict. Throws
/// [RouteRegistrationException] otherwise.
void validateRouteRegistration(
  String routerContents,
  RouteRegistration registration,
) {
  _requireSingleMarker(routerContents, _importMarker);
  _requireSingleMarker(routerContents, _routeConstMarker);
  _requireSingleMarker(routerContents, _routeMapMarker);
  if (routerContents.contains(registration.importLine)) {
    throw RouteRegistrationException(
      'Route import already exists for ${registration.viewClassName}.',
    );
  }
  if (RegExp(
    r'static\s+const\s+' +
        RegExp.escape(registration.routeConstantName) +
        r'\b',
  ).hasMatch(routerContents)) {
    throw RouteRegistrationException(
      'Route already exists for ${registration.viewClassName}.',
    );
  }
  if (routerContents.contains('const ${registration.viewClassName}()')) {
    throw RouteRegistrationException(
      'Route already exists for ${registration.viewClassName}.',
    );
  }
}

/// Returns [routerContents] with [registration] applied. Callers must call
/// [validateRouteRegistration] first.
String applyRouteRegistration(
  String routerContents,
  RouteRegistration registration,
) {
  final lineEnding = routerContents.contains('\r\n') ? '\r\n' : '\n';
  var contents = _insertBeforeMarker(
    routerContents,
    _importMarker,
    registration.importLine,
    lineEnding,
  );
  contents = _insertBeforeMarker(
    contents,
    _routeConstMarker,
    registration.routeConstLine,
    lineEnding,
  );
  contents = _insertBeforeMarker(
    contents,
    _routeMapMarker,
    registration.routeMapLine,
    lineEnding,
  );
  return contents;
}

RegExp _markerPattern(String marker) {
  return RegExp(
    r'^([ \t]*)' + RegExp.escape(marker) + r'[ \t]*$',
    multiLine: true,
  );
}

void _requireSingleMarker(String contents, String marker) {
  final count = _markerPattern(marker).allMatches(contents).length;
  if (count == 0) {
    throw RouteRegistrationException('Missing marker: $marker');
  }
  if (count > 1) {
    throw RouteRegistrationException('Duplicate marker: $marker');
  }
}

String _insertBeforeMarker(
  String contents,
  String marker,
  String newLine,
  String lineEnding,
) {
  return contents.replaceFirstMapped(_markerPattern(marker), (match) {
    final indent = match.group(1) ?? '';
    return '$indent$newLine$lineEnding$indent$marker';
  });
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}

String _camelCase(List<String> words) {
  if (words.isEmpty) return '';
  final pascal = _pascalCase(words);
  return pascal[0].toLowerCase() + pascal.substring(1);
}
