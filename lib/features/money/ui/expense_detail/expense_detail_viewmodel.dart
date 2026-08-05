import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ExpenseDetailViewModel extends BaseViewModel {
  ExpenseDetailViewModel(
    this.expense, {
    WorkRepository? workRepository,
    VehicleRepository? vehicleRepository,
    DriverRepository? driverRepository,
  }) : _workRepository = workRepository ?? locator<WorkRepository>(),
       _vehicleRepository = vehicleRepository ?? locator<VehicleRepository>(),
       _driverRepository = driverRepository ?? locator<DriverRepository>();

  final Expense expense;
  final WorkRepository _workRepository;
  final VehicleRepository _vehicleRepository;
  final DriverRepository _driverRepository;
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();

  WorkOrder? workOrder;
  Vehicle? vehicle;
  Driver? driver;

  Future<void> init() async {
    setBusy(true);
    if (expense.workOrderId != null) {
      switch (await _workRepository.fetchAll()) {
        case Success(:final value):
          workOrder = value
              .where((w) => w.id == expense.workOrderId)
              .firstOrNull;
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }
    if (expense.vehicleId != null) {
      switch (await _vehicleRepository.fetchVehicles()) {
        case Success(:final value):
          vehicle = value.where((v) => v.id == expense.vehicleId).firstOrNull;
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }
    if (expense.driverId != null) {
      switch (await _driverRepository.fetchDrivers()) {
        case Success(:final value):
          driver = value.where((d) => d.id == expense.driverId).firstOrNull;
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }
    setBusy(false);
  }

  void viewWorkOrder() {
    if (workOrder != null) {
      _navigation.navigateTo(
        Routes.workDetailView,
        arguments: WorkDetailViewArguments(work: workOrder!),
      );
    }
  }
}
