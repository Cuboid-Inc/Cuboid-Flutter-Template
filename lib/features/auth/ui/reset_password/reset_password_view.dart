import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';

import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_scaffold.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_header.dart';

import 'package:fleetgo/features/auth/ui/reset_password/reset_password_viewmodel.dart';

class ResetPasswordView extends StackedView<ResetPasswordViewModel> {
  const ResetPasswordView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ResetPasswordViewModel viewModel,
    Widget? child,
  ) {
    return AuthScaffold(
      onBack: viewModel.goBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: s16),
          const AuthHeader(
            icon: CupertinoIcons.lock_open,
            title: 'Reset Password',
            subtitle: 'Set a new secure password for your account',
          ),
          const SizedBox(height: s32),
          AppTextField(
            label: 'New Password',
            controller: viewModel.passwordController,
            hintText: '••••••••••',
            obscureText: true,
            showVisibilityToggle: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            enableSuggestions: false,
            autocorrect: false,
          ),
          const SizedBox(height: s12),
          AppTextField(
            label: 'Confirm Password',
            controller: viewModel.confirmPasswordController,
            hintText: '••••••••••',
            obscureText: true,
            showVisibilityToggle: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            enableSuggestions: false,
            autocorrect: false,
          ),
          const SizedBox(height: s20),
          AppButton(
            label: 'Update Password',
            loading: viewModel.isBusy,
            onPressed: viewModel.submitReset,
          ),
        ],
      ),
    );
  }

  @override
  ResetPasswordViewModel viewModelBuilder(BuildContext context) =>
      ResetPasswordViewModel();
}
