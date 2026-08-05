import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/route_rate_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:fleetgo/ui/widgets/paginated_list/pagination_controller.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum RouteRatesBusy { addRouteRate }

class RouteRatesViewModel extends BaseViewModel {
  final _repository = locator<RouteRateRepository>();
  final _bottomSheets = locator<BottomSheetService>();
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();

  late final PaginationController<RouteRate> pagination =
      PaginationController<RouteRate>(
        callback: (pageNumber, pageSize) => _repository.fetchRouteRatesPage(
          pageNumber: pageNumber,
          pageSize: pageSize,
          search: null,
        ),
        onStateChanged: notifyListeners,
      );

  Future<void> init() => pagination.loadInitial();

  Future<void> refreshList() async {
    _repository.invalidateCache();
    await pagination.refresh();
  }

  Future<void> addRouteRate() async {
    if (busy(RouteRatesBusy.addRouteRate)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<RouteRate, dynamic>(
        variant: BottomSheetType.routeRateForm,
        isScrollControlled: true,
      );
      final routeRate = response?.data;
      if (routeRate == null) return;
      switch (await _repository.addRouteRate(routeRate)) {
        case Success():
          await pagination.loadInitial();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: RouteRatesBusy.addRouteRate);
  }

  Future<void> openRouteRate(RouteRate routeRate) async {
    await _navigation.navigateTo(
      Routes.routeRateDetailView,
      arguments: RouteRateDetailViewArguments(routeRate: routeRate),
    );
    await pagination.loadInitial();
  }

  @override
  void dispose() {
    pagination.dispose();
    super.dispose();
  }
}
