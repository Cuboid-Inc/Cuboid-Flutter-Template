import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/features/money/ui/expense_detail/expense_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/money/ui/expense_detail/widgets/linked_resources_card.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/detail_header.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/section_label.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/summary_amount_card.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/ui/widgets/detail_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:cuboid_flutter_template/ui/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class ExpenseDetailView extends StackedView<ExpenseDetailViewModel> {
  const ExpenseDetailView({super.key, required this.expense});
  final Expense expense;

  @override
  void onViewModelReady(ExpenseDetailViewModel viewModel) => viewModel.init();

  @override
  ExpenseDetailViewModel viewModelBuilder(BuildContext context) =>
      ExpenseDetailViewModel(expense);

  @override
  Widget builder(
    BuildContext context,
    ExpenseDetailViewModel vm,
    Widget? child,
  ) {
    final expense = vm.expense;

    return Scaffold(
      appBar: const AppBarIOS(title: 'Expense Detail'),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading expense')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                DetailHeader(
                  title: expense.payee,
                  subtitle: expense.category.name,
                  trailing: expense.isPaid
                      ? StatusChip.success('Paid')
                      : StatusChip.neutral('Outstanding'),
                ),
                const SizedBox(height: 12),

                SummaryAmountCard(
                  label: 'Total Amount',
                  amount: Formatters.money(expense.total),
                ),
                const SizedBox(height: 14),

                const SectionLabel('EXPENSE DETAILS'),
                const SizedBox(height: 8),
                ListCard(
                  child: Column(
                    children: [
                      DetailRow(
                        label: 'Expense Date',
                        value: Formatters.date(expense.date),
                      ),
                      if (expense.dueDate != null)
                        DetailRow(
                          label: 'Due Date',
                          value: Formatters.date(expense.dueDate!),
                        ),
                      if (expense.reference != null &&
                          expense.reference!.isNotEmpty)
                        DetailRow(
                          label: 'Reference #',
                          value: expense.reference!,
                        ),
                      if (expense.description != null &&
                          expense.description!.isNotEmpty)
                        DetailRow(
                          label: 'Description',
                          value: expense.description!,
                        ),
                      if (expense.notes != null && expense.notes!.isNotEmpty)
                        DetailRow(label: 'Notes', value: expense.notes!),
                    ],
                  ),
                ),

                if (vm.workOrder != null ||
                    vm.vehicle != null ||
                    vm.driver != null) ...[
                  const SizedBox(height: 14),
                  const SectionLabel('LINKED RESOURCES'),
                  const SizedBox(height: 8),
                  LinkedResourcesCard(
                    workOrder: vm.workOrder,
                    vehicle: vm.vehicle,
                    driver: vm.driver,
                    onTapWorkOrder: vm.viewWorkOrder,
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
