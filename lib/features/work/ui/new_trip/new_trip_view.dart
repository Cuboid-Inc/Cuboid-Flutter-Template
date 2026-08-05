import 'package:fleetgo/features/work/ui/new_trip/new_trip_viewmodel.dart';
import 'package:fleetgo/features/work/ui/new_trip/steps/new_trip_step_one.dart';
import 'package:fleetgo/features/work/ui/new_trip/steps/new_trip_step_three.dart';
import 'package:fleetgo/features/work/ui/new_trip/steps/new_trip_step_two.dart';
import 'package:fleetgo/features/work/ui/new_trip/widgets/form_step_progress_bar.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Shell view for the New Trip wizard.
///
/// Responsibilities:
///   • Scaffold / AppBar
///   • [FormStepProgressBar] header
///   • Step routing → [NewTripStepOne] / [NewTripStepTwo] / [NewTripStepThree]
///   • Sticky Continue / Save button at the bottom
///
/// Each step is responsible for its own layout and dialogs.
class NewTripView extends StackedView<NewTripViewModel> {
  const NewTripView({super.key});

  @override
  void onViewModelReady(NewTripViewModel viewModel) => viewModel.init();

  @override
  NewTripViewModel viewModelBuilder(BuildContext context) => NewTripViewModel();

  @override
  Widget builder(BuildContext context, NewTripViewModel vm, Widget? child) {
    return Scaffold(
      appBar: AppBarIOS(
        title: _stepTitle(vm.step),
        onBack: vm.back,
        actions: [
          AppBarTextAction(
            label: 'Cancel',
            onPressed: vm.busy(NewTripBusy.saveWorkOrder) ? null : vm.cancel,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Step indicator ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: FormStepProgressBar(currentStep: vm.step),
          ),

          // ── Step body ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [_buildStep(context, vm)],
            ),
          ),

          // ── Primary action ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: AppButton(
              label: vm.step == 3 ? 'Save work order' : 'Continue',
              loading: vm.busy(NewTripBusy.saveWorkOrder),
              onPressed: vm.next,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the appropriate step widget for the current [step].
  Widget _buildStep(BuildContext context, NewTripViewModel vm) {
    return switch (vm.step) {
      1 => NewTripStepOne(vm: vm),
      2 => NewTripStepTwo(vm: vm),
      _ => NewTripStepThree(vm: vm),
    };
  }

  /// Dynamic AppBar title per step.
  String _stepTitle(int step) => switch (step) {
    1 => 'Customer & Route',
    2 => 'Vehicle & Driver',
    _ => 'Rate & Extras',
  };
}
