import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/auth/data/auth_validation.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';

class ResetPasswordViewModel extends BaseViewModel {
  final _authRepository = locator<AuthRepository>();
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future<void> submitReset() async {
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

    final result = await runBusyFuture(_authRepository.resetPassword(password));

    switch (result) {
      case Success<void>():
        _snackbarService.showSuccess(
          'Password updated. Sign in with your new password.',
        );
        await _navigationService.clearStackAndShow(Routes.loginView);
      case Failure<void>(:final failure):
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
