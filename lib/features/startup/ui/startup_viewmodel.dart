import 'package:cuboid_flutter/cuboid_flutter.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/services/navigation_service.dart';

class StartupViewModel extends CuboidViewModel {
  final _navigationService = locator<NavigationService>();

  Future<void> init() async {
    await _navigationService.replaceWith(Routes.homeView);
  }
}
