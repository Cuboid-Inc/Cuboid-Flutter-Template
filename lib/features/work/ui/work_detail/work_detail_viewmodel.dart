import 'package:fleetgo/app/app.dialogs.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/agreement.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/features/more/data/agreement_repository.dart';
import 'package:fleetgo/features/more/data/business_profile_repository.dart';
import 'package:fleetgo/features/more/data/driver_repository.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/work/data/work_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:fleetgo/ui/pdf/fleet_pdf.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum WorkDetailBusy { action }

class WorkDetailViewModel extends BaseViewModel {
  WorkDetailViewModel(
    this.work, {
    WorkRepository? repository,
    AgreementRepository? agreementRepository,
    VehicleRepository? vehicleRepository,
    DriverRepository? driverRepository,
    BusinessProfileRepository? businessProfileRepository,
    PartiesRepository? partiesRepository,
    MoneyRepository? moneyRepository,
  }) : _repository = repository ?? locator<WorkRepository>(),
       _agreementRepository =
           agreementRepository ?? locator<AgreementRepository>(),
       _vehicleRepository = vehicleRepository ?? locator<VehicleRepository>(),
       _driverRepository = driverRepository ?? locator<DriverRepository>(),
       _businessProfileRepository =
           businessProfileRepository ?? locator<BusinessProfileRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>(),
       _moneyRepository = moneyRepository ?? locator<MoneyRepository>();

  WorkOrder work;
  final _dialogs = locator<DialogService>();
  final _navigation = locator<NavigationService>();
  final WorkRepository _repository;
  final AgreementRepository _agreementRepository;
  final VehicleRepository _vehicleRepository;
  final DriverRepository _driverRepository;
  final BusinessProfileRepository _businessProfileRepository;
  final PartiesRepository _partiesRepository;
  final MoneyRepository _moneyRepository;
  final _authRepository = locator<AuthRepository>();
  final _snackbar = locator<SnackbarService>();

  Party? customer;
  Agreement? agreement;
  BusinessProfile? businessProfile;
  List<Vehicle> vehicles = const [];
  List<Driver> drivers = const [];

  Invoice? linkedInvoice;
  List<Expense> linkedExpenses = const [];

  bool get hasMoneyPermission {
    final access = _authRepository.currentAccess;
    return access?.isOwner == true ||
        access?.accessPacks.contains(AccessPack.money) == true;
  }

  num get totalSupplierPayable => work.allocations
      .where((a) => a.source == VehicleSource.supplier)
      .fold<num>(0, (sum, a) => roundMoney(sum + a.supplierPayable));

  Future<void> init() async {
    setBusy(true);
    switch (await _partiesRepository.fetchAll()) {
      case Success(:final value):
        customer = value
            .where((party) => party.id == work.customerId)
            .firstOrNull;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _agreementRepository.fetchAgreements()) {
      case Success(:final value):
        agreement = value
            .where((item) => item.id == work.agreementId)
            .firstOrNull;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _vehicleRepository.fetchVehicles()) {
      case Success(:final value):
        vehicles = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _driverRepository.fetchDrivers()) {
      case Success(:final value):
        drivers = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _businessProfileRepository.fetchBusinessProfile()) {
      case Success(:final value):
        businessProfile = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    if (work.invoiceId != null) {
      switch (await _moneyRepository.fetchInvoices()) {
        case Success(:final value):
          linkedInvoice = value
              .where((i) => i.id == work.invoiceId)
              .firstOrNull;
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }
    switch (await _moneyRepository.fetchExpenses()) {
      case Success(:final value):
        linkedExpenses = value.where((e) => e.workOrderId == work.id).toList();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  Future<void> openPrepareMonth() async {
    await _navigation.navigateTo(
      Routes.prepareMonthView,
      arguments: PrepareMonthViewArguments(customerId: customer?.id),
    );
    switch (await _repository.fetchOne(work.id)) {
      case Success(:final value):
        work = value;
        notifyListeners();
      case Failure():
        break;
    }
  }

  void viewInvoice() {
    if (linkedInvoice != null) {
      _navigation.navigateTo(
        Routes.invoiceDetailView,
        arguments: InvoiceDetailViewArguments(invoice: linkedInvoice!),
      );
    }
  }

  void openPdf() {
    if (businessProfile == null) return;
    _navigation.navigateTo(
      Routes.pdfPreviewView,
      arguments: PdfPreviewViewArguments(
        title: '${work.number} trip sheet',
        build: () => buildTripSheetPdf(work, businessProfile!),
      ),
    );
  }

  Future<void> complete() async {
    if (busy(WorkDetailBusy.action)) return;
    await runBusyFuture(() async {
      switch (await _repository.complete(work.id)) {
        case Success(:final value):
          work = value;
          notifyListeners();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: WorkDetailBusy.action);
  }

  String vehicleLabel(String id) =>
      vehicles.where((vehicle) => vehicle.id == id).firstOrNull?.label ?? id;
  String driverName(String? id) => id == null
      ? 'Assigned driver'
      : drivers.where((driver) => driver.id == id).firstOrNull?.name ?? id;

  Future<void> cancel() async {
    if (busy(WorkDetailBusy.action)) return;
    await runBusyFuture(() async {
      final response = await _dialogs.showCustomDialog(
        variant: DialogType.confirm,
        title: 'Cancel work order?',
        description: 'Canceled work stays in history and cannot be billed.',
        mainButtonTitle: 'Cancel work order',
        secondaryButtonTitle: 'Keep work order',
      );
      if (response?.confirmed != true) return;
      switch (await _repository.cancel(work.id)) {
        case Success(:final value):
          work = value;
          notifyListeners();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: WorkDetailBusy.action);
  }

  // Future<void> duplicate() async {
  //   if (busy(WorkDetailBusy.action)) return;
  //   final result = await _dialogs.showCustomDialog(
  //     variant: DialogType.confirm,
  //     title: 'Duplicate work order?',
  //     description: 'This will create a new work order with the same details.',
  //     mainButtonTitle: 'Duplicate',
  //     secondaryButtonTitle: 'Cancel',
  //   );
  //   if (result?.confirmed != true) return;
  //   await runBusyFuture(() async {
  //     switch (await _repository.duplicate(work.id)) {
  //       case Success(:final value):
  //         _snackbar.showSuccess('${value.number} duplicated');
  //       case Failure(:final failure):
  //         _snackbar.showError(failure.message);
  //     }
  //   }(), busyObject: WorkDetailBusy.action);
  // }
}
