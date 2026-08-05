import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/forms/form_validators.dart';
import 'package:fleetgo/ui/bottom_sheets/driver_form/driver_form_sheet_model.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_combo_box.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:fleetgo/ui/widgets/chip_selector.dart';
import 'package:fleetgo/ui/widgets/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class DriverFormSheet extends StackedView<DriverFormSheetModel> {
  const DriverFormSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  void onViewModelReady(DriverFormSheetModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    DriverFormSheetModel viewModel,
    Widget? child,
  ) => DemoSheet(
    title: viewModel.isEditing ? 'Edit driver' : 'Add driver',
    subtitle: 'Manage driver licensing, employment status, and details',
    busy: viewModel.isBusy,
    loadingMessage: 'Loading driver options',
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

            if (!viewModel.isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EMPLOYMENT TYPE', style: _label),
                        const SizedBox(height: 7),
                        ChipSelector<Responsibility>(
                          items: const [
                            Responsibility.operator,
                            Responsibility.customer,
                          ],
                          selected: [viewModel.employment],
                          labelBuilder: (t) => t == Responsibility.operator
                              ? 'Operator'
                              : 'Subcontracted',
                          onChanged: viewModel.selectEmployment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (viewModel.employment == Responsibility.customer) ...[
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
                    label: 'Full Name',
                    controller: viewModel.nameController,
                    hintText: 'e.g. John Doe',
                    validator: (value) =>
                        FormValidators.required(value, label: 'Full name'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Phone Number',
                    controller: viewModel.phoneController,
                    hintText: 'e.g. +971 50 123 4567',
                    validator: FormValidators.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Licence Number',
                    controller: viewModel.licenceNumberController,
                    hintText: 'e.g. L-55441',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Licence Expiry',
                    controller: TextEditingController(
                      text: viewModel.licenceExpiry != null
                          ? Formatters.date(viewModel.licenceExpiry!)
                          : '',
                    ),
                    hintText: 'Select date',
                    readOnly: true,
                    onTap: () => viewModel.pickDate(context, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Identity / Visa Ref',
                    controller: viewModel.identityReferenceController,
                    hintText: 'e.g. Emirates ID / Visa',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Identity Expiry',
                    controller: TextEditingController(
                      text: viewModel.identityExpiry != null
                          ? Formatters.date(viewModel.identityExpiry!)
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
              label: 'Save driver',
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
  DriverFormSheetModel viewModelBuilder(BuildContext context) =>
      DriverFormSheetModel(completer: completer!, request: request);
}

const _label = TextStyle(
  fontSize: 11.5,
  letterSpacing: 0.6,
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);
