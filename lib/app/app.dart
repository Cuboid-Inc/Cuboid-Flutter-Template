import 'package:cuboid_flutter_template/features/home/ui/home_view.dart';
import 'package:cuboid_flutter_template/features/startup/ui/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  logger: StackedLogger(logHelperName: "AppLogger"),
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    MaterialRoute(page: HomeView),
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    // @stacked-service
  ],
)
class App {}
