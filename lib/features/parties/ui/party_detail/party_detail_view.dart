import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/features/parties/ui/party_detail/party_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/parties/ui/party_detail/widgets/party_info_card.dart';
import 'package:cuboid_flutter_template/features/parties/ui/party_detail/widgets/party_open_invoice_tile.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class PartyDetailView extends StackedView<PartyDetailViewModel> {
  const PartyDetailView({super.key, required this.party});
  final Party party;

  @override
  void onViewModelReady(PartyDetailViewModel viewModel) => viewModel.init();

  @override
  PartyDetailViewModel viewModelBuilder(BuildContext context) =>
      PartyDetailViewModel(party);

  @override
  Widget builder(BuildContext context, PartyDetailViewModel vm, Widget? child) {
    final openInvoices = vm.invoices
        .where(
          (invoice) =>
              invoice.status != InvoiceStatus.voided &&
              vm.invoiceBalance(invoice) > 0,
        )
        .toList();

    return Scaffold(
      appBar: AppBarIOS(
        title: vm.party.name,
        actions: [
          AppBarTextAction(
            label: 'Edit',
            onPressed: vm.busy(PartyDetailBusy.editParty) ? null : vm.editParty,
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading party details')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                // Outstanding Balance Card (iOS Dark Navy styled card)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OUTSTANDING BALANCE',
                        style: TextStyle(
                          color: AppColors.mutedLight,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.money(vm.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vm.party.paymentTerms.label} · TRN ${vm.party.trn ?? '—'}',
                        style: const TextStyle(
                          color: AppColors.mutedLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Party Info Card (using the extracted sub-widget)
                PartyInfoCard(party: vm.party),
                const SizedBox(height: 14),

                // Open Invoices List
                if (openInvoices.isNotEmpty) ...[
                  const Text('OPEN INVOICES', style: _label),
                  const SizedBox(height: 8),
                  ListCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < openInvoices.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          PartyOpenInvoiceTile(
                            invoice: openInvoices[i],
                            balance: vm.invoiceBalance(openInvoices[i]),
                            onTap: () => vm.viewInvoice(openInvoices[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Buttons
                if (vm.shouldShowRecordPayment) ...[
                  AppButton(
                    compact: true,
                    label: 'Record payment',
                    loading: vm.busy(PartyDetailBusy.recordPayment),
                    onPressed: vm.recordPayment,
                  ),
                  const SizedBox(height: 12),
                ],
                AppOutlineButton(
                  compact: true,
                  color: Colors.red,
                  label: 'Archive party',
                  loading: vm.busy(PartyDetailBusy.archiveParty),
                  onPressed: vm.archiveParty,
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}

const _label = TextStyle(
  fontSize: 11.5,
  letterSpacing: 0.6,
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);
