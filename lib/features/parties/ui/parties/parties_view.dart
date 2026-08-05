import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/features/parties/ui/parties/parties_viewmodel.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/empty_state.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:fleetgo/ui/widgets/paginated_list/paginated_list_view.dart';
import 'package:fleetgo/ui/widgets/segmented_toggle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class PartiesView extends StackedView<PartiesViewModel> {
  const PartiesView({super.key});
  @override
  void onViewModelReady(PartiesViewModel viewModel) => viewModel.init();
  @override
  PartiesViewModel viewModelBuilder(BuildContext context) =>
      PartiesViewModel(null);

  @override
  Widget builder(
    BuildContext context,
    PartiesViewModel vm,
    Widget? child,
  ) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBarIOS(
      title: 'Customers & Suppliers',
      actions: [
        AppBarIconAction(
          icon: CupertinoIcons.add,
          onPressed: vm.busy(PartiesBusy.addParty) ? null : vm.add,
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(s16, s16, s16, 0),
          child: SegmentedToggle<PartyType>(
            values: PartyType.values,
            value: vm.selectedType,
            onChanged: vm.selectType,
            labelBuilder: (type) =>
                type == PartyType.customer ? 'Customers' : 'Suppliers',
          ),
        ),
        Expanded(
          child: PaginatedListView<Party>(
            controller: vm.pagination,
            onRefresh: vm.refreshList,
            padding: const EdgeInsets.all(s16),
            separator: const SizedBox(height: 8),
            itemBuilder: (context, party, index) => _row(party, vm),
            emptyWidget: EmptyState(
              title: vm.selectedType == PartyType.customer
                  ? 'No customers found'
                  : 'No suppliers found',
              subtitle:
                  'Tap the + button to add a new ${vm.selectedType == PartyType.customer ? 'customer' : 'supplier'}',
              icon: CupertinoIcons.person_3_fill,
              actionLabel:
                  'Add ${vm.selectedType == PartyType.customer ? 'Customer' : 'Supplier'}',
              onAction: vm.busy(PartiesBusy.addParty) ? null : vm.add,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _row(Party party, PartiesViewModel vm) => ListCard(
    onTap: () => vm.open(party),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: party.type == PartyType.supplier
                ? AppColors.warningBg
                : AppColors.chipBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            party.initials,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                party.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                party.paymentTerms.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedLight,
                ),
              ),
            ],
          ),
        ),
        Text(
          Formatters.money(vm.balanceFor(party.id)),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
