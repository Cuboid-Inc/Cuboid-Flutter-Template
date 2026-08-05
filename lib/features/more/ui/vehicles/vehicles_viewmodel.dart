import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:cuboid_flutter_template/ui/widgets/paginated_list/pagination_controller.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum VehiclesBusy { addVehicle }

class VehiclesViewModel extends BaseViewModel {
  final _repository = locator<VehicleRepository>();
  final _bottomSheets = locator<BottomSheetService>();
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();

  late final PaginationController<Vehicle> pagination =
      PaginationController<Vehicle>(
        callback: (pageNumber, pageSize) => _repository.fetchVehiclesPage(
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

  Future<void> addVehicle() async {
    if (busy(VehiclesBusy.addVehicle)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<Vehicle, dynamic>(
        variant: BottomSheetType.vehicleForm,
        isScrollControlled: true,
      );
      final vehicle = response?.data;
      if (vehicle == null) return;
      switch (await _repository.addVehicle(vehicle)) {
        case Success():
          await pagination.loadInitial();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: VehiclesBusy.addVehicle);
  }

  Future<void> openVehicle(Vehicle vehicle) async {
    await _navigation.navigateTo(
      Routes.vehicleDetailView,
      arguments: VehicleDetailViewArguments(vehicle: vehicle),
    );
    await pagination.loadInitial();
  }

  @override
  void dispose() {
    pagination.dispose();
    super.dispose();
  }
}
