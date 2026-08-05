import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/forms/form_validators.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/ui/bottom_sheets/vehicle_form/vehicle_form_sheet_model.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_combo_box.dart';
import 'package:fleetgo/ui/widgets/app_dropdown.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:fleetgo/ui/widgets/chip_selector.dart';
import 'package:fleetgo/ui/widgets/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class VehicleFormSheet extends StackedView<VehicleFormSheetModel> {
  const VehicleFormSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  void onViewModelReady(VehicleFormSheetModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    VehicleFormSheetModel viewModel,
    Widget? child,
  ) => DemoSheet(
    title: viewModel.isEditing ? 'Edit vehicle' : 'Add vehicle',
    subtitle: 'Manage plate numbers, ownership, classes, and expiries',
    busy: viewModel.isBusy,
    loadingMessage: 'Loading vehicle options',
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
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],

            const Text('OWNERSHIP', style: _label),
            const SizedBox(height: 7),
            ChipSelector<VehicleOwnership>(
              items: VehicleOwnership.values,
              selected: [viewModel.ownership],
              labelBuilder: (t) => t.label,
              onChanged: viewModel.selectOwnership,
            ),
            const SizedBox(height: 10),
            AppDropdown<VehicleClass>(
              label: 'Vehicle Class',
              value: viewModel.vehicleClass,
              items: VehicleClass.values,
              itemLabelBuilder: (vc) => vc.label,
              onChanged: viewModel.selectVehicleClass,
            ),
            const SizedBox(height: 12),

            if (viewModel.ownership == VehicleOwnership.external) ...[
              AppComboBox<Party>.async(
                label: 'Supplier (Required)',
                value: viewModel.selectedSupplier,
                itemLabelBuilder: (supplier) => supplier.name,
                onChanged: viewModel.selectSupplier,
                placeholder: 'Select supplier',
                fetchPage: viewModel.fetchSuppliersPage,
                fullScreen: true,
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Plate Number',
                    controller: viewModel.plateNumberController,
                    hintText: 'e.g. DXB A 34521',
                    validator: (value) =>
                        FormValidators.required(value, label: 'Plate number'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Display Label',
                    controller: viewModel.labelController,
                    hintText: 'e.g. 7-Ton Dubai',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Make',
                    controller: viewModel.makeController,
                    hintText: 'e.g. Isuzu',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Model',
                    controller: viewModel.modelController,
                    hintText: 'e.g. NPR',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Reg Expiry',
                    controller: TextEditingController(
                      text: viewModel.registrationExpiry != null
                          ? Formatters.date(viewModel.registrationExpiry!)
                          : '',
                    ),
                    hintText: 'Select date',
                    readOnly: true,
                    onTap: () => viewModel.pickDate(context, 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Year',
                    controller: viewModel.yearController,
                    hintText: 'e.g. 2023',
                    keyboardType: TextInputType.number,
                    validator: (value) => FormValidators.integerRange(
                      value,
                      label: 'Year',
                      min: 1900,
                      max: DateTime.now().year + 1,
                      optional: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Insp Expiry',
                    controller: TextEditingController(
                      text: viewModel.inspectionExpiry != null
                          ? Formatters.date(viewModel.inspectionExpiry!)
                          : '',
                    ),
                    hintText: 'Select date',
                    readOnly: true,
                    onTap: () => viewModel.pickDate(context, 3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Ins Expiry',
                    controller: TextEditingController(
                      text: viewModel.insuranceExpiry != null
                          ? Formatters.date(viewModel.insuranceExpiry!)
                          : '',
                    ),
                    hintText: 'Select date',
                    readOnly: true,
                    onTap: () => viewModel.pickDate(context, 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppTextField(
              label: 'Notes',
              controller: viewModel.notesController,
              hintText: 'Optional notes...',
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Save vehicle',
              onPressed: () {
                if (viewModel.formKey.currentState?.validate() == true) {
                  viewModel.submit();
                }
              },
            ),
          ],
        ),
      ),
    ),
  );

  @override
  VehicleFormSheetModel viewModelBuilder(BuildContext context) =>
      VehicleFormSheetModel(completer: completer!, request: request);
}

const TextStyle _label = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w800,
  color: AppColors.mutedLight,
);
