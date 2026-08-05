import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/features/money/data/money_rows.dart';
import 'package:cuboid_flutter_template/features/money/ui/statement_view/statement_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';

class StatementRowTile extends StatelessWidget {
  const StatementRowTile({
    super.key,
    required this.row,
    required this.viewModel,
  });

  final StatementRow row;
  final StatementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => viewModel.viewWorkOrder(row),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.workOrderId,
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
                  Formatters.money(row.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.date(row.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.muted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
