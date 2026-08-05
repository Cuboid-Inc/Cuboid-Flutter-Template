import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/features/more/ui/agreements/agreements_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/empty_state.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:cuboid_flutter_template/ui/widgets/paginated_list/paginated_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class AgreementsView extends StackedView<AgreementsViewModel> {
  const AgreementsView({super.key});

  @override
  void onViewModelReady(AgreementsViewModel viewModel) => viewModel.init();

  @override
  AgreementsViewModel viewModelBuilder(BuildContext context) =>
      AgreementsViewModel();

  @override
  Widget builder(BuildContext context, AgreementsViewModel vm, Widget? child) {
    return Scaffold(
      appBar: AppBarIOS(
        title: 'Agreements',
        actions: [
          AppBarIconAction(
            icon: CupertinoIcons.add,
            onPressed: vm.busy(AgreementsBusy.addAgreement)
                ? null
                : vm.addAgreement,
          ),
        ],
      ),
      body: PaginatedListView<Agreement>(
        controller: vm.pagination,
        onRefresh: vm.refreshList,
        padding: const EdgeInsets.all(s16),
        itemBuilder: (context, agreement, _) => _row(agreement, vm),
        emptyWidget: EmptyState(
          title: 'No Agreements',
          subtitle: 'Create a new agreement to get started',
          icon: CupertinoIcons.doc_text,
          actionLabel: 'Add Agreement',
          onAction: vm.busy(AgreementsBusy.addAgreement)
              ? null
              : vm.addAgreement,
        ),
      ),
    );
  }

  Widget _row(Agreement a, AgreementsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListCard(
        onTap: () => vm.openAgreement(a),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: a.rateModel == RateModel.monthly
                    ? AppColors.warningBg
                    : AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                a.rateModel == RateModel.monthly
                    ? CupertinoIcons.calendar
                    : CupertinoIcons.arrow_branch,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.reference,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Formatters.money(a.baseRate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontSize: 13,
                  ),
                ),
                Text(
                  a.rateModel == RateModel.monthly ? 'per month' : 'per trip',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.mutedLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
