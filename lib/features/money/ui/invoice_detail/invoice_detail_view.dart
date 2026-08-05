import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/features/money/ui/invoice_detail/invoice_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/money/ui/invoice_detail/widgets/invoice_date_card.dart';
import 'package:cuboid_flutter_template/features/money/ui/invoice_detail/widgets/invoice_line_tile.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/amount_row.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/detail_header.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/invoice_status_chip.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/locked_banner.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/section_label.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/ui/widgets/detail_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class InvoiceDetailView extends StackedView<InvoiceDetailViewModel> {
  const InvoiceDetailView({super.key, required this.invoice});
  final Invoice invoice;

  @override
  InvoiceDetailViewModel viewModelBuilder(BuildContext context) =>
      InvoiceDetailViewModel(invoice);

  @override
  void onViewModelReady(InvoiceDetailViewModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    InvoiceDetailViewModel vm,
    Widget? child,
  ) {
    final invoice = vm.invoice;
    final isLocked =
        invoice.status == InvoiceStatus.paid ||
        invoice.status == InvoiceStatus.voided;

    return Scaffold(
      appBar: AppBarIOS(
        title: invoice.number,
        actions: [
          AppBarIconAction(
            icon: CupertinoIcons.share,
            onPressed: vm.openPdf,
            tooltip: 'Share Invoice PDF',
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading invoice')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                if (isLocked)
                  LockedBanner(
                    paid: invoice.status == InvoiceStatus.paid,
                    message: invoice.status == InvoiceStatus.paid
                        ? 'This invoice is paid in full. Details are locked.'
                        : 'This invoice has been voided.${invoice.voidReason != null ? " Reason: ${invoice.voidReason}" : ""}',
                  ),

                DetailHeader(
                  title: invoice.buyerName,
                  subtitle: invoice.number,
                  trailing: InvoiceStatusChip(invoice.status),
                ),
                const SizedBox(height: 12),

                // Issue & Due Dates
                Row(
                  children: [
                    Expanded(
                      child: InvoiceDateCard(
                        label: 'Issue date',
                        date: invoice.issueDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InvoiceDateCard(
                        label: 'Due date',
                        date: invoice.dueDate,
                      ),
                    ),
                  ],
                ),

                // Billing Details
                if (invoice.buyerAddress != null ||
                    invoice.buyerTrn != null ||
                    invoice.paymentTerms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ListCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('BILLING DETAILS'),
                        const SizedBox(height: 8),
                        if (invoice.buyerAddress != null &&
                            invoice.buyerAddress!.isNotEmpty)
                          DetailRow(
                            label: 'Address',
                            value: invoice.buyerAddress!,
                          ),
                        if (invoice.buyerTrn != null &&
                            invoice.buyerTrn!.isNotEmpty)
                          DetailRow(label: 'TRN', value: invoice.buyerTrn!),
                        DetailRow(label: 'Terms', value: invoice.paymentTerms),
                        if (invoice.supplyDate != null)
                          DetailRow(
                            label: 'Supply Date',
                            value: Formatters.date(invoice.supplyDate!),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Invoice Items
                const SectionLabel('INVOICE CHARGES'),
                const SizedBox(height: 8),
                ListCard(
                  child: Column(
                    children: [
                      for (final line in invoice.lines)
                        InvoiceLineTile(line: line),
                      const Divider(),
                      AmountRow('Net', invoice.net),
                      AmountRow('VAT', invoice.vat),
                      AmountRow('Total', invoice.gross, strong: true),
                      AmountRow(
                        'Balance',
                        vm.balance,
                        color: vm.balance > 0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ],
                  ),
                ),

                // Linked Work Orders
                if (vm.linkedWorkOrders.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const SectionLabel('LINKED WORK ORDERS'),
                  const SizedBox(height: 8),
                  ListCard(
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i < vm.linkedWorkOrders.length;
                          i++
                        ) ...[
                          if (i > 0) const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              vm.linkedWorkOrders[i].number,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            subtitle: Text(
                              '${Formatters.date(vm.linkedWorkOrders[i].date)} · ${vm.linkedWorkOrders[i].route}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              color: AppColors.muted,
                            ),
                            onTap: () =>
                                vm.viewWorkOrder(vm.linkedWorkOrders[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Linked Payments
                if (vm.linkedPayments.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const SectionLabel('LINKED PAYMENTS'),
                  const SizedBox(height: 8),
                  ListCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < vm.linkedPayments.length; i++) ...[
                          if (i > 0) const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Payment via ${vm.linkedPayments[i].method.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            subtitle: Text(
                              '${Formatters.date(vm.linkedPayments[i].date)} · ${vm.linkedPayments[i].isCleared ? 'Cleared' : 'Awaiting clearance'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Text(
                              Formatters.money(vm.linkedPayments[i].amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Actions Section
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppOutlineButton(
                        compact: true,
                        label: 'View PDF',
                        onPressed: vm.openPdf,
                      ),
                    ),
                    if (invoice.status != InvoiceStatus.paid &&
                        invoice.status != InvoiceStatus.voided) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          compact: true,
                          label: 'Record payment',
                          loading: vm.busy(InvoiceDetailBusy.recordPayment),
                          onPressed: vm.recordPayment,
                        ),
                      ),
                    ],
                  ],
                ),
                if (invoice.status != InvoiceStatus.paid &&
                    invoice.status != InvoiceStatus.voided) ...[
                  const SizedBox(height: 10),
                  AppOutlineButton(
                    compact: true,
                    label: 'Void invoice',
                    color: AppColors.danger,
                    loading: vm.busy(InvoiceDetailBusy.voidInvoice),
                    onPressed: vm.voidInvoice,
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
