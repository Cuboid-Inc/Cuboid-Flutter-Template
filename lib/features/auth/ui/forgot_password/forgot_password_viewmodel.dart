import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/auth/data/auth_validation.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ForgotPasswordViewModel extends BaseViewModel {
  final _authRepository = locator<AuthRepository>();
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();

  final emailController = TextEditingController();

  ForgotPasswordViewModel() {
    emailController.addListener(notifyListeners);
  }

  bool get canSendEmail => isValidEmail(emailController.text);

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();
    if (!isValidEmail(email)) {
      _snackbarService.showWarning('Enter a valid email address');
      return;
    }

    if (isBusy) return;

    final result = await runBusyFuture(
      _authRepository.sendPasswordReset(email),
    );

    switch (result) {
      case Success<void>():
        _snackbarService.showSuccess(
          'If an account exists, a reset link was sent.',
        );
        _navigationService.back();
      case Failure<void>(:final failure):
        _snackbarService.showError(failure.message);
    }
  }

  void goBack() {
    _navigationService.back();
  }

  @override
  void dispose() {
    emailController.removeListener(notifyListeners);
    emailController.dispose();
    super.dispose();
  }
}
