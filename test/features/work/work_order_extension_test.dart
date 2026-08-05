import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/work/data/work_order_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and writes a work order with nested rows', () {
    final work = WorkOrderRow.fromRow({
      'id': 'work-1',
      'number': 'WO-1',
      'customer_id': 'customer-1',
      'agreement_id': 'agreement-1',
      'date': '2026-07-18T00:00:00.000',
      'pickup': 'Dubai',
      'destination': 'Abu Dhabi',
      'work_type': 'monthly_extra',
      'planned_start': '2026-07-18T08:00:00.000',
      'planned_end': '2026-07-18T17:00:00.000',
      'customer_job_reference': 'REF-1',
      'description': 'Description',
      'status': 'completed',
      'work_order_allocations': [
        {
          'vehicle_id': 'vehicle-1',
          'driver_id': 'driver-1',
          'source': 'supplier',
          'supplier_id': 'supplier-1',
          'supplier_payable': 10.005,
          'notes': 'Allocation',
        },
      ],
      'work_order_charge_lines': [
        {
          'name': 'Trip',
          'description': 'Charge',
          'quantity': 2.9,
          'unit_price': 10.005,
          'unit': 'trip',
          'discount': 1.005,
          'vat_rate': 5,
        },
      ],
      'notes': 'Notes',
      'invoice_id': 'invoice-1',
    });

    expect(work.workType, WorkType.monthlyExtra);
    expect(work.status, WorkStatus.completed);
    expect(work.plannedStart, isNotNull);
    expect(work.plannedEnd, isNotNull);
    expect(work.allocations.single.source, VehicleSource.supplier);
    expect(work.allocations.single.supplierPayable, 10.01);
    expect(work.chargeLines.single.quantity, 2);
    expect(work.chargeLines.single.unitPrice, 10.01);

    expect(work.toRow('tenant-1'), {
      'id': 'work-1',
      'number': 'WO-1',
      'tenant_id': 'tenant-1',
      'customer_id': 'customer-1',
      'agreement_id': 'agreement-1',
      'date': '2026-07-18T00:00:00.000',
      'work_type': 'monthly_extra',
      'status': 'completed',
      'pickup': 'Dubai',
      'destination': 'Abu Dhabi',
      'planned_start': '2026-07-18T08:00:00.000',
      'planned_end': '2026-07-18T17:00:00.000',
      'customer_job_reference': 'REF-1',
      'description': 'Description',
      'notes': 'Notes',
      'invoice_id': 'invoice-1',
      'allocations': [
        {
          'vehicle_id': 'vehicle-1',
          'driver_id': 'driver-1',
          'source': 'supplier',
          'supplier_id': 'supplier-1',
          'supplier_payable': 10.01,
          'notes': 'Allocation',
        },
      ],
      'charge_lines': [
        {
          'name': 'Trip',
          'description': 'Charge',
          'quantity': 2,
          'unit_price': 10.01,
          'unit': 'trip',
          'discount': 1.01,
          'vat_rate': 5,
        },
      ],
    });
  });

  test('maps nullable dates and empty nested rows', () {
    final work = WorkOrderRow.fromRow({
      'id': 'work-2',
      'number': 'WO-2',
      'customer_id': 'customer-1',
      'agreement_id': null,
      'date': '2026-07-18',
      'pickup': 'A',
      'destination': 'B',
      'work_type': 'per_trip',
      'planned_start': null,
      'planned_end': null,
      'customer_job_reference': null,
      'description': null,
      'status': 'planned',
      'notes': null,
      'invoice_id': null,
    });

    expect(work.plannedStart, isNull);
    expect(work.plannedEnd, isNull);
    expect(work.allocations, isEmpty);
    expect(work.chargeLines, isEmpty);
    expect(work.toRow('tenant-2')['planned_start'], isNull);
    expect(work.toRow('tenant-2')['planned_end'], isNull);
  });

  test('maps allocation and charge line rows directly', () {
    final allocation = VehicleAllocationRow.fromRow({
      'vehicle_id': 'vehicle-1',
      'driver_id': null,
      'source': 'owned',
      'supplier_id': null,
      'supplier_payable': 1.005,
      'notes': null,
    });
    final line = ChargeLineRow.fromRow({
      'name': 'Trip',
      'description': null,
      'quantity': 1.9,
      'unit_price': 2.005,
      'unit': 'unit',
      'discount': 0.005,
      'vat_rate': 5,
    });

    expect(allocation.toRow()['supplier_payable'], 1.01);
    expect(line.toRow()['quantity'], 1);
    expect(line.toRow()['unit_price'], 2.01);
    expect(line.toRow()['discount'], 0.01);
  });
}
