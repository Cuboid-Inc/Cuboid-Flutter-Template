import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/features/money/ui/settlement_detail/settlement_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';

class SettlementRowTile extends StatelessWidget {
  const SettlementRowTile({
    super.key,
    required this.line,
    required this.viewModel,
  });

  final SettlementLine line;
  final SettlementDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => viewModel.viewWorkOrder(line),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.workOrderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${line.route ?? "Custom route"}${line.vehicleId != null ? " · Vehicle: ${line.vehicleId}" : ""}',
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
                  Formatters.money(line.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.date(line.date),
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
