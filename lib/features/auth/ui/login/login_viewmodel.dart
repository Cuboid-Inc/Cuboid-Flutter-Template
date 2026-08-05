import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/auth/data/auth_validation.dart';

import 'package:fleetgo/ui/common/snackbar_ui.dart';

class LoginViewModel extends BaseViewModel {
  final _authRepository = locator<AuthRepository>();
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  LoginViewModel() {
    emailController.addListener(notifyListeners);
    passwordController.addListener(notifyListeners);
  }

  bool get canSignIn =>
      isValidEmail(emailController.text) && passwordController.text.isNotEmpty;

  Future<void> signIn() async {
    if (isBusy) return;
    final result = await runBusyFuture(
      _authRepository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      ),
    );

    switch (result) {
      case Success(:final value):
        await _open(value);
      case Failure(:final failure):
        _snackbarService.showError(failure.message);
    }
  }

  Future<void> _open(AuthStartup startup) async {
    switch (startup.destination) {
      case AuthDestination.signedIn:
        await _navigationService.replaceWith(Routes.shellView);
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
            message: 'Your account has no active FleetGo access.',
          ),
        );
      case AuthDestination.signedOut:
      case AuthDestination.passwordRecovery:
      case AuthDestination.linkExpired:
        await _navigationService.replaceWith(Routes.loginView);
    }
  }

  void forgotPassword() {
    _navigationService.navigateTo(Routes.forgotPasswordView);
  }

  @override
  void dispose() {
    emailController.removeListener(notifyListeners);
    passwordController.removeListener(notifyListeners);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
