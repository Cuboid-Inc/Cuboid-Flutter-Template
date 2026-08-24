import 'dart:async';

import 'package:cuboid_flutter/cuboid_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PopCountingObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

/// Pumps a `MaterialApp` with a single "first" screen already on the stack,
/// then pushes a "second" [CuboidPageRoute] on top of it so tests can drag
/// it back down.
Future<void> _pumpAppWithSecondRoute(
  WidgetTester tester, {
  required TargetPlatform platform,
  SwipeBackConfiguration? swipeBack,
  NavigatorObserver? observer,
  bool secondRouteCanPop = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      navigatorObservers: [?observer],
      home: const Scaffold(body: Center(child: Text('first'))),
    ),
  );

  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  final secondScreen = Scaffold(body: const Center(child: Text('second')));

  unawaited(
    navigator.push<void>(
      CuboidPageRoute<void>(
        swipeBack: swipeBack,
        builder: (_) => secondRouteCanPop
            ? secondScreen
            : PopScope(canPop: false, child: secondScreen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A slow, controlled-velocity drag from the left-of-center of the screen,
/// covering [fraction] of the app's width. Long duration keeps velocity
/// well under any reasonable fling threshold, isolating the
/// completion-threshold decision from the velocity-based one.
Future<void> _slowDrag(WidgetTester tester, double fraction) async {
  final width = tester.getSize(find.byType(MaterialApp)).width;
  await tester.timedDragFrom(
    const Offset(20, 300),
    Offset(width * fraction, 0),
    const Duration(seconds: 2),
  );
}

/// A short, fast drag simulating a fling: covers a modest, sub-threshold
/// distance but in very little time, so its average velocity clears the
/// default fling threshold.
Future<void> _fling(WidgetTester tester) async {
  await tester.timedDragFrom(
    const Offset(20, 300),
    const Offset(150, 0),
    const Duration(milliseconds: 50),
  );
}

void main() {
  group('iOS (enabled by default)', () {
    testWidgets('dragging past the completion threshold pops the route', (
      tester,
    ) async {
      final observer = _PopCountingObserver();
      await _pumpAppWithSecondRoute(
        tester,
        platform: TargetPlatform.iOS,
        observer: observer,
      );
      expect(find.text('second'), findsOneWidget);

      await _slowDrag(tester, 0.7);
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(observer.popCount, 1);
    });

    testWidgets('dragging under the threshold springs back without popping', (
      tester,
    ) async {
      await _pumpAppWithSecondRoute(tester, platform: TargetPlatform.iOS);

      await _slowDrag(tester, 0.2);
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });

    testWidgets('a fast fling under the threshold still completes the pop', (
      tester,
    ) async {
      await _pumpAppWithSecondRoute(tester, platform: TargetPlatform.iOS);

      await _fling(tester);
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing);
    });

    testWidgets('a vertical drag does not trigger navigation', (tester) async {
      await _pumpAppWithSecondRoute(tester, platform: TargetPlatform.iOS);
      final width = tester.getSize(find.byType(MaterialApp)).width;

      await tester.timedDragFrom(
        Offset(width / 2, 100),
        const Offset(0, 400),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('does nothing when there is no route to pop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(body: Center(child: Text('only'))),
        ),
      );

      await _slowDrag(tester, 0.9);
      await tester.pumpAndSettle();

      expect(find.text('only'), findsOneWidget);
    });

    testWidgets('a route that disables popping ignores the gesture', (
      tester,
    ) async {
      await _pumpAppWithSecondRoute(
        tester,
        platform: TargetPlatform.iOS,
        secondRouteCanPop: false,
      );

      await _slowDrag(tester, 0.9);
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('a completed swipe pops exactly once', (tester) async {
      final observer = _PopCountingObserver();
      await _pumpAppWithSecondRoute(
        tester,
        platform: TargetPlatform.iOS,
        observer: observer,
      );

      await _slowDrag(tester, 0.9);
      await tester.pumpAndSettle();

      expect(observer.popCount, 1);
    });
  });

  group('Android (disabled by default)', () {
    testWidgets('swipe-back does nothing by default', (tester) async {
      await _pumpAppWithSecondRoute(tester, platform: TargetPlatform.android);

      await _slowDrag(tester, 0.9);
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('swipe-back works once explicitly enabled', (tester) async {
      await _pumpAppWithSecondRoute(
        tester,
        platform: TargetPlatform.android,
        swipeBack: const SwipeBackConfiguration(enabledOnAndroid: true),
      );

      await _slowDrag(tester, 0.9);
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
    });

    testWidgets('system back (Navigator.maybePop) still works', (tester) async {
      await _pumpAppWithSecondRoute(tester, platform: TargetPlatform.android);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));

      await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
    });
  });

  testWidgets('programmatic Navigator.pop still works alongside the gesture', (
    tester,
  ) async {
    await _pumpAppWithSecondRoute(tester, platform: TargetPlatform.iOS);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsNothing);
  });
}
