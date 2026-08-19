import 'dart:io';

import 'package:cuboid/src/edit/generated_edits.dart';
import 'package:cuboid/src/route/register_route.dart';

/// This is the narrow inverse of automatic route registration only -- it
/// does **not** touch the View/ViewModel files themselves; that is what
/// `delete_view.dart` / `delete_feature.dart` are for. There is likewise no
/// standalone `cuboid create route` (see the doc comment atop
/// `register_route.dart`): a route is always created as a side effect of
/// creating a feature or View, and `cuboid delete route` exists only as an
/// escape hatch for un-registering a route without touching its files, e.g.
/// after a View was renamed or moved by hand.
class DeleteRouteInput {
  const DeleteRouteInput({
    required this.name,
    this.projectRoot,
    this.dryRun = false,
  });

  final String name;
  final Directory? projectRoot;
  final bool dryRun;
}

class DeleteRoutePlan {
  const DeleteRoutePlan({
    required this.name,
    required this.routerPath,
    required this.dryRun,
  });

  final String name;
  final String routerPath;
  final bool dryRun;
}

class DeleteRouteResult {
  const DeleteRouteResult({required this.plan});

  final DeleteRoutePlan plan;
}

class DeleteRouteException implements Exception {
  const DeleteRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeleteRouteService {
  Future<DeleteRoutePlan> plan(DeleteRouteInput input) async {
    final viewName = _normalizeName(input.name);
    return DeleteRoutePlan(
      name: viewName,
      routerPath: 'lib/app/app.router.dart',
      dryRun: input.dryRun,
    );
  }

  Future<DeleteRouteResult> delete(DeleteRouteInput input) async {
    final deletePlan = await plan(input);
    final projectRoot = (input.projectRoot ?? Directory.current).absolute;
    final routerFile = targetFile(projectRoot, deletePlan.routerPath);

    if (!isRegularFile(routerFile.path)) {
      throw DeleteRouteException('${deletePlan.routerPath} was not found.');
    }
    final routerContents = _readFile(routerFile, deletePlan.routerPath);

    final String importLine;
    final String nextContents;
    try {
      importLine = findRouteImportLine(routerContents, deletePlan.name);
      nextContents = removeRouteRegistration(
        routerContents,
        viewName: deletePlan.name,
        importLine: importLine,
      );
    } on RouteRegistrationException catch (error) {
      throw DeleteRouteException(error.message);
    }

    if (deletePlan.dryRun) {
      return DeleteRouteResult(plan: deletePlan);
    }

    try {
      atomicReplaceFileContents(routerFile, nextContents);
    } on FileSystemException catch (error) {
      throw DeleteRouteException(
        'Unable to delete route ${deletePlan.name}: ${error.message}',
      );
    }

    return DeleteRouteResult(plan: deletePlan);
  }
}

String _readFile(File file, String label) {
  try {
    return file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw DeleteRouteException('Unable to read $label: ${error.message}');
  }
}

String _normalizeName(String input) {
  final value = input.trim();
  if (value.isEmpty) {
    throw const DeleteRouteException('View name must not be empty.');
  }
  if (value == '.' || value == '..') {
    throw const DeleteRouteException(
      'View name must be a lower snake_case identifier.',
    );
  }
  if (value.contains('/') ||
      value.contains('\\') ||
      value.split(RegExp(r'[/\\]')).contains('..')) {
    throw const DeleteRouteException(
      'View name must not contain path separators or traversal.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z][A-Za-z0-9]*)*$',
  ).hasMatch(value)) {
    throw const DeleteRouteException(
      'View name must use letters and numbers separated by _ or -.',
    );
  }
  return value.replaceAll('-', '_').toLowerCase();
}
