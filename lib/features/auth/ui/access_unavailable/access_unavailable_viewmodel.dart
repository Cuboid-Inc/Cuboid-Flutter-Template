import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AccessUnavailableViewModel extends BaseViewModel {
  final _auth = locator<AuthRepository>();
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();

  Future<void> signOut() async {
    switch (await _auth.signOut()) {
      case Success():
        await _navigation.clearStackAndShow(Routes.loginView);
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }

  Future<void> retry() async {
    await _navigation.clearStackAndShow(Routes.startupView);
  }
}
