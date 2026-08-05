import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_loading_indicator.dart';
import 'package:fleetgo/features/more/ui/route_rate_detail/route_rate_detail_viewmodel.dart';
import 'package:fleetgo/features/more/ui/route_rate_detail/widgets/route_rate_info_card.dart';

class RouteRateDetailView extends StackedView<RouteRateDetailViewModel> {
  const RouteRateDetailView({super.key, required this.routeRate});
  final RouteRate routeRate;

  @override
  RouteRateDetailViewModel viewModelBuilder(BuildContext context) =>
      RouteRateDetailViewModel(routeRate);

  @override
  Widget builder(
    BuildContext context,
    RouteRateDetailViewModel vm,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBarIOS(
        title: 'Route Rate Details',
        actions: [
          AppBarTextAction(
            label: 'Edit',
            onPressed: vm.busy(RouteRateDetailBusy.action)
                ? null
                : vm.editRouteRate,
          ),
        ],
      ),
      body: vm.isBusy
          ? const AppLoadingIndicator(message: 'Loading route rate')
          : ListView(
              padding: const EdgeInsets.all(s16),
              children: [
                RouteRateInfoCard(routeRate: vm.routeRate),
                const SizedBox(height: 20),
                AppOutlineButton(
                  compact: true,
                  color: Colors.red,
                  label: 'Archive route rate',
                  loading: vm.busy(RouteRateDetailBusy.action),
                  onPressed: vm.archiveRouteRate,
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
