import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum DriverDetailBusy { action }

class DriverDetailViewModel extends BaseViewModel {
  DriverDetailViewModel(Driver initialDriver, {DriverRepository? repository})
    : driver = initialDriver,
      _repository = repository ?? locator<DriverRepository>();

  Driver driver;
  final DriverRepository _repository;
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

  Future<void> editDriver() async {
    if (busy(DriverDetailBusy.action)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<Driver, Driver>(
        variant: BottomSheetType.driverForm,
        data: driver,
        isScrollControlled: true,
      );
      final updatedDriver = response?.data;
      if (updatedDriver == null) return;
      switch (await _repository.addDriver(updatedDriver)) {
        case Success(:final value):
          driver = value;
          _snackbar.showSuccess('Driver details updated successfully');
          await init();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: DriverDetailBusy.action);
  }

  Future<void> archiveDriver() async {
    if (busy(DriverDetailBusy.action)) return;
    await runBusyFuture(() async {
      switch (await _repository.archiveDriver(driver.id)) {
        case Success():
          _snackbar.showSuccess('Driver archived successfully');
          _navigation.back();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: DriverDetailBusy.action);
  }
}
