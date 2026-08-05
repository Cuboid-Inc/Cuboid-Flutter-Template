import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class BalanceActivityItem {
  BalanceActivityItem({
    required this.date,
    required this.description,
    required this.amount,
    required this.runningBalance,
    this.invoice,
    this.settlement,
    this.payment,
  });

  final DateTime date;
  final String description;
  final num amount;
  final num runningBalance;
  final Invoice? invoice;
  final SupplierSettlement? settlement;
  final Payment? payment;
}

class BalanceDetailViewModel extends BaseViewModel {
  BalanceDetailViewModel(this.party, {MoneyRepository? repository})
    : _moneyRepository = repository ?? locator<MoneyRepository>();

  final Party party;
  final MoneyRepository _moneyRepository;
  final _navigation = locator<NavigationService>();

  List<BalanceActivityItem> activityItems = const [];
  num currentBalance = 0;
  String? errorMessage;

  Future<void> init() async {
    setBusy(true);

    List<Invoice> invoices = [];
    List<SupplierSettlement> settlements = [];
    List<Payment> payments = [];

    switch (await _moneyRepository.fetchInvoices()) {
      case Success(:final value):
        invoices = value.where((i) => i.buyerId == party.id).toList();
      case Failure(:final failure):
        errorMessage = failure.message;
    }
    switch (await _moneyRepository.fetchSettlements()) {
      case Success(:final value):
        settlements = value.where((s) => s.supplierId == party.id).toList();
      case Failure(:final failure):
        errorMessage = failure.message;
    }
    switch (await _moneyRepository.fetchPayments()) {
      case Success(:final value):
        payments = value.where((p) => p.partyId == party.id).toList();
      case Failure(:final failure):
        errorMessage = failure.message;
    }

    final events = <_TimelineEvent>[];
    for (final inv in invoices) {
      events.add(
        _TimelineEvent(
          date: inv.issueDate,
          amount: inv.gross,
          description: 'Invoice ${inv.number} issued',
          invoice: inv,
        ),
      );
    }
    for (final set in settlements) {
      events.add(
        _TimelineEvent(
          date: set.periodStart,
          amount: set.total,
          description: 'Settlement ${set.number} issued',
          settlement: set,
        ),
      );
    }
    for (final pay in payments) {
      final isIncoming = pay.direction == PaymentDirection.incoming;
      events.add(
        _TimelineEvent(
          date: pay.date,
          amount: isIncoming ? -pay.amount : -pay.amount,
          description: isIncoming
              ? 'Payment received via ${pay.method.name}'
              : 'Payment sent via ${pay.method.name}',
          payment: pay,
        ),
      );
    }

    events.sort((a, b) => a.date.compareTo(b.date));

    num running = 0;
    final items = <BalanceActivityItem>[];
    for (final ev in events) {
      running += ev.amount;
      items.add(
        BalanceActivityItem(
          date: ev.date,
          description: ev.description,
          amount: ev.amount,
          runningBalance: running,
          invoice: ev.invoice,
          settlement: ev.settlement,
          payment: ev.payment,
        ),
      );
    }

    currentBalance = running;
    activityItems = items.reversed.toList();

    setBusy(false);
  }

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

  void viewPayment(Payment payment) {
    _navigation.navigateTo(
      Routes.paymentDetailView,
      arguments: PaymentDetailViewArguments(payment: payment),
    );
  }
}

class _TimelineEvent {
  _TimelineEvent({
    required this.date,
    required this.amount,
    required this.description,
    this.invoice,
    this.settlement,
    this.payment,
  });
  final DateTime date;
  final num amount;
  final String description;
  final Invoice? invoice;
  final SupplierSettlement? settlement;
  final Payment? payment;
}
