import 'package:cuboid_flutter_template/ui/bottom_sheets/add_expense/add_expense_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/ui/widgets/empty_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VehicleExpenseSelector extends StatelessWidget {
  const VehicleExpenseSelector({super.key, required this.viewModel});

  final AddExpenseSheetModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.vehicleId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: viewModel.setVehicleSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search vehicle by plate or label...',
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
                if (viewModel.isBusy)
                  const AppLoadingIndicator()
                else if (viewModel.filteredVehicles.isEmpty)
                  const EmptyState(title: 'No vehicles found', compact: true)
                else
                  for (final vehicle in viewModel.filteredVehicles.take(3))
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: Text(
                        vehicle.plateNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        vehicle.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      onTap: () => viewModel.selectVehicle(vehicle),
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
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              viewModel.vehicles
                  .firstWhere((v) => v.id == viewModel.vehicleId)
                  .plateNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: viewModel.clearVehicle,
            child: const Text(
              'Change',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
