import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum PaymentDetailBusy { clearCheque }

class PaymentDetailViewModel extends BaseViewModel {
  PaymentDetailViewModel(
    this.payment, {
    MoneyRepository? repository,
    PartiesRepository? partiesRepository,
  }) : _moneyRepository = repository ?? locator<MoneyRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>();

  final Payment payment;
  final MoneyRepository _moneyRepository;
  final PartiesRepository _partiesRepository;
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();

  Party? party;
  List<Invoice> invoices = const [];
  List<SupplierSettlement> settlements = const [];

  Future<void> init() async {
    setBusy(true);
    if (payment.partyId != null) {
      switch (await _partiesRepository.fetchAll()) {
        case Success(:final value):
          party = value.where((p) => p.id == payment.partyId).firstOrNull;
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }
    switch (await _moneyRepository.fetchInvoices()) {
      case Success(:final value):
        invoices = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _moneyRepository.fetchSettlements()) {
      case Success(:final value):
        settlements = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  Invoice? getInvoice(String id) =>
      invoices.where((i) => i.id == id).firstOrNull;
  SupplierSettlement? getSettlement(String id) =>
      settlements.where((s) => s.id == id).firstOrNull;

  void viewInvoice(Invoice invoice) {
    _navigation.navigateTo(
      Routes.invoiceDetailView,
      arguments: InvoiceDetailViewArguments(invoice: invoice),
    );
  }

  void viewSettlement(SupplierSettlement settlement) {
    _navigation.navigateTo(
      Routes.settlementDetailView,
      arguments: SettlementDetailViewArguments(settlement: settlement),
    );
  }

  Future<void> clearCheque() async {
    if (busy(PaymentDetailBusy.clearCheque)) return;
    switch (await runBusyFuture(
      _moneyRepository.transitionChequeState(payment.id, ChequeState.cleared),
      busyObject: PaymentDetailBusy.clearCheque,
    )) {
      case Success():
        payment.chequeState = ChequeState.cleared;
        _snackbar.showSuccess('Cheque marked cleared successfully');
        notifyListeners();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }
}
