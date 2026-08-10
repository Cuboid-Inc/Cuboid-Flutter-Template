import 'package:nemara_homes/core/services/shell_service.dart';
import 'package:nemara_homes/features/home/ui/views/shell_view.dart';
import 'package:nemara_homes/features/startup/ui/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  logger: StackedLogger(logHelperName: "AppLogger"),
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    MaterialRoute(page: ShellView),
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: ShellService),
    // @stacked-service
  ],
)
class App {}
