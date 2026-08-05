import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/auth/data/auth_validation.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';

class AcceptInvitationViewModel extends BaseViewModel {
  final _authRepository = locator<AuthRepository>();
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();

  final String email;
  final String businessName;
  final List<AccessPack> accessPacks;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  AcceptInvitationViewModel({
    required this.email,
    required this.businessName,
    required this.accessPacks,
  });

  Future<void> acceptInvitation() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (passwordError(password) case final error?) {
      _snackbarService.showWarning(error);
      return;
    }

    if (password != confirmPassword) {
      _snackbarService.showWarning('Passwords do not match');
      return;
    }

    if (isBusy) return;

    final result = await runBusyFuture(
      _authRepository.acceptInvitation(email: email, password: password),
    );

    switch (result) {
      case Success(:final value):
        if (value.destination != AuthDestination.signedIn) {
          _snackbarService.showError('Your access is not active yet.');
          return;
        }
        _snackbarService.showSuccess('Welcome to $businessName.');
        await _navigationService.replaceWith(Routes.shellView);
      case Failure(:final failure):
        _snackbarService.showError(failure.message);
    }
  }

  void goBack() {
    _navigationService.back();
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
