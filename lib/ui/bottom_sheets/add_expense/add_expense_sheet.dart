import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/forms/form_validators.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/add_expense/add_expense_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/add_expense/widgets/driver_selector.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/add_expense/widgets/vehicle_selector.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/chip_selector.dart';
import 'package:cuboid_flutter_template/ui/widgets/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AddExpenseSheet extends StackedView<AddExpenseSheetModel> {
  const AddExpenseSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  void onViewModelReady(AddExpenseSheetModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    AddExpenseSheetModel viewModel,
    Widget? child,
  ) {
    final showFormFields =
        viewModel.category == ExpenseCategory.other ||
        (viewModel.isVehicleExpense && viewModel.vehicleId != null) ||
        (viewModel.isDriverExpense && viewModel.driverId != null);

    return DemoSheet(
      title: 'Add expense',
      subtitle: 'Fuel, maintenance, toll, parking, driver pay…',
      busy: viewModel.isBusy,
      loadingMessage: 'Loading vehicles and drivers',
      child: SingleChildScrollView(
        child: Form(
          key: viewModel.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.loadErrorMessage case final loadError?) ...[
                Text(
                  loadError,
                  style: const TextStyle(color: AppColors.danger),
                ),
                const SizedBox(height: 13),
              ],
              const Text('CATEGORY', style: _expenseLabel),
              const SizedBox(height: 7),
              ChipSelector<ExpenseCategory>(
                items: viewModel.availableCategories,
                selected: [viewModel.category],
                labelBuilder: (value) => value.label,
                onChanged: viewModel.selectCategory,
              ),
              const SizedBox(height: 13),
              if (viewModel.isVehicleExpense) ...[
                const Text('LINK TO VEHICLE', style: _expenseLabel),
                const SizedBox(height: 7),
                FormField<String>(
                  validator: (_) => FormValidators.selection(
                    viewModel.vehicleId,
                    'Select a vehicle for this expense',
                  ),
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VehicleExpenseSelector(viewModel: viewModel),
                      if (field.errorText case final error?)
                        Text(
                          error,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
              ] else if (viewModel.isDriverExpense) ...[
                const Text('LINK TO DRIVER', style: _expenseLabel),
                const SizedBox(height: 7),
                FormField<String>(
                  validator: (_) => FormValidators.selection(
                    viewModel.driverId,
                    'Select a driver for this expense',
                  ),
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DriverExpenseSelector(viewModel: viewModel),
                      if (field.errorText case final error?)
                        Text(
                          error,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
              ],
              if (showFormFields) ...[
                AppTextField(
                  label: 'Payee',
                  controller: viewModel.payeeController,
                  hintText: 'e.g. ENOC',
                  validator: (value) =>
                      FormValidators.required(value, label: 'Payee'),
                ),
                const SizedBox(height: 13),
                AppTextField(
                  label: 'Amount',
                  controller: viewModel.amountController,
                  hintText: 'AED 0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: FormValidators.money,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Save expense',
                  onPressed: () {
                    if (viewModel.formKey.currentState?.validate() == true) {
                      viewModel.submit();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  AddExpenseSheetModel viewModelBuilder(BuildContext context) =>
      AddExpenseSheetModel(completer: completer!);
}

const _expenseLabel = TextStyle(
  fontSize: 11.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.6,
  color: AppColors.muted,
);
