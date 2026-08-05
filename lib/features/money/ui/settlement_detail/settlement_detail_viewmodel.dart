import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:cuboid_flutter_template/ui/pdf/fleet_pdf.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum SettlementDetailBusy { recordPayment }

class SettlementDetailViewModel extends BaseViewModel {
  SettlementDetailViewModel(
    this.settlement, {
    MoneyRepository? repository,
    PartiesRepository? partiesRepository,
    WorkRepository? workRepository,
    VehicleRepository? vehicleRepository,
    BusinessProfileRepository? businessProfileRepository,
  }) : _moneyRepository = repository ?? locator<MoneyRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>(),
       _workRepository = workRepository ?? locator<WorkRepository>(),
       _vehicleRepository = vehicleRepository ?? locator<VehicleRepository>(),
       _businessProfileRepository =
           businessProfileRepository ?? locator<BusinessProfileRepository>();

  final SupplierSettlement settlement;
  final MoneyRepository _moneyRepository;
  final PartiesRepository _partiesRepository;
  final WorkRepository _workRepository;
  final VehicleRepository _vehicleRepository;
  final BusinessProfileRepository _businessProfileRepository;
  final _bottomSheets = locator<BottomSheetService>();
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();
  Party? supplier;
  num balance = 0;
  BusinessProfile? businessProfile;
  List<WorkOrder> workOrders = const [];
  List<Vehicle> vehicles = const [];

  String workOrderNumber(String id) =>
      workOrders.where((work) => work.id == id).firstOrNull?.number ?? id;
  String vehicleLabel(String id) =>
      vehicles.where((vehicle) => vehicle.id == id).firstOrNull?.label ?? id;

  Future<void> init() async {
    setBusy(true);
    switch (await _partiesRepository.fetchAll()) {
      case Success(:final value):
        supplier = value
            .where((party) => party.id == settlement.supplierId)
            .firstOrNull;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _moneyRepository.fetchBalances()) {
      case Success(:final value):
        balance = value.settlements[settlement.id] ?? 0;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _workRepository.fetchAll()) {
      case Success(:final value):
        workOrders = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _vehicleRepository.fetchVehicles()) {
      case Success(:final value):
        vehicles = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _businessProfileRepository.fetchBusinessProfile()) {
      case Success(:final value):
        businessProfile = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  void viewWorkOrder(SettlementLine line) async {
    setBusy(true);
    switch (await _workRepository.fetchAll()) {
      case Success(:final value):
        final work = value.where((w) => w.id == line.workOrderId).firstOrNull;
        if (work != null) {
          _navigation.navigateTo(
            Routes.workDetailView,
            arguments: WorkDetailViewArguments(work: work),
          );
        } else {
          _snackbar.showInfo('Work order not found');
        }
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  void openPdf() {
    if (supplier == null || businessProfile == null) return;
    _navigation.navigateTo(
      Routes.pdfPreviewView,
      arguments: PdfPreviewViewArguments(
        title: '${settlement.number}.pdf',
        build: () => buildSettlementPdf(
          supplier!,
          settlement.lines,
          settlement,
          businessProfile!,
          workOrderNumber,
          vehicleLabel,
        ),
      ),
    );
  }

  Future<void> recordPayment() async {
    if (busy(SettlementDetailBusy.recordPayment)) return;
    final response = await _bottomSheets
        .showCustomSheet<Payment, PaymentFormData>(
          variant: BottomSheetType.paymentForm,
          data: PaymentFormData(
            direction: PaymentDirection.outgoing,
            partyId: settlement.supplierId,
            settlementId: settlement.id,
          ),
          isScrollControlled: true,
        );
    final payment = response?.data;
    if (payment == null) return;
    switch (await runBusyFuture(
      _moneyRepository.recordPayment(payment),
      busyObject: SettlementDetailBusy.recordPayment,
    )) {
      case Success():
        await init();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }
}
