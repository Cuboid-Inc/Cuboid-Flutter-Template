import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum AgreementDetailBusy { action }

class AgreementDetailViewModel extends BaseViewModel {
  AgreementDetailViewModel(
    Agreement initialAgreement, {
    AgreementRepository? repository,
    VehicleRepository? vehicleRepository,
  }) : agreement = initialAgreement,
       _repository = repository ?? locator<AgreementRepository>(),
       _vehicleRepository = vehicleRepository ?? locator<VehicleRepository>();

  Agreement agreement;
  final AgreementRepository _repository;
  final VehicleRepository _vehicleRepository;
  final _bottomSheets = locator<BottomSheetService>();
  final _snackbar = locator<SnackbarService>();
  final _navigation = locator<NavigationService>();

  List<Party> parties = const [];
  List<Vehicle> vehicles = const [];

  Future<void> init() async {
    setBusy(true);
    switch (await locator<PartiesRepository>().fetchAll()) {
      case Success(:final value):
        parties = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _vehicleRepository.fetchVehicles()) {
      case Success(:final value):
        vehicles = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  String getCustomerName(String customerId) {
    final match = parties.where((p) => p.id == customerId).firstOrNull;
    return match?.name ?? 'Unknown Customer ($customerId)';
  }

  String getVehicleLabel(String? vehicleId) {
    if (vehicleId == null) return '—';
    final match = vehicles.where((v) => v.id == vehicleId).firstOrNull;
    return match?.label ?? 'Unknown Vehicle ($vehicleId)';
  }

  Future<void> editAgreement() async {
    if (busy(AgreementDetailBusy.action)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets
          .showCustomSheet<Agreement, Agreement>(
            variant: BottomSheetType.agreementForm,
            data: agreement,
            isScrollControlled: true,
          );
      final updatedAgreement = response?.data;
      if (updatedAgreement == null) return;
      switch (await _repository.addAgreement(updatedAgreement)) {
        case Success(:final value):
          agreement = value;
          _snackbar.showSuccess('Agreement details updated successfully');
          await init();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: AgreementDetailBusy.action);
  }

  Future<void> archiveAgreement() async {
    if (busy(AgreementDetailBusy.action)) return;
    await runBusyFuture(() async {
      switch (await _repository.archiveAgreement(agreement.id)) {
        case Success():
          _snackbar.showSuccess('Agreement archived successfully');
          _navigation.back();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: AgreementDetailBusy.action);
  }
}
