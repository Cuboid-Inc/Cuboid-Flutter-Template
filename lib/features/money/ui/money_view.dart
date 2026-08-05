import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/features/money/ui/money_viewmodel.dart';
import 'package:fleetgo/features/money/ui/widgets/invoice_status_chip.dart';
import 'package:fleetgo/features/money/ui/widgets/money_list_row.dart';
import 'package:fleetgo/features/money/ui/widgets/settlement_status_chip.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_loading_indicator.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:fleetgo/ui/widgets/empty_state.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:fleetgo/ui/widgets/paginated_list/paginated_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'widgets/money_segment_tile.dart';

class MoneyView extends StackedView<MoneyViewModel> {
  const MoneyView({super.key});
  @override
  void onViewModelReady(MoneyViewModel viewModel) => viewModel.init();
  @override
  MoneyViewModel viewModelBuilder(BuildContext context) => MoneyViewModel();
  @override
  Widget builder(BuildContext context, MoneyViewModel vm, Widget? child) =>
      SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(s16, s16, s16, s12),
              child: Row(
                children: [
                  const Text(
                    'Money',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  _newAction(vm),
                  const SizedBox(width: 8),
                  _refreshAction(vm),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(s16, s4, s16, s16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: '',
                          onChanged: vm.setQuery,
                          hintText: 'Search number, name, reference…',
                          prefixIcon: Icon(CupertinoIcons.search),
                        ),
                      ),
                      IconButton(
                        onPressed: vm.selectPeriod,
                        color: AppColors.bg,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            AppColors.primary,
                          ),
                        ),
                        icon: Badge(
                          isLabelVisible: vm.hasCustomPeriod,
                          smallSize: 8,
                          backgroundColor: AppColors.danger,
                          child: const Icon(CupertinoIcons.calendar),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.55,
                    children: [
                      for (final segment in MoneySegment.values)
                        MoneySegmentTile(
                          segment: segment,
                          count: vm.countFor(segment),
                          selected: vm.segment == segment,
                          onTap: () => vm.setSegment(segment),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: vm.isBusy && vm.invoices.isEmpty
                  ? const AppLoadingIndicator(message: 'Loading money records')
                  : vm.errorMessage != null
                  ? EmptyState(
                      title: "Couldn't load money records",
                      subtitle: vm.errorMessage,
                      icon: CupertinoIcons.exclamationmark_triangle_fill,
                      iconColor: AppColors.danger,
                      actionLabel: 'Try again',
                      actionIcon: CupertinoIcons.arrow_clockwise,
                      onAction: vm.init,
                    )
                  : _list(vm),
            ),
          ],
        ),
      );
  Widget _refreshAction(MoneyViewModel vm) => IconButton(
    tooltip: 'Refresh',
    onPressed: vm.busy(MoneyBusy.refreshSegment) ? null : vm.refreshSegment,
    icon: vm.busy(MoneyBusy.refreshSegment)
        ? AppLoadingIndicator()
        : const Icon(CupertinoIcons.arrow_clockwise),
  );

  Widget _newAction(MoneyViewModel vm) => switch (vm.segment) {
    MoneySegment.invoices => AppButton(
      label: '+ New invoice',
      onPressed: vm.openPrepare,
      compact: true,
    ),
    MoneySegment.settlements => AppButton(
      label: '+ New settlement',
      onPressed: () => vm.recordPayment(PaymentDirection.outgoing),
      compact: true,
    ),
    MoneySegment.payments => PopupMenuButton<PaymentDirection>(
      onSelected: vm.recordPayment,
      tooltip: 'New payment',
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: PaymentDirection.incoming,
          child: Text('Payment in'),
        ),
        PopupMenuItem(
          value: PaymentDirection.outgoing,
          child: Text('Payment out'),
        ),
      ],
      child: const IgnorePointer(
        child: AppOutlineButton(label: '+ New payment', compact: true),
      ),
    ),
    MoneySegment.expenses => AppButton(
      label: '+ New expense',
      onPressed: vm.newExpense,
      compact: true,
    ),
    MoneySegment.statements || MoneySegment.balances => TextButton(
      onPressed: null,
      child: Text('View Only', style: TextStyle(fontWeight: FontWeight.w900)),
    ),
  };

  Widget _list(MoneyViewModel vm) => switch (vm.segment) {
    MoneySegment.invoices => _invoices(vm),
    MoneySegment.statements => _statements(vm),
    MoneySegment.settlements => _settlements(vm),
    MoneySegment.payments => _payments(vm),
    MoneySegment.expenses => _expenses(vm),
    MoneySegment.balances => _balances(vm),
  };
  Widget _invoices(MoneyViewModel vm) => PaginatedListView<Invoice>(
    controller: vm.invoicePagination,
    onRefresh: vm.refreshSegment,
    padding: const EdgeInsets.fromLTRB(s16, 0, s16, 100),
    separator: const SizedBox(height: 10),
    itemBuilder: (_, invoice, _) => ListCard(
      onTap: () => vm.openInvoice(invoice),
      child: MoneyListRow(
        number: invoice.number,
        title: invoice.buyerName,
        subtitle:
            '${Formatters.date(invoice.issueDate)} · Due ${invoice.dueDate == null ? '—' : Formatters.date(invoice.dueDate!)}',
        amount: Formatters.money(invoice.gross),
        trailing: InvoiceStatusChip(invoice.status),
        note: Formatters.money(vm.invoiceBalance(invoice)),
      ),
    ),
    emptyWidget: EmptyState(
      title: 'No invoices',
      subtitle: 'Create your first invoice to get started',
      icon: MoneySegment.invoices.icon,
      actionLabel: 'New Invoice',
      actionIcon: CupertinoIcons.plus,
      onAction: vm.openPrepare,
    ),
  );
  Widget _settlements(MoneyViewModel vm) =>
      PaginatedListView<SupplierSettlement>(
        controller: vm.settlementPagination,
        onRefresh: vm.refreshSegment,
        padding: const EdgeInsets.fromLTRB(s16, 0, s16, 100),
        separator: const SizedBox(height: 10),
        itemBuilder: (_, settlement, _) => ListCard(
          onTap: () => vm.openSettlement(settlement),
          child: MoneyListRow(
            number: settlement.number,
            title: vm.partyLabel(settlement.supplierId),
            subtitle: Formatters.monthYear(settlement.periodEnd),
            amount: Formatters.money(settlement.total),
            trailing: SettlementStatusChip(settlement.status),
            note: Formatters.money(vm.settlementBalance(settlement)),
          ),
        ),
        emptyWidget: EmptyState(
          title: 'No settlements',
          subtitle: 'Create your first settlement to get started',
          icon: MoneySegment.settlements.icon,
          actionLabel: 'New Settlement',
          actionIcon: CupertinoIcons.plus,
          onAction: () => vm.recordPayment(PaymentDirection.outgoing),
        ),
      );
  Widget _payments(MoneyViewModel vm) => PaginatedListView<Payment>(
    controller: vm.paymentPagination,
    onRefresh: vm.refreshSegment,
    padding: const EdgeInsets.fromLTRB(s16, 0, s16, 100),
    separator: const SizedBox(height: 10),
    itemBuilder: (_, payment, _) => ListCard(
      onTap: () => vm.openPayment(payment),
      child: MoneyListRow(
        title: vm.partyLabel(payment.partyId ?? ''),
        subtitle:
            '${Formatters.date(payment.date)} · ${payment.method.name}${payment.isCleared ? ' · cleared' : ' · awaiting clearance'}',
        amount: Formatters.signedMoney(
          payment.direction == PaymentDirection.incoming
              ? payment.amount
              : -payment.amount,
        ),
        trailing: payment.isCleared
            ? null
            : TextButton(
                onPressed: vm.busy(MoneyBusy.clearCheque)
                    ? null
                    : () => vm.clearCheque(payment),
                child: const Text('Mark cleared'),
              ),
      ),
    ),
    emptyWidget: EmptyState(
      title: 'No payments',
      subtitle: 'Create your first payment to get started',
      icon: MoneySegment.payments.icon,
      actionLabel: 'New Payment',
      actionIcon: CupertinoIcons.plus,
      onAction: () => vm.recordPayment(PaymentDirection.incoming),
    ),
  );
  Widget _expenses(MoneyViewModel vm) => PaginatedListView<Expense>(
    controller: vm.expensePagination,
    onRefresh: vm.refreshSegment,
    padding: const EdgeInsets.fromLTRB(s16, 0, s16, 100),
    separator: const SizedBox(height: 10),
    itemBuilder: (_, expense, _) => ListCard(
      onTap: () => vm.openExpense(expense),
      child: MoneyListRow(
        title: expense.payee,
        subtitle: '${Formatters.date(expense.date)} · ${expense.category.name}',
        amount: Formatters.money(expense.total),
      ),
    ),
    emptyWidget: EmptyState(
      title: 'No Expenses',
      subtitle: 'Record your first expense to get started',
      icon: MoneySegment.expenses.icon,
      actionLabel: 'New Expense',
      actionIcon: CupertinoIcons.plus,
      onAction: vm.newExpense,
    ),
  );
  Widget _balances(MoneyViewModel vm) => _cards(
    vm,
    [
      for (final party in vm.parties)
        if (vm.partyBalance(party.id) != 0 && vm.matchesQuery(party.name))
          ListCard(
            onTap: () => vm.openBalance(party),
            child: MoneyListRow(
              title: party.name,
              subtitle: party.type == PartyType.supplier
                  ? 'Supplier · payable'
                  : 'Customer · balance owed',
              amount: Formatters.money(vm.partyBalance(party.id)),
            ),
          ),
    ],
    EmptyState(
      title: 'No balances',
      subtitle: 'Outstanding balances will show up here',
      icon: MoneySegment.balances.icon,
    ),
  );
  Widget _statements(MoneyViewModel vm) => _cards(
    vm,
    [
      for (final entry in vm.statementGroups.entries)
        ListCard(
          onTap: () => vm.openStatement(
            entry.value.first.partyId,
            Period.month(
              entry.value.first.date.year,
              entry.value.first.date.month,
            ),
          ),
          child: MoneyListRow(
            title: vm.partyLabel(entry.value.first.partyId),
            subtitle:
                '${Formatters.monthYear(entry.value.first.date)} · ${entry.value.length} work rows',
            amount: Formatters.money(
              entry.value.fold<num>(
                0,
                (sum, row) => roundMoney(sum + row.amount),
              ),
            ),
          ),
        ),
    ],
    EmptyState(
      title: 'No statements',
      subtitle: 'Work statements will show up here',
      icon: MoneySegment.statements.icon,
    ),
  );

  Widget _cards(MoneyViewModel vm, List<Widget> children, Widget emptyWidget) =>
      RefreshIndicator(
        onRefresh: vm.refreshSegment,
        child: children.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: emptyWidget,
                  ),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(s16, 0, s16, 100),
                itemCount: children.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) => children[index],
              ),
      );
}
