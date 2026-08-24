import 'package:flutter/widgets.dart';

import 'cuboid_page_route.dart';

/// Configures Cuboid's interactive, iOS-style swipe-to-go-back gesture.
///
/// Applied per [CuboidPageRoute]. Set
/// `CuboidPageRoute.defaultSwipeBack` once during app startup to change the
/// default every route pushed through `app.router.dart`'s
/// `onGenerateRoute` or `NavigationService`'s direct-widget push methods
/// gets, or pass one to an individual [CuboidPageRoute] to override it for
/// that route alone.
///
/// Defaults match native platform conventions: enabled on iOS, disabled on
/// Android (which keeps its own system/predictive back gesture). Pass
/// `enabledOnAndroid: true` to opt an app into the same interactive gesture
/// on Android too.
@immutable
class SwipeBackConfiguration {
  const SwipeBackConfiguration({
    this.enabled = true,
    this.enabledOnAndroid = false,
    this.completionThreshold = 0.5,
    this.minFlingVelocity = 700.0,
    this.transitionDuration = const Duration(milliseconds: 350),
  }) : assert(
         completionThreshold > 0 && completionThreshold <= 1,
         'completionThreshold must be in the range (0, 1].',
       ),
       assert(minFlingVelocity > 0, 'minFlingVelocity must be positive.');

  /// Master switch for the gesture. When `false`, no platform gets it,
  /// regardless of [enabledOnAndroid].
  final bool enabled;

  /// Opts Android into the same interactive gesture iOS gets by default.
  /// Ignored when [enabled] is `false`.
  final bool enabledOnAndroid;

  /// Fraction of the route's width, in the range `(0, 1]`, the user must
  /// drag past before a slow release completes the pop instead of
  /// springing back to the route's original position.
  final double completionThreshold;

  /// Logical pixels per second a release must exceed, in the direction of
  /// completing the gesture, to decide the outcome by velocity rather than
  /// by [completionThreshold].
  final double minFlingVelocity;

  /// How long the settle animation takes once the gesture is released --
  /// either finishing the pop or springing the route back into place.
  final Duration transitionDuration;

  /// Swipe-back disabled outright, on every platform.
  static const SwipeBackConfiguration disabled = SwipeBackConfiguration(
    enabled: false,
  );

  /// Whether the gesture should be offered on [platform] under this
  /// configuration.
  bool isEnabledFor(TargetPlatform platform) {
    if (!enabled) return false;
    return switch (platform) {
      TargetPlatform.iOS => true,
      TargetPlatform.android => enabledOnAndroid,
      _ => false,
    };
  }
}
