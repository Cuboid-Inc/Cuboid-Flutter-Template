import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/core/models/report_models.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/money/ui/money_viewmodel.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/shell/shell_service.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class FakePeriod extends Fake implements Period {}

class FakePayment extends Fake implements Payment {}

class FakeExpense extends Fake implements Expense {}

PaginatedResult<T> page<T>(List<T> items) => PaginatedResult(
  items: items,
  pageNumber: 1,
  pageSize: 50,
  totalRecords: items.length,
);

Invoice invoice() => Invoice(
  id: 'i',
  number: 'INV-1',
  buyerId: 'p',
  buyerName: 'Customer',
  issueDate: DateTime(2026, 7),
);
SupplierSettlement settlement() => SupplierSettlement(
  id: 's',
  number: 'SET-1',
  supplierId: 'p',
  periodStart: DateTime(2026, 7),
  periodEnd: DateTime(2026, 7, 31),
);
Payment payment() => Payment(
  id: 'pmt',
  direction: PaymentDirection.incoming,
  partyId: 'p',
  date: DateTime(2026, 7),
  amount: 10,
  method: PaymentMethod.cash,
);
Expense expense() => Expense(
  id: 'e',
  date: DateTime(2026, 7),
  category: ExpenseCategory.fuel,
  payee: 'Payee',
  net: 5,
);

void main() {
  late MockMoneyRepository repository;
  late MockPartiesRepository partiesRepository;
  late ShellService shell;
  late MockBottomSheetService sheets;
  late MockNavigationService navigation;
  setUpAll(() {
    registerFallbackValue(FakePeriod());
    registerFallbackValue(FakePayment());
    registerFallbackValue(FakeExpense());
  });
  setUp(() {
    repository = MockMoneyRepository();
    partiesRepository = MockPartiesRepository();
    shell = ShellService();
    sheets = MockBottomSheetService();
    navigation = MockNavigationService();
    replaceTestRegistration<ShellService>(shell);
    replaceTestRegistration<BottomSheetService>(sheets);
    replaceTestRegistration<NavigationService>(navigation);
    when(
      () => navigation.navigateTo(any(), arguments: any(named: 'arguments')),
    ).thenAnswer((_) async => null);
  });
  tearDown(locator.reset);

  void stubLoad() {
    when(
      () => repository.fetchInvoicesPage(
        pageNumber: 1,
        pageSize: 50,
        search: any(named: 'search'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => Success(page([invoice()])));
    when(
      () => repository.fetchSettlementsPage(
        pageNumber: 1,
        pageSize: 50,
        search: any(named: 'search'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => Success(page([settlement()])));
    when(
      () => repository.fetchPaymentsPage(
        pageNumber: 1,
        pageSize: 50,
        search: any(named: 'search'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => Success(page([payment()])));
    when(
      () => repository.fetchExpensesPage(
        pageNumber: 1,
        pageSize: 50,
        search: any(named: 'search'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => Success(page([expense()])));
    when(() => repository.fetchBalances()).thenAnswer(
      (_) async => const Success(
        MoneyBalances(
          invoices: {'i': 10},
          settlements: {'s': 20},
          parties: {'p': 30},
        ),
      ),
    );
    when(() => partiesRepository.fetchAll()).thenAnswer(
      (_) async => const Success([
        Party(id: 'p', name: 'Party', type: PartyType.customer),
      ]),
    );
    when(() => repository.statementRows(any())).thenAnswer(
      (_) async => Success([
        StatementRow(
          partyId: 'p',
          date: DateTime(2026, 7),
          workOrderId: 'w',
          description: 'Trip',
          amount: 3,
        ),
      ]),
    );
  }

  test('loads money data and exposes segments, balances, and groups', () async {
    stubLoad();
    final model = MoneyViewModel(repository, partiesRepository);
    await model.init();
    expect(model.invoices, hasLength(1));
    expect(model.settlements, hasLength(1));
    expect(model.payments, hasLength(1));
    expect(model.expenses, hasLength(1));
    expect(model.invoiceBalance(invoice()), 10);
    expect(model.settlementBalance(settlement()), 20);
    expect(model.partyBalance('p'), 30);
    expect(model.partyLabel('p'), 'Party');
    expect(model.partyLabel('unknown'), 'Expense payment');
    expect(model.statementGroups, hasLength(1));
    for (final segment in MoneySegment.values) {
      model.setSegment(segment);
      if (segment == MoneySegment.statements ||
          segment == MoneySegment.balances) {
        expect(model.countFor(segment), greaterThanOrEqualTo(0));
      } else {
        expect(model.pagination, isNotNull);
        expect(model.countFor(segment), 1);
      }
    }
  });

  test('reports init failure and opens money routes', () async {
    when(
      () => repository.fetchInvoicesPage(
        pageNumber: 1,
        pageSize: 50,
        search: any(named: 'search'),
        period: any(named: 'period'),
      ),
    ).thenAnswer(
      (_) async => const Failure(ValidationFailure('invoices failed')),
    );
    when(
      () => repository.fetchSettlementsPage(
        pageNumber: 1,
        pageSize: 50,
        search: any(named: 'search'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => Success(page<SupplierSettlement>([])));
    when(
      () => repository.fetchPaymentsPage(
        pageNumber: 1,
        pageSize: 50,
        search: any(named: 'search'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => Success(page<Payment>([])));
    when(
      () => repository.fetchExpensesPage(
        pageNumber: 1,
        pageSize: 50,
        search: any(named: 'search'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => Success(page<Expense>([])));
    when(() => repository.fetchBalances()).thenAnswer(
      (_) async => const Failure(ValidationFailure('balances failed')),
    );
    when(() => partiesRepository.fetchAll()).thenAnswer(
      (_) async => const Failure(ValidationFailure('parties failed')),
    );
    when(
      () => repository.statementRows(any()),
    ).thenAnswer((_) async => const Failure(ValidationFailure('rows failed')));
    final model = MoneyViewModel(repository, partiesRepository);
    await model.init();
    expect(model.errorMessage, 'rows failed');
    model.openPrepare();
    model.openInvoice(invoice());
    model.openSettlement(settlement());
    model.openStatement('p', Period.month(2026, 7));
    model.openPayment(payment());
    model.openExpense(expense());
    model.openBalance(
      const Party(id: 'p', name: 'Party', type: PartyType.customer),
    );
    verify(
      () => navigation.navigateTo(any(), arguments: any(named: 'arguments')),
    ).called(7);
  });

  test('clears cheques, records payments, and adds expenses', () async {
    stubLoad();
    final model = MoneyViewModel(repository, partiesRepository);
    when(
      () => repository.transitionChequeState('pmt', ChequeState.cleared),
    ).thenAnswer((_) async => const Success(null));
    await model.clearCheque(payment());
    when(
      () => sheets.showCustomSheet<Payment, PaymentFormData>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => SheetResponse(data: payment()));
    when(
      () => repository.recordPayment(any()),
    ).thenAnswer((_) async => const Success(null));
    await model.recordPayment(PaymentDirection.incoming);
    when(
      () => sheets.showCustomSheet<Expense, dynamic>(
        variant: any(named: 'variant'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => SheetResponse(data: expense()));
    when(
      () => repository.addExpense(any()),
    ).thenAnswer((_) async => Success(expense()));
    await model.newExpense();
    verify(
      () => repository.transitionChequeState('pmt', ChequeState.cleared),
    ).called(1);
    verify(() => repository.recordPayment(any())).called(1);
    verify(() => repository.addExpense(any())).called(1);
  });
}
