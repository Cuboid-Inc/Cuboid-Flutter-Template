import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockSheetRequest extends Mock implements SheetRequest {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockPartiesRepository partiesRepository;
  late MockMoneyRepository moneyRepository;
  late MockSheetRequest sheetRequest;

  setUp(() {
    partiesRepository = MockPartiesRepository();
    moneyRepository = MockMoneyRepository();
    sheetRequest = MockSheetRequest();

    if (locator.isRegistered<PartiesRepository>()) {
      locator.unregister<PartiesRepository>();
    }
    if (locator.isRegistered<MoneyRepository>()) {
      locator.unregister<MoneyRepository>();
    }

    locator.registerSingleton<PartiesRepository>(partiesRepository);
    locator.registerSingleton<MoneyRepository>(moneyRepository);

    when(
      () => sheetRequest.data,
    ).thenReturn(const PaymentFormData(direction: PaymentDirection.incoming));
  });

  tearDown(() {
    locator.reset();
  });

  test('fetchPartiesPage forwards server-side search and direction', () async {
    const party = Party(
      id: '1',
      name: 'Gulf Star Contracting',
      type: PartyType.customer,
    );
    const page = PaginatedResult<Party>(
      items: [party],
      pageNumber: 1,
      pageSize: 50,
      totalRecords: 1,
    );
    when(
      () => partiesRepository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        type: PartyType.customer,
        search: 'Gulf',
      ),
    ).thenAnswer((_) async => const Success(page));
    final model = PaymentFormSheetModel(
      completer: (_) {},
      request: sheetRequest,
    );

    final result = await model.fetchPartiesPage(pageNumber: 1, search: 'Gulf');

    expect(result.valueOrNull, page);
    verify(
      () => partiesRepository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        type: PartyType.customer,
        search: 'Gulf',
      ),
    ).called(1);
    model.dispose();
  });

  test('eligibleInvoices returns unpaid invoices for selected party', () async {
    const party = Party(id: 'c1', name: 'Gulf Star', type: PartyType.customer);
    final invoice1 = Invoice(
      id: 'inv1',
      number: 'INV-1',
      buyerId: 'c1',
      buyerName: 'Gulf Star',
      issueDate: DateTime.now(),
      status: InvoiceStatus.issued,
      lines: const [
        InvoiceLine(name: 'Trip', unitPrice: 5000.00),
      ], // Gross: 5,250.00
    );

    when(
      () => moneyRepository.fetchInvoices(),
    ).thenAnswer((_) async => Success([invoice1]));
    when(
      () => moneyRepository.fetchSettlements(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => moneyRepository.fetchExpenses(),
    ).thenAnswer((_) async => const Success([]));
    when(() => moneyRepository.fetchBalances()).thenAnswer(
      (_) async => const Success(
        MoneyBalances(invoices: {'inv1': 525000}, settlements: {}, parties: {}),
      ),
    );

    final model = PaymentFormSheetModel(
      completer: (_) {},
      request: sheetRequest,
    );

    await model.init();

    // No party selected initially
    expect(model.eligibleInvoices, isEmpty);

    model.selectParty(party);
    expect(model.eligibleInvoices, hasLength(1));
    expect(model.eligibleInvoices.first.number, 'INV-1');
  });

  test(
    'submit rejects an amount above the remaining invoice balance',
    () async {
      const party = Party(
        id: 'c1',
        name: 'Gulf Star',
        type: PartyType.customer,
      );
      final invoice1 = Invoice(
        id: 'inv1',
        number: 'INV-1',
        buyerId: 'c1',
        buyerName: 'Gulf Star',
        issueDate: DateTime.now(),
        status: InvoiceStatus.issued,
        lines: const [
          InvoiceLine(name: 'Trip', unitPrice: 5000.00),
        ], // Gross: 5,250.00
      );

      when(
        () => moneyRepository.fetchInvoices(),
      ).thenAnswer((_) async => Success([invoice1]));
      when(
        () => moneyRepository.fetchSettlements(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => moneyRepository.fetchExpenses(),
      ).thenAnswer((_) async => const Success([]));
      when(() => moneyRepository.fetchBalances()).thenAnswer(
        (_) async => const Success(
          MoneyBalances(
            invoices: {'inv1': 1000.00}, // Outstanding balance: 1,000.00 AED
            settlements: {},
            parties: {},
          ),
        ),
      );

      Payment? savedPayment;
      final model = PaymentFormSheetModel(
        completer: (response) {
          savedPayment = response.data as Payment;
        },
        request: sheetRequest,
      );

      await model.init();
      model.selectParty(party);
      model.selectInvoice(invoice1);

      // Enter payment amount larger than outstanding invoice balance.
      model.amountController.text = '1,500.00';
      model.submit();

      expect(savedPayment, isNull);
    },
  );

  test('submit requires a party and a positive valid amount', () {
    Payment? saved;
    final model = PaymentFormSheetModel(
      completer: (response) => saved = response.data as Payment?,
      request: sheetRequest,
    );

    model.submit();
    expect(saved, isNull);

    model.partyId = 'party';
    model.amountController.text = 'invalid';
    model.submit();
    expect(saved, isNull);

    model.amountController.text = '0';
    model.submit();
    expect(saved, isNull);
    model.dispose();
  });

  test('submit rejects outgoing amounts above linked balances', () {
    when(
      () => sheetRequest.data,
    ).thenReturn(const PaymentFormData(direction: PaymentDirection.outgoing));
    final settlement = SupplierSettlement(
      id: 'settlement',
      number: 'SET-1',
      supplierId: 'supplier',
      periodStart: DateTime(2026, 7),
      periodEnd: DateTime(2026, 7, 31),
      lines: [
        SettlementLine(
          workOrderId: 'work',
          date: DateTime(2026, 7),
          amount: 100,
        ),
      ],
    );
    final expense = Expense(
      id: 'expense',
      date: DateTime(2026, 7),
      category: ExpenseCategory.fuel,
      payee: 'Supplier',
      net: 100,
    );
    Payment? saved;
    final model =
        PaymentFormSheetModel(
            completer: (response) => saved = response.data as Payment?,
            request: sheetRequest,
          )
          ..partyId = 'supplier'
          ..allSettlements = [settlement]
          ..allExpenses = [expense]
          ..settlementBalances = const {'settlement': 100}
          ..linkedSettlementId = 'settlement'
          ..amountController.text = '150';

    model.submit();
    expect(saved, isNull);

    model.linkedSettlementId = null;
    model.linkedExpenseId = 'expense';
    model.submit();
    expect(saved, isNull);
    model.dispose();
  });

  test('init loads all collections and exposes the last failure', () async {
    when(
      () => moneyRepository.fetchInvoices(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => moneyRepository.fetchSettlements(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => moneyRepository.fetchExpenses(),
    ).thenAnswer((_) async => const Success([]));
    when(() => moneyRepository.fetchBalances()).thenAnswer(
      (_) async => const Success(
        MoneyBalances(invoices: {}, settlements: {}, parties: {}),
      ),
    );
    final model = PaymentFormSheetModel(
      completer: (_) {},
      request: sheetRequest,
    );
    await model.init();
    expect(model.errorMessage, isNull);

    when(() => moneyRepository.fetchInvoices()).thenAnswer(
      (_) async => const Failure(ValidationFailure('invoices failed')),
    );
    when(() => moneyRepository.fetchSettlements()).thenAnswer(
      (_) async => const Failure(ValidationFailure('settlements failed')),
    );
    when(() => moneyRepository.fetchExpenses()).thenAnswer(
      (_) async => const Failure(ValidationFailure('expenses failed')),
    );
    when(() => moneyRepository.fetchBalances()).thenAnswer(
      (_) async => const Failure(ValidationFailure('balances failed')),
    );
    await model.init();
    expect(model.errorMessage, 'balances failed');
    model.dispose();
  });

  test('init hydrates a preselected party', () async {
    const party = Party(id: 'p1', name: 'Party', type: PartyType.customer);
    when(() => sheetRequest.data).thenReturn(
      const PaymentFormData(
        direction: PaymentDirection.incoming,
        partyId: 'p1',
      ),
    );
    when(
      () => partiesRepository.fetchById('p1'),
    ).thenAnswer((_) async => const Success(party));
    when(
      () => moneyRepository.fetchInvoices(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => moneyRepository.fetchSettlements(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => moneyRepository.fetchExpenses(),
    ).thenAnswer((_) async => const Success([]));
    when(() => moneyRepository.fetchBalances()).thenAnswer(
      (_) async => const Success(
        MoneyBalances(invoices: {}, settlements: {}, parties: {}),
      ),
    );

    final model = PaymentFormSheetModel(
      completer: (_) {},
      request: sheetRequest,
    );
    await model.init();

    expect(model.selectedParty, party);
    verify(() => partiesRepository.fetchById('p1')).called(1);
    model.dispose();
  });

  test('eligible invoices, settlements, and expenses apply filters', () {
    const customer = Party(
      id: 'c1',
      name: 'Customer',
      type: PartyType.customer,
    );
    final invoice = Invoice(
      id: 'i1',
      number: 'INV-100',
      buyerId: 'c1',
      buyerName: 'Customer',
      issueDate: DateTime(2026),
      status: InvoiceStatus.issued,
      lines: const [InvoiceLine(name: 'Trip', unitPrice: 100)],
    );
    final voided = Invoice(
      id: 'i2',
      number: 'INV-VOID',
      buyerId: 'c1',
      buyerName: 'Customer',
      issueDate: DateTime(2026),
      status: InvoiceStatus.voided,
    );
    final zero = Invoice(
      id: 'i3',
      number: 'INV-ZERO',
      buyerId: 'c1',
      buyerName: 'Customer',
      issueDate: DateTime(2026),
      status: InvoiceStatus.issued,
    );
    final model =
        PaymentFormSheetModel(completer: (_) {}, request: sheetRequest)
          ..allInvoices = [invoice, voided, zero]
          ..invoiceBalances = const {'i1': 100, 'i2': 100, 'i3': 0};

    expect(model.eligibleInvoices, isEmpty);
    model.selectParty(customer);
    expect(model.eligibleInvoices, [invoice]);
    model.setDocSearchQuery('100');
    expect(model.eligibleInvoices, [invoice]);
    model.setDocSearchQuery('missing');
    expect(model.eligibleInvoices, isEmpty);

    final settlement = SupplierSettlement(
      id: 's1',
      number: 'SET-100',
      supplierId: 'c1',
      periodStart: DateTime(2026),
      periodEnd: DateTime(2026, 1, 31),
      lines: [
        SettlementLine(workOrderId: 'w1', date: DateTime(2026), amount: 80),
      ],
      status: SettlementStatus.issued,
    );
    final expense = Expense(
      id: 'e1',
      date: DateTime(2026),
      category: ExpenseCategory.fuel,
      payee: 'Customer',
      net: 50,
      description: 'Fuel',
      reference: 'REF-1',
    );
    model.allSettlements = [settlement];
    model.allExpenses = [expense];
    model.docSearchQuery = '';
    expect(model.eligibleSettlements, [settlement]);
    expect(model.eligibleExpenses, [expense]);
    model.setDocSearchQuery('REF-1');
    expect(model.eligibleExpenses, [expense]);
    model.setDocSearchQuery('SET-100');
    expect(model.eligibleSettlements, [settlement]);
    model.partyId = 'missing';
    expect(model.eligibleExpenses, isEmpty);
    model.clearParty();
    expect(model.eligibleSettlements, isEmpty);
    expect(model.eligibleExpenses, isEmpty);
    model.dispose();
  });

  test('selection, limits, labels, and clear methods update state', () {
    final model = PaymentFormSheetModel(
      completer: (_) {},
      request: sheetRequest,
    );
    final invoice = Invoice(
      id: 'i1',
      number: 'INV-1',
      buyerId: 'p1',
      buyerName: 'Party',
      issueDate: DateTime(2026),
    );
    final settlement = SupplierSettlement(
      id: 's1',
      number: 'SET-1',
      supplierId: 'p1',
      periodStart: DateTime(2026),
      periodEnd: DateTime(2026, 1, 31),
      lines: [
        SettlementLine(workOrderId: 'w1', date: DateTime(2026), amount: 80),
      ],
    );
    final expense = Expense(
      id: 'e1',
      date: DateTime(2026),
      category: ExpenseCategory.fuel,
      payee: 'Party',
      net: 50,
    );
    model.allInvoices = [invoice];
    model.allSettlements = [settlement];
    model.allExpenses = [expense];
    model.invoiceBalances = const {'i1': 40};
    model.settlementBalances = const {'s1': 30};
    model.selectParty(
      const Party(id: 'p1', name: 'Party', type: PartyType.customer),
    );
    model.selectInvoice(invoice);
    expect(model.paymentLimit, 40);
    expect(
      model.paymentLimitMessage,
      'Payment amount exceeds the invoice balance',
    );
    model.selectSettlement(settlement);
    expect(model.paymentLimit, 30);
    expect(
      model.paymentLimitMessage,
      'Payment amount exceeds the settlement balance',
    );
    model.selectExpense(expense);
    expect(model.paymentLimit, 50);
    expect(
      model.paymentLimitMessage,
      'Payment amount exceeds the expense balance',
    );
    model.clearLinkedDoc();
    expect(model.paymentLimit, isNull);
    expect(model.paymentLimitMessage, isNull);

    model.selectMethod([PaymentMethod.cash]);
    expect(model.method, PaymentMethod.cash);
    expect(model.methodLabel(PaymentMethod.bankTransfer), 'Bank transfer');
    expect(model.methodLabel(PaymentMethod.cash), 'Cash');
    expect(model.methodLabel(PaymentMethod.cheque), 'Cheque');
    model.setDocSearchQuery('Doc');
    expect(model.docSearchQuery, 'Doc');
    model.dispose();
  });

  test('submit creates incoming invoice and outgoing allocations', () {
    Payment? saved;
    final model = PaymentFormSheetModel(
      completer: (response) => saved = response.data as Payment?,
      request: sheetRequest,
    )..partyId = 'c1';
    final invoice = Invoice(
      id: 'i1',
      number: 'INV-1',
      buyerId: 'c1',
      buyerName: 'Customer',
      issueDate: DateTime(2026),
    );
    model.allInvoices = [invoice];
    model.invoiceBalances = const {'i1': 100};
    model.selectInvoice(invoice);
    model.amountController.text = '50';
    model.method = PaymentMethod.cheque;
    model.referenceController.text = ' CHQ-1 ';
    model.submit();

    expect(saved, isNotNull);
    expect(saved!.allocations.single.invoiceId, 'i1');
    expect(saved!.allocations.single.amount, 50);
    expect(saved!.bankOrChequeReference, 'CHQ-1');
    expect(saved!.chequeState, ChequeState.received);

    when(
      () => sheetRequest.data,
    ).thenReturn(const PaymentFormData(direction: PaymentDirection.outgoing));
    saved = null;
    final outgoing = PaymentFormSheetModel(
      completer: (response) => saved = response.data as Payment?,
      request: sheetRequest,
    )..partyId = 's1';
    final settlement = SupplierSettlement(
      id: 's1',
      number: 'SET-1',
      supplierId: 's1',
      periodStart: DateTime(2026),
      periodEnd: DateTime(2026, 1, 31),
      lines: [
        SettlementLine(workOrderId: 'w1', date: DateTime(2026), amount: 80),
      ],
    );
    final expense = Expense(
      id: 'e1',
      date: DateTime(2026),
      category: ExpenseCategory.fuel,
      payee: 'Supplier',
      net: 50,
    );
    outgoing.allSettlements = [settlement];
    outgoing.allExpenses = [expense];
    outgoing.selectSettlement(settlement);
    outgoing.amountController.text = '20';
    outgoing.submit();
    expect(saved!.allocations.single.settlementId, 's1');
    expect(saved!.chequeState, ChequeState.cleared);

    saved = null;
    outgoing.selectExpense(expense);
    outgoing.amountController.text = '20';
    outgoing.submit();
    expect(saved!.allocations.single.expenseId, 'e1');

    saved = null;
    outgoing.clearLinkedDoc();
    expect(outgoing.hasLinkedDoc, isFalse);
    expect(outgoing.linkedDocError, isNotNull);
    outgoing.amountController.text = '10';
    outgoing.submit();
    expect(saved, isNull, reason: 'submit must reject a payment with no linked settlement/expense');
    model.dispose();
    outgoing.dispose();
  });
}
