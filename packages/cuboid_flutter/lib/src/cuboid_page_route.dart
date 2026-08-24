import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'swipe_back_configuration.dart';

/// A [MaterialPageRoute] that adds Cuboid's interactive swipe-to-go-back
/// gesture on top of the platform's normal push/pop transition.
///
/// Used in place of [MaterialPageRoute] everywhere Cuboid constructs a
/// route -- `app.router.dart`'s `onGenerateRoute` and
/// `NavigationService`'s direct-widget push methods -- so every screen
/// gets the gesture for free, with no per-screen wiring.
///
/// The platform's own transition (`CupertinoPageTransitionsBuilder` on
/// iOS, `ZoomPageTransitionsBuilder`/predictive back elsewhere) is left
/// intact; this route only adds a gesture layer above it. That layer
/// drags the route's own [controller] -- the exact [AnimationController]
/// Flutter's push/pop animation already uses -- so programmatic
/// navigation, `Navigator.pop`, and system back all keep working exactly
/// as before, and there is no separate navigation state to fall out of
/// sync.
///
/// See [SwipeBackConfiguration] for what's configurable, and
/// [defaultSwipeBack] for changing the app-wide default.
class CuboidPageRoute<T> extends MaterialPageRoute<T> {
  CuboidPageRoute({
    required super.builder,
    super.settings,
    super.requestFocus,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
    SwipeBackConfiguration? swipeBack,
  }) : swipeBack = swipeBack ?? defaultSwipeBack;

  /// Configuration used by [CuboidPageRoute]s constructed without an
  /// explicit [swipeBack] override. Set once during app startup, before
  /// the first route is pushed, to change swipe-back behavior for the
  /// whole app -- for example:
  ///
  /// ```dart
  /// void main() {
  ///   CuboidPageRoute.defaultSwipeBack = const SwipeBackConfiguration(
  ///     enabledOnAndroid: true,
  ///   );
  ///   runApp(const MyApp());
  /// }
  /// ```
  static SwipeBackConfiguration defaultSwipeBack =
      const SwipeBackConfiguration();

  /// The swipe-back behavior for this route.
  final SwipeBackConfiguration swipeBack;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final platform = Theme.of(context).platform;

    final Widget page;
    if (platform == TargetPlatform.iOS && !fullscreenDialog) {
      // Reimplemented rather than delegated to super so we can attach our
      // own gesture detector below instead of the narrow 20px edge
      // detector CupertinoPageTransitionsBuilder installs internally --
      // running both at once would double-enter the gesture arena for the
      // same touch in that edge sliver.
      page = cupertino.CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: popGestureInProgress,
        child: child,
      );
    } else {
      // Fullscreen dialogs and every other platform keep their normal,
      // unmodified transition (CupertinoFullscreenDialogTransition on iOS,
      // the theme's PageTransitionsBuilder everywhere else).
      page = super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    if (!swipeBack.isEnabledFor(platform)) return page;

    return _SwipeBackGestureDetector<T>(
      route: this,
      // `controller` is `@protected` on TransitionRoute -- read it here,
      // an instance member of a TransitionRoute subclass, rather than
      // from the unrelated detector/controller classes below.
      controller: controller!,
      configuration: swipeBack,
      child: page,
    );
  }
}

/// Wraps [child] in a full-surface, horizontal-drag gesture region that
/// drives [route]'s own transition [AnimationController] the same way
/// Flutter's built-in Cupertino edge-swipe does, just without the edge
/// restriction.
///
/// Rendered as a [Positioned.fill] `Listener` layered with (not on top
/// of, in hit-testing terms -- see [HitTestBehavior.translucent]) [child],
/// so it never blocks taps, and only claims a gesture once a
/// [HorizontalDragGestureRecognizer] decides the pointer's movement is
/// horizontally dominant. That lets vertical scrolling, and any
/// descendant's own horizontal gesture handling (a `PageView`, a
/// carousel, a slider, a map's platform view), win the gesture arena for
/// gestures that are legitimately theirs: descendants are hit-tested, and
/// so enter the arena, before this ancestor listener does, so in a
/// genuine conflict the more specific widget gets the first claim.
class _SwipeBackGestureDetector<T> extends StatefulWidget {
  const _SwipeBackGestureDetector({
    super.key,
    required this.route,
    required this.controller,
    required this.configuration,
    required this.child,
  });

  final PageRoute<T> route;
  final AnimationController controller;
  final SwipeBackConfiguration configuration;
  final Widget child;

  @override
  State<_SwipeBackGestureDetector<T>> createState() =>
      _SwipeBackGestureDetectorState<T>();
}

class _SwipeBackGestureDetectorState<T>
    extends State<_SwipeBackGestureDetector<T>> {
  _CuboidBackGestureController<T>? _backGestureController;
  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    // If this is disposed mid-drag, tell the navigator the user gesture is
    // over once the current frame finishes, mirroring Cupertino's own
    // back-gesture detector.
    if (_backGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_backGestureController?.navigator.mounted ?? false) {
          _backGestureController?.navigator.didStopUserGesture();
        }
        _backGestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    final width = context.size?.width;
    if (width == null || width == 0) return;
    _backGestureController = _CuboidBackGestureController<T>(
      navigator: widget.route.navigator!,
      controller: widget.controller,
      completionThreshold: widget.configuration.completionThreshold,
      minFlingVelocityFraction: widget.configuration.minFlingVelocity / width,
      settleDuration: widget.configuration.transitionDuration,
      getIsCurrent: () => widget.route.isCurrent,
      getIsActive: () => widget.route.isActive,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final width = context.size?.width;
    if (width == null || width == 0) return;
    _backGestureController?.dragUpdate(
      _convertToLogical(details.primaryDelta! / width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    final width = context.size?.width;
    final velocity = (width == null || width == 0)
        ? 0.0
        : _convertToLogical(details.velocity.pixelsPerSecond.dx / width);
    _backGestureController?.dragEnd(velocity);
    _backGestureController = null;
  }

  void _handleDragCancel() {
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.route.popGestureEnabled) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// Drives [controller] -- a [PageRoute]'s own transition animation
/// controller -- directly from drag input, the same way Flutter's
/// built-in Cupertino edge-swipe gesture does. Works entirely in logical
/// coordinates: `1.0` is the route fully shown, `0.0` is fully popped
/// away.
class _CuboidBackGestureController<T> {
  _CuboidBackGestureController({
    required this.navigator,
    required this.controller,
    required this.completionThreshold,
    required this.minFlingVelocityFraction,
    required this.settleDuration,
    required this.getIsCurrent,
    required this.getIsActive,
  }) {
    navigator.didStartUserGesture();
  }

  final NavigatorState navigator;
  final AnimationController controller;
  final double completionThreshold;
  final double minFlingVelocityFraction;
  final Duration settleDuration;
  final ValueGetter<bool> getIsCurrent;
  final ValueGetter<bool> getIsActive;

  /// [delta] is the drag's horizontal movement since the last update, as a
  /// fraction of the route's width. Positive values drag right (revealing
  /// the previous route), so they subtract from the controller.
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  /// [velocity] is the release velocity as a fraction of the route's
  /// width per second.
  void dragEnd(double velocity) {
    const curve = Curves.fastEaseInToSlowEaseOut;
    final isCurrent = getIsCurrent();
    final bool cancel;

    if (!isCurrent) {
      // The route was already navigated away from programmatically while
      // the drag was in progress; follow that outcome regardless of where
      // the drag ended up. See flutter/flutter#141268 for the equivalent
      // Cupertino fix this mirrors.
      cancel = getIsActive();
    } else if (velocity.abs() >= minFlingVelocityFraction) {
      cancel = velocity <= 0;
    } else {
      cancel = controller.value > (1 - completionThreshold);
    }

    if (cancel) {
      controller.animateTo(1.0, duration: settleDuration, curve: curve);
    } else {
      if (isCurrent) {
        // Reuse the navigator's own pop so this participates in the normal
        // Navigator/NavigationService pop path -- no separate stack, no
        // duplicate pop.
        navigator.pop();
      }
      if (controller.isAnimating) {
        controller.animateBack(0.0, duration: settleDuration, curve: curve);
      }
    }

    if (controller.isAnimating) {
      late AnimationStatusListener statusListener;
      statusListener = (status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(statusListener);
      };
      controller.addStatusListener(statusListener);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
