import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/features/more/ui/vehicles/vehicles_viewmodel.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/empty_state.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:fleetgo/ui/widgets/paginated_list/paginated_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class VehiclesView extends StackedView<VehiclesViewModel> {
  const VehiclesView({super.key});

  @override
  void onViewModelReady(VehiclesViewModel viewModel) => viewModel.init();

  @override
  VehiclesViewModel viewModelBuilder(BuildContext context) =>
      VehiclesViewModel();

  @override
  Widget builder(BuildContext context, VehiclesViewModel vm, Widget? child) {
    return Scaffold(
      appBar: AppBarIOS(
        title: 'Vehicles',
        actions: [
          AppBarIconAction(
            icon: CupertinoIcons.add,
            onPressed: vm.busy(VehiclesBusy.addVehicle) ? null : vm.addVehicle,
          ),
        ],
      ),
      body: PaginatedListView<Vehicle>(
        controller: vm.pagination,
        onRefresh: vm.refreshList,
        padding: const EdgeInsets.all(s16),
        itemBuilder: (context, vehicle, _) => _row(vehicle, vm),
        emptyWidget: EmptyState(
          title: 'No Vehicles',
          subtitle: 'Add a vehicle to get started',
          icon: CupertinoIcons.car_detailed,
          actionLabel: 'Add Vehicle',
          onAction: vm.busy(VehiclesBusy.addVehicle) ? null : vm.addVehicle,
        ),
      ),
    );
  }

  Widget _row(Vehicle v, VehiclesViewModel vm) {
    final expiryDate = v.insuranceExpiry ?? v.registrationExpiry;
    final isNearExpiry =
        expiryDate != null &&
        expiryDate.difference(DateTime.now()).inDays <= 30;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListCard(
        onTap: () => vm.openVehicle(v),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: v.ownership == VehicleOwnership.external
                    ? AppColors.warningBg
                    : AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                v.ownership == VehicleOwnership.external
                    ? CupertinoIcons.person_2
                    : CupertinoIcons.car_detailed,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.plateNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${v.label} · ${v.vehicleClass.label} · ${v.ownership == VehicleOwnership.owned ? "Owned" : "External"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (expiryDate != null) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'EXPIRY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    Formatters.date(expiryDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isNearExpiry
                          ? Colors.orange.shade800
                          : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.mutedLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
