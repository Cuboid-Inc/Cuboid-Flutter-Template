import 'dart:async';

import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart' as app_router;
import 'package:cuboid_flutter_template/core/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/service_mocks.dart';

const _routeA = '/a';
const _routeB = '/b';
const _routeC = '/c';
const _routeD = '/d';

final _testRoutes = <String, WidgetBuilder>{
  _routeA: (_) => const _ScreenWithArgs('A'),
  _routeB: (_) => const _ScreenWithArgs('B'),
  _routeC: (_) => const _ScreenWithArgs('C'),
  _routeD: (_) => const _ScreenWithArgs('D'),
};

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final builder = _testRoutes[settings.name];
  if (builder == null) return null;
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}

class _ScreenWithArgs extends StatelessWidget {
  const _ScreenWithArgs(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return Scaffold(
      body: Column(
        children: [
          Text('screen:$label'),
          if (arguments != null) Text('args:$arguments'),
        ],
      ),
    );
  }
}

class _AdHocView extends StatelessWidget {
  const _AdHocView(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('adhoc:$label'));
  }
}

// [NavigationService.navigatorKey] is a process-wide static GlobalKey.
// Detach it from whatever tree the previous test left it on before
// attaching it to a fresh Navigator, so each test starts from a clean
// single-route stack.
Future<void> _releaseNavigatorKey(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

Future<void> _pumpTestApp(
  WidgetTester tester, {
  String initialRoute = _routeA,
}) async {
  await _releaseNavigatorKey(tester);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: initialRoute,
      onGenerateRoute: _onGenerateRoute,
    ),
  );
}

void main() {
  late NavigationService service;

  setUp(() {
    service = NavigationService();
  });

  group('navigateTo', () {
    testWidgets('pushes the named route on top of the stack', (tester) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB));
      await tester.pumpAndSettle();

      expect(find.text('screen:B'), findsOneWidget);
      expect(find.text('screen:A'), findsNothing);
    });

    testWidgets('passes arguments through to the pushed route', (tester) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB, arguments: 'payload'));
      await tester.pumpAndSettle();

      expect(find.text('args:payload'), findsOneWidget);
    });

    testWidgets('resolves with the result passed to back', (tester) async {
      await _pumpTestApp(tester);
      String? result;

      unawaited(
        service.navigateTo<String>(_routeB).then((value) => result = value),
      );
      await tester.pumpAndSettle();
      service.back<String>(result: 'from-b');
      await tester.pumpAndSettle();

      expect(result, 'from-b');
      expect(find.text('screen:A'), findsOneWidget);
    });
  });

  group('replaceWith', () {
    testWidgets('replaces the current route instead of stacking it', (
      tester,
    ) async {
      await _pumpTestApp(tester);

      unawaited(service.replaceWith(_routeB));
      await tester.pumpAndSettle();

      expect(find.text('screen:B'), findsOneWidget);
      expect(service.canPop, isFalse);
    });
  });

  group('back', () {
    testWidgets('pops the current route and is a no-op at the root', (
      tester,
    ) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB));
      await tester.pumpAndSettle();
      expect(find.text('screen:B'), findsOneWidget);

      service.back();
      await tester.pumpAndSettle();
      expect(find.text('screen:A'), findsOneWidget);

      service.back();
      await tester.pumpAndSettle();
      expect(find.text('screen:A'), findsOneWidget);
    });
  });

  group('popUntil', () {
    testWidgets('pops routes until the predicate matches', (tester) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB));
      await tester.pumpAndSettle();
      unawaited(service.navigateTo(_routeC));
      await tester.pumpAndSettle();
      expect(find.text('screen:C'), findsOneWidget);

      service.popUntil(ModalRoute.withName(_routeA));
      await tester.pumpAndSettle();

      expect(find.text('screen:A'), findsOneWidget);
    });
  });

  group('backTo', () {
    testWidgets('pops routes until the named route is current', (tester) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB));
      await tester.pumpAndSettle();
      unawaited(service.navigateTo(_routeC));
      await tester.pumpAndSettle();

      service.backTo(_routeB);
      await tester.pumpAndSettle();

      expect(find.text('screen:B'), findsOneWidget);
    });
  });

  group('pushNamedAndRemoveUntil', () {
    testWidgets('removes routes that fail the predicate', (tester) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB));
      await tester.pumpAndSettle();

      unawaited(
        service.pushNamedAndRemoveUntil(
          _routeC,
          predicate: ModalRoute.withName(_routeA),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('screen:C'), findsOneWidget);

      service.back();
      await tester.pumpAndSettle();

      expect(find.text('screen:A'), findsOneWidget);
    });
  });

  group('clearStackAndShow', () {
    testWidgets('leaves the new route as the only entry on the stack', (
      tester,
    ) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB));
      await tester.pumpAndSettle();
      unawaited(service.navigateTo(_routeC));
      await tester.pumpAndSettle();

      unawaited(service.clearStackAndShow(_routeD));
      await tester.pumpAndSettle();

      expect(find.text('screen:D'), findsOneWidget);
      expect(service.canPop, isFalse);
    });
  });

  group('navigateToView', () {
    testWidgets('pushes a widget directly without a registered route', (
      tester,
    ) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateToView(const _AdHocView('x')));
      await tester.pumpAndSettle();

      expect(find.text('adhoc:x'), findsOneWidget);
      expect(service.canPop, isTrue);
    });

    testWidgets('resolves with the result passed to back', (tester) async {
      await _pumpTestApp(tester);
      String? result;

      unawaited(
        service
            .navigateToView<String>(const _AdHocView('x'))
            .then((value) => result = value),
      );
      await tester.pumpAndSettle();
      service.back<String>(result: 'from-adhoc');
      await tester.pumpAndSettle();

      expect(result, 'from-adhoc');
    });
  });

  group('replaceWithView', () {
    testWidgets('replaces the current route with the widget', (tester) async {
      await _pumpTestApp(tester);

      unawaited(service.replaceWithView(const _AdHocView('y')));
      await tester.pumpAndSettle();

      expect(find.text('adhoc:y'), findsOneWidget);
      expect(service.canPop, isFalse);
    });
  });

  group('pushAndRemoveUntil', () {
    testWidgets('pushes the widget and removes routes per the predicate', (
      tester,
    ) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB));
      await tester.pumpAndSettle();

      unawaited(
        service.pushAndRemoveUntil(
          const _AdHocView('z'),
          predicate: ModalRoute.withName(_routeA),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('adhoc:z'), findsOneWidget);

      service.back();
      await tester.pumpAndSettle();

      expect(find.text('screen:A'), findsOneWidget);
    });
  });

  group('clearStackAndShowView', () {
    testWidgets('leaves the widget as the only entry on the stack', (
      tester,
    ) async {
      await _pumpTestApp(tester);

      unawaited(service.navigateTo(_routeB));
      await tester.pumpAndSettle();

      unawaited(service.clearStackAndShowView(const _AdHocView('w')));
      await tester.pumpAndSettle();

      expect(find.text('adhoc:w'), findsOneWidget);
      expect(service.canPop, isFalse);
    });
  });

  group('interaction with app.router.dart', () {
    testWidgets('follows the real startup route through to home, matching the '
        "app's actual onGenerateRoute/Routes table", (tester) async {
      // StartupView's StartupViewModel resolves NavigationService from
      // the locator (see lib/features/startup/ui/startup_viewmodel.dart).
      replaceTestRegistration<NavigationService>(NavigationService());
      addTearDown(() {
        if (locator.isRegistered<NavigationService>()) {
          locator.unregister<NavigationService>();
        }
      });

      await _releaseNavigatorKey(tester);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          initialRoute: app_router.Routes.startupView,
          onGenerateRoute: app_router.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
      expect(service.canPop, isFalse);
    });
  });
}
