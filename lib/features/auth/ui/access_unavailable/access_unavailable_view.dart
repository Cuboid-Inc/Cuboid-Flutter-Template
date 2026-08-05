import 'package:fleetgo/features/auth/ui/access_unavailable/access_unavailable_viewmodel.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_header.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';

class AccessUnavailableView extends StackedView<AccessUnavailableViewModel> {
  const AccessUnavailableView({
    super.key,
    required this.title,
    required this.message,
    this.showRetry = false,
  });

  final String title;
  final String message;
  final bool showRetry;

  @override
  Widget builder(
    BuildContext context,
    AccessUnavailableViewModel viewModel,
    Widget? child,
  ) => AuthScaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: s32),
        AuthHeader(
          icon: CupertinoIcons.lock_shield,
          title: title,
          subtitle: message,
        ),
        const SizedBox(height: s32),
        if (showRetry) ...[
          AppButton(label: 'Retry', onPressed: viewModel.retry),
          const SizedBox(height: s12),
        ],
        AppOutlineButton(label: 'Sign out', onPressed: viewModel.signOut),
      ],
    ),
  );

  @override
  AccessUnavailableViewModel viewModelBuilder(BuildContext context) =>
      AccessUnavailableViewModel();
}
