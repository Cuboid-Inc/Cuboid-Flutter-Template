import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/features/money/ui/statement_view/statement_viewmodel.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/detail_header.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/section_label.dart';
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

import 'widgets/statement_row_tile.dart';

class StatementView extends StackedView<StatementViewModel> {
  const StatementView({super.key, required this.partyId, required this.period});
  final String partyId;
  final Period period;

  @override
  StatementViewModel viewModelBuilder(BuildContext context) =>
      StatementViewModel(partyId: partyId, period: period);

  @override
  void onViewModelReady(StatementViewModel viewModel) => viewModel.init();

  @override
  Widget builder(BuildContext context, StatementViewModel vm, Widget? child) {
    return Scaffold(
      appBar: AppBarIOS(
        title: 'Statement',
        actions: [
          AppBarIconAction(
            icon: CupertinoIcons.share,
            onPressed: vm.openPdf,
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading statement')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                DetailHeader(
                  title: vm.party?.name ?? '',
                  subtitle:
                      'Statement for ${Formatters.monthYear(vm.period.end)}',
                ),
                const SizedBox(height: 12),

                SummaryAmountCard(
                  label: 'Total Balance Owed',
                  amount: Formatters.money(vm.total),
                  color: AppColors.warning,
                ),
                const SizedBox(height: 14),

                const SectionLabel('STATEMENT ROWS'),
                const SizedBox(height: 8),
                ListCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < vm.rows.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        StatementRowTile(row: vm.rows[i], viewModel: vm),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                AppOutlineButton(
                  compact: true,
                  label: 'View Statement PDF',
                  onPressed: vm.openPdf,
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
