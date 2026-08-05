import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/forms/form_validators.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/party_form/party_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_dropdown.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/chip_selector.dart';
import 'package:cuboid_flutter_template/ui/widgets/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class PartyFormSheet extends StackedView<PartyFormSheetModel> {
  const PartyFormSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  Widget builder(
    BuildContext context,
    PartyFormSheetModel viewModel,
    Widget? child,
  ) => DemoSheet(
    title: viewModel.isEditing
        ? 'Edit customer / supplier'
        : 'Add customer / supplier',
    subtitle: 'One party record can have both roles',
    child: SingleChildScrollView(
      child: Form(
        key: viewModel.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!viewModel.isEditing) ...[
              const Text('ROLE', style: _label),
              const SizedBox(height: 7),
              ChipSelector<PartyType>(
                items: PartyType.values,
                selected: [viewModel.type],
                labelBuilder: (t) => t.label,
                onChanged: viewModel.selectType,
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(
              label: 'Legal or display name',
              controller: viewModel.nameController,
              hintText: 'e.g. Falcon Readymix LLC',
              validator: (value) =>
                  FormValidators.required(value, label: 'Party name'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Contact Person',
              controller: viewModel.contactPersonController,
              hintText: 'Optional',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Phone',
                    controller: viewModel.phoneController,
                    hintText: 'Optional',
                    validator: FormValidators.phone,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Email',
                    controller: viewModel.emailController,
                    hintText: 'Optional',
                    validator: (value) =>
                        FormValidators.email(value, optional: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Address',
              controller: viewModel.addressController,
              hintText: 'Optional',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'City',
                    controller: viewModel.cityController,
                    hintText: 'Optional',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Country',
                    controller: viewModel.countryController,
                    hintText: 'Optional',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'TRN / TIN',
                    controller: viewModel.trnController,
                    hintText: 'Optional',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppDropdown<PaymentTerms>(
                    label: 'Payment terms',
                    value: viewModel.paymentTerms,
                    items: PaymentTerms.values,
                    itemLabelBuilder: (pt) => pt.label,
                    onChanged: viewModel.selectPaymentTerms,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Notes',
              controller: viewModel.notesController,
              hintText: 'Optional',
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Save party',
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
  PartyFormSheetModel viewModelBuilder(BuildContext context) =>
      PartyFormSheetModel(completer: completer!, request: request);
}

const _label = TextStyle(
  fontSize: 11.5,
  letterSpacing: 0.6,
  color: Color(0xFF667085),
  fontWeight: FontWeight.w800,
);
