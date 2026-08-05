import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/forms/form_validators.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/agreement_form/agreement_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_combo_box.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_dropdown.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/demo_sheet.dart';
import 'package:cuboid_flutter_template/ui/widgets/extra_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:cuboid_flutter_template/ui/widgets/section_label.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AgreementFormSheet extends StackedView<AgreementFormSheetModel> {
  const AgreementFormSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  void onViewModelReady(AgreementFormSheetModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    AgreementFormSheetModel viewModel,
    Widget? child,
  ) => DemoSheet(
    title: viewModel.isEditing ? 'Edit agreement' : 'Add agreement',
    subtitle: 'Define rates, billing models, po numbers, and custom terms',
    busy: viewModel.isBusy,
    loadingMessage: 'Loading agreement options',
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

            Row(
              children: [
                if (!viewModel.isEditing) ...[
                  Expanded(
                    child: AppDropdown<RateModel>(
                      label: 'Billing Model',
                      value: viewModel.rateModel,
                      items: RateModel.values,
                      itemLabelBuilder: (rm) => rm == RateModel.perTrip
                          ? 'Per Trip Rate'
                          : 'Monthly Hire',
                      onChanged: viewModel.selectRateModel,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: AppDropdown<PaymentTerms>(
                    label: 'Payment Terms',
                    value: viewModel.paymentTerms,
                    items: PaymentTerms.values,
                    itemLabelBuilder: (pt) => pt.label,
                    onChanged: viewModel.selectPaymentTerms,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!viewModel.isEditing) ...[
              AppComboBox<Party>.async(
                label: 'Customer (Required)',
                value: viewModel.selectedCustomer,
                itemLabelBuilder: (c) => c.name,
                onChanged: viewModel.selectCustomer,
                placeholder: 'Select customer',
                fetchPage: viewModel.fetchCustomersPage,
                fullScreen: true,
              ),
              const SizedBox(height: 12),
            ],

            AppTextField(
              label: 'Agreement Name',
              controller: viewModel.nameController,
              hintText: 'e.g. Dubai Main Contract',
              validator: (value) =>
                  FormValidators.required(value, label: 'Agreement name'),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'VAT Rate %',
                    controller: viewModel.vatRateController,
                    hintText: 'e.g. 5',
                    keyboardType: TextInputType.number,
                    validator: (value) => FormValidators.integerRange(
                      value,
                      label: 'VAT rate',
                      min: 0,
                      max: 100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (viewModel.rateModel == RateModel.monthly) ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Base Rate AED',
                      controller: viewModel.baseRateAEDController,
                      hintText: 'e.g. 1500.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => FormValidators.money(
                        value,
                        label: 'Rate',
                        allowZero: true,
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
                      label: 'Duty Days',
                      controller: viewModel.dutyDaysController,
                      hintText: 'e.g. 26',
                      keyboardType: TextInputType.number,
                      validator: (value) => FormValidators.integerRange(
                        value,
                        label: 'Duty days',
                        min: 0,
                        max: 31,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: 'Included Hours',
                      controller: viewModel.includedHoursController,
                      hintText: 'e.g. 260',
                      keyboardType: TextInputType.number,
                      validator: (value) => FormValidators.integerRange(
                        value,
                        label: 'Included hours',
                        min: 0,
                        max: 744,
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
                      label: 'Overtime AED/hr',
                      controller: viewModel.overtimeRateController,
                      hintText: 'e.g. 50.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => FormValidators.money(
                        value,
                        label: 'Rate',
                        allowZero: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: 'Extra Day AED',
                      controller: viewModel.extraDayRateController,
                      hintText: 'e.g. 400.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => FormValidators.money(
                        value,
                        label: 'Rate',
                        allowZero: true,
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
                      label: 'Extra Trip AED',
                      controller: viewModel.extraTripRateController,
                      hintText: 'e.g. 150.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => FormValidators.money(
                        value,
                        label: 'Rate',
                        allowZero: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const SectionLabel('DEFAULT EXTRAS'),
              const SizedBox(height: 8),

              if (viewModel.extras.isNotEmpty) ...[
                ListCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < viewModel.extras.length; i++) ...[
                        ExtraRow(
                          name: viewModel.extras[i].key,
                          amount: Formatters.money(viewModel.extras[i].value),
                          onEdit: () => viewModel.openEditExtraDialog(i),
                          onDelete: () => viewModel.removeExtra(i),
                        ),
                        if (i < viewModel.extras.length - 1)
                          const Divider(height: 1, color: AppColors.border),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              FormField<void>(
                validator: (_) => viewModel.validateExtras(),
                builder: (field) => field.errorText == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          field.errorText!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
              ),

              AppOutlineButton(
                compact: true,
                label: 'Add Extra',
                onPressed: viewModel.openAddExtraDialog,
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: AppComboBox<Vehicle>.async(
                    label: 'Default Vehicle',
                    value: viewModel.selectedVehicle,
                    itemLabelBuilder: (vehicle) => vehicle.label,
                    onChanged: viewModel.selectVehicle,
                    placeholder: 'Optional vehicle link',
                    fetchPage: viewModel.fetchVehiclesPage,
                    fullScreen: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Start Date',
                    controller: TextEditingController(
                      text: viewModel.startDate != null
                          ? Formatters.date(viewModel.startDate!)
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
                    label: 'End Date',
                    controller: TextEditingController(
                      text: viewModel.endDate != null
                          ? Formatters.date(viewModel.endDate!)
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
              label: 'Save agreement',
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
  AgreementFormSheetModel viewModelBuilder(BuildContext context) =>
      AgreementFormSheetModel(completer: completer!, request: request);
}
