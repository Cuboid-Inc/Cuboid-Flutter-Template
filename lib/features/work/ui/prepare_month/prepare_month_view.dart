import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/money.dart';
import 'package:cuboid_flutter_template/features/work/ui/prepare_month/prepare_month_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_combo_box.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class PrepareMonthView extends StackedView<PrepareMonthViewModel> {
  const PrepareMonthView({super.key, this.customerId});

  final String? customerId;

  @override
  void onViewModelReady(PrepareMonthViewModel viewModel) => viewModel.init();

  @override
  PrepareMonthViewModel viewModelBuilder(BuildContext context) =>
      PrepareMonthViewModel(customerId: customerId);

  @override
  Widget builder(
    BuildContext context,
    PrepareMonthViewModel vm,
    Widget? child,
  ) => Scaffold(
    appBar: const AppBarIOS(title: 'Prepare monthly invoice'),
    body: ListView(
      padding: const EdgeInsets.all(s16),
      children: [
        AppComboBox<Party>.async(
          label: 'Customer',
          value: vm.selectedCustomer,
          placeholder: 'Tap to select customer...',
          itemLabelBuilder: (party) => party.name,
          fetchPage: vm.fetchCustomersPage,
          onChanged: vm.selectCustomer,
        ),
        const SizedBox(height: 14),
        const Text('MONTH', style: _label),
        const SizedBox(height: 8),
        ListCard(
          onTap: vm.choosePeriod,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.monthYear(vm.period.start),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(CupertinoIcons.calendar),
            ],
          ),
        ),
        if (vm.works.any((work) => work.workType != WorkType.perTrip)) ...[
          const SizedBox(height: 14),
          const Text('MONTHLY-HIRE WORK', style: _label),
          const SizedBox(height: 8),
          for (final work in vm.works.where(
            (work) => work.workType != WorkType.perTrip,
          ))
            _workCard(vm, work),
        ],
        if (vm.works.any((work) => work.workType == WorkType.perTrip)) ...[
          const SizedBox(height: 14),
          const Text('PER-TRIP WORK', style: _label),
          const SizedBox(height: 8),
          for (final work in vm.works.where(
            (work) => work.workType == WorkType.perTrip,
          ))
            _workCard(vm, work),
        ],
        if (vm.customerId != null && vm.works.isEmpty) ...[
          const SizedBox(height: 14),
          _noWorkNotice(vm),
        ],
        ListCard(
          child: Column(
            children: [
              _row('Net', vm.net),
              _row('VAT 5%', vm.vat),
              _row('Invoice total', roundMoney(vm.net + vm.vat), strong: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Issue invoice',
          loading: vm.busy(PrepareMonthBusy.issueInvoice),
          onPressed: vm.canIssue ? vm.issue : null,
        ),
      ],
    ),
  );

  Widget _workCard(PrepareMonthViewModel vm, WorkOrder work) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListCard(
      onTap: () => vm.toggleWork(work.id),
      child: Row(
        children: [
          Icon(
            vm.isSelected(work.id)
                ? CupertinoIcons.checkmark_square_fill
                : CupertinoIcons.square,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work.number,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  work.route,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            Formatters.money(work.net),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );

  Widget _noWorkNotice(PrepareMonthViewModel vm) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.warningBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: AppColors.warningDark,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'No unbilled work for ${vm.selectedCustomer?.name} in '
            '${Formatters.monthYear(vm.period.start)}.',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.warningDark,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _row(String label, num value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          Formatters.money(value),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            fontSize: strong ? 17 : 13,
          ),
        ),
      ],
    ),
  );
}

const _label = TextStyle(
  fontSize: 11.5,
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.6,
);
