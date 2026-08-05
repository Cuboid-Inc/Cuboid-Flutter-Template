import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/features/work/ui/work_detail/work_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/status_chip.dart';
import 'package:flutter/material.dart';

class WorkAllocationTile extends StatelessWidget {
  const WorkAllocationTile({
    super.key,
    required this.allocation,
    required this.viewModel,
  });

  final VehicleAllocation allocation;
  final WorkDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final showPayable =
        viewModel.hasMoneyPermission &&
        allocation.source == VehicleSource.supplier;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        viewModel.vehicleLabel(allocation.vehicleId),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      subtitle: Text(
        viewModel.driverName(allocation.driverId),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
      trailing: allocation.source == VehicleSource.supplier
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip.neutral('External'),
                if (showPayable) ...[
                  const SizedBox(height: 4),
                  Text(
                    Formatters.money(allocation.supplierPayable),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            )
          : StatusChip.info('Owned'),
    );
  }
}
