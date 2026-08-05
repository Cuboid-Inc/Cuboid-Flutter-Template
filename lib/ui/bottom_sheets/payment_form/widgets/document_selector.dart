import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/empty_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DocumentSelector extends StatelessWidget {
  const DocumentSelector({super.key, required this.viewModel});

  final PaymentFormSheetModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.incoming) {
      if (viewModel.linkedInvoiceId == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: viewModel.setDocSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search unpaid invoices...',
                prefixIcon: Icon(CupertinoIcons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.white,
              ),
              child: Column(
                children: [
                  if (viewModel.eligibleInvoices.isEmpty)
                    const EmptyState(
                      title: 'No unpaid invoices found',
                      icon: CupertinoIcons.doc_text,
                      compact: true,
                    )
                  else
                    for (final invoice in viewModel.eligibleInvoices.take(3))
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        title: Text(
                          invoice.number,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${Formatters.date(invoice.issueDate)} · Unpaid: ${Formatters.money(viewModel.invoiceBalances[invoice.id] ?? invoice.gross)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                        trailing: Text(
                          Formatters.money(invoice.gross),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onTap: () => viewModel.selectInvoice(invoice),
                      ),
                ],
              ),
            ),
          ],
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.link, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.allInvoices
                            .cast<Invoice?>()
                            .firstWhere(
                              (inv) => inv?.id == viewModel.linkedInvoiceId,
                              orElse: () => null,
                            )
                            ?.number ??
                        'Loading...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Unpaid: ${Formatters.money(viewModel.invoiceBalances[viewModel.linkedInvoiceId] ?? 0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (viewModel.data.invoiceId == null)
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle, size: 18),
                onPressed: viewModel.clearLinkedDoc,
              ),
          ],
        ),
      );
    }

    // Outgoing path
    if (viewModel.linkedSettlementId == null &&
        viewModel.linkedExpenseId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: viewModel.setDocSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search unpaid settlements/expenses...',
              prefixIcon: Icon(CupertinoIcons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.white,
            ),
            child: Column(
              children: [
                if (viewModel.eligibleSettlements.isEmpty &&
                    viewModel.eligibleExpenses.isEmpty)
                  const EmptyState(
                    title: 'No outstanding settlements or expenses',
                    icon: CupertinoIcons.arrow_2_squarepath,
                    compact: true,
                  )
                else ...[
                  for (final s in viewModel.eligibleSettlements.take(3))
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: Text(
                        s.number,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Settlement · Unpaid: ${Formatters.money(viewModel.settlementBalances[s.id] ?? s.total)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      trailing: Text(
                        Formatters.money(s.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => viewModel.selectSettlement(s),
                    ),
                  for (final e in viewModel.eligibleExpenses.take(3))
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: Text(
                        e.category.name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Expense · ${e.description ?? ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      trailing: Text(
                        Formatters.money(e.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => viewModel.selectExpense(e),
                    ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (viewModel.linkedSettlementId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.link, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.allSettlements
                            .cast<SupplierSettlement?>()
                            .firstWhere(
                              (s) => s?.id == viewModel.linkedSettlementId,
                              orElse: () => null,
                            )
                            ?.number ??
                        'Loading...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Unpaid: ${Formatters.money(viewModel.settlementBalances[viewModel.linkedSettlementId] ?? 0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (viewModel.data.settlementId == null)
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle, size: 18),
                onPressed: viewModel.clearLinkedDoc,
              ),
          ],
        ),
      );
    }

    // Expense
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.link, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.allExpenses
                          .cast<Expense?>()
                          .firstWhere(
                            (e) => e?.id == viewModel.linkedExpenseId,
                            orElse: () => null,
                          )
                          ?.category
                          .name
                          .toUpperCase() ??
                      'LOADING...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Unpaid: ${Formatters.money(viewModel.allExpenses.cast<Expense?>().firstWhere((e) => e?.id == viewModel.linkedExpenseId, orElse: () => null)?.total ?? 0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (viewModel.data.expenseId == null)
            IconButton(
              icon: const Icon(CupertinoIcons.xmark_circle, size: 18),
              onPressed: viewModel.clearLinkedDoc,
            ),
        ],
      ),
    );
  }
}
