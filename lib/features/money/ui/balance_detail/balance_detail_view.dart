import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/features/money/ui/balance_detail/balance_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/money/ui/balance_detail/widgets/balance_activity_tile.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/detail_header.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/section_label.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/summary_amount_card.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/ui/widgets/empty_state.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class BalanceDetailView extends StackedView<BalanceDetailViewModel> {
  const BalanceDetailView({super.key, required this.party});
  final Party party;

  @override
  void onViewModelReady(BalanceDetailViewModel viewModel) => viewModel.init();

  @override
  BalanceDetailViewModel viewModelBuilder(BuildContext context) =>
      BalanceDetailViewModel(party);

  @override
  Widget builder(
    BuildContext context,
    BalanceDetailViewModel vm,
    Widget? child,
  ) {
    final party = vm.party;

    return Scaffold(
      appBar: const AppBarIOS(title: 'Statement of Account'),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading account activity')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                DetailHeader(
                  title: party.name,
                  subtitle: party.type == PartyType.customer
                      ? 'Customer'
                      : 'Supplier',
                ),
                const SizedBox(height: 12),

                SummaryAmountCard(
                  label: party.type == PartyType.customer
                      ? 'Net Receivable'
                      : 'Net Payable',
                  amount: Formatters.money(vm.currentBalance),
                  color: vm.currentBalance > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
                const SizedBox(height: 14),

                const SectionLabel('STATEMENT ACTIVITY'),
                const SizedBox(height: 8),
                ListCard(
                  child: vm.activityItems.isEmpty
                      ? const EmptyState(
                          title: 'No activity recorded',
                          compact: true,
                        )
                      : Column(
                          children: [
                            for (
                              var i = 0;
                              i < vm.activityItems.length;
                              i++
                            ) ...[
                              if (i > 0) const Divider(height: 1),
                              BalanceActivityTile(
                                item: vm.activityItems[i],
                                viewModel: vm,
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
