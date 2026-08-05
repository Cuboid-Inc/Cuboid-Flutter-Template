import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/features/more/ui/driver_detail/driver_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/more/ui/driver_detail/widgets/driver_info_card.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class DriverDetailView extends StackedView<DriverDetailViewModel> {
  const DriverDetailView({super.key, required this.driver});
  final Driver driver;

  @override
  void onViewModelReady(DriverDetailViewModel viewModel) => viewModel.init();

  @override
  DriverDetailViewModel viewModelBuilder(BuildContext context) =>
      DriverDetailViewModel(driver);

  @override
  Widget builder(
    BuildContext context,
    DriverDetailViewModel vm,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBarIOS(
        title: vm.driver.name,
        actions: [
          AppBarTextAction(
            label: 'Edit',
            onPressed: vm.busy(DriverDetailBusy.action) ? null : vm.editDriver,
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading driver')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                DriverInfoCard(
                  driver: vm.driver,
                  supplierName: vm.getSupplierName(vm.driver.supplierId),
                ),
                const SizedBox(height: 20),
                AppOutlineButton(
                  compact: true,
                  color: Colors.red,
                  label: 'Archive driver',
                  loading: vm.busy(DriverDetailBusy.action),
                  onPressed: vm.archiveDriver,
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
