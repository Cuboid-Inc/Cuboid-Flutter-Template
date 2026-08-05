import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('stores balance maps', () {
    const balances = MoneyBalances(
      invoices: {'invoice': 1.25},
      settlements: {'settlement': 2.5},
      parties: {'party': 3.75},
    );

    expect(balances.invoices['invoice'], 1.25);
    expect(balances.settlements['settlement'], 2.5);
    expect(balances.parties['party'], 3.75);
  });

  test(
    'money operations return guard failures without Supabase config',
    () async {
      final repository = MoneyRepository(MockAuthRepository());
      final invoice = Invoice(
        id: 'invoice',
        number: 'INV-1',
        buyerId: 'party',
        buyerName: 'Customer',
        issueDate: DateTime(2026, 7, 18),
      );
      final settlement = SupplierSettlement(
        id: 'settlement',
        number: 'SET-1',
        supplierId: 'supplier',
        periodStart: DateTime(2026, 7, 1),
        periodEnd: DateTime(2026, 7, 31),
      );
      final payment = Payment(
        id: 'payment',
        direction: PaymentDirection.incoming,
        partyId: 'party',
        date: DateTime(2026, 7, 18),
        amount: 10,
        method: PaymentMethod.cash,
      );
      final expense = Expense(
        id: 'expense',
        date: DateTime(2026, 7, 18),
        category: ExpenseCategory.fuel,
        payee: 'Fuel',
        net: 5,
      );

      expect(await repository.fetchInvoices(), isA<Failure<List<Invoice>>>());
      expect(
        await repository.fetchSettlements(),
        isA<Failure<List<SupplierSettlement>>>(),
      );
      expect(await repository.fetchPayments(), isA<Failure<List<Payment>>>());
      expect(await repository.fetchExpenses(), isA<Failure<List<Expense>>>());
      expect(await repository.fetchInvoicesPage(pageNumber: 1), isA<Failure>());
      expect(
        await repository.fetchSettlementsPage(pageNumber: 1),
        isA<Failure>(),
      );
      expect(await repository.fetchPaymentsPage(pageNumber: 1), isA<Failure>());
      expect(await repository.fetchExpensesPage(pageNumber: 1), isA<Failure>());
      expect(await repository.fetchUnbilledWork(), isA<Failure>());
      expect(await repository.fetchBalances(), isA<Failure<MoneyBalances>>());
      expect(
        await repository.statementRows(Period.month(2026, 7)),
        isA<Failure>(),
      );
      expect(await repository.issueInvoice(invoice), isA<Failure<Invoice>>());
      expect(await repository.voidInvoice('invoice'), isA<Failure<void>>());
      expect(
        await repository.issueSettlement(settlement),
        isA<Failure<SupplierSettlement>>(),
      );
      expect(
        await repository.voidSettlement('settlement'),
        isA<Failure<void>>(),
      );
      expect(await repository.recordPayment(payment), isA<Failure<void>>());
      expect(
        await repository.transitionChequeState('payment', ChequeState.bounced),
        isA<Failure<void>>(),
      );
      expect(
        await repository.markChequeCleared('payment'),
        isA<Failure<void>>(),
      );
      expect(await repository.addExpense(expense), isA<Failure<Expense>>());
      repository.invalidateCache();
    },
  );
}
