import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:cuboid_flutter_template/ui/widgets/paginated_list/pagination_controller.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum DriversBusy { addDriver }

class DriversViewModel extends BaseViewModel {
  final _repository = locator<DriverRepository>();
  final _bottomSheets = locator<BottomSheetService>();
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();

  late final PaginationController<Driver> pagination =
      PaginationController<Driver>(
        callback: (pageNumber, pageSize) => _repository.fetchDriversPage(
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

  Future<void> addDriver() async {
    if (busy(DriversBusy.addDriver)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<Driver, dynamic>(
        variant: BottomSheetType.driverForm,
        isScrollControlled: true,
      );
      final driver = response?.data;
      if (driver == null) return;
      switch (await _repository.addDriver(driver)) {
        case Success():
          await pagination.loadInitial();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: DriversBusy.addDriver);
  }

  Future<void> openDriver(Driver driver) async {
    await _navigation.navigateTo(
      Routes.driverDetailView,
      arguments: DriverDetailViewArguments(driver: driver),
    );
    await pagination.loadInitial();
  }

  @override
  void dispose() {
    pagination.dispose();
    super.dispose();
  }
}
