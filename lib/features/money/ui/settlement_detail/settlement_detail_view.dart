import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/amount_row.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/detail_header.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/locked_banner.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/section_label.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/settlement_status_chip.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/summary_amount_card.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'settlement_detail_viewmodel.dart';
import 'widgets/settlement_row_tile.dart';

class SettlementDetailView extends StackedView<SettlementDetailViewModel> {
  const SettlementDetailView({super.key, required this.settlement});
  final SupplierSettlement settlement;

  @override
  SettlementDetailViewModel viewModelBuilder(BuildContext context) =>
      SettlementDetailViewModel(settlement);

  @override
  void onViewModelReady(SettlementDetailViewModel viewModel) =>
      viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    SettlementDetailViewModel vm,
    Widget? child,
  ) {
    final settlement = vm.settlement;
    final isLocked =
        settlement.status == SettlementStatus.paid ||
        settlement.status == SettlementStatus.voided;

    return Scaffold(
      appBar: AppBarIOS(
        title: settlement.number,
        actions: [
          AppBarIconAction(
            icon: CupertinoIcons.share,
            onPressed: vm.openPdf,
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading settlement')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                if (isLocked)
                  LockedBanner(
                    paid: settlement.status == SettlementStatus.paid,
                    message: settlement.status == SettlementStatus.paid
                        ? 'This settlement is paid in full. Details are locked.'
                        : 'This settlement has been voided.',
                  ),

                DetailHeader(
                  title: vm.supplier?.name ?? '',
                  subtitle:
                      'Settlement for ${Formatters.monthYear(settlement.periodEnd)}',
                  trailing: SettlementStatusChip(settlement.status),
                ),
                const SizedBox(height: 12),

                SummaryAmountCard(
                  label: 'Total Payable Amount',
                  amount: Formatters.money(settlement.total),
                ),
                const SizedBox(height: 14),

                // Settlement Lines
                const SectionLabel('SETTLEMENT DETAILS'),
                const SizedBox(height: 8),
                ListCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < settlement.lines.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        SettlementRowTile(
                          line: settlement.lines[i],
                          viewModel: vm,
                        ),
                      ],
                      const Divider(),
                      AmountRow('Total', settlement.total, strong: true),
                      AmountRow(
                        'Balance Due',
                        vm.balance,
                        color: vm.balance > 0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppOutlineButton(
                        compact: true,
                        label: 'View PDF',
                        onPressed: vm.openPdf,
                      ),
                    ),
                    if (settlement.status != SettlementStatus.paid &&
                        settlement.status != SettlementStatus.voided) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          compact: true,
                          label: 'Record payment',
                          loading: vm.busy(SettlementDetailBusy.recordPayment),
                          onPressed: vm.recordPayment,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
