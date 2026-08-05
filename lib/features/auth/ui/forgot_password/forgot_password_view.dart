import 'package:fleetgo/features/auth/ui/forgot_password/forgot_password_viewmodel.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_header.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_scaffold.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';

class ForgotPasswordView extends StackedView<ForgotPasswordViewModel> {
  const ForgotPasswordView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ForgotPasswordViewModel viewModel,
    Widget? child,
  ) {
    return AuthScaffold(
      onBack: viewModel.goBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: s16),
          const AuthHeader(
            icon: CupertinoIcons.lock,
            title: 'Forgot Password',
            subtitle: 'Enter your email to request a reset link',
          ),
          const SizedBox(height: s32),
          AppTextField(
            label: 'Email Address',
            controller: viewModel.emailController,
            hintText: 'name@company.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            autocorrect: false,
          ),
          const SizedBox(height: s16),
          AppButton(
            label: 'Send Reset Link',
            loading: viewModel.isBusy,
            onPressed: viewModel.canSendEmail ? viewModel.sendResetEmail : null,
          ),
        ],
      ),
    );
  }

  @override
  ForgotPasswordViewModel viewModelBuilder(BuildContext context) =>
      ForgotPasswordViewModel();
}
