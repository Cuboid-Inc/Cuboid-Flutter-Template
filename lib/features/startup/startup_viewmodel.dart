import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class StartupViewModel extends BaseViewModel {
  final _authRepository = locator<AuthRepository>();
  final _navigationService = locator<NavigationService>();

  Future<void> init() async {
    switch (await _authRepository.resolveStartup()) {
      case Failure(:final failure):
        await _navigationService.replaceWith(
          Routes.accessUnavailableView,
          arguments: AccessUnavailableViewArguments(
            title: 'Connection required',
            message: failure.message,
            showRetry: true,
          ),
        );
      case Success(:final value):
        await _open(value);
    }
  }

  Future<void> _open(AuthStartup startup) async {
    switch (startup.destination) {
      case AuthDestination.signedOut:
        await _navigationService.replaceWith(Routes.loginView);
      case AuthDestination.signedIn:
        await _navigationService.replaceWith(Routes.shellView);
      case AuthDestination.passwordRecovery:
        await _navigationService.replaceWith(Routes.resetPasswordView);
      case AuthDestination.invitation:
        final access = startup.access!;
        await _navigationService.replaceWith(
          Routes.acceptInvitationView,
          arguments: AcceptInvitationViewArguments(
            email: access.email,
            businessName: access.tenantName,
            accessPacks: access.accessPacks.toList(),
          ),
        );
      case AuthDestination.accessUnavailable:
        await _navigationService.replaceWith(
          Routes.accessUnavailableView,
          arguments: const AccessUnavailableViewArguments(
            title: 'Access unavailable',
            message: 'Your access is inactive. Contact your FleetGo owner.',
          ),
        );
      case AuthDestination.linkExpired:
        await _navigationService.replaceWith(
          Routes.accessUnavailableView,
          arguments: const AccessUnavailableViewArguments(
            title: 'Link expired',
            message: 'Request a new reset link or staff invitation.',
          ),
        );
    }
  }
}
