import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class PaymentFormData {
  const PaymentFormData({
    required this.direction,
    this.partyId,
    this.invoiceId,
    this.settlementId,
    this.expenseId,
  });

  final PaymentDirection direction;
  final String? partyId;
  final String? invoiceId;
  final String? settlementId;
  final String? expenseId;
}

class PaymentFormSheetModel extends BaseViewModel {
  PaymentFormSheetModel({required this.completer, required this.request})
    : data = request.data as PaymentFormData,
      partyId = (request.data as PaymentFormData).partyId,
      linkedInvoiceId = (request.data as PaymentFormData).invoiceId,
      linkedSettlementId = (request.data as PaymentFormData).settlementId,
      linkedExpenseId = (request.data as PaymentFormData).expenseId;

  final Function(SheetResponse response) completer;
  final SheetRequest request;
  final PaymentFormData data;
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? partyId;
  String? linkedInvoiceId;
  String? linkedSettlementId;
  String? linkedExpenseId;

  PaymentMethod method = PaymentMethod.bankTransfer;
  Party? selectedParty;

  List<Invoice> allInvoices = const [];
  List<SupplierSettlement> allSettlements = const [];
  List<Expense> allExpenses = const [];
  Map<String, num> invoiceBalances = const {};
  Map<String, num> settlementBalances = const {};

  String docSearchQuery = '';
  String? loadErrorMessage;

  String? get errorMessage => loadErrorMessage;

  final _partiesRepository = locator<PartiesRepository>();
  final _moneyRepository = locator<MoneyRepository>();

  bool get incoming => data.direction == PaymentDirection.incoming;

  num? get paymentLimit {
    if (linkedInvoiceId != null) {
      final invoice = allInvoices
          .where((item) => item.id == linkedInvoiceId)
          .firstOrNull;
      return invoiceBalances[linkedInvoiceId] ?? invoice?.gross;
    }
    if (linkedSettlementId != null) {
      final settlement = allSettlements
          .where((item) => item.id == linkedSettlementId)
          .firstOrNull;
      return settlementBalances[linkedSettlementId] ?? settlement?.total;
    }
    if (linkedExpenseId != null) {
      return allExpenses
          .where((item) => item.id == linkedExpenseId)
          .firstOrNull
          ?.total;
    }
    return null;
  }

  String? get paymentLimitMessage {
    if (linkedInvoiceId != null) {
      return 'Payment amount exceeds the invoice balance';
    }
    if (linkedSettlementId != null) {
      return 'Payment amount exceeds the settlement balance';
    }
    if (linkedExpenseId != null) {
      return 'Payment amount exceeds the expense balance';
    }
    return null;
  }

  bool get hasLinkedDoc =>
      linkedInvoiceId != null ||
      linkedSettlementId != null ||
      linkedExpenseId != null;

  String? get linkedDocError => hasLinkedDoc
      ? null
      : incoming
      ? 'Select an invoice to link this payment'
      : 'Select a settlement or expense to link this payment';

  Future<void> init() async {
    setBusy(true);

    if (partyId != null) {
      switch (await _partiesRepository.fetchById(partyId!)) {
        case Success(:final value):
          selectedParty = value;
        case Failure(:final failure):
          loadErrorMessage = failure.message;
      }
    }

    switch (await _moneyRepository.fetchInvoices()) {
      case Success(:final value):
        allInvoices = value;
      case Failure(:final failure):
        loadErrorMessage = failure.message;
    }

    switch (await _moneyRepository.fetchSettlements()) {
      case Success(:final value):
        allSettlements = value;
      case Failure(:final failure):
        loadErrorMessage = failure.message;
    }

    switch (await _moneyRepository.fetchExpenses()) {
      case Success(:final value):
        allExpenses = value;
      case Failure(:final failure):
        loadErrorMessage = failure.message;
    }

    switch (await _moneyRepository.fetchBalances()) {
      case Success(:final value):
        invoiceBalances = value.invoices;
        settlementBalances = value.settlements;
      case Failure(:final failure):
        loadErrorMessage = failure.message;
    }

    setBusy(false);
  }

  Future<Result<PaginatedResult<Party>>> fetchPartiesPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) => _partiesRepository.fetchPage(
    pageNumber: pageNumber,
    pageSize: pageSize,
    type: incoming ? PartyType.customer : PartyType.supplier,
    search: search,
  );

  List<Invoice> get eligibleInvoices {
    if (partyId == null) return const [];
    final customerInvoices = allInvoices.where((invoice) {
      final balance = invoiceBalances[invoice.id] ?? invoice.gross;
      return invoice.buyerId == partyId &&
          invoice.status != InvoiceStatus.voided &&
          balance > 0;
    }).toList();

    if (docSearchQuery.trim().isEmpty) return customerInvoices;
    final query = docSearchQuery.toLowerCase();
    return customerInvoices
        .where((invoice) => invoice.number.toLowerCase().contains(query))
        .toList();
  }

  List<SupplierSettlement> get eligibleSettlements {
    if (partyId == null) return const [];
    final supplierSettlements = allSettlements.where((settlement) {
      final balance = settlementBalances[settlement.id] ?? settlement.total;
      return settlement.supplierId == partyId &&
          settlement.status != SettlementStatus.voided &&
          balance > 0;
    }).toList();

    if (docSearchQuery.trim().isEmpty) return supplierSettlements;
    final query = docSearchQuery.toLowerCase();
    return supplierSettlements
        .where((settlement) => settlement.number.toLowerCase().contains(query))
        .toList();
  }

  List<Expense> get eligibleExpenses {
    if (partyId == null) return const [];
    final party = selectedParty;
    if (party == null || party.id != partyId) return const [];
    final supplierExpenses = allExpenses.where((expense) {
      final payeeMatch =
          expense.payee.toLowerCase() == party.name.toLowerCase() ||
          expense.payee.toLowerCase() == party.name.toLowerCase();
      return payeeMatch && !expense.isPaid;
    }).toList();

    if (docSearchQuery.trim().isEmpty) return supplierExpenses;
    final query = docSearchQuery.toLowerCase();
    return supplierExpenses.where((expense) {
      return (expense.description ?? '').toLowerCase().contains(query) ||
          (expense.reference ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void selectParty(Party party) {
    partyId = party.id;
    selectedParty = party;
    linkedInvoiceId = null;
    linkedSettlementId = null;
    linkedExpenseId = null;
    notifyListeners();
  }

  void clearParty() {
    partyId = null;
    selectedParty = null;
    linkedInvoiceId = null;
    linkedSettlementId = null;
    linkedExpenseId = null;
    notifyListeners();
  }

  void selectInvoice(Invoice invoice) {
    linkedInvoiceId = invoice.id;
    linkedSettlementId = null;
    linkedExpenseId = null;
    docSearchQuery = '';
    notifyListeners();
  }

  void selectSettlement(SupplierSettlement settlement) {
    linkedSettlementId = settlement.id;
    linkedInvoiceId = null;
    linkedExpenseId = null;
    docSearchQuery = '';
    notifyListeners();
  }

  void selectExpense(Expense expense) {
    linkedExpenseId = expense.id;
    linkedInvoiceId = null;
    linkedSettlementId = null;
    docSearchQuery = '';
    notifyListeners();
  }

  void clearLinkedDoc() {
    linkedInvoiceId = null;
    linkedSettlementId = null;
    linkedExpenseId = null;
    docSearchQuery = '';
    notifyListeners();
  }

  void setDocSearchQuery(String val) {
    docSearchQuery = val;
    notifyListeners();
  }

  void selectMethod(List<PaymentMethod> values) {
    method = values.first;
    notifyListeners();
  }

  String methodLabel(PaymentMethod value) => switch (value) {
    PaymentMethod.bankTransfer => 'Bank transfer',
    PaymentMethod.cash => 'Cash',
    PaymentMethod.cheque => 'Cheque',
  };

  void submit() {
    final amount = Formatters.parseMoney(amountController.text);
    if (partyId == null || amount == null || amount <= 0 || !hasLinkedDoc) {
      return;
    }

    List<PaymentAllocation> allocations = const [];
    if (incoming) {
      if (linkedInvoiceId != null) {
        final balance = paymentLimit;
        if (balance == null || amount > balance) return;
        allocations = [
          PaymentAllocation(amount: amount, invoiceId: linkedInvoiceId),
        ];
      }
    } else {
      if (linkedSettlementId != null) {
        final balance = paymentLimit;
        if (balance == null || amount > balance) return;
        allocations = [
          PaymentAllocation(amount: amount, settlementId: linkedSettlementId),
        ];
      } else if (linkedExpenseId != null) {
        final balance = paymentLimit;
        if (balance == null || amount > balance) return;
        allocations = [
          PaymentAllocation(amount: amount, expenseId: linkedExpenseId),
        ];
      }
    }

    completer(
      SheetResponse<Payment>(
        confirmed: true,
        data: Payment(
          id: '',
          direction: data.direction,
          partyId: partyId,
          date: DateTime.now(),
          amount: amount,
          method: method,
          bankOrChequeReference: referenceController.text.trim().isEmpty
              ? null
              : referenceController.text.trim(),
          chequeState: method == PaymentMethod.cheque
              ? ChequeState.received
              : ChequeState.cleared,
          allocations: allocations,
        ),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    super.dispose();
  }
}
