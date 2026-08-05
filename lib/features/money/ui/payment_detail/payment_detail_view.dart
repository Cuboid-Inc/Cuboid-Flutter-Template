import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/detail_header.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/section_label.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/summary_amount_card.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/ui/widgets/detail_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:cuboid_flutter_template/ui/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'payment_detail_viewmodel.dart';
import 'widgets/payment_allocation_tile.dart';

class PaymentDetailView extends StackedView<PaymentDetailViewModel> {
  const PaymentDetailView({super.key, required this.payment});
  final Payment payment;

  @override
  void onViewModelReady(PaymentDetailViewModel viewModel) => viewModel.init();

  @override
  PaymentDetailViewModel viewModelBuilder(BuildContext context) =>
      PaymentDetailViewModel(payment);

  @override
  Widget builder(
    BuildContext context,
    PaymentDetailViewModel vm,
    Widget? child,
  ) {
    final payment = vm.payment;
    final isChequeAwaiting =
        payment.method == PaymentMethod.cheque && !payment.isCleared;

    return Scaffold(
      appBar: AppBarIOS(
        title: payment.direction == PaymentDirection.incoming
            ? 'Receipt Detail'
            : 'Payment Out Detail',
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading payment')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                DetailHeader(
                  title: vm.party?.name ?? 'Expense Payment',
                  subtitle: payment.direction == PaymentDirection.incoming
                      ? 'Incoming Payment'
                      : 'Outgoing Payment',
                  trailing: payment.isCleared
                      ? StatusChip.success('Cleared')
                      : StatusChip.warning('Awaiting Clearance'),
                ),
                const SizedBox(height: 12),

                SummaryAmountCard(
                  label: 'Amount Paid',
                  amount: Formatters.money(payment.amount),
                  color: payment.direction == PaymentDirection.incoming
                      ? AppColors.success
                      : AppColors.danger,
                ),
                const SizedBox(height: 14),

                const SectionLabel('PAYMENT DETAILS'),
                const SizedBox(height: 8),
                ListCard(
                  child: Column(
                    children: [
                      DetailRow(
                        label: 'Payment Date',
                        value: Formatters.date(payment.date),
                      ),
                      DetailRow(
                        label: 'Payment Method',
                        value: payment.method.name,
                      ),
                      if (payment.bankOrChequeReference != null &&
                          payment.bankOrChequeReference!.isNotEmpty)
                        DetailRow(
                          label: 'Reference / Cheque #',
                          value: payment.bankOrChequeReference!,
                        ),
                      if (payment.chequeDate != null)
                        DetailRow(
                          label: 'Cheque Date',
                          value: Formatters.date(payment.chequeDate!),
                        ),
                      if (payment.notes != null && payment.notes!.isNotEmpty)
                        DetailRow(label: 'Notes', value: payment.notes!),
                    ],
                  ),
                ),

                // Allocations Card
                if (payment.allocations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const SectionLabel('ALLOCATIONS'),
                  const SizedBox(height: 8),
                  ListCard(
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i < payment.allocations.length;
                          i++
                        ) ...[
                          if (i > 0) const Divider(height: 1),
                          PaymentAllocationTile(
                            allocation: payment.allocations[i],
                            viewModel: vm,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Action
                if (isChequeAwaiting) ...[
                  const SizedBox(height: 24),
                  AppButton(
                    compact: true,
                    label: 'Mark Cheque Cleared',
                    loading: vm.busy(PaymentDetailBusy.clearCheque),
                    onPressed: vm.clearCheque,
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
