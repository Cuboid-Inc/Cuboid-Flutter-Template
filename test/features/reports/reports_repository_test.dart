import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/features/reports/data/reports_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profit folds rounded line totals, payables, and expenses', () {
    final period = Period.month(2026, 7);
    final result = ReportsRepository.profitFor(
      period: period,
      invoices: [
        Invoice(
          id: 'invoice',
          number: 'INV-1',
          buyerId: 'party',
          buyerName: 'Customer',
          issueDate: period.start,
          lines: [
            InvoiceLine(name: 'A', unitPrice: 0.335),
            InvoiceLine(name: 'B', unitPrice: 0.335),
            InvoiceLine(name: 'C', unitPrice: 0.335),
          ],
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
              workOrderId: '1',
              date: DateTime(2026, 7, 1),
              amount: 0.33,
            ),
            SettlementLine(
              workOrderId: '2',
              date: DateTime(2026, 7, 1),
              amount: 0.33,
            ),
            SettlementLine(
              workOrderId: '3',
              date: DateTime(2026, 7, 1),
              amount: 0.33,
            ),
          ],
          status: SettlementStatus.issued,
        ),
      ],
      expenses: [
        Expense(
          id: 'expense',
          date: period.start,
          category: ExpenseCategory.fuel,
          payee: 'Fuel',
          net: 0.01,
        ),
      ],
    );

    expect(result, 0.02);
  });

  test('ownership assigns supplier work to external revenue', () {
    final owned = _work('owned', const [VehicleAllocation(vehicleId: 'v1')]);
    final external = _work('external', const [
      VehicleAllocation(
        vehicleId: 'v2',
        source: VehicleSource.supplier,
        supplierId: 'supplier',
      ),
    ]);

    final result = ReportsRepository.ownershipFor([owned, external]);

    expect(result.owned, 1);
    expect(result.external, 1);
  });

  test('vehicle profit assigns proportional remainder to first allocation', () {
    final work = _work('shared', const [
      VehicleAllocation(vehicleId: 'v1'),
      VehicleAllocation(vehicleId: 'v2'),
      VehicleAllocation(
        vehicleId: 'v3',
        source: VehicleSource.supplier,
        supplierId: 'supplier',
        supplierPayable: 0.10,
      ),
    ]);
    final result = ReportsRepository.vehicleProfitFor(
      vehicles: [_vehicle('v1'), _vehicle('v2'), _vehicle('v3')],
      workOrders: [work],
      expenses: [
        Expense(
          id: 'expense',
          date: DateTime(2026, 7),
          category: ExpenseCategory.fuel,
          payee: 'Fuel',
          net: 0.05,
          vehicleId: 'v1',
        ),
      ],
    );

    expect(result.map((row) => row.revenue), [0.34, 0.33, 0.33]);
    expect(result.map((row) => row.payable), [0, 0, 0.10]);
    expect(result.map((row) => row.expense), [0.05, 0, 0]);
    expect(result.map((row) => row.profit), [0.29, 0.33, 0.23]);
  });

  test('cashbook totals include cleared payments only', () {
    final result = ReportsRepository.cashbookFor([
      _payment('in', PaymentDirection.incoming, 0.335),
      _payment('out', PaymentDirection.outgoing, 0.335),
      _payment(
        'pending',
        PaymentDirection.incoming,
        99,
        method: PaymentMethod.cheque,
        chequeState: ChequeState.received,
      ),
    ]);

    expect(result.inAmount, 0.34);
    expect(result.outAmount, 0.34);
    expect(result.net, 0);
  });
}

WorkOrder _work(String id, List<VehicleAllocation> allocations) => WorkOrder(
  id: id,
  number: id,
  customerId: 'customer',
  agreementId: 'agreement',
  date: DateTime(2026, 7),
  pickup: 'A',
  destination: 'B',
  allocations: allocations,
  chargeLines: const [ChargeLine(name: 'Transport', unitPrice: 1, vatRate: 0)],
);

Vehicle _vehicle(String id) => Vehicle(
  id: id,
  plateNumber: id,
  label: id,
  vehicleClass: VehicleClass.threeTon,
  ownership: VehicleOwnership.owned,
);

Payment _payment(
  String id,
  PaymentDirection direction,
  num amount, {
  PaymentMethod method = PaymentMethod.cash,
  ChequeState chequeState = ChequeState.cleared,
}) => Payment(
  id: id,
  direction: direction,
  partyId: 'party',
  date: DateTime(2026, 7),
  amount: amount,
  method: method,
  chequeState: chequeState,
);
