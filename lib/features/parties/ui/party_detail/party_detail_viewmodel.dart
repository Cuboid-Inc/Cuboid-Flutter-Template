import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/work/data/work_repository.dart';
import 'package:fleetgo/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum PartyDetailBusy { editParty, recordPayment, archiveParty }

class PartyDetailViewModel extends BaseViewModel {
  PartyDetailViewModel(
    Party initialParty, {
    MoneyRepository? moneyRepository,
    PartiesRepository? partiesRepository,
    WorkRepository? workRepository,
  }) : party = initialParty,
       _moneyRepository = moneyRepository ?? locator<MoneyRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>(),
       _workRepository = workRepository ?? locator<WorkRepository>();

  Party party;
  final MoneyRepository _moneyRepository;
  final PartiesRepository _partiesRepository;
  final WorkRepository _workRepository;
  final _bottomSheets = locator<BottomSheetService>();
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();

  List<Invoice> invoices = const [];
  bool hasWork = false;
  num balance = 0;
  Map<String, num> invoiceBalances = const {};

  void viewInvoice(Invoice invoice) {
    _navigation.navigateTo(
      Routes.invoiceDetailView,
      arguments: InvoiceDetailViewArguments(invoice: invoice),
    );
  }

  Future<void> init() async {
    setBusy(true);
    switch (await _moneyRepository.fetchInvoices()) {
      case Success(:final value):
        invoices = value
            .where((invoice) => invoice.buyerId == party.id)
            .toList();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _workRepository.fetchAll()) {
      case Success(:final value):
        hasWork = value.any((order) => order.customerId == party.id);
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _moneyRepository.fetchBalances()) {
      case Success(:final value):
        balance = value.parties[party.id] ?? 0;
        invoiceBalances = value.invoices;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  num invoiceBalance(Invoice invoice) => invoiceBalances[invoice.id] ?? 0;

  bool get shouldShowRecordPayment {
    return party.type == PartyType.customer && (invoices.isNotEmpty || hasWork);
  }

  Future<void> editParty() async {
    if (busy(PartyDetailBusy.editParty)) return;
    final response = await _bottomSheets.showCustomSheet<Party, Party>(
      variant: BottomSheetType.partyForm,
      data: party,
      isScrollControlled: true,
    );
    final updatedParty = response?.data;
    if (updatedParty == null) return;
    switch (await runBusyFuture(
      _partiesRepository.create(updatedParty),
      busyObject: PartyDetailBusy.editParty,
    )) {
      case Success(:final value):
        party = value;
        await init();
        _snackbar.showSuccess('Party details updated successfully');
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }

  Future<void> recordPayment() async {
    if (busy(PartyDetailBusy.recordPayment)) return;
    final response = await _bottomSheets
        .showCustomSheet<Payment, PaymentFormData>(
          variant: BottomSheetType.paymentForm,
          data: PaymentFormData(
            direction: PaymentDirection.incoming,
            partyId: party.id,
          ),
          isScrollControlled: true,
        );
    final payment = response?.data;
    if (payment == null) return;
    switch (await runBusyFuture(
      _moneyRepository.recordPayment(payment),
      busyObject: PartyDetailBusy.recordPayment,
    )) {
      case Success():
        _snackbar.showSuccess('Payment recorded');
        await init();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }

  Future<void> archiveParty() async {
    if (busy(PartyDetailBusy.archiveParty)) return;
    switch (await runBusyFuture(
      _partiesRepository.archive(party.id),
      busyObject: PartyDetailBusy.archiveParty,
    )) {
      case Success():
        _snackbar.showSuccess('Party archived successfully');
        _navigation.back();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }
}
