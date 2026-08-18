import 'package:flutter/material.dart';

/// Navigates using a global [navigatorKey] so view models can request
/// navigation without holding a [BuildContext]. Replaces
/// `stacked_services`' `NavigationService`.
class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError('NavigationService used before a Navigator exists.');
    }
    return state;
  }

  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return _navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  Future<T?> replaceWith<T, TO>(String routeName, {Object? arguments}) {
    return _navigator.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
    );
  }

  void back<T>({T? result}) {
    if (_navigator.canPop()) {
      _navigator.pop<T>(result);
    }
  }
}
