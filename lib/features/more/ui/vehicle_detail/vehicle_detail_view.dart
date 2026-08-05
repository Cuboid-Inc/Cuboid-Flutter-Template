import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_loading_indicator.dart';
import 'package:fleetgo/features/more/ui/vehicle_detail/vehicle_detail_viewmodel.dart';
import 'package:fleetgo/features/more/ui/vehicle_detail/widgets/vehicle_info_card.dart';

class VehicleDetailView extends StackedView<VehicleDetailViewModel> {
  const VehicleDetailView({super.key, required this.vehicle});
  final Vehicle vehicle;

  @override
  void onViewModelReady(VehicleDetailViewModel viewModel) => viewModel.init();

  @override
  VehicleDetailViewModel viewModelBuilder(BuildContext context) =>
      VehicleDetailViewModel(vehicle);

  @override
  Widget builder(
    BuildContext context,
    VehicleDetailViewModel vm,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBarIOS(
        title: vm.vehicle.label,
        actions: [
          AppBarTextAction(
            label: 'Edit',
            onPressed: vm.busy(VehicleDetailBusy.action)
                ? null
                : vm.editVehicle,
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading vehicle')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                VehicleInfoCard(
                  vehicle: vm.vehicle,
                  supplierName: vm.getSupplierName(vm.vehicle.supplierId),
                ),
                const SizedBox(height: 20),
                AppOutlineButton(
                  compact: true,
                  color: Colors.red,
                  label: 'Archive vehicle',
                  loading: vm.busy(VehicleDetailBusy.action),
                  onPressed: vm.archiveVehicle,
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
