import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/features/more/ui/drivers/drivers_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/empty_state.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:cuboid_flutter_template/ui/widgets/paginated_list/paginated_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class DriversView extends StackedView<DriversViewModel> {
  const DriversView({super.key});

  @override
  void onViewModelReady(DriversViewModel viewModel) => viewModel.init();

  @override
  DriversViewModel viewModelBuilder(BuildContext context) => DriversViewModel();

  @override
  Widget builder(BuildContext context, DriversViewModel vm, Widget? child) {
    return Scaffold(
      appBar: AppBarIOS(
        title: 'Drivers',
        actions: [
          AppBarIconAction(
            icon: CupertinoIcons.add,
            onPressed: vm.busy(DriversBusy.addDriver) ? null : vm.addDriver,
          ),
        ],
      ),
      body: PaginatedListView<Driver>(
        controller: vm.pagination,
        onRefresh: vm.refreshList,
        padding: const EdgeInsets.all(s16),
        itemBuilder: (context, driver, _) => _row(driver, vm),
        emptyWidget: EmptyState(
          title: 'No Drivers',
          subtitle: 'Add a driver to get started',
          icon: CupertinoIcons.person_2,
          actionLabel: 'Add Driver',
          onAction: vm.busy(DriversBusy.addDriver) ? null : vm.addDriver,
        ),
      ),
    );
  }

  Widget _row(Driver d, DriversViewModel vm) {
    final expiryDate = d.licenceExpiry ?? d.identityExpiry;
    final isNearExpiry =
        expiryDate != null &&
        expiryDate.difference(DateTime.now()).inDays <= 30;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListCard(
        onTap: () => vm.openDriver(d),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: d.employment == Responsibility.customer
                    ? AppColors.warningBg
                    : AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                d.employment == Responsibility.customer
                    ? CupertinoIcons.person_2
                    : CupertinoIcons.person_crop_circle_badge_checkmark,
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
                    d.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.phone ?? "No phone"} · ${d.employment == Responsibility.operator ? "Operator" : "Subcontracted"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (expiryDate != null) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'EXPIRY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    Formatters.date(expiryDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isNearExpiry
                          ? Colors.orange.shade800
                          : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
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
