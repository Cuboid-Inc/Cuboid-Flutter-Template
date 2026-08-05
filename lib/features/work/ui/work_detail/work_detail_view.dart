import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/features/work/ui/work_detail/widgets/work_allocation_tile.dart';
import 'package:fleetgo/features/work/ui/work_detail/widgets/work_charge_tile.dart';
import 'package:fleetgo/features/work/ui/work_detail/work_detail_viewmodel.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_loading_indicator.dart';
import 'package:fleetgo/ui/widgets/detail_row.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:fleetgo/ui/widgets/status_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class WorkDetailView extends StackedView<WorkDetailViewModel> {
  const WorkDetailView({super.key, required this.work});
  final WorkOrder work;

  @override
  WorkDetailViewModel viewModelBuilder(BuildContext context) =>
      WorkDetailViewModel(work);

  @override
  void onViewModelReady(WorkDetailViewModel viewModel) => viewModel.init();

  @override
  Widget builder(BuildContext context, WorkDetailViewModel vm, Widget? child) {
    final work = vm.work;
    final isLocked =
        work.status == WorkStatus.billed || work.status == WorkStatus.canceled;

    return Scaffold(
      appBar: AppBarIOS(
        title: work.number,
        actions: [
          AppBarIconAction(
            icon: CupertinoIcons.share,
            onPressed: vm.openPdf,
            tooltip: 'Share Trip Sheet',
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading work order')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                if (isLocked)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          work.status == WorkStatus.billed
                              ? CupertinoIcons.lock
                              : CupertinoIcons.xmark_circle,
                          color: AppColors.muted,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            work.status == WorkStatus.billed
                                ? 'This work order has been billed. Details are locked.'
                                : 'This work order has been canceled.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            work.number,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${Formatters.dateTime(work.date)} · ${vm.customer?.name ?? ''}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _status(work.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Route & Schedule Card
                ListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.arrow_branch,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ROUTE', style: _label),
                                Text(
                                  work.route,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (vm.agreement != null)
                            Text(
                              vm.agreement!.reference,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      if (work.plannedStart != null ||
                          work.plannedEnd != null ||
                          (work.customerJobReference != null &&
                              work.customerJobReference!.isNotEmpty)) ...[
                        const Divider(height: 20),
                        if (work.plannedStart != null)
                          DetailRow(
                            label: 'Planned Start',
                            value: Formatters.dateTime(work.plannedStart!),
                          ),
                        if (work.plannedEnd != null)
                          DetailRow(
                            label: 'Planned End',
                            value: Formatters.dateTime(work.plannedEnd!),
                          ),
                        if (work.customerJobReference != null &&
                            work.customerJobReference!.isNotEmpty)
                          DetailRow(
                            label: 'Job Reference',
                            value: work.customerJobReference!,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Vehicle Allocations Section
                const Text('VEHICLE ALLOCATIONS', style: _label),
                const SizedBox(height: 8),
                ListCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < work.allocations.length; i++) ...[
                        if (i > 0) const Divider(),
                        WorkAllocationTile(
                          allocation: work.allocations[i],
                          viewModel: vm,
                        ),
                      ],
                      if (vm.hasMoneyPermission &&
                          vm.totalSupplierPayable > 0) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Supplier Payable',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                Formatters.money(vm.totalSupplierPayable),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Customer Charges Section
                const Text('CUSTOMER CHARGES', style: _label),
                const SizedBox(height: 8),
                ListCard(
                  child: Column(
                    children: [
                      for (final line in work.chargeLines)
                        WorkChargeTile(line: line),
                      const Divider(),
                      _total('Net', work.net),
                      _total('VAT', work.vat),
                      _total('Total', work.gross, strong: true),
                    ],
                  ),
                ),

                // Linked Documents (Money Permission Required)
                if (vm.hasMoneyPermission) ...[
                  if (vm.linkedInvoice != null) ...[
                    const SizedBox(height: 14),
                    const Text('LINKED INVOICE', style: _label),
                    const SizedBox(height: 8),
                    ListCard(
                      onTap: vm.viewInvoice,
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.doc_text,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vm.linkedInvoice!.number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  'Issued ${Formatters.date(vm.linkedInvoice!.issueDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _invoiceStatus(vm.linkedInvoice!.status),
                          const SizedBox(width: 6),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (vm.linkedExpenses.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('LINKED EXPENSES', style: _label),
                    const SizedBox(height: 8),
                    ListCard(
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < vm.linkedExpenses.length;
                            i++
                          ) ...[
                            if (i > 0) const Divider(height: 0),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                vm.linkedExpenses[i].payee,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              subtitle: Text(
                                '${Formatters.date(vm.linkedExpenses[i].date)} · ${vm.linkedExpenses[i].category.name}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Text(
                                Formatters.money(vm.linkedExpenses[i].total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.danger,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],

                // Notes & Description Section
                if ((work.description != null &&
                        work.description!.isNotEmpty) ||
                    (work.notes != null && work.notes!.isNotEmpty)) ...[
                  const SizedBox(height: 14),
                  const Text('NOTES & DESCRIPTION', style: _label),
                  const SizedBox(height: 8),
                  ListCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (work.description != null &&
                            work.description!.isNotEmpty) ...[
                          const Text(
                            'DESCRIPTION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.muted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            work.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          if (work.notes != null && work.notes!.isNotEmpty)
                            const SizedBox(height: 12),
                        ],
                        if (work.notes != null && work.notes!.isNotEmpty) ...[
                          const Text(
                            'NOTES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.muted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            work.notes!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Actions Section
                const SizedBox(height: 20),
                if (work.status == WorkStatus.planned)
                  AppButton(
                    compact: true,
                    label: 'Mark completed',
                    loading: vm.busy(WorkDetailBusy.action),
                    onPressed: vm.complete,
                  ),
                if (work.status == WorkStatus.completed)
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          compact: true,
                          label: 'Add to invoice',
                          onPressed: vm.openPrepareMonth,
                        ),
                      ),
                      // const SizedBox(width: 10),
                      // Expanded(
                      //   child: AppOutlineButton(
                      //     compact: true,
                      //     label: 'Duplicate',
                      //     loading: vm.busy(WorkDetailBusy.action),
                      //     onPressed: vm.duplicate,
                      //   ),
                      // ),
                    ],
                  ),
                if (work.status == WorkStatus.planned) ...[
                  const SizedBox(height: 10),
                  AppOutlineButton(
                    compact: true,
                    color: AppColors.danger,
                    label: 'Cancel work order',
                    loading: vm.busy(WorkDetailBusy.action),
                    onPressed: vm.cancel,
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _total(String label, num value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        Text(
          Formatters.money(value),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            fontSize: strong ? 17 : 13,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );

  Widget _status(WorkStatus status) => switch (status) {
    WorkStatus.planned => StatusChip.info('Planned'),
    WorkStatus.completed => StatusChip.success('Completed'),
    WorkStatus.billed => StatusChip.neutral('Billed'),
    WorkStatus.canceled => StatusChip.neutral('Canceled'),
  };

  Widget _invoiceStatus(InvoiceStatus status) => switch (status) {
    InvoiceStatus.paid => StatusChip.success('Paid'),
    InvoiceStatus.partPaid => StatusChip.warning('Part Paid'),
    InvoiceStatus.issued => StatusChip.info('Issued'),
    InvoiceStatus.voided => StatusChip.neutral('Void'),
    InvoiceStatus.draft => StatusChip.neutral('Draft'),
  };
}

const _label = TextStyle(
  fontSize: 11.5,
  letterSpacing: 0.6,
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);
