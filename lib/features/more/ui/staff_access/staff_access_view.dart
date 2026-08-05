import 'package:fleetgo/features/more/ui/staff_access/staff_access_viewmodel.dart';
import 'package:fleetgo/features/more/ui/staff_access/widgets/staff_row.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/app_loading_indicator.dart';
import 'package:fleetgo/ui/widgets/empty_state.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class StaffAccessView extends StackedView<StaffAccessViewModel> {
  const StaffAccessView({super.key});

  @override
  void onViewModelReady(StaffAccessViewModel viewModel) => viewModel.init();

  @override
  StaffAccessViewModel viewModelBuilder(BuildContext context) =>
      StaffAccessViewModel();

  @override
  Widget builder(
    BuildContext context,
    StaffAccessViewModel vm,
    Widget? child,
  ) => Scaffold(
    appBar: AppBarIOS(
      title: 'Staff & access',
      actions: [
        AppBarTextAction(
          label: 'Invite',
          onPressed: vm.busy(StaffAccessBusy.inviteStaff) ? null : vm.invite,
        ),
      ],
    ),
    body: SafeArea(
      child: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading staff')
          : vm.errorMessage != null
          ? EmptyState(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              title: "Couldn't load staff",
              subtitle: vm.errorMessage,
              actionLabel: 'Try again',
              actionIcon: CupertinoIcons.arrow_clockwise,
              onAction: vm.init,
            )
          : vm.staff.isEmpty
          ? EmptyState(
              icon: CupertinoIcons.shield_lefthalf_fill,
              title: 'No staff yet',
              subtitle: 'Invite teammates to grant them scoped access.',
              actionLabel: 'Invite teammate',
              actionIcon: CupertinoIcons.person_add,
              onAction: vm.invite,
            )
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                ListCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < vm.staff.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 60),
                        StaffRow(
                          member: vm.staff[i],
                          packsLabel: vm.packsLabel,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}
