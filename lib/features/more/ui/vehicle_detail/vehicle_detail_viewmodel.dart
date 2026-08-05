import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum VehicleDetailBusy { action }

class VehicleDetailViewModel extends BaseViewModel {
  VehicleDetailViewModel(
    Vehicle initialVehicle, {
    VehicleRepository? repository,
  }) : vehicle = initialVehicle,
       _repository = repository ?? locator<VehicleRepository>();

  Vehicle vehicle;
  final VehicleRepository _repository;
  final _bottomSheets = locator<BottomSheetService>();
  final _snackbar = locator<SnackbarService>();
  final _navigation = locator<NavigationService>();

  List<Party> parties = const [];

  Future<void> init() async {
    setBusy(true);
    switch (await locator<PartiesRepository>().fetchAll()) {
      case Success(:final value):
        parties = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  String getSupplierName(String? supplierId) {
    if (supplierId == null) return '—';
    final match = parties.where((p) => p.id == supplierId).firstOrNull;
    return match?.name ?? 'Unknown Supplier ($supplierId)';
  }

  Future<void> editVehicle() async {
    if (busy(VehicleDetailBusy.action)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<Vehicle, Vehicle>(
        variant: BottomSheetType.vehicleForm,
        data: vehicle,
        isScrollControlled: true,
      );
      final updatedVehicle = response?.data;
      if (updatedVehicle == null) return;
      switch (await _repository.addVehicle(updatedVehicle)) {
        case Success(:final value):
          vehicle = value;
          _snackbar.showSuccess('Vehicle details updated successfully');
          await init();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: VehicleDetailBusy.action);
  }

  Future<void> archiveVehicle() async {
    if (busy(VehicleDetailBusy.action)) return;
    await runBusyFuture(() async {
      switch (await _repository.archiveVehicle(vehicle.id)) {
        case Success():
          _snackbar.showSuccess('Vehicle archived successfully');
          _navigation.back();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: VehicleDetailBusy.action);
  }
}
