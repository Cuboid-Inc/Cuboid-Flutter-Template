/// Internal route-registration helpers.
///
/// There is no longer a standalone `cuboid create route` (or legacy
/// `cuboid route`) command: creating a feature or an additional view
/// registers its route automatically, matching the intended architecture
/// where a View always has a corresponding route. This module is the shared
/// implementation both `create_feature.dart` and `create_view.dart` patch
/// `lib/app/app.dart` with; it performs no file I/O itself so callers can
/// compose it into their own validate/write/rollback sequence.
class RouteRegistrationException implements Exception {
  const RouteRegistrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RouteRegistration {
  const RouteRegistration({
    required this.viewClassName,
    required this.importLine,
    required this.routeLine,
  });

  final String viewClassName;
  final String importLine;
  final String routeLine;
}

RouteRegistration planRouteRegistration({
  required String packageName,
  required String featureName,
  required String viewName,
}) {
  final words = viewName.split('_');
  final viewClassName = '${_pascalCase(words)}View';

  return RouteRegistration(
    viewClassName: viewClassName,
    importLine:
        "import 'package:$packageName/features/$featureName/ui/${viewName}_view.dart';",
    routeLine: '    MaterialRoute(page: $viewClassName),',
  );
}

/// Same as [planRouteRegistration] but for a shared View that lives under
/// `lib/shared/views/` instead of a feature directory.
RouteRegistration planSharedRouteRegistration({
  required String packageName,
  required String viewName,
}) {
  final words = viewName.split('_');
  final viewClassName = '${_pascalCase(words)}View';

  return RouteRegistration(
    viewClassName: viewClassName,
    importLine:
        "import 'package:$packageName/shared/views/${viewName}_view.dart';",
    routeLine: '    MaterialRoute(page: $viewClassName),',
  );
}

/// Validates that [appContents] (the contents of `lib/app/app.dart`) can
/// accept [registration] without conflict. Throws
/// [RouteRegistrationException] otherwise.
void validateRouteRegistration(
  String appContents,
  RouteRegistration registration,
) {
  _requireSingleMarker(appContents, '// @stacked-import');
  _requireSingleMarker(appContents, '// @stacked-route');
  if (appContents.contains(registration.importLine)) {
    throw RouteRegistrationException(
      'Route import already exists for ${registration.viewClassName}.',
    );
  }
  if (appContents.contains(
    'MaterialRoute(page: ${registration.viewClassName})',
  )) {
    throw RouteRegistrationException(
      'Route already exists for ${registration.viewClassName}.',
    );
  }
}

/// Returns [appContents] with [registration] applied. Callers must call
/// [validateRouteRegistration] first.
String applyRouteRegistration(
  String appContents,
  RouteRegistration registration,
) {
  final lineEnding = appContents.contains('\r\n') ? '\r\n' : '\n';
  return appContents
      .replaceFirst(
        RegExp(r'^[ \t]*// @stacked-import', multiLine: true),
        '${registration.importLine}$lineEnding// @stacked-import',
      )
      .replaceFirst(
        RegExp(r'^[ \t]*// @stacked-route', multiLine: true),
        '${registration.routeLine}$lineEnding    // @stacked-route',
      );
}

void _requireSingleMarker(String contents, String marker) {
  final count = marker.allMatches(contents).length;
  if (count == 0) {
    throw RouteRegistrationException('Missing marker: $marker');
  }
  if (count > 1) {
    throw RouteRegistrationException('Duplicate marker: $marker');
  }
}

String _pascalCase(List<String> words) {
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join();
}
