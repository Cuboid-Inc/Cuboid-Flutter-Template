import 'package:cuboid_flutter_template/features/work/ui/monthly_work/monthly_work_viewmodel.dart';
import 'package:cuboid_flutter_template/features/work/ui/monthly_work/steps/monthly_work_step_one.dart';
import 'package:cuboid_flutter_template/features/work/ui/monthly_work/steps/monthly_work_step_three.dart';
import 'package:cuboid_flutter_template/features/work/ui/monthly_work/steps/monthly_work_step_two.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/form_step_progress_bar.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class MonthlyWorkView extends StackedView<MonthlyWorkViewModel> {
  const MonthlyWorkView({super.key});

  @override
  void onViewModelReady(MonthlyWorkViewModel viewModel) => viewModel.init();

  @override
  MonthlyWorkViewModel viewModelBuilder(BuildContext context) =>
      MonthlyWorkViewModel();

  @override
  Widget builder(BuildContext context, MonthlyWorkViewModel vm, Widget? child) {
    return Scaffold(
      appBar: AppBarIOS(title: _stepTitle(vm.step), onBack: vm.back),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: FormStepProgressBar(currentStep: vm.step, totalSteps: 3),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [_buildStep(vm)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: AppButton(
              label: vm.step == 3 ? 'Submit monthly work' : 'Continue',
              loading: vm.busy(MonthlyWorkBusy.saveWorkOrder),
              onPressed: vm.next,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(MonthlyWorkViewModel vm) => switch (vm.step) {
    1 => MonthlyWorkStepOne(vm: vm),
    2 => MonthlyWorkStepTwo(vm: vm),
    _ => MonthlyWorkStepThree(vm: vm),
  };

  String _stepTitle(int step) => switch (step) {
    1 => 'Agreement & Date',
    2 => 'Charges',
    _ => 'Review & Submit',
  };
}
