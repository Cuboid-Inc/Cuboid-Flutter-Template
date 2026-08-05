import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/features/more/ui/route_rates/route_rates_viewmodel.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/empty_state.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:fleetgo/ui/widgets/paginated_list/paginated_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class RouteRatesView extends StackedView<RouteRatesViewModel> {
  const RouteRatesView({super.key});

  @override
  void onViewModelReady(RouteRatesViewModel viewModel) => viewModel.init();

  @override
  RouteRatesViewModel viewModelBuilder(BuildContext context) =>
      RouteRatesViewModel();

  @override
  Widget builder(BuildContext context, RouteRatesViewModel vm, Widget? child) {
    return Scaffold(
      appBar: AppBarIOS(
        title: 'Route Rate Card',
        actions: [
          AppBarIconAction(
            icon: CupertinoIcons.add,
            onPressed: vm.busy(RouteRatesBusy.addRouteRate)
                ? null
                : vm.addRouteRate,
          ),
        ],
      ),
      body: PaginatedListView<RouteRate>(
        controller: vm.pagination,
        onRefresh: vm.refreshList,
        padding: const EdgeInsets.all(s16),
        itemBuilder: (context, routeRate, _) => _row(routeRate, vm),
        emptyWidget: EmptyState(
          title: 'No Route Rates',
          subtitle: 'Add a route rate to get started',
          icon: CupertinoIcons.map,
          actionLabel: 'Add Route Rate',
          onAction: vm.busy(RouteRatesBusy.addRouteRate)
              ? null
              : vm.addRouteRate,
        ),
      ),
    );
  }

  Widget _row(RouteRate r, RouteRatesViewModel vm) {
    final isCustomClient = r.appliesTo != 'All customers';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListCard(
        onTap: () => vm.openRouteRate(r),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCustomClient ? AppColors.warningBg : AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.arrow_branch,
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
                    '${r.pickup} → ${r.destination}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.appliesTo} · ${r.vehicleClass}',
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
            Text(
              Formatters.money(r.rate),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 13,
              ),
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
