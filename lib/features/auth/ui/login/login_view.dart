import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'package:fleetgo/core/config/app_config.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_scaffold.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_header.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_styles.dart';

import 'package:fleetgo/features/auth/ui/login/login_viewmodel.dart';

/// Dark gradient sign-in screen matching the design's LOGIN section.
class LoginView extends StackedView<LoginViewModel> {
  const LoginView({super.key});

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
    Widget? child,
  ) {
    return AuthScaffold(
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: s32),
            const AuthHeader(
              logoAsset: 'assets/splash/logo_tile.png',
              title: AppConfig.appName,
              subtitle: 'Operations & money — one app',
            ),
            const SizedBox(height: s32),
            AppTextField(
              label: 'Email',
              controller: viewModel.emailController,
              hintText: 'name@company.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              textInputAction: TextInputAction.next,
              autocorrect: false,
            ),
            const SizedBox(height: s12),
            AppTextField(
              label: 'Password',
              controller: viewModel.passwordController,
              hintText: '••••••••••',
              obscureText: true,
              showVisibilityToggle: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: s8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: viewModel.forgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: s16),
            AppButton(
              label: 'Sign in',
              loading: viewModel.isBusy,
              onPressed: viewModel.canSignIn ? viewModel.signIn : null,
            ),
            const SizedBox(height: s24),
            const Text(
              'Owner & staff accounts only.\nDrivers are managed profiles — no login.',
              textAlign: TextAlign.center,
              style: AuthStyles.infoTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  @override
  LoginViewModel viewModelBuilder(BuildContext context) => LoginViewModel();
}
