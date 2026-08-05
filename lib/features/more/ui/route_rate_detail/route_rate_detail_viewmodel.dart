import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/route_rate_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum RouteRateDetailBusy { action }

class RouteRateDetailViewModel extends BaseViewModel {
  RouteRateDetailViewModel(
    RouteRate initialRouteRate, {
    RouteRateRepository? repository,
  }) : routeRate = initialRouteRate,
       _repository = repository ?? locator<RouteRateRepository>();

  RouteRate routeRate;
  final RouteRateRepository _repository;
  final _bottomSheets = locator<BottomSheetService>();
  final _snackbar = locator<SnackbarService>();
  final _navigation = locator<NavigationService>();

  Future<void> editRouteRate() async {
    if (busy(RouteRateDetailBusy.action)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets
          .showCustomSheet<RouteRate, RouteRate>(
            variant: BottomSheetType.routeRateForm,
            data: routeRate,
            isScrollControlled: true,
          );
      final updatedRoute = response?.data;
      if (updatedRoute == null) return;
      switch (await _repository.addRouteRate(updatedRoute)) {
        case Success(:final value):
          routeRate = value;
          _snackbar.showSuccess('Route rate updated successfully');
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: RouteRateDetailBusy.action);
  }

  Future<void> archiveRouteRate() async {
    if (busy(RouteRateDetailBusy.action)) return;
    await runBusyFuture(() async {
      switch (await _repository.archiveRouteRate(routeRate.id)) {
        case Success():
          _snackbar.showSuccess('Route rate archived successfully');
          _navigation.back();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: RouteRateDetailBusy.action);
  }
}
