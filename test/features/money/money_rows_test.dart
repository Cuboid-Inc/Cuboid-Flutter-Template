import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/money/data/money_rows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a statement row and defaults a null amount to zero', () {
    final statement = StatementRowMapping.fromRow({
      'party_id': 'party-1',
      'date': '2026-07-18',
      'work_order_id': 'work-1',
      'description': 'Trip',
      'amount': null,
    });

    expect(statement.partyId, 'party-1');
    expect(statement.date, DateTime(2026, 7, 18));
    expect(statement.amount, 0);
  });

  test('maps unbilled work from list rows', () {
    final result = UnbilledWorkRowMapping.fromRow({
      'customer_name': 'Customer',
      'work_order_id': 'work-1',
      'number': 'WO-1',
      'customer_id': 'customer-1',
      'agreement_id': null,
      'date': '2026-07-18',
      'pickup': 'Dubai',
      'destination': 'Abu Dhabi',
      'work_type': 'per_trip',
      'status': 'planned',
      'planned_start': null,
      'planned_end': null,
      'customer_job_reference': null,
      'description': null,
      'notes': null,
      'allocations': [
        {
          'vehicle_id': 'vehicle-1',
          'driver_id': null,
          'source': 'owned',
          'supplier_id': null,
          'supplier_payable': 10.005,
          'notes': null,
        },
      ],
      'charge_lines': [
        {
          'name': 'Trip',
          'description': null,
          'quantity': 2,
          'unit_price': 10.005,
          'unit': 'trip',
          'discount': 1.005,
          'vat_rate': 5,
        },
      ],
    });

    expect(result.customerName, 'Customer');
    expect(result.workOrder.allocations.single.source, VehicleSource.owned);
    expect(result.workOrder.allocations.single.supplierPayable, 10.01);
    expect(result.workOrder.chargeLines.single.quantity, 2);
    expect(result.workOrder.chargeLines.single.unitPrice, 10.01);
    expect(result.workOrder.plannedStart, isNull);
  });

  test('maps unbilled work from JSON rows and handles unsupported lists', () {
    final result = UnbilledWorkRowMapping.fromRow({
      'customer_name': 'Customer',
      'work_order_id': 'work-2',
      'number': 'WO-2',
      'customer_id': 'customer-1',
      'agreement_id': 'agreement-1',
      'date': '2026-07-18',
      'pickup': 'A',
      'destination': 'B',
      'work_type': 'monthly_extra',
      'status': 'completed',
      'planned_start': '2026-07-18T08:00:00.000',
      'planned_end': '2026-07-18T17:00:00.000',
      'customer_job_reference': 'REF-1',
      'description': 'Description',
      'notes': 'Notes',
      'allocations':
          '[{"vehicle_id":"vehicle-1","driver_id":"driver-1","source":"supplier","supplier_id":"supplier-1","supplier_payable":20,"notes":"N"}]',
      'charge_lines':
          '[{"name":"Extra","description":"D","quantity":1,"unit_price":20,"unit":"hour","discount":0,"vat_rate":5}]',
    });

    expect(result.workOrder.agreementId, 'agreement-1');
    expect(result.workOrder.workType, WorkType.monthlyExtra);
    expect(result.workOrder.status, WorkStatus.completed);
    expect(result.workOrder.plannedStart, isNotNull);
    expect(result.workOrder.plannedEnd, isNotNull);
    expect(result.workOrder.allocations.single.supplierId, 'supplier-1');

    final empty = UnbilledWorkRowMapping.fromRow({
      'customer_name': 'Customer',
      'work_order_id': 'work-3',
      'number': 'WO-3',
      'customer_id': 'customer-1',
      'agreement_id': null,
      'date': '2026-07-18',
      'pickup': 'A',
      'destination': 'B',
      'work_type': 'per_trip',
      'status': 'planned',
      'planned_start': null,
      'planned_end': null,
      'customer_job_reference': null,
      'description': null,
      'notes': null,
      'allocations': 1,
      'charge_lines': 1,
    });
    expect(empty.workOrder.allocations, isEmpty);
    expect(empty.workOrder.chargeLines, isEmpty);
  });

  test('maps an unpaid invoice row', () {
    final unpaid = UnpaidInvoiceRowMapping.fromRow({
      'id': 'invoice-1',
      'number': 'INV-1',
      'buyer_id': 'customer-1',
      'buyer_name': 'Customer',
      'buyer_address': null,
      'buyer_trn': null,
      'buyer_contact': null,
      'payment_terms': 'On receipt',
      'issue_date': '2026-07-18',
      'due_date': null,
      'supply_date': null,
      'status': 'issued',
      'void_reason': null,
      'invoice_lines': const [],
      'balance': 10.005,
    });

    expect(unpaid.invoice.id, 'invoice-1');
    expect(unpaid.invoice.status, InvoiceStatus.issued);
    expect(unpaid.balance, 10.01);
  });
}
