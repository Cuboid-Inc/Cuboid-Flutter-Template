import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/forms/form_validators.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:fleetgo/ui/bottom_sheets/payment_form/widgets/document_selector.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_combo_box.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:fleetgo/ui/widgets/chip_selector.dart';
import 'package:fleetgo/ui/widgets/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class PaymentFormSheet extends StackedView<PaymentFormSheetModel> {
  const PaymentFormSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  void onViewModelReady(PaymentFormSheetModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    PaymentFormSheetModel viewModel,
    Widget? child,
  ) => DemoSheet(
    title: viewModel.incoming ? 'Payment in' : 'Payment out',
    subtitle: viewModel.incoming
        ? 'Money received from a customer'
        : 'Money paid to a supplier',
    busy: viewModel.isBusy,
    loadingMessage: 'Loading payment details',
    child: SingleChildScrollView(
      child: Form(
        key: viewModel.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (viewModel.loadErrorMessage case final loadError?) ...[
              Text(loadError, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 13),
            ],
            FormField<String>(
              validator: (_) =>
                  FormValidators.selection(viewModel.partyId, 'Select a party'),
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppComboBox<Party>.async(
                    label: 'Party',
                    value: viewModel.selectedParty,
                    itemLabelBuilder: (party) => party.name,
                    itemSubtitleBuilder: (party) =>
                        party.trn != null ? 'TRN: ${party.trn}' : 'No TRN',
                    placeholder: viewModel.incoming
                        ? 'Tap to select customer...'
                        : 'Tap to select supplier...',
                    fetchPage: viewModel.fetchPartiesPage,
                    onChanged: (party) =>
                        party != null ? viewModel.selectParty(party) : null,
                    fullScreen: true,
                  ),
                  if (field.errorText case final error?)
                    Text(
                      error,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Text(
              viewModel.incoming
                  ? 'LINK TO INVOICE'
                  : 'LINK TO SETTLEMENT OR EXPENSE',
              style: _labelStyle,
            ),
            const SizedBox(height: 7),
            FormField<String>(
              validator: (_) => viewModel.linkedDocError,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DocumentSelector(viewModel: viewModel),
                  if (field.errorText case final error?)
                    Text(
                      error,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            AppTextField(
              label: 'Amount',
              controller: viewModel.amountController,
              hintText: 'AED 0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => FormValidators.money(
                value,
                label: 'Payment amount',
                max: viewModel.paymentLimit,
                maxMessage: viewModel.paymentLimitMessage,
              ),
            ),
            const SizedBox(height: 13),
            const Text('METHOD', style: _labelStyle),
            const SizedBox(height: 7),
            ChipSelector<PaymentMethod>(
              items: PaymentMethod.values,
              selected: [viewModel.method],
              labelBuilder: viewModel.methodLabel,
              onChanged: viewModel.selectMethod,
            ),
            if (viewModel.method == PaymentMethod.cheque) ...[
              const SizedBox(height: 8),
              const Text(
                'Cheque is recorded as received. Balances update after clearance.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 13),
            AppTextField(
              label: 'Bank or cheque reference',
              controller: viewModel.referenceController,
              hintText: 'Optional',
            ),
            const SizedBox(height: 16),
            AppButton(
              label: viewModel.incoming
                  ? 'Save payment in'
                  : 'Save payment out',
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
  PaymentFormSheetModel viewModelBuilder(BuildContext context) =>
      PaymentFormSheetModel(completer: completer!, request: request);
}

const _labelStyle = TextStyle(
  fontSize: 11.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.6,
  color: AppColors.muted,
);
