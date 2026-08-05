import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/forms/form_validators.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/route_rate_form/route_rate_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_dropdown.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/demo_sheet.dart';
import 'package:cuboid_flutter_template/ui/widgets/extra_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:cuboid_flutter_template/ui/widgets/section_label.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class RouteRateFormSheet extends StackedView<RouteRateFormSheetModel> {
  const RouteRateFormSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  void onViewModelReady(RouteRateFormSheetModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    RouteRateFormSheetModel viewModel,
    Widget? child,
  ) => DemoSheet(
    title: viewModel.isEditing ? 'Edit route rate' : 'Add route rate',
    subtitle:
        'Define flat rate structures for specific paths and vehicle types',
    busy: viewModel.isBusy,
    loadingMessage: 'Loading route rate options',
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
                    child: AppDropdown<String>(
                      label: 'Customer Association',
                      value: viewModel.appliesTo,
                      items: [
                        'All customers',
                        ...viewModel.customers.map((c) => c.name),
                      ],
                      itemLabelBuilder: (c) => c,
                      onChanged: (val) {
                        if (val != null) viewModel.selectAppliesTo(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: AppDropdown<VehicleClass>(
                    label: 'Vehicle Class',
                    value: viewModel.vehicleClass,
                    items: VehicleClass.values,
                    itemLabelBuilder: (vc) => vc.label,
                    onChanged: viewModel.selectVehicleClass,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!viewModel.isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Pickup Location',
                      controller: viewModel.pickupController,
                      hintText: 'e.g. Jebel Ali Port',
                      validator: (value) => FormValidators.required(
                        value,
                        label: 'Pickup location',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: 'Destination Location',
                      controller: viewModel.destinationController,
                      hintText: 'e.g. Al Maktoum Airport',
                      validator: (value) =>
                          FormValidators.required(value, label: 'Destination'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Rate AED',
                    controller: viewModel.rateAEDController,
                    hintText: 'e.g. 850.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        FormValidators.money(value, label: 'Rate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── DEFAULT EXTRAS section ─────────────────────────────────
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
            const SizedBox(height: 24),
            AppButton(
              label: 'Save route rate',
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
  RouteRateFormSheetModel viewModelBuilder(BuildContext context) =>
      RouteRateFormSheetModel(completer: completer!, request: request);
}
