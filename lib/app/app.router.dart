import 'package:cuboid_flutter_template/features/home/ui/home_view.dart';
import 'package:cuboid_flutter_template/features/startup/ui/startup_view.dart';
import 'package:flutter/material.dart';
// @cuboid-import

class Routes {
  static const startupView = '/';
  static const homeView = '/home-view';
  // @cuboid-route-const
}

final Map<String, WidgetBuilder> appRoutes = {
  Routes.startupView: (_) => const StartupView(),
  Routes.homeView: (_) => const HomeView(),
  // @cuboid-route
};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}
