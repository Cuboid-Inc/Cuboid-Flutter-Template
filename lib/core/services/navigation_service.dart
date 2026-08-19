import 'package:flutter/material.dart';

/// Navigates using a global [navigatorKey] so view models can request
/// navigation without holding a [BuildContext]. Replaces
/// `stacked_services`' `NavigationService`.
///
/// Two families of methods are provided:
///
/// * Named-route methods ([navigateTo], [replaceWith],
///   [pushNamedAndRemoveUntil], [clearStackAndShow]) push routes registered
///   in `lib/app/app.router.dart`'s `appRoutes`/`onGenerateRoute`, by
///   [Routes] name.
/// * Direct-widget methods ([navigateToView], [replaceWithView],
///   [pushAndRemoveUntil], [clearStackAndShowView]) push a [Widget]
///   instance directly via [MaterialPageRoute], for views that don't need a
///   registered named route (or need constructor arguments `arguments:`
///   can't carry). Cuboid has no route code generation, so these are not
///   per-view generated methods the way Stacked's `navigateToLoginView()`
///   was -- they are generic over any [Widget].
///
/// Stacked capabilities intentionally not reproduced:
///
/// * Multiple/nested navigators (`stacked_services` supported a registry of
///   navigator keys). Cuboid's base template has one [Navigator] via
///   [navigatorKey]; add a second key/service deliberately if a generated
///   app grows nested navigation.
/// * `replaceWithTransition`/custom per-call transitions. Route transitions
///   belong on the [Route] built in `app.router.dart`'s `onGenerateRoute`,
///   not as ad hoc arguments on every navigation call.
class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError('NavigationService used before a Navigator exists.');
    }
    return state;
  }

  // --- Named-route navigation (lib/app/app.router.dart's Routes) ---
  //
  // `app.router.dart`'s `onGenerateRoute` is a plain `RouteFactory`
  // (`Route<dynamic>? Function(RouteSettings)`) -- Cuboid has no route
  // code generation to give each registered route its own static result
  // type. Flutter's `pushNamed<T>`/`pushReplacementNamed<T>`/
  // `pushNamedAndRemoveUntil<T>` cast the `Route<dynamic>` that
  // `onGenerateRoute` returns to `Route<T?>` internally, which throws at
  // runtime for any concrete, non-dynamic `T` -- so these methods push
  // through Flutter untyped (`Route<dynamic>`) and cast the *popped
  // result value* to `T?` themselves once navigation completes, instead of
  // asking Flutter to cast the route object.

  /// Pushes the route registered as [routeName], returning a future that
  /// completes with the result passed to [back] when it is popped.
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) async {
    final result = await _navigator.pushNamed<dynamic>(
      routeName,
      arguments: arguments,
    );
    return result as T?;
  }

  /// Replaces the current route with the route registered as [routeName].
  Future<T?> replaceWith<T, TO>(String routeName, {Object? arguments}) async {
    final result = await _navigator.pushReplacementNamed<dynamic, TO>(
      routeName,
      arguments: arguments,
    );
    return result as T?;
  }

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
  }

  /// Pushes the route registered as [routeName] and removes every other
  /// route, leaving [routeName] as the only entry on the stack.
  Future<T?> clearStackAndShow<T>(String routeName, {Object? arguments}) {
    return pushNamedAndRemoveUntil<T>(
      routeName,
      predicate: (route) => false,
      arguments: arguments,
    );
  }

  // --- Direct-widget navigation ---

  /// Pushes [view] directly, without going through a registered named
  /// route. Pass [settings] to give the pushed route a name (for example so
  /// [backTo] or [popUntil] can target it later).
  Future<T?> navigateToView<T>(Widget view, {RouteSettings? settings}) {
    return _navigator.push<T>(
      MaterialPageRoute<T>(builder: (_) => view, settings: settings),
    );
  }

  /// Replaces the current route with [view], pushed directly.
  Future<T?> replaceWithView<T, TO>(Widget view, {RouteSettings? settings}) {
    return _navigator.pushReplacement<T, TO>(
      MaterialPageRoute<T>(builder: (_) => view, settings: settings),
    );
  }

  /// Pushes [view] directly, then removes every earlier route for which
  /// [predicate] returns `false`.
  Future<T?> pushAndRemoveUntil<T>(
    Widget view, {
    required RoutePredicate predicate,
    RouteSettings? settings,
  }) {
    return _navigator.pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(builder: (_) => view, settings: settings),
      predicate,
    );
  }

  /// Pushes [view] directly and removes every other route, leaving it as
  /// the only entry on the stack.
  Future<T?> clearStackAndShowView<T>(Widget view, {RouteSettings? settings}) {
    return pushAndRemoveUntil<T>(
      view,
      predicate: (route) => false,
      settings: settings,
    );
  }

  // --- Back navigation ---

  /// Whether [back] would pop a route right now.
  bool get canPop => _navigator.canPop();

  /// Pops the current route, if there is one to pop, passing [result] to
  /// the future returned by whichever push call is completing.
  void back<T>({T? result}) {
    if (_navigator.canPop()) {
      _navigator.pop<T>(result);
    }
  }

  /// Pops routes until the route named [routeName] is current. [routeName]
  /// must already be on the stack -- typically the target of an earlier
  /// [navigateTo] call.
  void backTo(String routeName) {
    _navigator.popUntil(ModalRoute.withName(routeName));
  }

  /// Pops routes until [predicate] returns `true` for the current route.
  void popUntil(RoutePredicate predicate) {
    _navigator.popUntil(predicate);
  }
}
