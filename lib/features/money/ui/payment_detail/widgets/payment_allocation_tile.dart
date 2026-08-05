import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/features/money/ui/payment_detail/payment_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';

class PaymentAllocationTile extends StatelessWidget {
  const PaymentAllocationTile({
    super.key,
    required this.allocation,
    required this.viewModel,
  });

  final PaymentAllocation allocation;
  final PaymentDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (allocation.invoiceId != null) {
      final invoice = viewModel.getInvoice(allocation.invoiceId!);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: invoice != null ? () => viewModel.viewInvoice(invoice) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice?.number ?? allocation.invoiceId!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Customer Invoice Allocation',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.money(allocation.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontSize: 14,
                ),
              ),
              if (invoice != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.muted,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (allocation.settlementId != null) {
      final settlement = viewModel.getSettlement(allocation.settlementId!);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: settlement != null
            ? () => viewModel.viewSettlement(settlement)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settlement?.number ?? allocation.settlementId!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Supplier Settlement Allocation',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.money(allocation.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontSize: 14,
                ),
              ),
              if (settlement != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.muted,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'General Allocation',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              fontSize: 13.5,
            ),
          ),
          Text(
            Formatters.money(allocation.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
