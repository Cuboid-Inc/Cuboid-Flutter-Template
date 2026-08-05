import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/features/money/data/money_rows.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/shell/shell_service.dart';
import 'package:fleetgo/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:fleetgo/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:fleetgo/ui/widgets/paginated_list/pagination_controller.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum MoneyBusy { clearCheque, recordPayment, addExpense, refreshSegment }

class MoneyViewModel extends ReactiveViewModel {
  MoneyViewModel([
    MoneyRepository? repository,
    PartiesRepository? partiesRepository,
  ]) : _repository = repository ?? locator<MoneyRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>();
  final MoneyRepository _repository;
  final PartiesRepository _partiesRepository;
  final _navigation = locator<NavigationService>();
  final _shellService = locator<ShellService>();
  final _bottomSheets = locator<BottomSheetService>();

  // Variables

  List<Party> parties = const [];
  Map<String, num> invoiceBalances = const {};
  Map<String, num> settlementBalances = const {};
  Map<String, num> partyBalances = const {};
  List<StatementRow> statementRows = const [];
  String? errorMessage;

  String _query = '';
  String get query => _query;

  late final invoicePagination = _paginated<Invoice>(
    _repository.fetchInvoicesPage,
  );
  late final settlementPagination = _paginated<SupplierSettlement>(
    _repository.fetchSettlementsPage,
  );
  late final paymentPagination = _paginated<Payment>(
    _repository.fetchPaymentsPage,
  );
  late final expensePagination = _paginated<Expense>(
    _repository.fetchExpensesPage,
  );

  // Getters
  @override
  List<ListenableServiceMixin> get listenableServices => [_shellService];
  List<Invoice> get invoices => invoicePagination.items;
  List<SupplierSettlement> get settlements => settlementPagination.items;
  List<Payment> get payments => paymentPagination.items;
  List<Expense> get expenses => expensePagination.items;
  MoneySegment get segment => _shellService.moneySegment;
  Period _period = Period.year(DateTime.now().year);
  // True once the user picks anything other than the current calendar year.
  bool get hasCustomPeriod => _period != Period.year(DateTime.now().year);
  String get periodLabel => Formatters.monthYear(_period.start);
  PaginationController get pagination => switch (segment) {
    MoneySegment.invoices => invoicePagination,
    MoneySegment.settlements => settlementPagination,
    MoneySegment.payments => paymentPagination,
    MoneySegment.expenses => expensePagination,
    // Balances/statements are computed client-side, not server-paginated.
    _ => throw StateError('The selected money segment is not paginated.'),
  };

  // Lifecycle

  Future<void> init() async {
    setBusy(true);
    errorMessage = null;
    await Future.wait([
      invoicePagination.loadInitial(),
      settlementPagination.loadInitial(),
      paymentPagination.loadInitial(),
      expensePagination.loadInitial(),
    ]);
    // First failure among the four parallel loads wins.
    errorMessage =
        invoicePagination.error ??
        settlementPagination.error ??
        paymentPagination.error ??
        expensePagination.error;

    // _loadBalances() also fetches parties, so nothing further is needed here.
    await _loadBalances();
    await _loadStatements();
    setBusy(false);
  }

  Future<void> selectPeriod() async {
    final response = await _bottomSheets
        .showCustomSheet<Period, PeriodSheetData>(
          variant: BottomSheetType.period,
          data: (selected: _period, resetTo: Period.year(DateTime.now().year)),
          isScrollControlled: true,
        );
    final period = response?.data;
    if (period == null) return;
    _period = period;
    await Future.wait([
      pagination.refresh(),
      _loadStatements(),
      _loadBalances(),
    ]);
    notifyListeners();
  }

  void setSegment(MoneySegment value) {
    _shellService.setMoneySegment(value);
    if (_query.isNotEmpty) _reloadForQuery();
  }

  void setQuery(String value) {
    _query = value;
    _reloadForQuery();
  }

  void _reloadForQuery() {
    switch (segment) {
      // Balances/statements just re-filter the data already in memory.
      case MoneySegment.balances:
      case MoneySegment.statements:
        notifyListeners();
      // Other segments re-fetch page 1 from the server with the new search term.
      case MoneySegment.invoices:
      case MoneySegment.settlements:
      case MoneySegment.payments:
      case MoneySegment.expenses:
        pagination.refresh();
    }
  }

  // Case-insensitive substring match; empty query matches everything.
  bool matchesQuery(String text) =>
      _query.isEmpty || text.toLowerCase().contains(_query.toLowerCase());

  Future<void> refreshSegment() async {
    if (busy(MoneyBusy.refreshSegment)) return;
    await runBusyFuture(
      _refreshSegment(),
      busyObject: MoneyBusy.refreshSegment,
    );
  }

  Future<void> _refreshSegment() async {
    _repository.invalidateCache();
    errorMessage = null;
    switch (segment) {
      case MoneySegment.invoices:
      case MoneySegment.settlements:
      case MoneySegment.payments:
      case MoneySegment.expenses:
        await pagination.refresh();
        errorMessage = pagination.error;
      case MoneySegment.balances:
        await _loadBalances();
      case MoneySegment.statements:
        await _loadStatements();
    }
    notifyListeners();
  }

  Future<void> _loadBalances() async {
    switch (await _repository.fetchBalances()) {
      case Success(:final value):
        invoiceBalances = value.invoices;
        settlementBalances = value.settlements;
        partyBalances = value.parties;
      case Failure(:final failure):
        errorMessage = failure.message;
    }
    switch (await _partiesRepository.fetchAll()) {
      case Success(:final value):
        parties = value;
      case Failure(:final failure):
        errorMessage = failure.message;
    }
  }

  Future<void> _loadStatements() async {
    switch (await _repository.statementRows(_period)) {
      case Success(:final value):
        statementRows = value;
      case Failure(:final failure):
        errorMessage = failure.message;
    }
  }

  int countFor(MoneySegment value) => switch (value) {
    MoneySegment.invoices => invoicePagination.totalRecords,
    MoneySegment.statements => statementGroups.length,
    MoneySegment.settlements => settlementPagination.totalRecords,
    MoneySegment.payments => paymentPagination.totalRecords,
    MoneySegment.expenses => expensePagination.totalRecords,
    // Only count parties with a non-zero outstanding balance.
    MoneySegment.balances =>
      parties
          .where((p) => partyBalance(p.id) != 0 && matchesQuery(p.name))
          .length,
  };
  num invoiceBalance(Invoice invoice) => invoiceBalances[invoice.id] ?? 0;
  num settlementBalance(SupplierSettlement settlement) =>
      settlementBalances[settlement.id] ?? 0;
  num partyBalance(String id) => partyBalances[id] ?? 0;
  String partyLabel(String id) =>
      parties.where((party) => party.id == id).firstOrNull?.name ??
      'Expense payment';
  Map<String, List<StatementRow>> get statementGroups {
    final groups = <String, List<StatementRow>>{};
    for (final row in statementRows) {
      if (!matchesQuery(partyLabel(row.partyId))) continue;
      // Group by party + calendar month so each card is one statement.
      final key = '${row.partyId}-${Formatters.monthYear(row.date)}';
      (groups[key] ??= []).add(row);
    }
    return groups;
  }

  // Navigation

  void openPrepare() => _navigation.navigateTo(Routes.prepareMonthView);
  void openInvoice(Invoice invoice) => _navigation.navigateTo(
    Routes.invoiceDetailView,
    arguments: InvoiceDetailViewArguments(invoice: invoice),
  );
  void openSettlement(SupplierSettlement settlement) => _navigation.navigateTo(
    Routes.settlementDetailView,
    arguments: SettlementDetailViewArguments(settlement: settlement),
  );
  void openStatement(String partyId, Period period) => _navigation.navigateTo(
    Routes.statementView,
    arguments: StatementViewArguments(partyId: partyId, period: period),
  );
  void openPayment(Payment payment) => _navigation.navigateTo(
    Routes.paymentDetailView,
    arguments: PaymentDetailViewArguments(payment: payment),
  );
  void openExpense(Expense expense) => _navigation.navigateTo(
    Routes.expenseDetailView,
    arguments: ExpenseDetailViewArguments(expense: expense),
  );
  void openBalance(Party party) => _navigation.navigateTo(
    Routes.balanceDetailView,
    arguments: BalanceDetailViewArguments(party: party),
  );
  // Actions

  Future<void> clearCheque(Payment payment) async {
    if (busy(MoneyBusy.clearCheque)) return;
    switch (await runBusyFuture(
      _repository.transitionChequeState(payment.id, ChequeState.cleared),
      busyObject: MoneyBusy.clearCheque,
    )) {
      case Success():
        await init();
      case Failure(:final failure):
        errorMessage = failure.message;
        notifyListeners();
    }
  }

  Future<void> recordPayment(PaymentDirection direction) async {
    if (busy(MoneyBusy.recordPayment)) return;
    final response = await _bottomSheets
        .showCustomSheet<Payment, PaymentFormData>(
          variant: BottomSheetType.paymentForm,
          data: PaymentFormData(direction: direction),
          isScrollControlled: true,
        );
    final payment = response?.data;
    if (payment == null) return;
    switch (await runBusyFuture(
      _repository.recordPayment(payment),
      busyObject: MoneyBusy.recordPayment,
    )) {
      case Success():
        await init();
      case Failure(:final failure):
        errorMessage = failure.message;
        notifyListeners();
    }
  }

  Future<void> newExpense() async {
    if (busy(MoneyBusy.addExpense)) return;
    final response = await _bottomSheets.showCustomSheet<Expense, dynamic>(
      variant: BottomSheetType.addExpense,
      isScrollControlled: true,
    );
    final expense = response?.data;
    if (expense == null) return;
    switch (await runBusyFuture(
      _repository.addExpense(expense),
      busyObject: MoneyBusy.addExpense,
    )) {
      case Success():
        await init();
      case Failure(:final failure):
        errorMessage = failure.message;
        notifyListeners();
    }
  }

  // Shared factory: every fetchXPage repo method has this same signature, so
  // one generic wrapper replaces four copy-pasted PaginationController blocks.
  PaginationController<T> _paginated<T>(
    Future<Result<PaginatedResult<T>>> Function({
      required int pageNumber,
      int pageSize,
      String? search,
      Period? period,
    })
    fetch,
  ) => PaginationController<T>(
    callback: (page, size) => fetch(
      pageNumber: page,
      pageSize: size,
      search: _query,
      period: _period,
    ),
    onStateChanged: notifyListeners,
  );
}
