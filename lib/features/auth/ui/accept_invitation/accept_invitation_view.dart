import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/features/auth/ui/accept_invitation/accept_invitation_viewmodel.dart';
import 'package:cuboid_flutter_template/features/auth/ui/widgets/auth_header.dart';
import 'package:cuboid_flutter_template/features/auth/ui/widgets/auth_scaffold.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/status_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class AcceptInvitationView extends StackedView<AcceptInvitationViewModel> {
  const AcceptInvitationView({
    super.key,
    required this.email,
    required this.businessName,
    required this.accessPacks,
  });

  final String email;
  final String businessName;
  final List<AccessPack> accessPacks;

  @override
  Widget builder(
    BuildContext context,
    AcceptInvitationViewModel viewModel,
    Widget? child,
  ) {
    return AuthScaffold(
      onBack: viewModel.goBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: s16),
          AuthHeader(
            icon: CupertinoIcons.mail,
            title: 'Accept Invitation',
            subtitle: 'You have been invited to join $businessName',
          ),
          const SizedBox(height: s32),
          const Text(
            'INVITED EMAIL',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.mutedLight,
            ),
          ),
          const SizedBox(height: s8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: s16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              border: Border.all(color: const Color(0x1DFFFFFF)),
              borderRadius: BorderRadius.circular(radiusSm),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.lock,
                  size: 16,
                  color: AppColors.mutedLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: s16),
          const Text(
            'ASSIGNED ROLES',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.mutedLight,
            ),
          ),
          const SizedBox(height: s8),
          Wrap(
            spacing: s8,
            runSpacing: s8,
            children: accessPacks
                .map((role) => StatusChip.info(role.label))
                .toList(),
          ),
          const SizedBox(height: s20),
          AppTextField(
            label: 'Set Password',
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
          const SizedBox(height: s24),
          AppButton(
            label: 'Accept Invitation & Sign In',
            loading: viewModel.isBusy,
            onPressed: viewModel.acceptInvitation,
          ),
        ],
      ),
    );
  }

  @override
  AcceptInvitationViewModel viewModelBuilder(BuildContext context) =>
      AcceptInvitationViewModel(
        email: email,
        businessName: businessName,
        accessPacks: accessPacks,
      );
}
