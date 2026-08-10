import 'package:nemara_homes/app/app.locator.dart';
import 'package:nemara_homes/app/app.router.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  Future<void> init() async {
    await _navigationService.replaceWith(Routes.shellView);
  }
}
