import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/features/more/ui/agreement_detail/agreement_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/more/ui/agreement_detail/widgets/agreement_info_card.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class AgreementDetailView extends StackedView<AgreementDetailViewModel> {
  const AgreementDetailView({super.key, required this.agreement});
  final Agreement agreement;

  @override
  void onViewModelReady(AgreementDetailViewModel viewModel) => viewModel.init();

  @override
  AgreementDetailViewModel viewModelBuilder(BuildContext context) =>
      AgreementDetailViewModel(agreement);

  @override
  Widget builder(
    BuildContext context,
    AgreementDetailViewModel vm,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBarIOS(
        title: vm.agreement.reference,
        actions: [
          AppBarTextAction(
            label: 'Edit',
            onPressed: vm.busy(AgreementDetailBusy.action)
                ? null
                : vm.editAgreement,
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading agreement')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                AgreementInfoCard(
                  agreement: vm.agreement,
                  customerName: vm.getCustomerName(vm.agreement.customerId),
                  vehicleLabel: vm.getVehicleLabel(
                    vm.agreement.defaultVehicleId,
                  ),
                ),
                const SizedBox(height: 20),
                AppOutlineButton(
                  compact: true,
                  color: Colors.red,
                  label: 'Archive agreement',
                  loading: vm.busy(AgreementDetailBusy.action),
                  onPressed: vm.archiveAgreement,
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
