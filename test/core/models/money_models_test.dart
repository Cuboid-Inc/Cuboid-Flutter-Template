import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invoice rounds each line before accumulating totals', () {
    final invoice = Invoice(
      id: 'invoice',
      number: 'INV-1',
      buyerId: 'customer',
      buyerName: 'Customer',
      issueDate: DateTime(2026, 7),
      lines: const [
        InvoiceLine(name: 'A', unitPrice: 0.335),
        InvoiceLine(name: 'B', unitPrice: 0.335),
        InvoiceLine(name: 'C', unitPrice: 0.335),
      ],
    );

    expect(invoice.net, 1.02);
    expect(invoice.vat, 0.06);
    expect(invoice.gross, 1.08);
  });

  test('invoice line honors issued snapshot amount overrides', () {
    const line = InvoiceLine(
      name: 'Snapshot',
      unitPrice: 99,
      netAmountOverride: 10.005,
      vatAmountOverride: 0.505,
    );

    expect(line.net, 10.01);
    expect(line.vat, 0.51);
    expect(line.gross, 10.52);
  });

  test('work order rounds each charge before accumulating totals', () {
    final work = WorkOrder(
      id: 'work',
      number: 'WO-1',
      customerId: 'customer',
      agreementId: 'agreement',
      date: DateTime(2026, 7),
      pickup: 'A',
      destination: 'B',
      chargeLines: const [
        ChargeLine(name: 'A', unitPrice: 0.335),
        ChargeLine(name: 'B', unitPrice: 0.335),
        ChargeLine(name: 'C', unitPrice: 0.335),
      ],
    );

    expect(work.net, 1.02);
    expect(work.vat, 0.06);
    expect(work.gross, 1.08);
  });

  test('expense, settlement, cashbook, and vehicle profit round totals', () {
    final expense = Expense(
      id: 'expense',
      date: DateTime(2026, 7),
      category: ExpenseCategory.fuel,
      payee: 'Fuel',
      net: 0.335,
      vat: 0.335,
    );
    final settlement = SupplierSettlement(
      id: 'settlement',
      number: 'SET-1',
      supplierId: 'supplier',
      periodStart: DateTime(2026, 7),
      periodEnd: DateTime(2026, 7, 31),
      lines: [
        for (var index = 0; index < 3; index++)
          SettlementLine(
            workOrderId: '$index',
            date: DateTime(2026, 7),
            amount: 0.335,
          ),
      ],
    );

    expect(expense.total, 0.67);
    expect(settlement.total, 1.02);
    expect(const CashbookTotals(inAmount: 10.005, outAmount: 3).net, 7.01);
    expect(
      const VehicleProfit(
        vehicleId: 'vehicle',
        revenue: 10.005,
        payable: 2,
        expense: 3,
      ).profit,
      5.01,
    );
  });
}
