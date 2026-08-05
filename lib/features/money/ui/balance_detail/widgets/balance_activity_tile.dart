import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/features/money/ui/balance_detail/balance_detail_viewmodel.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';

class BalanceActivityTile extends StatelessWidget {
  const BalanceActivityTile({
    super.key,
    required this.item,
    required this.viewModel,
  });

  final BalanceActivityItem item;
  final BalanceDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final hasClick =
        item.invoice != null || item.settlement != null || item.payment != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasClick
          ? () {
              if (item.invoice != null) viewModel.viewInvoice(item.invoice!);
              if (item.settlement != null) {
                viewModel.viewSettlement(item.settlement!);
              }
              if (item.payment != null) viewModel.viewPayment(item.payment!);
            }
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
                    item.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.date(item.date),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.signedMoney(item.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: item.amount < 0 ? AppColors.success : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bal: ${Formatters.money(item.runningBalance)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.mutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (hasClick) ...[
              const SizedBox(width: 6),
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
}
