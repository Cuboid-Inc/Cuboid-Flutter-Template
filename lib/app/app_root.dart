import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/constants/app_constants.dart';
import 'package:cuboid_flutter_template/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:upgrader/upgrader.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      navigatorKey: StackedService.navigatorKey,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      initialRoute: Routes.startupView,
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          UpgradeAlert(child: child ?? const SizedBox()),
    );
  }
}
