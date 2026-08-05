import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/features/home/data/home_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'home totals folds cleared cash and expense allocations with rounding',
    () {
      final period = Period.month(2026, 7);
      final result = HomeRepository.homeTotalsFor(
        period: period,
        invoices: [
          Invoice(
            id: 'invoice',
            number: 'INV-1',
            buyerId: 'party',
            buyerName: 'Customer',
            issueDate: period.start,
            lines: const [InvoiceLine(name: 'Trip', unitPrice: 10)],
          ),
        ],
        settlements: [
          SupplierSettlement(
            id: 'settlement',
            number: 'SET-1',
            supplierId: 'supplier',
            periodStart: period.start,
            periodEnd: period.end,
            lines: [
              SettlementLine(
                workOrderId: 'work',
                date: period.start,
                amount: 2,
              ),
            ],
          ),
        ],
        payments: [
          Payment(
            id: 'in',
            direction: PaymentDirection.incoming,
            partyId: 'party',
            date: period.start,
            amount: 10,
            method: PaymentMethod.cash,
            allocations: const [
              PaymentAllocation(amount: 10, invoiceId: 'invoice'),
            ],
          ),
          Payment(
            id: 'out',
            direction: PaymentDirection.outgoing,
            partyId: 'party',
            date: period.start,
            amount: 3,
            method: PaymentMethod.cash,
            allocations: const [PaymentAllocation(amount: 1, expenseId: 'e')],
          ),
        ],
        expenses: [
          Expense(
            id: 'e',
            date: period.start,
            category: ExpenseCategory.fuel,
            payee: 'Fuel',
            net: 4,
          ),
        ],
      );

      expect(result.billed, 10.5);
      expect(result.revenue, 10);
      expect(result.operatingCosts, 6);
      expect(result.profit, 4);
      expect(result.received, 10);
      expect(result.paidOut, 3);
      expect(result.cashFlow, 7);
    },
  );
}
